WebService-Strava3    [![Build Status](https://travis-ci.org/techman83/WebService-Strava3.svg?branch=master)](https://travis-ci.org/techman83/WebService-Strava3)  [![Coverage Status](https://coveralls.io/repos/techman83/WebService-Strava3/badge.svg?branch=master)](https://coveralls.io/r/techman83/WebService-Strava3?branch=master)
==================

A Perl client to Version 3 of the Strava.com API

You will need to register for a Client Secret + Access token here:
https://www.strava.com/settings/api

Set the authorization callback domain to: http://127.0.0.1

To setup your authentication run the following
```bash
strava --setup
```

It will generate a file `~/.stravarc` where the authentication information is stored.

It will be available on CPAN soon, but you can install after cloning from github and
using cpanminus.

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

or cpanm (once it's uploaded there):

```bash
cpanm WebService::Strava
```
