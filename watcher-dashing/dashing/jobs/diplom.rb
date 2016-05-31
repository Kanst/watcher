db = mongo_auth()
interval_sec = 5
table_vision = true
config_file = File.dirname(File.expand_path(__FILE__)) + "/../config/config_assa.yml"

SCHEDULER.every "#{interval_sec}s" do
    if table_vision
        send_event("pg_stat_database", style1: "display: none;", style2: "")
        send_event("server_all_metrics", style1: "display: none;", style2: "")
    else
        send_event("pg_stat_database", style2: "display: none;", style1: "")
        send_event("server_all_metrics", style2: "display: none;", style1: "")
    end

    config = YAML::load(File.open(config_file))
    # send to widgets
    sleep(interval_sec / 6.0)
    data = db['pg_stat_database'].find('err' => false)
    send_to_pg_table(data, config['pg_stat'], table_vision, 'pg_stat_database')

    coll = db['assa']
    res = coll.find('host' => config['host'])
    send_to_one_widget(widget='disk-write', widget_type='Number', mongo_res=res.clone, key='Disk_write')
    send_to_one_widget(widget='disk-read', widget_type='Number', mongo_res=res.clone, key='Disk_read')
    send_to_one_widget(widget='cpu-sys', widget_type='Meter', mongo_res=res.clone, key='CPU_system', interval=interval_sec, div=1, warning=[50, 89], error=[90, 100])
    send_to_one_widget(widget='la1', widget_type='Graph', mongo_res=res.clone, key='System_la1', interval=interval_sec, div=1, warning=[1, 2], error=[2, Float::INFINITY])
    send_to_one_widget(widget='net-send', widget_type='Number', mongo_res=res.clone, key='Net_send')
    send_to_one_widget(widget='net-recv', widget_type='Number', mongo_res=res.clone, key='Net_recv')
    send_to_one_widget(widget='mem-free', widget_type='Graph', mongo_res=res.clone, key='Memory_free', interval=interval_sec, div=0.000001, warning=[67108864, 134217728], error=[0, 67108863])
    send_to_one_widget(widget='cpu-iowait', widget_type='Meter', mongo_res=res.clone, key='CPU_iowait', interval=interval_sec)
    send_to_one_widget(widget='net-retransmit', widget_type='Number', mongo_res=res.clone, key='Net_retransmit', interval=interval_sec, div=1, warning=[100, 199], error=[200, Float::INFINITY])
    res_all = coll.find()
    send_all_to_table(res_all.clone, config['all_metrics'], table_vision, 'server_all_metrics')
    table_vision = !table_vision
end
