#!/usr/bin/python

import sys
import datetime
from twisted.internet import task
from twisted.enterprise import adbapi

from pymongo import MongoClient
import yaml

DEFAULT_DB = 'dashing'


def to_mongo(name, sql_result, err):
    group = 'sql'
    metric = sql_result
    tail = {}
    tail['last_update'] = datetime.datetime.now()
    tail['err'] = err
    if not err:
        if metric != '':
            try:
                tail[name] = float(metric)
            except:
                tail[name] = metric
    db[group].update({'host': name}, {"$set": tail}, True)


def getSQL(info):
    dbpool = adbapi.ConnectionPool(
        info['db_type'],
        db=info['db'],
        user=info['user'],
        passwd=info['pass'],
        host=info['host'],
        port=info['port'],
        cp_reconnect=True
    )
    result = dbpool.runQuery(info['request'])
    dbpool.finalClose()
    if result:
        return result
    else:
        return None


def period(hosts):

    get = []
    errors = []

    def got_sql(metrics, host):
        metrics = metrics[0][0]
        if metrics is not None:
            to_mongo(host, metrics, False)
        else:
            to_mongo(host, metrics, True)

        get.append(metrics)

    def sql_failed(err, host):
        print >> sys.stderr, datetime.datetime.now(), host, err
        to_mongo(host, '', True)
        errors.append(err)

    def sql_done(_):
        if len(get) + len(errors) == len(hosts):
            pass
            # from twisted.internet import reactor
            # l.reset()
            # reactor.stop()

    for request in hosts.keys():
        d = getSQL(hosts[request])
        d.addCallback(got_sql, request)
        d.addErrback(sql_failed, request)
        d.addBoth(sql_done)


def sql_to_mongo(conf_file):
    connection = MongoClient()
    global db
    db = connection[DEFAULT_DB]
    pwd = open('/etc/warcher-server/pass.pwd').read()[0:-1]
    db.authenticate('dashing', pwd)

    f = open(conf_file, 'r')
    hosts = yaml.safe_load(f)
    f.close()

    all_loopingcall = {}
    for el in hosts:
        all_loopingcall.setdefault(hosts[el]['update_time'], {})[
            el] = hosts[el]

    for update_time, update_time_hash in all_loopingcall.items():
        l = task.LoopingCall(period, update_time_hash)
        l.start(update_time, now=True)

    from twisted.internet import reactor
    reactor.run()

if __name__ == '__main__':
    sql_to_mongo('ymail-sql-to-mongo.yaml')
