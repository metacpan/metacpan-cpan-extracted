#!/usr/bin/perl
use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;

ok( my $xu = XHTML::Util->new,
    "XHTML::Util->new " );

dies_ok( sub { $xu->html_to_xhtml('whatever') },
         "Not implemented" );
