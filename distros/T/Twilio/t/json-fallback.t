use 5.016;
use warnings;

use Test::More;

# Most users will not have Cpanel::JSON::XS. Hiding it here is the only way to run the
# fallback on systems that have it, which include the CI images. Tools such as Devel::Cover
# may have loaded it already, so it also has to leave %INC for require to look again.
BEGIN {
  delete $INC{'Cpanel/JSON/XS.pm'};
  unshift @INC, sub {
    my (undef, $file) = @_;
    die "hidden for this test\n" if $file eq 'Cpanel/JSON/XS.pm';
    return;
  };
}

use Twilio::Http::Response;
use Twilio::Json;

ok(!$INC{'Cpanel/JSON/XS.pm'}, 'Cpanel::JSON::XS is not loaded');
ok($INC{'JSON/PP.pm'},         'JSON::PP is loaded');

subtest 'round trip' => sub {
  my $data = { name => "\x{263A}", list => [1, 2], nested => { a => undef } };
  is_deeply(Twilio::Json::decode(Twilio::Json::encode($data)), $data, 'same data');
};

subtest 'encoded text is UTF-8 bytes with sorted keys' => sub {
  is(Twilio::Json::encode({ b => 1, a => "\x{263A}" }), qq({"a":"\xE2\x98\xBA","b":1}), 'bytes');
};

subtest 'scalars are valid JSON' => sub {
  is(Twilio::Json::decode('"text"'), 'text', 'decoded');
};

subtest 'invalid JSON dies' => sub {
  my $ok = eval { Twilio::Json::decode('<html>'); 1 };
  ok(!$ok, 'died');
};

subtest 'responses work with the fallback' => sub {
  my $response = Twilio::Http::Response->new(200, '{"sid":"SM1"}');
  is_deeply($response->get_content, { sid => 'SM1' }, 'decoded');
  is(Twilio::Http::Response->new(502, '<html>')->get_content, undef, 'not JSON is not fatal');
};

done_testing;
