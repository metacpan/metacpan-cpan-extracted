#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Piece ();
my $s = '2026-10-15T09:05:07Z';
my $tk = rate(sub { Time::Keeper->parse($s) }, 'Time::Keeper');
mark('parse ISO 8601; Time::Piece by strptime', $tk, rate(sub { Time::Piece->strptime('2026-10-15T09:05:07', '%Y-%m-%dT%H:%M:%S') }, 'Time::Piece'), 1, 'Time::Piece');
if (eval { require DateTime::Format::ISO8601; 1 }) {
    mark('parse ISO 8601', $tk, rate(sub { DateTime::Format::ISO8601->parse_datetime($s) }, '::ISO8601'), 10, '::ISO8601');
}
else { print "SKIP parse ISO 8601 against DateTime::Format::ISO8601: not installed\n" }
done();
