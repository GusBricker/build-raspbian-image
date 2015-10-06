#!/bin/bash

BannerEcho "Python: Adding PIP"

AptInstall python
curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | python

BannerEcho "Python: Done"
