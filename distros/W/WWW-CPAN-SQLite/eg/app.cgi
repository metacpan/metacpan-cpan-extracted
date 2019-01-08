#!/usr/bin/env perl

# $Id: app.cgi 68 2019-01-04 00:15:58Z stro $

use strict;
use warnings;
use File::Spec;
use FindBin::Real;
use Plack::Loader;

my $app = Plack::Util::load_psgi(File::Spec->catfile(FindBin::Real::Bin(), 'app.psgi'));
my $rv = Plack::Loader->load('CGI')->run($app);

use Data::Dumper;
warn Data::Dumper->Dump([{
    'app'   => $app,
    'rv'    => $rv,

}]);

