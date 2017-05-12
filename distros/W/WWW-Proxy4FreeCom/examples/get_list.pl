#!perl

use strict;
use warnings;

use lib qw(lib ../lib);

use WWW::Proxy4FreeCom;

my $prox = WWW::Proxy4FreeCom->new;

my $proxies = $prox->get_list
    or die $prox->error;

printf "%-40s (last tested %s ago)\n", @$_{ qw(domain last_test) }
    for @$proxies;