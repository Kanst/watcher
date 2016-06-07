def correct(string)
    if string.length > 13 then
        return string[0..6] + '..' + string[-4..-1]
    else
        return string
    end
end

def print_package(table, tailer_name, db, group)
    packages = db[group].distinct(tailer_name, {'err' => false})

    for x in packages do 
        items = []
        package = correct(x[7..-9])
        items.push({
                    title: x,
                    value: package,
                    y_class: ''
                })
        a = db[group].find(tailer_name => x, "err" => false).to_a

        err_hosts = []
        for info in a do
            err_hosts.push(info['host'].split('.')[0])
        end

        items.push({
                    title: err_hosts[0..20],
                    value: a.length,
                    y_class: 'text-right'
                    })
        table.push({ cols: items})
    end
    return table
end

def print_package_meta(table, tailer_name, db, group)
    packages = db[group].distinct(tailer_name, {'err' => false})

    for x in packages do 
        items = []
        package = x[0..-8]
        items.push({
                    title: x,
                    value: package,
                    y_class: ''
                })
        a = db[group].find(tailer_name => x, "err" => false).to_a

        err_hosts = []
        for info in a do
            err_hosts.push(info['host'].split('.')[0])
        end

        items.push({
                    title: err_hosts[0..20],
                    value: a.length,
                    y_class: 'text-right'
                    })
        table.push({ cols: items})
    end
    return table
end
