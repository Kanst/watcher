#!/usr/bin/python

import psycopg2
import datetime
import yaml
import multiprocessing
import time
import sys
from pymongo import MongoClient

DEFAULT_DB = 'dashing'


def to_mongo(name, sql_result, err, db):
    group = name
    metric = sql_result
    if not err and metric:
        colnames = metric[1]
        for line in metric[0]:
            tail = {}
            tail['last_update'] = datetime.datetime.now()
            tail['err'] = err
            for x in range(len(line)):
                tail[colnames[x]] = line[x]
            db[group].update({'host': tail['datname']}, {"$set": tail}, True)
    else:
        tail = {}
        tail['last_update'] = datetime.datetime.now()
        tail['err'] = err
        db[group].update({'host': name}, {"$set": tail}, True)


def period(requests, update_time, db):
    while True:
        r = requests
        for request in requests:
            try:
                conn = psycopg2.connect(database=r[request]['db'], user=r[request]['user'], password=r[
                                        request]['pass'], host=r[request]['host'], port=r[request]['port'])
                conn.autocommit = True
                cur = conn.cursor()
                cur.execute(r[request]['request'])
                mops_q = cur.fetchall()
                colnames = [desc[0] for desc in cur.description]
                to_mongo(request, [mops_q, colnames], False, db)
                cur.close()
                conn.close()
            except Exception as e:
                print >> sys.stderr, datetime.datetime.now(), request, e
                to_mongo(request, None, True, db)
        time.sleep(update_time)


def pg_stat_database(conf_file):
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
        all_loopingcall.setdefault(hosts[el]['update_time'], {})[
            el] = hosts[el]

    procs = []
    for update_time, update_time_hash in all_loopingcall.items():
        procs.append(multiprocessing.Process(
            target=period, args=(update_time_hash, update_time, db)))

    for i in range(len(procs)):
        procs[i].daemon = True
        procs[i].start()
    for i in range(len(procs)):
        procs[i].join()


if __name__ == '__main__':
    pg_stat_database('/etc/watcher-server/pg_stat_database_to_mongo.yaml')
