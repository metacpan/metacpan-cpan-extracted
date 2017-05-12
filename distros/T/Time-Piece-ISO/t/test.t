#!/usr/bin/perl -w

use strict;
use Test::More tests => 23;
use constant DEBUG => 0;
BEGIN { use_ok 'Time::Piece::ISO' };

# Try base class functionality.
ok(my $t = gmtime(315532800), 'Get object from gtime'); # 00:00:00 1/1/1980
is($t->hour, 0, 'Hour is 0');
is($t->mon, 1, "Month is 1");
isa_ok(localtime, 'Time::Piece');
isa_ok(localtime, 'Time::Piece::ISO');
isa_ok(gmtime, 'Time::Piece');
isa_ok(gmtime, 'Time::Piece::ISO');

# Try new functionality.
ok( $t = Time::Piece::ISO->new(315532800), # 00:00:00 1/1/1980
    "Get object from new()");
ok( my $t2 = localtime(315532800), "Get object from localtime");
is($t <=> $t2, 0,
   "New and localtime objects should numerically be the same time");
is($t cmp $t2, 0,
   "New and localtime objects should stringly be the same time");

# Compare to a Time::Piece object.
ok my $tp = Time::Piece->new(315532800), "Create Time::Piece object";
is($t <=> $tp, 0,
   "Comparison to Time::Piece objects should numerically be the same time");
is($t cmp $t2, 0,
   "Comparison to Time::Piece  objects should stringly be the same time");


# cmp operator.
ok($t = gmtime(315532800), # 00:00:00 1/1/1980
   "Get object from gmtime again");
is($t cmp "1980-01-01T00:00:00", 0,
   "Stringification comparison should be equal");
is($t cmp "1990-01-01T00:00:00", -1,
   "Stringification comparison should be less than");
is($t cmp "1970-01-01T00:00:00", 1,
   "Stringification comparison should be greater than");

# String operator and iso() method.
is("$t", "1980-01-01T00:00:00", "Stringification should be ISO format");
is($t->iso, "1980-01-01T00:00:00", "iso() should return ISO format");

# Test strptime.
isa_ok(Time::Piece::ISO->strptime("1980-01-01T00:00:00"), 'Time::Piece' );
isa_ok(Time::Piece::ISO->strptime("1980-01-01T00:00:00"), 'Time::Piece::ISO' );
