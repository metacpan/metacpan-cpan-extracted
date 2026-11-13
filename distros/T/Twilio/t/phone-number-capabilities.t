use 5.016;
use warnings;

use Test::More;

use Twilio::Base::PhoneNumberCapabilities;
use Twilio::Json;

subtest 'a number you own, in lower case' => sub {
  my $capabilities = from_json('{"fax":false,"mms":true,"sms":true,"voice":true}');

  is($capabilities->fax,   0, 'fax');
  is($capabilities->mms,   1, 'mms');
  is($capabilities->sms,   1, 'sms');
  is($capabilities->voice, 1, 'voice');
};

subtest 'an available number, in upper case and with no fax' => sub {
  my $capabilities = from_json('{"MMS":true,"SMS":false,"voice":true}');

  is($capabilities->fax,   0, 'a capability that is not given is false');
  is($capabilities->mms,   1, 'upper case is read');
  is($capabilities->sms,   0, 'upper case false is read');
  is($capabilities->voice, 1, 'lower case in the same value is read');
};

subtest 'nothing given' => sub {
  my $capabilities = Twilio::Base::PhoneNumberCapabilities->new({});
  is($capabilities->$_, 0, "$_ is false") for Twilio::Base::PhoneNumberCapabilities->capabilities;
};

subtest 'capability names' => sub {
  is_deeply([Twilio::Base::PhoneNumberCapabilities->capabilities],
    [qw(fax mms sms voice)], 'all of them');
};

done_testing;

sub from_json {
  my ($text) = @_;
  return Twilio::Base::PhoneNumberCapabilities->new(Twilio::Json::decode($text));
}
