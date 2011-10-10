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
    
    rss_url = "http://#{host}/job/#{project}/rssAll"

    puts "Polling #{rss_url}"
                      contents = open(rss_url).read
    xml = XmlSimple.xml_in(contents)
    latest_build_info = xml['entry'].first['title'].first
    latest_build_date = xml['entry'].first['published'].first

    match = latest_build_info.match(/#([0-9]+) \((.+)\)$/)
    build_status_text = match[2]
    status.date = latest_build_date
    status.state = build_status_text
    status.build_number = match[1].to_i

    if build_status_text =~ /still/
	status.state = "unstable"
    end

    if build_status_text =~ /started/
	status.state = "unstable"
    end

    if build_status_text =~ /broken/
	status.state = "broken"
    end


    if build_status_text == 'broken'
      status.state = 'claimed' if build_claimed? host, status
    end
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
