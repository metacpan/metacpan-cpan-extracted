use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 29;

use HTTP::Request;
use Sub::Override;
use Test::MockObject;

use WWW::Curl::Easy;

BEGIN {
    use_ok('WWW::Curl::UserAgent');
}

{
    note 'perform without active handles';

    my $ua = Test::MockObject->new;
    $ua->set_series( _drain_handler_queue => (0) );

    WWW::Curl::UserAgent::perform($ua);

    ok !$ua->called('_wait_for_response'), 'not waited for response';
    ok !$ua->called('_perform_callbacks'), 'no callback performed';
}

{
    note 'perform with active handle';

    my $ua = Test::MockObject->new;
    $ua->set_series( _drain_handler_queue => ( 1, 0 ) );
    $ua->set_true( '_wait_for_response', '_perform_callbacks' );

    WWW::Curl::UserAgent::perform($ua);

    ok $ua->called('_wait_for_response'), 'waited for response';
    ok $ua->called('_perform_callbacks'), 'callback performed';
}

{
    note 'drain no handler';

    my $ua = get_activating_ua();

    is $ua->_drain_handler_queue, 0, 'no handler activation';
    is $ua->request_queue_size,   0, 'no handler left to activate';
}

{
    note 'drain a single handler';

    my $handler = Test::MockObject->new;
    $handler->set_isa('WWW::Curl::UserAgent::Handler');

    my $ua = get_activating_ua();
    $ua->add_handler($handler);

    is $ua->_drain_handler_queue, 1, 'activated one handler';
    is $ua->request_queue_size,   0, 'no handler left to activate';
}

{
    note 'drain 5 handler';

    my $ua = get_activating_ua();
    for ( 1 .. 5 ) {
        my $handler = Test::MockObject->new;
        $handler->set_isa('WWW::Curl::UserAgent::Handler');
        $ua->add_handler($handler);
    }

    is $ua->_drain_handler_queue, 5, 'activated 5 handlers';
    is $ua->request_queue_size,   0, 'no handler left to activate';
}

{
    note 'drain 6 handler';

    my $ua = get_activating_ua();
    for ( 1 .. 6 ) {
        my $handler = Test::MockObject->new;
        $handler->set_isa('WWW::Curl::UserAgent::Handler');
        $ua->add_handler($handler);
    }

    is $ua->_drain_handler_queue, 5, 'activated 5 handlers';
    is $ua->request_queue_size,   1, 'one handler left to activate';
}

# TODO: _perform_callbacks, _activate_handler

{
    note 'build default http no content response';

    my $http_response_header = <<EOF;
HTTP/1.0 204 No Content\r
Content-Length: 0\r
Content-Type: text/html\r
\r
EOF
    
    my $response = WWW::Curl::UserAgent->_build_http_response($http_response_header, undef);
    is $response->code, 204;
    is $response->message, 'No Content';
    is $response->content, '';
}

{
    note 'build default http response';

    my $http_response_header = <<EOF;
HTTP/1.1 200 OK\r
Content-Length: 12\r
Content-Type: text/plain\r
\r
EOF
    my $http_response_body = 'some content';
    
    my $response = WWW::Curl::UserAgent->_build_http_response($http_response_header, $http_response_body);
    is $response->code, 200;
    is $response->message, 'OK';
    is $response->content, $http_response_body;
}

{
  note 'default http response with Content-Base';
  my $http_response_header = <<EOF;
HTTP/1.1 200 OK\r
Content-Length: 12\r
Content-Type: text/plain\r
Content-Base: http://www.example.com\r
\r
EOF
    my $http_response_body = 'some content';
    
    my $response = WWW::Curl::UserAgent->_build_http_response($http_response_header, $http_response_body);
    is $response->code, 200;
    is $response->message, 'OK';
    is $response->content, $http_response_body;
    is $response->base, 'http://www.example.com';
  
}

{
    note 'mixed header with continue';

    my $http_response_header = <<EOF;
HTTP/1.1 100 Continue\r\n\r
HTTP/1.0 100 Continue\r\n\r
HTTP/1.0 204 No Content\r
Content-Length: 0\r
Content-Type: text/html\r
\r
EOF

    my $response = WWW::Curl::UserAgent->_build_http_response($http_response_header, undef);
    is $response->code, 204;
    is $response->message, 'No Content';
    is $response->content, '';
}

{
    note 'mixed header with redirect';

    my $http_response_header = <<EOF;
HTTP/1.1 301 Redirect\r\n\r
HTTP/1.0 301 Redirect\r\n\r
HTTP/1.0 204 No Content\r
Content-Length: 0\r
Content-Type: text/html\r
\r
EOF

    my $response = WWW::Curl::UserAgent->_build_http_response($http_response_header, undef);
    is $response->code, 204;
    is $response->message, 'No Content';
    is $response->content, '';
}


sub get_activating_ua {
    my $ua = WWW::Curl::UserAgent->new;

    my $i = 1;
    push @{ $ua->{overrides} }, Sub::Override->new(
        'WWW::Curl::UserAgent::_activate_handler' => sub {
            my ( $self, $handler ) = @_;
            $self->_set_active_handler( $i++ => $handler );
        }
    );

    return $ua;
}
