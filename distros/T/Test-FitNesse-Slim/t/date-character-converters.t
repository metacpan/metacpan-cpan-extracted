#! perl

use strict;
use warnings;
use utf8;

use lib 'lib';
use Encode qw(encode decode);
use Test::More;
use Time::Local qw(timelocal);
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::ConverterRegistry;

my $registry = Test::FitNesse::Slim::ConverterRegistry->new;
my $character = $registry->get_converter('java.lang.Character');
my $primitive_character = $registry->get_converter('char');
my $date = $registry->get_converter('java.util.Date');

ok($character && $primitive_character && $date,
  'Character, char, and Date converters are registered');
BAIL_OUT('missing standard converter') unless $character && $primitive_character && $date;

is($character->from_string('A'), ord('A'),
  'boxed Character conversion returns the UTF-16 code unit');
is($character->from_string("\x{FFFF}"), 0xFFFF,
  'Character conversion accepts the last non-surrogate BMP code unit');
is($character->from_string("\x{1F600}"), 0xD83D,
  'supplementary input converts to Java charAt(0), the high surrogate');
is($character->from_string(chr(0xD800)), 0xD800,
  'an isolated high surrogate code unit is retained as an integer');
is($character->from_string(chr(0xDFFF)), 0xDFFF,
  'an isolated low surrogate code unit is retained as an integer');
ok(!defined($character->from_string('')),
  'blank boxed Character input becomes null');
ok(!defined($character->from_string("\n\t")),
  'Java whitespace-only boxed Character input becomes null');
my $nbsp = decode('UTF-8', encode('UTF-8', "\x{00A0}"));
is($character->from_string($nbsp), 0x00A0,
  'nonbreaking space is not Java Character whitespace');
is($primitive_character->from_string(' '), 0,
  'blank primitive char input defaults to NUL');
is($character->to_string(0x0041), 'A',
  'BMP Character results serialize as their character');
is($character->to_string(0), "\0",
  'primitive NUL results remain an actual NUL character');
is($character->to_string(0xD83D), '?',
  'a Java surrogate result uses the UTF-8 encoder replacement on the wire');
is($character->to_string(0xDFFF), '?',
  'isolated low surrogate results use the UTF-8 encoder replacement');
my $bad_character = eval { $character->to_string(0x10000); '' };
like($@, qr/Character result must be a UTF-16 code unit/,
  'Character result conversion rejects values outside the UTF-16 code-unit range');

my $epoch = timelocal(0, 0, 0, 1, 0, 1970) * 1000;
is($date->from_string('01-Jan-1970'), $epoch,
  'Date parsing interprets midnight in the process default timezone');
is($date->to_string($epoch), '01-Jan-1970',
  'Date result formatting uses dd-MMM-yyyy with US month names');
is($date->to_string($date->from_string('29-Feb-2024')), '29-Feb-2024',
  'Date conversion round-trips a leap day');
is($date->to_string($date->from_string('32-Jan-2024')), '01-Feb-2024',
  'lenient Date parsing rolls an overflowing day into the next month');
is($date->to_string($date->from_string('00-Mar-2024')), '29-Feb-2024',
  'lenient Date parsing rolls day zero into the previous month');
is($date->to_string($date->from_string('31-Apr-2024')), '01-May-2024',
  'lenient Date parsing normalizes a short month');
is($date->to_string($date->from_string('01-january-2024 trailing text')),
  '01-Jan-2024', 'Date parsing accepts case-insensitive full month names and trailing text');
is($date->to_string($date->from_string(" \t01-Jan-2024")),
  '01-Jan-2024', 'Date parsing accepts leading Java whitespace');
is($date->to_string($date->from_string('01-Jan-1583')), '01-Jan-1583',
  'Date conversion supports the documented lower calendar boundary');
is($date->to_string($date->from_string('31-Dec-9999')), '31-Dec-9999',
  'Date conversion supports the documented upper calendar boundary');
ok(!defined($date->from_string('  ')), 'blank Date input becomes null');
my $bad_date = eval { $date->from_string('12-NotAMonth-2024'); '' };
like($@, qr/Can't convert 12-NotAMonth-2024 to date/,
  'malformed Date input reports the FitNesse conversion message');

my @declared = $registry->convert_arguments(
  { parameters => ['char', 'java.util.Date'] }, 'typed_character_date',
  "\x{1F642}", '02-Jun-2025'
);
is_deeply(\@declared, [0xD83D, $date->from_string('02-Jun-2025')],
  'declared Character and Date arguments use their standard converters');
my ($character_result) = $registry->convert_result(
  { return => 'java.lang.Character' }, 0x03A9
);
is($character_result, "\x{03A9}", 'declared Character results are converted to text');
is(Test::FitNesse::Slim::List->new([$character->to_string(0xD83D)])->serialize,
  '[000001:000001:?:]', 'surrogate Character result serializes as the Java UTF-8 replacement');
my ($date_result) = $registry->convert_result(
  { return => 'java.util.Date' }, $date->from_string('03-Feb-2026')
);
is($date_result, '03-Feb-2026', 'declared Date results use the standard formatter');
my $date_error = eval {
  $registry->convert_arguments(
    { parameters => ['java.util.Date'] }, 'bad_typed_date', 'not a date'
  );
  '';
};
like($@, qr/Can't convert not a date to date.*Tried to invoke: bad_typed_date/s,
  'Date conversion errors retain method invocation context');

done_testing;
