jenkins_host = 'psn-ci:8080'

config = {
  'default' => [
    { :jenkins_host => jenkins_host, :projects => "gate-1-build" },
    { :jenkins_host => jenkins_host, :projects => "gate-2a-quick_test" },
    { :jenkins_host => jenkins_host, :projects => "gate-2b-integration_test" },
    { :jenkins_host => jenkins_host, :projects => "gate-3-staging"},
  ],
}

host = `hostname -s`.chomp
host = 'default' if config[host].nil?

HOSTS = config[host].map { |line| line[:jenkins_host] }
PROJECT_INCLUSIONS = config[host].map { |line| line[:projects] }
QUIET_SUCCESS = /^git.*/

puts "ci_monitor PID #{Process.pid} is now monitoring projects: #{PROJECT_INCLUSIONS.inspect} from #{HOSTS}"
