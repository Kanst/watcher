# Pixel metrics

def pixel_all_metrics(buzzword_counts, all_metrics, t1_sleep, script_name, split_str)
    # Формирование таблицы пиксельных  выходных данных (по каждой машине)
    pixel = []
    buzzword_counts.each_pair do |key,value| 
        items = []
        items.push({
            title: key,
            value: key.split(".#{split_str}")[0]
        })
        if not value['err']
            all_metrics.each do |metric, params|
                if value[metric] / params["div"].to_i > params["max_val_error"].to_i || 
                     value[metric] / params["div"].to_i < params["min_val_error"].to_i
                    y_class = "danger text-center"  
                elsif   value[metric] / params["div"].to_i > params["max_val_warning"].to_i || 
                            value[metric] / params["div"].to_i < params["min_val_warning"].to_i
                    y_class = "warning text-center" 
                else
                    y_class = 'success text-center'
                end
                items.push({
                    title: value[metric],
                    value: '',
        #           value: value[metric] / params["div"].to_i,
                    y_class: y_class
                })
            end
        else
            all_metrics.each do |metric, params|
                y_class = "danger text-center"    
                items.push({
                    title: -1,
                    value: '',
                    y_class: y_class
                })
            end
        end
        pixel.push({ cols: items})
    end

    # Сортировка

    pixel = pixel.sort_by {|key|
        [key[:cols][0][:value].split('.')[0][-1], key[:cols][0][:value].split('.')[0][-3..-1]]
    }

    # генерация заголовка таблицы
    pixel_header = Hash.new()
    pixel_header['server'] = { value: "s"}
    all_metrics.each do |metric, params|
        pixel_header[metric] = { value:  params['shortname']}
    end

    if t1_sleep
    send_event("pixel_#{script_name}", headers1: pixel_header.values, rows1: pixel)
    else
    send_event("pixel_#{script_name}", headers2: pixel_header.values, rows2: pixel)
    end
end
