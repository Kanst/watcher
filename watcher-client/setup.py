#!/usr/bin/env python
# -*- coding: utf-8 -*-

from setuptools import setup, find_packages


def version():
    return "0.3.0"


def dataFiles():
    from glob import glob
    installPath = "/etc/watcher-client/"
    configPath = "src/etc/watcher-client/"
    result = [(installPath, glob(configPath+"*.cfg")+glob(configPath+"*.conf"))]
    result.append(("/etc/init.d/", ["src/watcher-daemon"]))
    return result

setup(
    name="watcher-client",
    version=version(),
    packages=find_packages(),
    scripts=[
    ],
    data_files=dataFiles(),
    author="Evgeny Avramenko",
    author_email="kanst9@yandex-team.ru",
    description="Watcher-client",
    keywords="watchet client",
    url="https://github.com/Kanst/watcher/watcher-client",
)
