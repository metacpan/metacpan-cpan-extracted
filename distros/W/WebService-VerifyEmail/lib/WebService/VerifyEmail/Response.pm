package WebService::VerifyEmail::Response;
$WebService::VerifyEmail::Response::VERSION = '0.03';
use Moo;

has authentication_status   => (is => 'ro');
has limit_status            => (is => 'ro');
has limit_desc              => (is => 'ro');
has verify_status           => (is => 'ro');
has verify_status_desc      => (is => 'ro');

1;
