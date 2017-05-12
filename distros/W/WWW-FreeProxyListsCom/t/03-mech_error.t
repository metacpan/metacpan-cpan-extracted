#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

BEGIN {
    use_ok('WWW::FreeProxyListsCom');
};

my $o = WWW::FreeProxyListsCom->new(timeout => 10);

# set a faulty url to force an error

$o->_url('');

SKIP: {
    eval { my $list_ref = $o->get_list(type => 'elite'); };
    if ($@) { 
        print $@;
        skip 'errored out expectedly', 1;
    }
};

done_testing();
