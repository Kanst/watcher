def number_to_human(num, suffix='')
    ['','K','M','G','T','P','E','Z'].each do |unit|
        if num.abs < 1000.0 then
             return "#{format("%3.1f", num)}#{unit}#{suffix}"
        end
        num = num / 1000.0
    end
    return "#{format("%3.1f", num)}Y#{suffix}"
end
