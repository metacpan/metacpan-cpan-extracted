#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use constant TEMPLATE => 'Time now: <%=scalar localtime 1219952008 %>';

ok(my $t = Text::Template::Simple->new( cache => 1 ), 'object');

ok(my $raw1 = $t->compile( TEMPLATE ),'compile raw1');

ok( $t->cache->has( data => TEMPLATE          ), 'Run 1: Cache has DATA' );
ok( $t->cache->has( id   => $t->cache->id     ), 'Run 1: Cache has ID'   );

ok(my $raw2 = $t->compile( TEMPLATE ),'compile raw2');

ok( $t->cache->has( data => TEMPLATE          ), 'Run 2: Cache has DATA' );
ok( $t->cache->has( id   => $t->cache->id     ), 'Run 2: Cache has ID'   );

ok(my $raw3 = $t->compile( TEMPLATE, undef, { id => '11_cache_mem_t' } ), 'compile raw3');

ok( $t->cache->has( data => TEMPLATE          ), 'Run 3: Cache has DATA' );
ok( $t->cache->has( id   => '11_cache_mem_t'  ), 'Run 3: Cache has ID'   );
is( $t->cache->id, '11_cache_mem_t'            , 'Cache ID OK'           );

is( $raw1, $raw2, 'RAW1 EQ RAW2' );
is( $raw2, $raw3, 'RAW2 EQ RAW3' );

is( $t->cache->type, 'MEMORY', 'Correct cache type is set' );
