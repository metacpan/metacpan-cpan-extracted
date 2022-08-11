#! /usr/bin/env python3
import sys, urllib.request, urllib.error, urllib.parse, time, json, syslog, socket
from daemonize import Daemonize

graphite_servers = [ ('10.0.0.1', 2003), ('10.128.0.18', 2003) ]
purpleair_url='http://10.0.0.153/json'
prefix = 'qq.airquality'

debug=True

metrics = ['current_temp_f', 'current_humidity', 'pressure', 'pm1_0_atm_b', 'pm2_5_atm_b', 'pm10_0_atm_b', 'pm1_0_cf_1_b', 'pm2_5_cf_1_b', 'pm10_0_cf_1_b', 'p_0_3_um_b', 'p_0_5_um_b', 'p_1_0_um_b', 'p_2_5_um_b', 'p_5_0_um_b', 'p_10_0_um_b', 'pm1_0_atm', 'pm2_5_atm', 'pm10_0_atm', 'pm1_0_cf_1', 'pm2_5_cf_1', 'pm10_0_cf_1', 'p_0_3_um', 'p_0_5_um', 'p_1_0_um', 'p_2_5_um', 'p_5_0_um', 'p_10_0_um', 'pm2.5_aqi_b', 'pm2.5_aqi']

def log(x):
    syslog.syslog(syslog.LOG_NOTICE, ("%s" % (x)))
    sys.stderr.write("purpleair-to-graphite: %s" %(x))

def fetch_pa2_data(url):
    try:
        req = urllib.request.Request(url)
        response = urllib.request.urlopen(req)
        body=response.read().decode('utf-8')
        data = json.loads(body)
    except:
        log("failed to fetch %s\r\n" % url)
        data = {}
    return data

def gr_submit(greport):
    for srv in graphite_servers:
        try:
            s = socket.create_connection(srv, 1.0) # short 1.0 sec timeout
            s.send(greport.encode())
            s.send('\r\n'.encode())
            s.close()
        except:
            if debug:
                raise
            log('failed to submit graphite report to %s:%s' % (srv[0], srv[1]))

syslog.openlog(logoption=syslog.LOG_PID, facility=syslog.LOG_USER)

def main():
    while True:
        data = fetch_pa2_data(purpleair_url)
        now = int(time.time())
        greport = ''   
        for m in metrics:
            try:
                greport += '%s.%s.%s %s %d\n' % (prefix, data['SensorId'], m.replace('.','_'), data[m], now)
            except:
                log ('couldn\'t find metric %s' %(m))
        if debug:
            print("submitting:\r\n", greport)
        gr_submit(greport)
        time.sleep(30)
    
if debug:
    main()
else:
    daemon = Daemonize(app='purpleair_to_graphite',
                       pid='/tmp/purpleair_to_graphite.pid',
                       action=main)
    daemon.start()


