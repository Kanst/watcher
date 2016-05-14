#!/usr/bin/python

import sys
import datetime
import json
import os
import re

from twisted.internet import defer
from twisted.internet.protocol import Protocol, ClientFactory
from twisted.internet import task
from twisted.names.client import getHostByName

from pymongo import MongoClient

DEFAULT_PORT = 89
DEFAULT_DB = 'dashing'


class GetProtocol(Protocol):

    tailer = ''

    def dataReceived(self, data):
        self.tailer += data

    def connectionLost(self, reason):
        self.tailerReceived(self.tailer)

    def tailerReceived(self, tailer):
        self.factory.tailer_finished(tailer)


class GetClientFactory(ClientFactory):

    protocol = GetProtocol

    def __init__(self, deferred, host):
        self.deferred = deferred
        self.host = host

    def tailer_finished(self, tailer):
        if self.deferred is not None:
            d, self.deferred = self.deferred, None
            d.callback(tailer)

    def clientConnectionFailed(self, connector, reason):
        if self.deferred is not None:
            d, self.deferred = self.deferred, None
            d.errback(reason)


def get_tailer(host, port):
    d = defer.Deferred()
    factory = GetClientFactory(d, host)
    from twisted.internet import reactor
    reactor.connectTCP(host, port, factory)
    return d


def to_mongo(group, host, tailer, err):
    group = group
    tailer_metrics = tailer.split('\n')
    tail = {}
    tail['last_update'] = datetime.datetime.now()
    if not err:
        tail['err'] = False
        for metric in tailer_metrics:
            if metric != '':
                spl = metric.split('=')
                try:
                    tail[spl[0].strip()] = int(spl[1].strip())
                except:
                    tail[spl[0].strip()] = '='.join(spl[1:].strip())
    else:
        tail['err'] = True
    db[group].update({'host': host}, {"$set": tail}, True)


def netcat_to_mongo(group, update_time, tailer_port, ipv6only=False):
    connection = MongoClient()
    global db
    db = connection[DEFAULT_DB]
    pwd = open('/etc/watcher-server/pass.pwd').read()[0:-1]
    db.authenticate('dashing', pwd)
    global grr
    grr = group
    db[grr].ensure_index('host', unique=True)

    tmpfile = "/tmp/tailer_%s" % group
    if os.path.isfile(tmpfile):
        os.remove(tmpfile)

    # fix me
    if ipv6only:
        def resolv():
            get = {}
            gr = '/etc/watcher-server/hosts/%s' % group
            f = open(gr, 'r')
            hosts = f.readlines()
            hosts = [x[0:-1] for x in hosts]

            if os.path.isfile(tmpfile):
                f = open(tmpfile)
                data_tmp = json.load(f)
                f.close()
            else:
                data_tmp = {}

            def resolv_host(metrics, host):
                get[host] = metrics

            def resolv_failed(err, host):
                print >> sys.stderr, datetime.datetime.now(), host, err
                get[host] = host

            def tailer_done(_):
                if len(get) == len(hosts):
                    for key, value in get.items():
                        matches = re.compile(
                            '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))').findall(value)
                        if len(matches):
                            data_tmp[key] = value
                        else:
                            data_tmp[key] = data_tmp.get(key, value)

                    with open(tmpfile, 'w') as outfile:
                        json.dump(data_tmp, outfile)
                    r.reset()

            for addres in hosts:
                host = addres
                d = getHostByName(host, timeout=(2, 3))
                d.addCallback(resolv_host, host)
                d.addErrback(resolv_failed, host)
                d.addBoth(tailer_done)

        r = task.LoopingCall(resolv)
        r.start(20, now=True)

    def f():
        get = []
        errors = []

        if os.path.isfile(tmpfile):
            f = open(tmpfile)
            data = json.load(f)
            f.close()
        else:
            gr = '/etc/watcher-server/hosts/%s' % group
            f = open(gr, 'r')
            hosts = f.readlines()
            hosts = [x[0:-1] for x in hosts]
            data = {}
            for x in hosts:
                data[x] = x

        def got_tailer(metrics, host):
            to_mongo(group, host, metrics, False)
            get.append(metrics)

        def tailer_failed(err, host):
            print >> sys.stderr, datetime.datetime.now(), host, err
            to_mongo(grr, host, '', True)
            errors.append(err)

        def tailer_done(_):
            if len(get) + len(errors) == len(data):
                l.reset()

        for key, value in data.items():
            host = key
            addres = value
            port = tailer_port
            d = get_tailer(addres, port)
            d.addCallback(got_tailer, host)
            d.addErrback(tailer_failed, host)
            d.addBoth(tailer_done)

    l = task.LoopingCall(f)
    l.start(update_time, now=True)

    from twisted.internet import reactor
    reactor.run()

if __name__ == '__main__':
    netcat_to_mongo('mail_xivahub', 5, 89, True)
