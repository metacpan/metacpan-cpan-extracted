WebService::Freshservice [![Build Status](https://travis-ci.org/techman83/WebService-Freshservice.svg?branch=master)](https://travis-ci.org/techman83/WebService-Freshservice)   [![Coverage Status](https://coveralls.io/repos/techman83/WebService-Freshservice/badge.svg?branch=master)](https://coveralls.io/r/techman83/WebService-Freshservice?branch=master)
===========

A Perl client to the [Freshservice API](http://api.freshservice.com/)

Cpanm + Local-Lib
=================

```bash
cpanm WebService::FreshService
```

Build from Source
================= 
Grab cpanm + local::lib
```bash
$ sudo apt-get install cpanminus liblocal-lib-perl
```

Configure local::lib if you haven't already done so:

```bash
$ perl -Mlocal::lib >> ~/.bashrc
$ eval $(perl -Mlocal::lib)
```

Install from git, you can then use:

```bash
$ dzil authordeps | cpanm
$ dzil listdeps   | cpanm
$ dzil install
```

