require 'rubygems'
require 'ruby-growl'
require 'open-uri'
require 'json'
require 'yaml'

module RcrNotify
  class Notifier
    attr_reader :settings, :last_projects
    
    def initialize
      @settings = {:interval => 30}
      @growl = Growl.new "localhost", "run>code>run notifier", %w(success failure)
    end
    
    def poll
      data = JSON::parse open(url).read
      
      projects = data["user"]["projects"].inject({}) do |hash, project|
        hash.merge project.delete("name") => project
      end

      if last_projects && last_time
        projects.each do |name, this_time|
          notify_for name, last_projects[name], this_time
        end
      end
      
      @last_projects = projects
    end
    
    private
    
    def notify_for(name, last_time, this_time)
      return if this_time['commit'] == last_time['commit']

      commit_message = "\"#{this_time['commit_message']}\"\n" +
                       "\t\t—#{this_time['author_name']}"
        
      title = if success?(this_time)
        success?(last_time) ? 'success' : 'fixed'
      else
        success?(last_time) ? 'broken' : 'still broken'
      end
      
      notify "#{name} build #{title}", commit_message, success?(this_time)
    end
    
    def success?(hash)
      hash && hash["status"] == "success"
    end
        
    def url
      "http://runcoderun.com/api/v1/json/#{settings[:username]}"
    end
  
    def notify(title, body, success)
      type = success ? 'success' : 'failure'
      puts "#{title} (#{type})\n#{body}\n\n"
      @growl.notify type, title, body
    end
  end
end

