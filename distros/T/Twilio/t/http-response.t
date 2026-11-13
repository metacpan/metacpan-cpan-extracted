use 5.016;
use warnings;

use Test::More;

use Twilio::Http::Response;

subtest 'JSON body' => sub {
  my $response = Twilio::Http::Response->new(200, '{"sid":"SM1"}', { 'x-request' => 'abc' });

  is($response->get_status_code, 200, 'status');
  is_deeply($response->get_content, { sid => 'SM1' }, 'decoded content');
  is($response->get_raw_content, '{"sid":"SM1"}', 'raw content');
  is_deeply($response->get_headers, { 'x-request' => 'abc' }, 'headers');
};

subtest 'bodies that are not JSON do not die' => sub {
  my @cases = (['html', '<html>Bad gateway</html>'], ['empty', q{}], ['missing', undef]);

  for my $case (@cases) {
    my ($name, $body) = @{$case};
    my $content = Twilio::Http::Response->new(502, $body)->get_content;
    is($content, undef, $name);
  }
};

subtest 'ok follows the status code' => sub {
  ok(Twilio::Http::Response->new(200)->ok,  'status 200');
  ok(Twilio::Http::Response->new(302)->ok,  'status 302');
  ok(!Twilio::Http::Response->new(400)->ok, 'status 400');
  ok(!Twilio::Http::Response->new(500)->ok, 'status 500');
};

subtest 'headers default to an empty hash' => sub {
  is_deeply(Twilio::Http::Response->new(204)->get_headers, {}, 'empty');
};

done_testing;
