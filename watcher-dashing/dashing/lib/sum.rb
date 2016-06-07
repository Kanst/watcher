# Summ all 

def sum_all_machine(buzzword_counts, all_metrics, script_name)
    # суммирование по всем машинам
    sum_hash = Hash.new(0)
    buzzword_counts.each_pair do |key,value| 
        all_metrics.each do |metric, params|
            if value[metric] != -1
                sum_hash[metric] += value[metric].to_i
            end    
        end
    end

    # Формируем данные, выводимые на общий виджен (где сумма). При этом делим их на число, указанное в конфиге.
    out_hash = Hash.new()
    all_metrics.each do |metric, params|
        sum = sum_hash[metric] / params['div'].to_i
        len = rp(params['div'].to_i)
        out_hash[metric] = { label: metric[0..(21 - len.length - sum.to_s.length)] + len, value: sum}
    end


    # Разукрашиваем данные
    widget_class = 'widget_class'
    ws_all = []
    all_metrics.each do |metric, params|
        if out_hash[metric][:value] > params['max_sum_error_all'].to_i ||
             out_hash[metric][:value] < params['min_sum_error_all'].to_i
            ws_all.push('failed')
        elsif out_hash[metric][:value] > params['max_sum_warning_all'].to_i || 
                    out_hash[metric][:value] < params['min_sum_warning_all'].to_i
            ws_all.push('passed')
        else
            ws_all.push('')
        end
    end
    ws = ''
    if ws_all.include?('passed')
        ws = 'passed'
    end

    if ws_all.include?('failed')
        ws = 'failed'
    end

    send_event("buzzwords_#{script_name}", items: out_hash.values, widget_class: ws)
end
