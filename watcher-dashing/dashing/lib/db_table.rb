# Table metrics

def metrics_to_db(buzzword_counts, all_metrics)
    hash = Hash.new()
    buzzword_counts.each_pair do |key, value|
        all_metrics.each do |metric, params|
            if params != '\n' or params != '-1' 
                value[metric].split().each do |host_bb|
                    if hash.has_key?(host_bb.split(':')[1].to_s)
                        hash[host_bb.split(':')[1].to_s] += host_bb.split(':')[0].to_i
                    else
                        hash[host_bb.split(':')[1].to_s] = host_bb.split(':')[0].to_i    
                    end
                end
            end
        end
    end
    return hash
end

def db_table_all_metrics(buzzword_counts, all_metrics, t1_sleep, script_name, split_str)
# Формирование таблицы выходных данных (по каждой машине)
    table = [];
    buzzword_counts.each_pair do |key,value| 
        items = []
        items.push({
            title: key,
            value: key
        })

        all_metrics.each do |metric, params|
            if value > params["max_val_error"].to_i || 
                 value < params["min_val_error"].to_i
                y_class = "danger text-center"    
            elsif    value > params["max_val_warning"].to_i || 
                        value < params["min_val_warning"].to_i
                y_class = "warning text-center"    
            else
                y_class = 'text-center'
            end
            items.push({
                title: value,
                value: value / params["div"].to_i,
                y_class: y_class
            })
        end
        table.push({ cols: items})
    end

    # Сортировка
    table = table.sort_by do |key|
        key[:cols].map { |e| e[:value] }.reverse
    end.reverse

    # генерация заголовка таблицы
    table_header = Hash.new()
    table_header['server'] = { value: "db"}
    all_metrics.each do |metric, params|
        table_header[metric] = { value:  params['shortname'] }
    end
    if t1_sleep
        send_event("db_table_#{script_name}", headers1: table_header.values, rows1: table)
    else
        send_event("db_table_#{script_name}", headers2: table_header.values, rows2: table)
    end
end
