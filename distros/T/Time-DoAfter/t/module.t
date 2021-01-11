use Test2::V0;
use Time::DoAfter;

my @obj;
ok( push( @obj, Time::DoAfter->new ), 'Time::DoAfter->new' );
is( ref $obj[-1], 'Time::DoAfter', 'ref $object' );

ok( push( @obj, Time::DoAfter->new( sub {} ) ), 'Time::DoAfter->new( sub {} )' );
is( ref $obj[-1], 'Time::DoAfter', 'ref $object' );

ok( push( @obj, Time::DoAfter->new( 'label1', sub {} ) ), 'Time::DoAfter->new( sub {} )' );
is( ref $obj[-1], 'Time::DoAfter', 'ref $object' );

ok( push( @obj,
    Time::DoAfter->new( 'label2', sub {}, 2, 3, 'label3', sub {}, sub{}, 'label4', [ 2, 3 ] )
), 'Time::DoAfter->new( sub {} )' );
is( ref $obj[-1], 'Time::DoAfter', 'ref $object' );

ok( lives { $obj[1]->do }, '$object->do' ) or note $@;
ok( lives { $obj[0]->do( sub {} ) }, '$object->do( sub {} )' ) or note $@;
ok( lives { $obj[0]->do('label1') }, '$object->do("label") run 1' ) or note $@;
ok( lives { $obj[0]->do('label1') }, '$object->do("label") run 2' ) or note $@;
ok( lives { $obj[0]->do('label1') }, '$object->do("label") run 3' ) or note $@;

my $history;
ok( lives { $history = $obj[0]->history }, '$object->history' ) or note $@;
is( @$history, 5, 'full history size' );

ok( lives { $history = $obj[0]->history('label1') }, '$object->history("label")' ) or note $@;
is( @$history, 3, 'label history size' );

ok( lives { $history = $obj[0]->history('label1', 2 ) }, '$object->history( "label", 2 )' ) or note $@;
is( @$history, 2, 'label history size' );

ok( $obj[0]->last, '$object->last' );
ok( $obj[0]->last('label1'), '$object->last("label")' );
ok( $obj[0]->last( 'label1', 1138 ), '$object->last( "label", time )' );
is( $obj[0]->last('label1'), 1138, '$object->last("label") new time' );

ok( $obj[0]->now, '$object->now' );

my $sub = sub {};
isnt( $obj[0]->sub('label1'), $sub, '$object->sub("label")' );
ok( lives { $obj[0]->sub( 'label1', $sub ) }, '$object->sub( "label", sub {} )' ) or note $@;
is( $obj[0]->sub('label1'), $sub, '$object->sub("label") saved' );

is( $obj[0]->wait('label4'), [ 2, 3 ], '$object->wait("label")' );
ok( lives { $obj[0]->wait( 'label4', [ 5, 7 ] ) }, '$object->wait( "label", $new_wait )' ) or note $@;
is( $obj[0]->wait('label4'), [ 5, 7 ], '$object->wait("label") saved' );

ok( lives { $obj[0]->wait_adjust( 'label4', 3 ) }, '$object->wait_adjust( "label", 2 )' ) or note $@;
is( $obj[0]->wait('label4'), [ 8, 10 ], '$object->wait("label") changed OK' );
ok( lives { $obj[0]->wait_adjust( 'label4', -4 ) }, '$object->wait_adjust( "label", -4 )' ) or note $@;
is( $obj[0]->wait('label4'), [ 4, 6 ], '$object->wait("label") changed OK again' );
ok( lives { $obj[0]->wait_adjust( 'label3', 3 ) }, '$object->wait_adjust( "simple", 3 )' ) or note $@;
is( $obj[0]->wait('label3'), 6, '$object->wait("simple") changed OK' );

done_testing;
