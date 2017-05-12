# 01-basic.t
#
# Test suite for WWW::Velib
# Make sure the basic stuff works
#
# copyright (C) 2007 David Landgren

use strict;

eval qq{ use Test::More tests => 16 };
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

eval q{ use_ok 'WWW::Velib' };
eval q{ use_ok 'WWW::Velib::Map' };
eval q{ use_ok 'WWW::Velib::Station' };
eval q{ use_ok 'WWW::Velib::Trip' };

diag( "testing WWW::Velib v$WWW::Velib::VERSION" );
diag( " ...  WWW::Velib::Map v$WWW::Velib::Map::VERSION" );
diag( " ...  WWW::Velib::Station v$WWW::Velib::Station::VERSION" );
diag( " ...  WWW::Velib::Trip v$WWW::Velib::Trip::VERSION" );

{
    my $v = WWW::Velib->new(login => '123456', pin => '9876', defer => 1);
    ok( defined($v), 'WWW::Velib->new() defines ...' );
    ok( ref($v) eq 'WWW::Velib', '... a WWW::Velib object' );
}

{
    my $s = WWW::Velib::Station->make(1, 'station', 'addr', 'fullAddr', 0, 0, 0);
    ok( defined($s), 'WWW::Velib::Station->make() defines ...' );
    ok( ref($s) eq 'WWW::Velib::Station', '... a WWW::Velib::Station object' );
}

{
    my $cost = '2,75'; # need a scalar upon which to transliterate
    my $t = WWW::Velib::Trip->make('01/01/1970', 'from', 'to', 1, 1, $cost);
    ok( defined($t), 'WWW::Velib::Trip->make() defines ...' );
    ok( ref($t) eq 'WWW::Velib::Trip', '... a WWW::Velib::Trip object' );

    is($t->date, '01/01/1970', 'trip date');
    is($t->from, 'from', 'trip from');
    is($t->to, 'to', 'trip to');
    is($t->duration, 61, 'trip duration');
    is($t->cost, 2.75, 'trip cost');
}

is( $_, $Unchanged, $Unchanged );
