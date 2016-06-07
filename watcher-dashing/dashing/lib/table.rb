# Table metrics

def table_all_metrics(buzzword_counts, all_metrics, t1_sleep, script_name, split_str)
# Формирование таблицы выходных данных (по каждой машине)
    table = [];
    buzzword_counts.each_pair do |key,value| 
        items = []
        items.push({
            title: key,
            value: key.split(".#{split_str}")[0],
            y_class: 'text_center'
        })
        if not value['err']
            all_metrics.each do |metric, params|
                metric = metric.to_s
                if params['type'] == 'int' or params['type'] == 'float' then
                    if params['type'] == 'int' then
                        div_value = value[metric].to_i / params['div'].to_f
                    elsif params['type'] == 'float' then
                        div_value = value[metric].to_f / params['div'].to_f
                    end

                    if div_value.to_i > params["max_val_error"].to_i || 
                       div_value.to_i < params["min_val_error"].to_i
                        y_class = "danger text-center"    
                    elsif div_value.to_i > params["max_val_warning"].to_i || 
                          div_value.to_i < params["min_val_warning"].to_i
                        y_class = "warning text-center"    
                    else
                        y_class = 'text-center'
                    end
                    items.push({
                        title: value[metric],
                        value: div_value.to_i,
                        y_class: y_class
                    })
                end
            end
        else
            all_metrics.each do |metric, params|
                y_class = "danger text-center"
                items.push({
                    title: -1,
                    value: -1,
                    y_class: y_class
                })
            end
        end
        table.push({ cols: items})
    end

    # Сортировка
    table = table.sort_by do |key|
        key[:cols].map { |e| e[:value] }.reverse
    end.reverse

    # генерация заголовка таблицы
    table_header = Hash.new()
    table_header['server'] = { value: "server"}
    all_metrics.each do |metric, params|
        table_header[metric] = { value:  params['shortname'] }
    end

    if t1_sleep
        send_event("table_#{script_name}", headers1: table_header.values, rows1: table)
    else
        send_event("table_#{script_name}", headers2: table_header.values, rows2: table)
    end
end
