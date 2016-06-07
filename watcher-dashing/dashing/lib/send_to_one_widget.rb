#!/usr/bin/ruby
# Send events for data-view="Number", data-view="Graph", data-view="Meter" 

def send_to_one_widget(widget='sample-widget', widget_type='Number', mongo_res=nil, key='la', interval=5, div=1, warning=[Float::INFINITY, Float::INFINITY], error=[Float::INFINITY, Float::INFINITY])
    # TODO add last_update
    if mongo_res.count > 0 then
        val = 0
        mongo_res.each do |h|
            if h['err'] == false then
                if h.include?(key) then
                    val = h[key]
                end
            end
        end
    else 
        val = 0
    end
    # div
    val = val.to_f / div
    if val >= error[0] && val < error[1] then
        status = 'warning'
    elsif val >= warning[0] && val <= warning[1] then
        status = 'danger'
    else
        status = 'ok'
    end 

    # get last data
    if widget_type == 'Number' then
        tmp_file = "/tmp/#{widget}-#{widget_type}-#{key}"
        if File.exist?(tmp_file) then
            last = File.open(tmp_file){ |file| file.read }
        else
            last = 0
        end

        File.open(tmp_file, 'w'){ |file| file.write val }

        send_event(widget, { current: val, last: last, status: status })
    elsif widget_type == 'Graph' then
        tmp_file = "/tmp/#{widget}-#{widget_type}-#{key}"
        if File.exist?(tmp_file) then
            points = []
            File.open(tmp_file) do |file|
                file.each_line do |line|
                    points.push(eval(line))
                end
            end
        else
            points = []
            range = 60 / interval - 1
            (0..range).each do |time|
                points.push({x: time * interval, y: 0})
            end  
        end
        last_x = points.last[:x]
        points.shift
        last_x  += interval
        points <<  {x: last_x, y: val.to_f}

        File.open(tmp_file, 'w'){ |file| points.each { |element| file.puts(element) } }

        send_event(widget, points: points, status: status )
    else
        send_event(widget, { value: val.to_f.round(1), status: status } ) 
    end
end

if __FILE__ == $0
    send_to_one_widget()
end
