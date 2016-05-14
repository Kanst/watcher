#!/usr/bin/python

import sys
import datetime
from twisted.internet import task
from twisted.web.client import getPage

from pymongo import MongoClient
import simplejson as json
import yaml

DEFAULT_DB = 'dashing'


def to_mongo(name, http, err):
    group = 'http'
    metric = http
    tail = {}
    tail['last_update'] = datetime.datetime.now()
    if not err:
        tail['err'] = False
        if metric != '':
            try:
                http = str(http).replace('\r', '').replace('\n', '')
                r = round(float(http), 2)
                # if r / int(http) == 1:
                #     tail[name] = int(http)
                # else:
                #     tail[name] = r
                tail[name] = r
            except:
                tail[name] = -1
    else:
        tail['err'] = True
    db[group].update({'host': name}, {"$set": tail}, True)


def period(hosts):
    get = []
    errors = []

    def got_http(metrics, host):
        if hosts[host]['type'] == 'json':
            x = json.loads(metrics)
            for n in hosts[host]['name']:
                to_mongo(n, x[hosts[host]['name'][n]], False)
        elif hosts[host]['type'] == 'currency':
            x = json.loads(metrics)
            to_mongo(hosts[host]['name'].keys()[0], x[2], False)
        else:
            to_mongo(hosts[host]['name'].keys()[0], metrics, False)
        get.append(metrics)

    def http_failed(err, host):
        print >> sys.stderr, datetime.datetime.now(), host, err
        if hosts[host]['type'] == 'json':
            for n in hosts[host]['name']:
                to_mongo(n, '-1', True)
        else:
            to_mongo(hosts[host]['name'].keys()[0], '-1', True)
        errors.append(err)

    def http_done(_):
        if len(get) + len(errors) == len(hosts):
            pass
            # from twisted.internet import reactor
            # l.reset()
            # reactor.stop()

    for address in hosts.keys():
        host = address
        d = getPage(host)
        d.addCallback(got_http, host)
        d.addErrback(http_failed, host)
        d.addBoth(http_done)


def http_to_mongo(conf_file):
    connection = MongoClient()
    global db
    db = connection[DEFAULT_DB]
    pwd = open('/etc/watcher-server/pass.pwd').read()[0:-1]
    db.authenticate('dashing', pwd)

    f = open(conf_file, 'r')
    hosts = yaml.safe_load(f)
    f.close()

    all_loopingcall = {}
    for el in hosts:
        all_loopingcall.setdefault(hosts[el]['update_time'], {})[el] = hosts[el]

    for update_time, update_time_hash in all_loopingcall.items():
        l = task.LoopingCall(period, update_time_hash)
        l.start(update_time, now=True)

    from twisted.internet import reactor
    reactor.run()

if __name__ == '__main__':
    http_to_mongo('ymail-http-to-mongo.yaml')
