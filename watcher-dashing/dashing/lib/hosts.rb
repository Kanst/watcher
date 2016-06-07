# Hosts to file
#

require 'net/http'
require 'fileutils'

def hosts_to_file(group)
    begin
       page_source = Net::HTTP.get(URI.parse("http://ro.admin.yandex-team.ru/api/host_query.sbml?grpgroup=conductor.#{group.to_s}"))
       if not page_source.include?('error')

           File.open("#{File.dirname(File.expand_path(__FILE__))}/../hosts/#{group}.hosts.tmp", 'w') do |f2|  
               f2.puts page_source  
           end  
           
           if File.file?("#{File.dirname(File.expand_path(__FILE__))}/../hosts/#{group}.hosts")
               if not FileUtils.cmp("#{File.dirname(File.expand_path(__FILE__))}/../hosts/#{group}.hosts.tmp", "#{File.dirname(File.expand_path(__FILE__))}/../hosts/#{group}.hosts")
                   FileUtils.mv("#{File.dirname(File.expand_path(__FILE__))}/../hosts/#{group}.hosts.tmp", "#{File.dirname(File.expand_path(__FILE__))}/../hosts/#{group}.hosts")
               end
           else
               FileUtils.mv("#{File.dirname(File.expand_path(__FILE__))}/../hosts/#{group}.hosts.tmp", "#{File.dirname(File.expand_path(__FILE__))}/../hosts/#{group}.hosts")
           end
       end

    rescue SocketError => e
            puts "[#{Time.now.to_s}] #{e.message} #{group}"
    end
end
