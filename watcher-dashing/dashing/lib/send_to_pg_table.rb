# Table metrics

def send_to_pg_table(data=nil, config=nil, t1_sleep, widget_name)
    # генерация заголовка таблицы
    table_header = Hash.new()
    table_header['table'] = { value: "Таблица в БД", y_class: 'text-center' }
    config['metrics'].each do |metric, params|
        table_header[metric] = { value:  params['shortname'], y_class: 'text-center' }
    end

    table = [];
    data_tmp = data.clone
    data_tmp.each do |line| 
        items = []
        items.push({
            title: line['host'],
            value: line['host'].split(config['split_str'])[0],
            y_class: 'text-center'
        })
        config['metrics'].each do |metric, params|
            if line['err'] then
                y_class = "danger text-center"    
                items.push({
                    title: -1,
                    value: -1,
                    y_class: y_class
                })
            else
                if params['type'] == 'int' or params['type'] == 'float' then
                    if params['type'] == 'int' then
                        div_value = line[metric].to_i / params['div'].to_f
                        div_value = div_value.to_i 
                    elsif params['type'] == 'float' then
                        div_value = line[metric].to_f / params['div'].to_f
                        if div_value >= 100 then
                            div_value = div_value.to_i
                        else
                            div_value = div_value.round(2)
                        end
                    end

                    if params.include?('max_val_error') then
                        if div_value.to_i > params["max_val_error"].to_i || 
                           div_value.to_i < params["min_val_error"].to_i
                            y_class = "danger text-center"    
                        elsif div_value.to_i > params["max_val_warning"].to_i || 
                              div_value.to_i < params["min_val_warning"].to_i
                            y_class = "warning text-center"    
                        else
                            y_class = 'text-center'
                        end
                    else
                        y_class = 'text-center'
                    end
                    items.push({
                        title: line[metric],
                        value: number_to_human(div_value),
                        y_class: y_class
                    })
                end
            end
        end
  
        table.push({ cols: items})
    end

    # footer
    table_footer = []
    table_footer.push({
        title: 'total',
        value: 'Все',
        y_class: 'text-center',
    })
    config['metrics'].each do |metric, params|
        if params['total'] then
            sum = 0
            data_tmp = data.clone
            data_tmp.each do |line|
                if params['type'] == 'int' then
                    sum += line[metric].to_i
                elsif params['type'] == 'float' then
                    sum += line[metric].to_f 
                end
            end
            sum = number_to_human(sum.to_i)
        else
            sum = '-'
        end
        table_footer.push({
            title: metric,
            value: sum,
            y_class: 'text-center'
        })
    end
    table.unshift({ cols: table_footer})


    if t1_sleep
        send_event(widget_name, headers1: table_header.values, rows1: table)
    else
        send_event(widget_name, headers2: table_header.values, rows2: table)
    end
end
