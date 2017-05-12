use Test::More tests=>1;


use Test::Mock::LWP;

my $Content  = undef;

$Mock_request->mock(
    content_type => sub {
    }
  )->mock(
    header => sub {
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
$Mock_resp->set_always('code', 403);
$Mock_resp->set_always('is_success', 0);


$Mock_ua->mock(
    agent => sub {
    }
);

$Mock_response->mock(
    content => sub {
        return << 'RESPONSE';
Error=BadAuthentication

RESPONSE
    }
);

use WebService::GData::ClientLogin;
use WebService::GData::Constants qw(:errors);

my $auth;
eval {
    $auth = new WebService::GData::ClientLogin(email=> 'test@gmail.com',password=>'tt');
};
my $error = $@;
ok($error->code eq BAD_AUTHENTICATION,'the error code is set properly.');
