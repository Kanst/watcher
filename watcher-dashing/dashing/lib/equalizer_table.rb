# Table metrics

def equalizer_table_all_metrics(buzzword_counts, all_metrics, t1_sleep, script_name, split_str)
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
                if params['type'] == 'int' or params['type'] == 'float' then
                    if params['type'] == 'int' then
                        div_value = value[metric].to_i / params['div'].to_f
                        div_value = div_value.to_i
                    elsif params['type'] == 'float' then
                        div_value = value[metric].to_f / params['div'].to_f
                        if div_value >= 100 then
                            div_value = div_value.to_i
                        else
                            div_value = div_value.round(2)
                        end
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
                        value: div_value,
                        y_class: y_class
                    })
                end
            end
        else
            all_metrics.each do |metric, params|
                y_class = "danger text-center"    
                #items.push({
                #    title: -1,
                #    value: -1,
                #    y_class: y_class
                #})
            end
        end
        table.push({ cols: items})
    end

    # table_fail = []

    # table.each do |v|
    #     f = false
    #     v[:cols].each do |z|
    #         if z[:y_class].include?('warning') || z[:y_class].include?('danger') then
    #             f = true
    #         end
    #     end
    #     if f then
    #         table_fail.push(v)
    #     end
    # end

    # table = table_fail

    # Сортировка
    # table = table.sort_by do |key|
    #     [key[:cols][3][:value], key[:cols][0][:value][-1], -key[:cols][0][:value][0..-1].split('eb')[1].to_i]
    # end.reverse

    # генерация заголовка таблицы
    table_header = Hash.new()
    table_header['server'] = { value: "server"}
    all_metrics.each do |metric, params|
        table_header[metric] = { value:  params['shortname'] }
    end

    # footer
    table_footer = []
    table_footer.push({
        title: 'total',
        value: 'total',
        y_class: 'text-center',
    })
    all_metrics.each do |metric, params|
        if params['total'] then
            sum = 0
            buzzword_counts.each_value do |value|
                if params['type'] == 'int' then
                    sum += value[metric].to_i
                elsif params['type'] == 'float' then
                    sum += value[metric].to_f 
                end
            end
            sum = sum.to_i
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
    table.push({ cols: table_footer})

    if t1_sleep
        send_event("table_#{script_name}", headers1: table_header.values, rows1: table)
    else
        send_event("table_#{script_name}", headers2: table_header.values, rows2: table)
    end
end
