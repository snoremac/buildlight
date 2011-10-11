require 'rubygems'
require 'open-uri'
require 'zlib'
require 'xmlsimple'
require 'config'
require 'ostruct'

# make sure we don't try to use a proxy
ENV['http_proxy'] = nil

def get_all_projects_status(host, projects)
  statuses = []
  
  projects.each do |project|
    status = OpenStruct.new
    status.name = project
    status.state = 'unknown'
    
    rss_url = "http://#{host}/job/#{project}/api/xml"
    contents = open(rss_url).read
    xml = XmlSimple.xml_in(contents)
	all_builds = xml['build'].collect {|build| build['number'].to_s}.sort.reverse

   	last_result = nil
	building = nil
	if xml['color'].first == "disabled"
		last_result = "stopped"
		building = "false"
	else
		while !last_result do
    			rss_url = "http://#{host}/job/#{project}/#{all_builds.shift}/api/xml"
    			contents = open(rss_url).read
    			xml = XmlSimple.xml_in(contents)
			building ||= xml['building']
			if xml['result'] 
				last_result = xml['result'].first.downcase     
			end
		end
	  	latest_build_date = xml['timestamp'].first
   		status.date = latest_build_date
    	status.build_number = xml['number'].first
	 end
	
	status.building = building
  	status.state = last_result
    statuses << status
  end

  puts "--> #{statuses.inspect}"

  statuses
end

def build_claimed? host, project_status
  claimed_rss_url = "http://#{host}/job/#{project_status.name}/#{project_status.build_number}/"
  html = open(claimed_rss_url).readlines(nil).first
  !!(html =~ /This build was claimed by/)
end
