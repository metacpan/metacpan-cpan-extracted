use Test::More tests=>24;

use Test::Mock::LWP;


my %RHeaders = ();
my $UA       = undef;
my $Method   = undef;
my $Content  = undef;

$Mock_request->mock(
    content_type => sub {
    }
  )->mock(
    header => sub {
        my ( $this, $header, $content ) = @_;
        $RHeaders{$header} = $content if ( $header && $content );
        return $RHeaders{$header};
    }
  )->mock(
    method => sub {
    }
  )->mock(
    content => sub {
        my ( $this, $content ) = @_;
        $Content = $content if ($content);
        return $Content;

    }
  );

$Mock_ua->mock(
    agent => sub {
        my ( $this, $agent ) = @_;
        $UA = $agent if ($agent);
        return $UA;
    }
);

$Mock_response->mock(
    content => sub {
        return << 'RESPONSE';
Auth=AIwbFARksypDdUSGGYRI_5v7Z9TaijoPQqpIfCEjTFPAiknOCI1VJtQ
YouTubeUser=testuser
RESPONSE
    }
);

use WebService::GData::ClientLogin;
use WebService::GData::Constants qw(:service);

my $auth;
eval { $auth = new WebService::GData::ClientLogin(); };
my $error = $@;
$auth = new WebService::GData::ClientLogin(email=> 'test@test.com',password=>'mypassword');

ok(ref($auth) eq 'WebService::GData::ClientLogin', 'An instance was created.' );

ok( $error->isa(q[WebService::GData::Error]), 'an error is thrown if required parameters are not set.' );

ok($error->code eq 'invalid_parameters','not setting the required parameters throws an invalid_parameters error code.');

ok( $auth->email eq 'test@test.com', 'The email was properly sent.' );

ok( $auth->password eq 'mypassword', 'The email was properly sent.' );

ok( $auth->service eq 'youtube', 'The service by default is youtube.' );

ok(
    $auth->source eq ref($auth) . '-'
      . $WebService::GData::ClientLogin::VERSION,
    'The source by default is properly set.'
);

ok( $auth->type eq 'HOSTED_OR_GOOGLE', 'The type by default is properly set.' );

ok( !$auth->key, 'The key by default is not set.' );

ok( !$auth->captcha_token, 'The captcha_token by default is not set.' );

ok( !$auth->captcha_url, 'The captcha_url by default is not set.' );

ok( !$auth->captcha_answer, 'The captcha_answer by default is not set.' );

ok(
    $auth->authorization_key eq
      'AIwbFARksypDdUSGGYRI_5v7Z9TaijoPQqpIfCEjTFPAiknOCI1VJtQ',
    'The authorization_key by default is not set.'
);
my $v = $WebService::GData::ClientLogin::VERSION;
$v=~s/\./%2e/;
ok(
    $Mock_request->content eq
qq[Email=test%40test%2ecom&Passwd=mypassword&service=youtube&source=WebService%3a%3aGData%3a%3aClientLogin%2d$v&accountType=HOSTED_OR_GOOGLE],
    'The content is properly encoded.'
);

$auth = new WebService::GData::ClientLogin(
    email          => 'test@test.com',
    password       => 'mypassword',
    service        => CALENDAR_SERVICE,
    type           => 'HOSTED',
    source         => 'MyCompany-MyApp-v2',
    captcha_token  => 'abcd',
    captcha_answer => '123',
    key            => 'key'
);

ok(
    $Mock_request->content eq 'Email=test%40test%2ecom&Passwd=mypassword&service=cl&source=MyCompany%2dMyApp%2dv2&accountType=HOSTED&logintoken=abcd&logincaptcha=123',
    'all the parameters are properly set.');

ok( $auth->service eq CALENDAR_SERVICE, 'The service is properly set.' );

ok( $auth->source eq 'MyCompany-MyApp-v2', 'The source is properly set.' );

ok( $auth->type eq 'HOSTED', 'The type is properly set.' );

ok( $auth->key eq 'key', 'The key is properly set.' );

ok( !$auth->captcha_token, 'The captcha_token has been reset properly.' );

ok( !$auth->captcha_url, 'The captcha_url has been reset properly.' );

ok( $auth->captcha_answer eq '123', 'The captcha_answer has been properly set.' );

$auth->set_authorization_headers(undef,$Mock_request);

ok($Mock_request->header('Authorization') eq 'GoogleLogin auth=' . $auth->authorization_key, 'The request object authorization header has been properly set.' );

$auth->set_service_headers(undef,$Mock_request);

ok($Mock_request->header('X-GData-Key') eq 'key=' . $auth->key, 'The request object service header has been properly set.' );

