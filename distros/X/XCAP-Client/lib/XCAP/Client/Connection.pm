
package XCAP::Client::Connection;

use Moose;

use LWP::UserAgent;
use URI::Split qw(uri_split);
use HTTP::Status qw(:constants status_message);

has ['uri', 'auth_realm', 'auth_username','auth_password', 'content'] => (
    is => 'rw', 
    isa => 'Str'
);

has 'useragent' => ( 
    is => 'rw', 
    isa => 'Object',
    lazy => 1,
    default => sub { LWP::UserAgent->new(agent => 'XCAP::Client') }
);

has 'netloc' => (
    is => 'ro',
    isa => 'Str', 
    lazy => 1, 
    default => sub { 
        my $self = shift;
        my ($scheme, $auth) = uri_split($self->uri);
        $auth;
    }
);

sub _http_response_code () {
    my ($self, $method, $code) = @_;

    # HTTP_CONFLICT - RFC 4825 - Section 11. 
    return 0 if $code == HTTP_OK || $code == HTTP_CONFLICT;
    return 0 if $code == HTTP_CREATED && $method eq 'PUT';
    die status_message($code);
}

sub _request () {
    my ($self, $method) = @_;

    $self->useragent->credentials($self->netloc, $self->auth_realm,
                   $self->auth_username, $self->auth_password);

    my $request = new HTTP::Request($method => $self->uri);
    
    if ($method eq 'PUT') {
        $request->header('content-length' => length($self->content));
        $request->content($self->content);
    }
   
    my $response = $self->useragent->request($request);
    
    $self->_http_response_code($method,$response->code) 
        if $method ne "DELETE";

    return ($method eq 'GET' || $response->code == HTTP_CONFLICT)
        ? $response->content : $response->code;
}



sub get { $_[0]->_request('GET'); }   

sub delete { $_[0]->_request('DELETE'); }

sub put { $_[0]->_request('PUT'); }


1;

