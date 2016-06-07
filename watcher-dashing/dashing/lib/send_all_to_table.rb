# Table metrics

def send_all_to_table(data=nil, config=nil, t1_sleep, widget_name)
    # генерация заголовка таблицы
    table_header = Hash.new()
    table_header['table'] = { value: "Сервер", y_class: 'text-center' }

    ignore_metrics = ['_id', 'last_update', 'host', 'err']
    ignore_metrics += config['ignore'].split(',')

    table = [];
    data.each do |line| 
        if line['err'] == true then
            next
        end
        items = []
        items.push({
            title: line['host'],
            value: line['host'].split(config['split_str'])[0],
            y_class: 'text-center'
        })
        line.sort.each do |key, value| 
            if ignore_metrics.include?(key) then
                next
            end
            # Чтобы не занимало много места
            v = key.gsub('Memory', 'M').gsub('System', 'S').gsub('Disk', 'D').gsub('Net', 'N').gsub('CPU', 'C')
            # Начальная строка
            table_header[key] = { value:  v, title: key, y_class: 'text-center' }

            y_class = 'text-center'
            div_value = value
            if config['metrics'].include?(key) then
                params = config['metrics'][key]
                div_value = value.to_f / params['div'].to_f
                if div_value.to_f > params["max_val_error"].to_f || 
                   div_value.to_f < params["min_val_error"].to_f
                    y_class = "danger text-center"    
                elsif div_value > params["max_val_warning"].to_f || 
                      div_value < params["min_val_warning"].to_f
                    y_class = "warning text-center"    
                else
                    y_class = 'text-center'
                end

            end
            items.push({
                title: div_value,
                value: number_to_human(div_value.to_f),
                y_class: y_class
            })

        end
        table.push({ cols: items})
    end

    #                 if div_value.to_i > params["max_val_error"].to_i || 
    #                    div_value.to_i < params["min_val_error"].to_i
    #                     y_class = "danger text-center"    
    #                 elsif div_value.to_i > params["max_val_warning"].to_i || 
    #                       div_value.to_i < params["min_val_warning"].to_i
    #                     y_class = "warning text-center"    
    #                 else
    #                     y_class = 'text-center'
    #                 end
    #                 items.push({
    #                     title: line[metric],
    #                     value: number_to_human(div_value),
    #                     y_class: y_class
    #                 })
    #             end
    #         end
    #     end
  
    # end

    # # footer
    # table_footer = []
    # table_footer.push({
    #     title: 'total',
    #     value: 'Все',
    #     y_class: 'text-center',
    # })
    # config['metrics'].each do |metric, params|
    #     if params['total'] then
    #         sum = 0
    #         data_tmp = data.clone
    #         data_tmp.each do |line|
    #             if params['type'] == 'int' then
    #                 sum += line[metric].to_i
    #             elsif params['type'] == 'float' then
    #                 sum += line[metric].to_f 
    #             end
    #         end
    #         sum = number_to_human(sum.to_i)
    #     else
    #         sum = '-'
    #     end
    #     table_footer.push({
    #         title: metric,
    #         value: sum,
    #         y_class: 'text-center'
    #     })
    # end
    # table.unshift({ cols: table_footer})


    if t1_sleep
        send_event(widget_name, headers1: table_header.values, rows1: table)
    else
        send_event(widget_name, headers2: table_header.values, rows2: table)
    end
end
