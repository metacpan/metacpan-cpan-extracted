use strict;
use warnings;

use Test::Most;

use constant MODULE => 'Time::DoAfter';

BEGIN { use_ok(MODULE); }
require_ok(MODULE);

my @obj;
ok( push( @obj, MODULE->new ), MODULE . '->new' );
is( ref $obj[-1], MODULE, 'ref $object' );

ok( push( @obj, MODULE->new( sub {} ) ), MODULE . '->new( sub {} )' );
is( ref $obj[-1], MODULE, 'ref $object' );

ok( push( @obj, MODULE->new( 'label1', sub {} ) ), MODULE . '->new( sub {} )' );
is( ref $obj[-1], MODULE, 'ref $object' );

ok( push( @obj,
    MODULE->new( 'label2', sub {}, 2, 3, 'label3', sub {}, sub{}, 'label4', [ 2, 3 ] )
), MODULE . '->new( sub {} )' );
is( ref $obj[-1], MODULE, 'ref $object' );

lives_ok( sub{ $obj[1]->do }, '$object->do' );
lives_ok( sub{ $obj[0]->do( sub {} ) }, '$object->do( sub {} )' );
lives_ok( sub{ $obj[0]->do('label1') }, '$object->do("label") run 1' );
lives_ok( sub{ $obj[0]->do('label1') }, '$object->do("label") run 2' );
lives_ok( sub{ $obj[0]->do('label1') }, '$object->do("label") run 3' );

my $history;
lives_ok( sub { $history = $obj[0]->history }, '$object->history' );
is( @$history, 5, 'full history size' );

lives_ok( sub { $history = $obj[0]->history('label1') }, '$object->history("label")' );
is( @$history, 3, 'label history size' );

lives_ok( sub { $history = $obj[0]->history('label1', 2 ) }, '$object->history( "label", 2 )' );
is( @$history, 2, 'label history size' );

ok( $obj[0]->last, '$object->last' );
ok( $obj[0]->last('label1'), '$object->last("label")' );
ok( $obj[0]->last( 'label1', 1138 ), '$object->last( "label", time )' );
is( $obj[0]->last('label1'), 1138, '$object->last("label") new time' );

ok( $obj[0]->now, '$object->now' );

my $sub = sub {};
isnt( $obj[0]->sub('label1'), $sub, '$object->sub("label")' );
lives_ok( sub { $obj[0]->sub( 'label1', $sub ) }, '$object->sub( "label", sub {} )' );
is( $obj[0]->sub('label1'), $sub, '$object->sub("label") saved' );

is_deeply( $obj[0]->wait('label4'), [ 2, 3 ], '$object->wait("label")' );
lives_ok( sub { $obj[0]->wait( 'label4', [ 5, 7 ] ) }, '$object->wait( "label", $new_wait )' );
is_deeply( $obj[0]->wait('label4'), [ 5, 7 ], '$object->wait("label") saved' );

lives_ok( sub { $obj[0]->wait_adjust( 'label4', 3 ) }, '$object->wait_adjust( "label", 2 )' );
is_deeply( $obj[0]->wait('label4'), [ 8, 10 ], '$object->wait("label") changed OK' );
lives_ok( sub { $obj[0]->wait_adjust( 'label4', -4 ) }, '$object->wait_adjust( "label", -4 )' );
is_deeply( $obj[0]->wait('label4'), [ 4, 6 ], '$object->wait("label") changed OK again' );
lives_ok( sub { $obj[0]->wait_adjust( 'label3', 3 ) }, '$object->wait_adjust( "simple", 3 )' );
is_deeply( $obj[0]->wait('label3'), 6, '$object->wait("simple") changed OK' );

done_testing;
