# 05-exception.t
#
# Test suite for WWW::Velib
#
# copyright (C) 2007 David Landgren

use strict;

use Test::More;
eval qq{use Test::Exception};
if( $@ ) {
    plan skip_all => 'Test::Exception is not installed';
}
else {
    plan tests => 4;
}

use WWW::Velib::Map;

dies_ok( sub{WWW::Velib::Map->new(file => '/no/such/file')}, 'no such file' );
dies_ok( sub{WWW::Velib::Map->new(file => 'MANIFEST')},      'garbage file' );

my $m = WWW::Velib::Map->new(file => 'eg/data/map.cache.v1');
dies_ok( sub{$m->save}, 'save no file' );
dies_ok( sub{$m->save('/path/to/nothing/at/all')}, 'save failure' );
