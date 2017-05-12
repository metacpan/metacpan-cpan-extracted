#!/usr/bin/perl 

use strict;
use warnings;

use Test::More tests => 3;
use XML::Writer::Simple partial => 1, tags => [qw/a b c d e/];


is(start_a(),"<a>\n");
is(start_a({foo=>'bar'}),"<a foo=\"bar\">\n");
is(end_e(),"</e>\n");
