# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 1;

BEGIN { use_ok('WWW::Mechanize::Pluggable') };

my $mech = WWW::Mechanize::Pluggable->new();
