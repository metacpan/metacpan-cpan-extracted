#!perl
use strict;
use warnings;

use Test::More;
use Scalar::Util    qw[blessed refaddr];

use lib 't';
use Util            qw[ throws_ok ];
use Time::Str::Util qw[ find_tzdb_directory ];

my $TZDIR = find_tzdb_directory();

# Skip all tests if zoneinfo is not available
unless (defined $TZDIR && -f "$TZDIR/UTC") {
  plan skip_all => "zoneinfo directory not available";
}

use_ok('Time::Str::TimeZone', qw[timezone]);

## timezone(): argument checking

throws_ok { timezone() }
  qr/^Usage: timezone/,
  'timezone: no arguments';

throws_ok { timezone('UTC', 'extra') }
  qr/^Usage: timezone/,
  'timezone: too many arguments';

## timezone(): invalid IANA names croak

throws_ok { timezone('') }
  qr/not a valid IANA Time Zone Database timezone name/,
  'timezone: empty name';

throws_ok { timezone('Europe/Stock holm') }
  qr/not a valid IANA Time Zone Database timezone name/,
  'timezone: name with space';

throws_ok { timezone('../etc/passwd') }
  qr/not a valid IANA Time Zone Database timezone name/,
  'timezone: traversal attempt rejected by name validation';

## timezone(): syntactically valid but nonexistent zone croaks

throws_ok { timezone('Mars/Phobos') }
  qr/Unable to locate IANA Time Zone: 'Mars\/Phobos'/,
  'timezone: nonexistent zone';

## timezone(): a real zone resolves to a Time::TZif object

my $utc = timezone('UTC');
isa_ok($utc, 'Time::TZif', 'timezone: UTC');
is($utc->name, 'UTC', 'timezone: UTC has name "UTC"');

SKIP: {
  skip "Europe/Stockholm not in this zoneinfo", 2
    unless -f "$TZDIR/Europe/Stockholm";

  my $sth = timezone('Europe/Stockholm');
  isa_ok($sth, 'Time::TZif', 'timezone: Europe/Stockholm');
  is($sth->name, 'Europe/Stockholm',
    'timezone: name preserved for subpath zone');
}

## Caching: repeated lookups return the same object

my $utc2 = timezone('UTC');
is(refaddr($utc), refaddr($utc2),
  'timezone: same name returns the cached object');

## reset(): drops the cache

throws_ok { Time::Str::TimeZone->reset('extra') }
  qr/^Usage: Time::Str::TimeZone->reset/,
  'reset: too many arguments';

Time::Str::TimeZone->reset;
my $utc3 = timezone('UTC');
isnt(refaddr($utc), refaddr($utc3),
  'timezone: object is re-resolved after reset');

## timezone('local'): resolved from TZ, DST-aware object

{
  local $ENV{TZ} = 'UTC';
  Time::Str::TimeZone->reset;

  my $local = timezone('local');
  ok(blessed($local), 'timezone: local returns an object');
  ok($local->can('offset_for_local') && $local->can('offset_for_utc'),
    'timezone: local object provides the offset_for_* methods');
}

SKIP: {
  skip "Europe/Stockholm not in this zoneinfo", 1
    unless -f "$TZDIR/Europe/Stockholm";

  local $ENV{TZ} = 'Europe/Stockholm';
  Time::Str::TimeZone->reset;

  my $local = timezone('local');
  is($local->name, 'Europe/Stockholm',
    'timezone: local resolves TZ to the named zone');
}

Time::Str::TimeZone->reset;   # leave the cache clean for later tests

## Pluggable provider: timezone()/reset dispatch through $PROVIDER

{
  package My::TZProvider;
  my %Calls;
  sub locate { my ($class, $name) = @_; $Calls{locate}++; return "OBJ:$name" }
  sub flush  { $Calls{flush}++;  return }
  sub calls  { \%Calls }
}

{
  no warnings 'once';
  
  local $Time::Str::TimeZone::PROVIDER = 'My::TZProvider';

  is(timezone('Foo/Bar'), 'OBJ:Foo/Bar',
    'timezone: dispatches to $PROVIDER->locate');

  Time::Str::TimeZone->reset;
  ok(My::TZProvider->calls->{flush},
    'reset: dispatches to $PROVIDER->flush');
}

done_testing();
