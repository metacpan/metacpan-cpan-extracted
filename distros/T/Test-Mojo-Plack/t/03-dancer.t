#!/usr/bin/perl

use strict;
use warnings;

use Test::Mojo::Plack;
use Test::More skip_all => 'Need to implement fake Dancer application';

use FindBin;
use lib "$FindBin::Bin/lib";

my $t = Test::Mojo::Plack->new('FakeDancerApp');

$t->get_ok('/')->status_is('200')->content_type_is('text/plain')->content_is('Hello from Catalyst');

done_testing;
