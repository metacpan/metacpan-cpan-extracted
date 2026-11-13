use 5.016;
use warnings;

use lib 't/lib';

use Test::More;

use Local::Resources;

use Twilio::ApiV1Version;
use Twilio::Exceptions::TwilioServiceException;
use Twilio::Http::FakeClient;
use Twilio::Http::Response;
use Twilio::Json;
use Twilio::Rest::Client;

my $CLASS = 'Twilio::Exceptions::TwilioServiceException';

# The example in the error responses of twilio_numbers_v3.json.
my %PROBLEM = (
  type     => 'https://www.twilio.com/docs/api/errors/20001',
  title    => 'Invalid parameter',
  status   => 400,
  code     => 20001,
  detail   => q{The 'PhoneNumber' parameter is required but was not provided.},
  instance => '/api/v1/accounts/AC123/calls/CA456',
  errors   => [
    { detail => 'must be a positive integer',        pointer => '#/age' },
    { detail => q{must be 'green', 'red' or 'blue'}, pointer => '#/profile/color' },
  ],
);
my $FULL_MESSAGE =
    q{[HTTP 400] Unable to fetch: Invalid parameter - The 'PhoneNumber' parameter is required }
  . q{but was not provided. (#/age: must be a positive integer; #/profile/color: must be }
  . q{'green', 'red' or 'blue')};

subtest 'every member is kept' => sub {
  my $error = classic_exception(400, \%PROBLEM);

  isa_ok($error, $CLASS);
  is($error->get_type,        $PROBLEM{type},      'type');
  is($error->get_title,       'Invalid parameter', 'title');
  is($error->get_detail,      $PROBLEM{detail},    'detail');
  is($error->get_instance,    $PROBLEM{instance},  'instance');
  is($error->get_code,        20001,               'code');
  is($error->get_status_code, 400,                 'status');
  is($error->get_more_info,   $PROBLEM{type},      'more_info is the type');
  is_deeply($error->get_errors, $PROBLEM{errors}, 'field errors');
  is($error->get_message, $FULL_MESSAGE, 'the message has the title, detail and field errors');
  is("$error",            $FULL_MESSAGE, 'and so does the string');
};

subtest 'it can be caught as a RestException' => sub {
  my $error = classic_exception(400, \%PROBLEM);

  isa_ok($error, 'Twilio::Exceptions::RestException');
  isa_ok($error, 'Twilio::Exceptions::TwilioException');
  is_deeply($error->get_details, {}, 'details has its default');
};

# The status member would send it to the classic class, which is how the fields were lost.
subtest 'an API of the v1.0 standard gives it too' => sub {
  my $error = v1_exception(400, \%PROBLEM);

  isa_ok($error, $CLASS);
  ok(!$error->isa('Twilio::Exceptions::RestExceptionV1'), 'not the V1 class');
  is($error->get_message, $FULL_MESSAGE, 'message');
};

subtest 'only the four required members' => sub {
  my %required = map { $_ => $PROBLEM{$_} } qw(type title status code);
  my $error    = classic_exception(422, \%required);

  isa_ok($error, $CLASS);
  is($error->get_message,     '[HTTP 422] Unable to fetch: Invalid parameter', 'the title only');
  is($error->get_status_code, 422,                                             'the HTTP status');
  is($error->get_detail,      undef,                                           'no detail');
  is($error->get_instance,    undef,                                           'no instance');
  is_deeply($error->get_errors, [], 'no field errors');
};

subtest 'field errors with parts missing' => sub {
  my $error = classic_exception(
    400,
    {
      %PROBLEM,
      detail => undef,
      errors => [{ detail => 'is required' }, { pointer => '#/name' }, 'odd', {}],
    }
  );

  is(
    $error->get_message,
    '[HTTP 400] Unable to fetch: Invalid parameter (is required; #/name)',
    'what there is'
  );
  is(scalar @{ $error->get_errors }, 4, 'all kept as sent');
};

subtest 'field errors that are not a list' => sub {
  my $error = classic_exception(400, { %PROBLEM, errors => { pointer => '#/age' } });
  is_deeply($error->get_errors, [], 'none');
};

subtest 'what is not an RFC 9457 document keeps its class' => sub {
  my @required = qw(type title status code);
  for my $member (@required) {
    my %without = map { $_ => $PROBLEM{$_} } grep { $_ ne $member } @required;
    ok(!classic_exception(400, \%without)->isa($CLASS), "without $member");
  }
  ok(!classic_exception(400, { %PROBLEM, code   => 'E20001' })->isa($CLASS), 'a code in letters');
  ok(!classic_exception(400, { %PROBLEM, status => 'bad' })->isa($CLASS),    'a status in letters');
  ok(!classic_exception(400, { %PROBLEM, title  => undef })->isa($CLASS),    'a null title');
  ok(!classic_exception(400, { %PROBLEM, type   => {} })->isa($CLASS), 'a type that is an object');
};

# Answers seen live on 2026-11-11, from three of the four APIs that describe RFC 9457 errors.
subtest 'the shapes Twilio answers with today are unchanged' => sub {
  my $classic = v1_exception(
    404,
    {
      code      => 404,
      message   => 'Unknown conversation.',
      more_info => 'https://www.twilio.com/docs/errors/404',
      status    => 404
    }
  );
  is(ref $classic,          'Twilio::Exceptions::RestException', 'Conversations v2, classic');
  is($classic->get_message, '[HTTP 404] Unable to fetch: Unknown conversation.', 'its message');

  my $v1 = v1_exception(
    404,
    {
      code           => 20404,
      message        => 'The requested resource /v1/Webhooks/Rules/XX0000 was not found',
      httpStatusCode => 404,
      userError      => Twilio::Json::decode('true'),
      params         => { twilioErrorCodeUrl => 'https://www.twilio.com/docs/errors/20404' },
    }
  );
  is(ref $v1, 'Twilio::Exceptions::RestExceptionV1', 'Webhooks v1, the v1.0 standard');
};

subtest 'is_problem' => sub {
  ok($CLASS->is_problem(\%PROBLEM), 'a document');
  ok(!$CLASS->is_problem(undef),    'nothing');
  ok(!$CLASS->is_problem('text'),   'text');
  ok(!$CLASS->is_problem([]),       'a list');
};

subtest 'new without a status uses the one in the document' => sub {
  my $error = $CLASS->new('[HTTP 400] Unable to create record', { %PROBLEM, status => 409 });
  is($error->get_status_code, 409, 'status');
};

subtest 'through a generated class, from each kind of version' => sub {
  my $http = Twilio::Http::FakeClient->new;
  my $client =
    Twilio::Rest::Client->new('ACxx', 'secret', { http_client => $http, environment => {} });

  my @calls = (
    [
      'Numbers v3, a create' => sub { $client->numbers->v3->hosted_number_orders->create('+1', 1) },
      '[HTTP 422] Unable to create record: Invalid parameter'
    ],
    [
      'Api 2010, a fetch' => sub { $client->messages('SMxx')->fetch },
      '[HTTP 422] Unable to fetch record: Invalid parameter'
    ],
    [
      'Api 2010, a page' => sub { $client->messages->read({}, 1) },
      '[HTTP 422] Unable to fetch page: Invalid parameter'
    ],
  );
  for my $call (@calls) {
    my ($name, $code, $prefix) = @{$call};
    $http->mock(422, { %PROBLEM, status => 422 });
    my $ok    = eval { $code->(); 1 };
    my $error = $@;
    ok(!$ok, "$name dies");
    isa_ok($error, $CLASS, $name);
    like($error->get_message, qr/\A\Q$prefix\E - /, "$name: message");
  }
};

done_testing;

sub classic_exception {
  my ($status, $content) = @_;
  my (undef,   $version) = Local::Resources::build({ environment => {} });
  return $version->exception(response($status, $content), 'Unable to fetch');
}

sub v1_exception {
  my ($status, $content) = @_;
  my (undef,   $classic) = Local::Resources::build({ environment => {} });
  my $version = Twilio::ApiV1Version->new($classic->get_domain, 'v3');
  return $version->exception(response($status, $content), 'Unable to fetch');
}

sub response {
  my ($status, $content) = @_;
  return Twilio::Http::Response->new($status, Twilio::Json::encode($content));
}
