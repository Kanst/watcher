# Summ all 
require 'mongo'


def pull(group)
    db = mongo_auth()
    coll   = db[group]
    hosts = []
    f = File.open("/etc/ymail-hostlist/hosts/#{group}") 
    f.each do |line|
        hosts.push(line)
    end
    
    h = Hash.new() 
    coll.find.each do |row|
        if hosts.include?("#{row['host']}\n") then	
                h[row['host']] = row
        end
    end

    return h
end

def pull2(group)
    db = mongo_auth()
    coll   = db[group]
     
    hosts = ["kanst9", "bombastic"]
    
    h = Hash.new() 
    coll.find.each do |row|
        if hosts.include?(row['name']) then
                h[row['name']] = row
        end
    end

    return h
end
