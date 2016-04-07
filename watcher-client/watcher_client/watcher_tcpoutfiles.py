#!/usr/bin/env python
# encoding: utf-8

import socket
import logging
from ConfigParser import RawConfigParser
import os.path


def send_answer(conn, data=""):
    conn.send(str(data))


def parse(conn, addr, files, log):
    out = ''
    if len(files) == 0:
        log.error('No file for output')
    else:
        for cat in files:
            if os.path.isfile(cat):
                f = open(cat, 'r')
                out += f.read()
                f.close()
            else:
                log.error('File %s not exist' % cat)
    send_answer(conn, data=out)


def watcher_tcpoutfiles():
    # parse config
    config = RawConfigParser()
    config.read('/etc/watcher-client/watcher-tcpoutfiles.conf')
    _port = config.getint('main', 'port')
    files = []
    for i in config.items('files'):
        files.append(i[1])

    # greate logging
    log = logging.getLogger('tcpoutfiles')
    log.setLevel(config.get('main', 'log_level').upper())
    _format = logging.Formatter("%(asctime)s [%(levelname)s] %(name)s:\t%(message)s")
    _handler = logging.FileHandler(
        '/var/log/watcher-client/watcher-tcpoutfiles.log')
    _handler.setFormatter(_format)
    _handler.setLevel(config.get('main', 'log_level').upper())
    log.addHandler(_handler)

    # create socket
    sock = socket.socket()
    sock.bind(("", _port))
    sock.listen(5)
    log.info('Starting server')

    try:
        while 1:
            conn, addr = sock.accept()
            log.info("New connection from " + addr[0])
            try:
                parse(conn, addr, files, log)
            except Exception as e:
                log.exception(e)
                send_answer(conn, data=e)
            finally:
                conn.close()
    except KeyboardInterrupt:
        sock.close()
    finally:
        sock.close()


if __name__ == "__main__":
    watcher_tcpoutfiles()
