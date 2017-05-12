#!/usr/bin/env perl

use strict;
use warnings;
use constant TESTS   => 7;
use Test::More tests => TESTS;

BEGIN { use_ok('WWW::Wordnik::API'); }
require_ok('WWW::Wordnik::API');

my $wn = WWW::Wordnik::API->new();

$wn->server_uri('http://www.example.com/api-v3');
$wn->debug(1);
$wn->cache(2);
$wn->format('perl');

my $namespace = 'word';
my $query     = 'Wordnik/definitions';
my $response  = '{"message":"word not found","type":"error"}';
my $request   = undef;
my $data      = undef;

is( $request = $wn->_build_request( $namespace, $query ),
    'http://www.example.com/api-v3/word.json/Wordnik/definitions',
    '_build_request'
);

my $cache = {
    max      => 2,
    requests => { $request => \$data },
    data     => [ [ $request, $data ], ],
};

is( $data = $wn->_load_cache( $request, $data ),
    $data, '_load_cache returns loaded data' );

is_deeply( $wn->{_cache}, $cache, '_cache built correctly' );

is( $wn->_pop_cache, $data, '_pop_cache returns unloaded data' );

$cache = {
    max      => 2,
    requests => {},
    data     => [],
};

is_deeply( $wn->{_cache}, $cache, '_cache emptied correctly' );

