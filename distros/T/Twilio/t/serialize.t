use 5.016;
use warnings;

use Test::More;

use Time::Piece ();

use Twilio::Json;
use Twilio::Serialize;

subtest 'boolean_to_string' => sub {
  my @cases = (
    ['one',          1,       'true'],
    ['zero',         0,       'false'],
    ['empty string', q{},     'false'],
    ['word true',    'true',  'true'],
    ['word false',   'false', 'false'],
    ['undef',        undef,   undef],
  );

  for my $case (@cases) {
    my ($name, $value, $expected) = @{$case};
    is(Twilio::Serialize::boolean_to_string($value), $expected, $name);
  }
};

subtest 'iso8601_date_time' => sub {
  my $moment = 1_438_287_151;

  is(Twilio::Serialize::iso8601_date_time(scalar Time::Piece->gmtime($moment)),
    '2015-07-30T20:12:31Z', 'object in UTC');
  is(Twilio::Serialize::iso8601_date_time(scalar Time::Piece->localtime($moment)),
    '2015-07-30T20:12:31Z', 'local object still gives UTC');
  is(Twilio::Serialize::iso8601_date_time(Local::Moment->new($moment)),
    '2015-07-30T20:12:31Z', 'any object with epoch, as DateTime has');

  is(Twilio::Serialize::iso8601_date_time('2015-07-30'), '2015-07-30', 'string kept');
  is(Twilio::Serialize::iso8601_date_time(undef),        undef,        'undef kept');

  my $no_epoch = bless {}, 'Local::NoEpoch';
  is(Twilio::Serialize::iso8601_date_time($no_epoch), $no_epoch, 'other objects kept');
};

subtest 'path_segment' => sub {
  my @cases = (
    ['plain sid',         'SM123abc',     'SM123abc'],
    ['unreserved kept',   'a-b_c.d~e',    'a-b_c.d~e'],
    ['slash',             'a/b',          'a%2Fb'],
    ['plus',              '+1555',        '%2B1555'],
    ['space is not plus', 'a b',          'a%20b'],
    ['characters',        "\x{263A}",     '%E2%98%BA'],
    ['already UTF-8',     "\xE2\x98\xBA", '%E2%98%BA'],
  );

  for my $case (@cases) {
    my ($name, $value, $expected) = @{$case};
    is(Twilio::Serialize::path_segment($value), $expected, $name);
  }

  is(Twilio::Serialize::path_segment(0), '0', 'zero is a value');
  for my $missing (undef, q{}) {
    my $ok = eval { Twilio::Serialize::path_segment($missing); 1 };
    ok(!$ok, 'a missing value dies');
    like($@, qr/A URL needs an id that is missing/, 'and says why');
  }
};

subtest 'iso8601_date' => sub {
  is(Twilio::Serialize::iso8601_date(undef),        undef,        'undef stays undef');
  is(Twilio::Serialize::iso8601_date('2026-11-06'), '2026-11-06', 'a string stays the same');
  is(Twilio::Serialize::iso8601_date(Local::Moment->new(0)), '1970-01-01', 'an object');
  is(Twilio::Serialize::iso8601_date(Local::Moment->new(86_399)),
    '1970-01-01', 'the last second of a day');
  is(Twilio::Serialize::iso8601_date(Local::Moment->new(86_400)),
    '1970-01-02', 'the first second of the next');
  is(Twilio::Serialize::iso8601_date(scalar Time::Piece->gmtime(0)), '1970-01-01', 'Time::Piece');

  my $unknown = bless {}, 'Local::NoEpoch';
  is(Twilio::Serialize::iso8601_date($unknown), $unknown, 'an object with no epoch stays the same');
};

# twilio-php's DifferentTimezone cases: 2017-02-01T17:15:41-0800 is already the 2nd in UTC.
subtest 'a moment behind UTC is sent as its UTC day and time' => sub {
  my $moment = Local::Moment->new(1_485_998_141);

  is(Twilio::Serialize::iso8601_date($moment),      '2017-02-02',           'the date');
  is(Twilio::Serialize::iso8601_date_time($moment), '2017-02-02T01:15:41Z', 'the date and time');
  is($moment->epoch,                                1_485_998_141, 'the object is not changed');
};

