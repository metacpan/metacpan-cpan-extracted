#!/usr/bin/env perl

# $Id: app.fcgi 68 2019-01-04 00:15:58Z stro $

use strict;
use warnings;
use 5.010;

use FCGI;
use Plack::Loader;

my $app = Plack::Util::load_psgi('./app.psgi');
my $request = FCGI::Request();

while ($request->Accept() >= 0) {
  Plack::Loader->load('CGI')->run($app);
}

