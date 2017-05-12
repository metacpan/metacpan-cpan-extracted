use blib;
use strict;
use autobox::List::Util;
use Test::More tests => 13;

my @r;

@r = []->shuffle;
ok( !@r,	'no args');

@r = [9]->shuffle;
is( 0+@r,	1,	'1 in 1 out');
is( $r[0],	9,	'one arg');

my @in = 1..100;
@r = @in->shuffle;
is( 0+@r,	0+@in,	'arg count');

isnt( "@r",	"@in",	'result different to args');

my @s = sort { $a <=> $b } @r;
is( "@in",	"@s",	'values');

my $r;

$r = []->shuffle;
ok( !@$r,	'no args (ref)');

$r = [9]->shuffle;
is( 0+@$r,	1,	'1 in 1 out (ref)');
is( $r->[0],	9,	'one arg (ref)');

$r = @in->shuffle;
is( 0+@$r,	0+@in,	'arg count (ref)');

isnt( "@$r",	"@in",	'result different to args (ref)');

@s = sort { $a <=> $b } @$r;
is( "@in",	"@s",	'values (ref)');

is @in->shuffle->first(sub { $_ == 5 }), 5, "can chain calls";