subtest 'json_object' => sub {
  is(Twilio::Serialize::json_object(undef),              undef,           'undef stays undef');
  is(Twilio::Serialize::json_object('{"a":1}'),          '{"a":1}',       'text stays the same');
  is(Twilio::Serialize::json_object({ a => 1, b => 2 }), '{"a":1,"b":2}', 'a hash');
  is(Twilio::Serialize::json_object([1, 'two']),         '[1,"two"]',     'an array');
  is(Twilio::Serialize::json_object({}),                 '{}', 'an empty hash is still sent');

  my $object = bless {}, 'Local::NoEpoch';
  is(Twilio::Serialize::json_object($object), $object, 'an object stays the same');
};

subtest 'json_body' => sub {
  my $moment = Local::Moment->new(1_438_287_151);
  my $rules =
    { day => 'iso8601_date', at => 'iso8601_date_time', on => 'boolean', off => 'boolean' };
  my $body = {
    day  => $moment,
    at   => $moment,
    on   => 1,
    off  => 'false',
    name => 'x',
    deep => { when => $moment, list => [$moment, 'y'], flag => \1 },
  };
  my $sent = Twilio::Serialize::json_body($body, $rules);

  is($sent->{day}, '2015-07-30',           'a date');
  is($sent->{at},  '2015-07-30T20:12:31Z', 'a date and time');
  is_deeply([$sent->{on}, $sent->{off}], [\1, \0], 'booleans for JSON');
  is($sent->{name}, 'x', 'a field with no rule stays');
  is_deeply(
    $sent->{deep},
    { when => '2015-07-30T20:12:31Z', list => ['2015-07-30T20:12:31Z', 'y'], flag => \1 },
    'dates below the top level are written as text'
  );
  is(ref $body->{deep}{when},           'Local::Moment', 'the caller keeps its data');
  is(Twilio::Json::encode($sent->{on}), 'true',          'a boolean encodes as JSON true');

  is_deeply(Twilio::Serialize::json_body(undef), {}, 'no body is an empty one');
  my $ok    = eval { Twilio::Serialize::json_body('{"a":1}'); 1 };
  my $error = $@;
  ok(!$ok, 'anything else is refused');
  like($error, qr/A JSON body must be a hash reference/, 'says why');
};

# The expected values are what twilio-php 8.14.0 returns for the same input.
subtest 'map_values' => sub {
  my $json = \&Twilio::Serialize::json_object;

  is_deeply(
    Twilio::Serialize::map_values([{ a => 1 }, '{"b":2}'], $json),
    ['{"a":1}', '{"b":2}'],
    'each element'
  );
  is(Twilio::Serialize::map_values('plain', $json), 'plain', 'anything else stays the same');
  is(Twilio::Serialize::map_values(undef,   $json), undef,   'undef stays undef');

  my $values = [{ a => 1 }];
  Twilio::Serialize::map_values($values, $json);
  is_deeply($values, [{ a => 1 }], 'the caller keeps its array');
};

subtest 'prefixed_collapsible_map' => sub {
  is_deeply(
    Twilio::Serialize::prefixed_collapsible_map(
      { lookup => { Key => 'v', List => ['x', 'y'] }, top => '2' }, 'AddOns'
    ),
    {
      'AddOns.lookup.Key'    => 'v',
      'AddOns.lookup.List.0' => 'x',
      'AddOns.lookup.List.1' => 'y',
      'AddOns.top'           => '2',
    },
    'nested keys joined with dots, and arrays by index'
  );
  is_deeply(Twilio::Serialize::prefixed_collapsible_map({},    'AddOns'), {}, 'an empty hash');
  is_deeply(Twilio::Serialize::prefixed_collapsible_map(undef, 'AddOns'), {}, 'undef');

  my $ok    = eval { Twilio::Serialize::prefixed_collapsible_map('text', 'AddOns'); 1 };
  my $error = $@;
  ok(!$ok, 'anything else is refused');
  like($error, qr/A value sent as AddOns[.][*] must be a hash reference/, 'says why');
};

done_testing;

package Local::Moment;

sub new {
  my ($class, $epoch) = @_;
  return bless { epoch => $epoch }, $class;
}

sub epoch { return $_[0]{epoch} }
