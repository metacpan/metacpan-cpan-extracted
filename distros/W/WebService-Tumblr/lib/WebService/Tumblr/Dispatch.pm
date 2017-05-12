package WebService::Tumblr::Dispatch;

use strict;
use warnings;

use Any::Moose;
use Try::Tiny;
use HTTP::Request;

has tumblr => qw/ is ro required 1 isa WebService::Tumblr weak_ref 1 /, handles => [qw/ agent /];
has request => qw/ is ro lazy_build 1 isa HTTP::Request /;
sub _build_request {
    my $self = shift;

    my $method = $self->method;
    my $uri = $self->uri;
    $uri = $uri->uri if $uri->can( 'uri' );
    my $query = $self->query;

    my $request = HTTP::Request->new( $method, $uri );
    
    if ( 'POST' eq uc $method ) {
        require URI;
        my $tmp = URI->new('http:');
        $tmp->query_form( %$query );
        my $content = $tmp->query;
        $request->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
        $request->header( 'Content-Length' => length $content );
        $request->content( $content );
    }
    else {
        $request->uri->query_form( %$query );
    }

    return $request;
}

has result => qw/ is ro lazy_build 1 /, handles => [qw/ content response is_success /];
sub _build_result {
    my $self = shift;
    return $self->_submit;
}

has url => qw/ accessor _url required 1 /;
sub url {
    my $self = shift;
    return $self->_url unless @_;
    $self->_url( @_ );
    return $self;
}
sub uri { return shift->url( @_ ) }

has method => qw/ accessor _method required 1 isa Str /;
sub method {
    my $self = shift;
    return $self->_method unless @_;
    $self->_method( @_ );
    return $self;
}

has query => qw/ accessor _query isa HashRef /, default => sub { {} };
sub query {
    my $self = shift;
    my $query = $self->_query;
    return $query unless @_;
    my %set = @_;
    @$query{ keys %set } = values %set; 
    $self->_query( $query ); # Probably do not need to do this, but, eh
    return $self;
}

sub _submit {
    my $self = shift;
    
    my $agent = $self->agent;
    my $request = $self->request;
    my $response = $agent->request( $request );
    my $result = WebService::Tumblr::Result->new( dispatch => $self, request => $request, response => $response );

    return $result;
}

sub submit {
    my $self = shift;
    
    return $self->result->content;
}

sub authenticate {
    my $self = shift;

    my $query = $self->query;
    my ( $email, $password ) = $self->tumblr->identity;
    defined $query->{ email } or $query->{ email } = $email;
    defined $query->{ password } or $query->{ password } = $password;

    $self->method( 'POST' );

    return $self;
}


1;
