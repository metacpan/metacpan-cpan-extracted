use 5.016;
use warnings;

use Test::More;

use Twilio::Exceptions::ConfigurationException;
use Twilio::Exceptions::EnvironmentException;
use Twilio::Exceptions::RestException;
use Twilio::Exceptions::TwilioException;

my $base = 'Twilio::Exceptions::TwilioException';

subtest 'throw dies with an object that stringifies to its message' => sub {
  my $ok    = eval { $base->throw('Something broke', 42); 1 };
  my $error = $@;

  ok(!$ok, 'died');
  isa_ok($error, $base);
  is($error->get_message, 'Something broke', 'message');
  is($error->get_code,    42,                'code');
  is("$error",            'Something broke', 'stringifies');
  ok($error, 'is true, so eval checks see it');
};

subtest 'defaults' => sub {
  my $error = $base->new;
  is($error->get_message, q{}, 'empty message');
  is($error->get_code,    0,   'code 0');
};

subtest 'subclasses' => sub {
  isa_ok("Twilio::Exceptions::$_", $base) for qw(
    ConfigurationException EnvironmentException RestException);
};

subtest 'RestException carries the error details' => sub {
  my $error = Twilio::Exceptions::RestException->new(
    '[HTTP 400] Unable to create record: Bad number',
    21211, 400,
    'https://www.twilio.com/docs/errors/21211',
    { field => 'To' },
  );

  is($error->get_code,        21211,                                      'Twilio code');
  is($error->get_status_code, 400,                                        'HTTP status');
  is($error->get_more_info,   'https://www.twilio.com/docs/errors/21211', 'more info');
  is_deeply($error->get_details, { field => 'To' }, 'details');
  like("$error", qr/Bad number/, 'stringifies');
};

subtest 'RestException defaults' => sub {
  my $error = Twilio::Exceptions::RestException->new('[HTTP 500]', 500, 500);
  is($error->get_more_info, q{}, 'empty more info');
  is_deeply($error->get_details, {}, 'empty details');
};

done_testing;
