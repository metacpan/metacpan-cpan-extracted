use 5.016;
use warnings;

use Test::More;

use Twilio::Deserialize;
use Twilio::Json;

my $MOMENT = 1_438_287_151;    # 2015-07-30 20:12:31 UTC

subtest 'every format Twilio uses gives the same moment' => sub {
  my @cases = (
    ['RFC 2822 from the 2010 API', 'Thu, 30 Jul 2015 20:12:31 +0000'],
    ['RFC 2822 with an offset',    'Thu, 30 Jul 2015 15:12:31 -0500'],
    ['RFC 2822 with GMT',          'Thu, 30 Jul 2015 20:12:31 GMT'],
    ['RFC 2822 with no zone',      'Thu, 30 Jul 2015 20:12:31'],
    ['RFC 2822 with no weekday',   '30 Jul 2015 20:12:31 +0000'],
    ['RFC 2822 in lower case',     'thu, 30 jul 2015 20:12:31 +0000'],
    ['ISO 8601 from product APIs', '2015-07-30T20:12:31Z'],
    ['ISO 8601 with fractions',    '2015-07-30T20:12:31.123Z'],
    ['ISO 8601 with an offset',    '2015-07-31T01:42:31+05:30'],
    ['ISO 8601 with a short one',  '2015-07-30T15:12:31-0500'],
    ['ISO 8601 with no zone',      '2015-07-30T20:12:31'],
    ['ISO 8601 with a space',      '2015-07-30 20:12:31'],
  );

  for my $case (@cases) {
    my ($name, $value) = @{$case};
    my $date = Twilio::Deserialize::date_time($value);
    isa_ok($date, 'Time::Piece', $name);
    is($date->epoch, $MOMENT, "$name: moment");
  }
};

subtest 'a date alone is midnight UTC' => sub {
  my $date = Twilio::Deserialize::date_time('2015-07-30');
  is($date->datetime, '2015-07-30T00:00:00', 'date');
};

subtest 'the result reads as UTC' => sub {
  my $date = Twilio::Deserialize::date_time('Thu, 30 Jul 2015 15:12:31 -0500');
  is($date->ymd,             '2015-07-30', 'ymd');
  is($date->hms,             '20:12:31',   'hms');
  is($date->tzoffset->hours, 0,            'no offset');
};

subtest 'a date is one value in list context' => sub {
  my @values = Twilio::Deserialize::date_time('2015-07-30');
  is(scalar @values, 1, 'one value');
  isa_ok($values[0], 'Time::Piece');
};

subtest 'every month name' => sub {
  my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

  for my $index (0 .. $#months) {
    my $date = Twilio::Deserialize::date_time("15 $months[$index] 2020 12:00:00 +0000");
    is($date->mon, $index + 1, $months[$index]);
  }
};

subtest 'a date that has not happened yet is quiet' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  is(Twilio::Deserialize::date_time(undef), undef, 'undef');
  is_deeply(\@warnings, [], 'no warnings');
};

subtest 'values that are not dates are returned as they are' => sub {
  my @values = (
    'not a date', '2015-13-01', '2015-02-30', '2015-07-30T25:00:00Z',
    'Thu, 30 Foo 2015 20:12:31 +0000',
    '2015-07-30T20:12:31 Z',
    q{}, undef,
  );

  for my $value (@values) {
    is(Twilio::Deserialize::date_time($value), $value, $value // 'undef');
  }
};

subtest 'phone_number_capabilities' => sub {
  my $read = \&Twilio::Deserialize::phone_number_capabilities;

  my $capabilities = $read->(Twilio::Json::decode('{"MMS":true,"SMS":false,"voice":true}'));
  isa_ok($capabilities, 'Twilio::Base::PhoneNumberCapabilities');
  is($capabilities->mms, 1, 'upper case');
  is($capabilities->sms, 0, 'false stays false');

  isa_ok($read->({ fax => 0 }), 'Twilio::Base::PhoneNumberCapabilities');

  is($read->(undef),  undef,  'undef stays undef');
  is($read->('text'), 'text', 'text stays the same');
  is_deeply($read->({}),             {},             'an empty hash stays the same');
  is_deeply($read->({ other => 1 }), { other => 1 }, 'an unknown hash stays the same');
  is_deeply($read->([1]),            [1],            'an array stays the same');
};

done_testing;
