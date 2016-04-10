#!/usr/bin/env python
# -*- coding: utf-8 -*-

from setuptools import setup, find_packages


def version():
    return "0.3.0"


def dataFiles():
    from glob import glob
    from os import listdir
    installPath = "/etc/watcher-server/"
    configPath = "src/etc/watcher-server/"
    result = [(installPath, glob(configPath+"*.yaml")+glob(configPath+"*.pwd")+glob(configPath+"*.example"))]
    result.append(("/etc/init.d/", ["src/watcher-server-daemon"]))
    result.append(("/etc/watcher-server/hosts/", ["src/etc/watcher-server/hosts/assa"]))
    return result


setup(
    name="watcher-server",
    version=version(),
    packages=find_packages(),
    scripts=[
    ],
    data_files=dataFiles(),
    author="Evgeny Avramenko",
    author_email="kanst9@yandex-team.ru",
    description="Watcher-server",
    keywords="watchet server",
    url="https://github.com/Kanst/watcher/watcher-server",
)
