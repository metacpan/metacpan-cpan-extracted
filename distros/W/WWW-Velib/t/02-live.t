# 02-live.t
#
# Test suite for WWW::Velib
# Try a real connection
#
# copyright (C) 2007 David Landgren

use strict;

use Test::More tests => 11;

use WWW::Velib;
use WWW::Velib::Map;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

SKIP: {

my $login = $ENV{PERL_TESTING_WWW_VELIB_LOGIN};
my $pin   = $ENV{PERL_TESTING_WWW_VELIB_PIN};

skip 'PERL_TESTING_WWW_VELIB_* environment variables not set, see README', 7
	unless defined $login and defined $pin;

my ($v, $err);
eval {$v = WWW::Velib->new( login => $login, pin => $pin, cache_dir => '.' )};
$err = $@;
is($err,'', 'new() succeeded');

is(ref($v), 'WWW::Velib', 'instantiated a live object');
cmp_ok(length($v->{html}{myaccount}), '>', 0, 'have some content');

like($v->end_date, qr{\A\d{2}/\d{2}/\d{4}\Z}, 'have a date');

cmp_ok($v->remain, '>', 0, 'account expires in more than 1 day');

eval {$v->get_month};
$err = $@;
is($err,'', 'get_month() succeeded');

cmp_ok(length($v->{html}{month}), '>', 0,
	'got some content for the trips of the month');
}

my $map = WWW::Velib::Map->new;

is(ref($map),'WWW::Velib::Map', 'instantiated a WWW::Velib::Map');

my $file;
do {
	$file = join '.', "test.map", time, $$, rand(9999);
} while (-f $file); # vague race condition possible

$map->save($file);
ok( -f $file, 'dumped local cache of map');

my $m2 = WWW::Velib::Map->new(file => $file);
is(ref($m2),'WWW::Velib::Map', 'instantiated a cached WWW::Velib::Map');

is( $_, $Unchanged, $Unchanged );
