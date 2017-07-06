use strict;
use warnings;
package Wing::Client;
$Wing::Client::VERSION = '1.1000';
use HTTP::Thin;
use HTTP::Request::Common;
use HTTP::CookieJar;
use JSON;
use URI;
use Ouch;
use Moo;


=head1 NAME

Wing::Client - A simple client to Wing's web services.

=head1 VERSION

version 1.1000

=head1 SYNOPSIS

 use Wing::Client;

 my $wing = Wing::Client->new(uri => 'https://www.thegamecrafter.com');

 my $game = $wing->get('game/528F18A2-F2C4-11E1-991D-40A48889CD00');
 
 my $session = $wing->post('session', { username => 'me', password => '123qwe', api_key_id => 'abcdefghijklmnopqrztuz' });

 $game = $wing->put('game/528F18A2-F2C4-11E1-991D-40A48889CD00', { session_id => $session->{id}, name => 'Lacuna Expanse' });

 my $status = $wing->delete('game/528F18A2-F2C4-11E1-991D-40A48889CD00', { session_id => $session->{id} });

=head1 DESCRIPTION

A light-weight wrapper for Wing's (L<https://github.com/plainblack/Wing>) RESTful API (an example of which can be found at: L<https://www.thegamecrafter.com/developer/>). This wrapper basically hides the request cycle from you so that you can get down to the business of using the API. It doesn't attempt to manage the data structures or objects the web service interfaces with.

=head1 METHODS

The following methods are available.

=head2 new ( params ) 

Constructor.

=over

=item params

A hash of parameters.

=over

=item uri

The base URI of the service you're interacting with. Example: C<https://www.thegamecrafter.com>.

=item session_id

A Wing session_id.  If set, this is automatically added to all requests because I'm lazy.  If you don't
want a session_id for a while, set the C<no_session_id> flag on the object.

=item no_session_id

If set to true, prevents adding the session_id to the request.

=cut

has uri => (
    is          => 'rw',
    required    => 1,
);

=item agent

A LWP::UserAgent object used to keep a persistent cookie_jar across requests.

=back

=back

=cut

has agent => (
    is          => 'ro',
    required    => 0,
    lazy        => 1,
    builder     => '_build_agent',
);

sub _build_agent {
    return HTTP::Thin->new( cookie_jar => HTTP::CookieJar->new() )
}

has [qw/session_id no_session_id/] => (
    is          => 'rw',
    required    => 0,
);

##Optionally add a session id, if the following conditions are met:
## 1) A session_id was put into the object
## 2) no_session_id was not set
## 3) No session_id was passed with any parameters when calling the method.

sub _add_session_id {
    my $orig   = shift;
    my $self   = shift;
    my $uri    = shift;
    my $params = shift || {};
    if ($self->session_id && ! $self->no_session_id && ! exists $params->{session_id}) {
        $params->{session_id} = $self->session_id;
    }
    return $self->$orig($uri, $params, @_);
}

around get => \&_add_session_id;
around post => \&_add_session_id;
around put => \&_add_session_id;
around delete => \&_add_session_id;

=head2 get(path, params)

Performs a C<GET> request, which is used for reading data from the service.

=over

=item path

The path to the REST interface you wish to call. You can abbreviate and leave off the C</api/> part if you wish.

=item params

A hash reference of parameters you wish to pass to the web service.

=back

=cut

sub get {
    my ($self, $path, $params) = @_;
    my $uri = $self->_create_uri($path);
    $uri->query_form($params);
    return $self->_process_request( GET $uri );
}

=head2 delete(path, params)

Performs a C<DELETE> request, deleting data from the service.

=over

=item path

The path to the REST interface you wish to call. You can abbreviate and leave off the C</api/> part if you wish.

=item params

A hash reference of parameters you wish to pass to the web service.

=back

=cut

sub delete {
    my ($self, $path, $params) = @_;
    my $uri = $self->_create_uri($path);
    return $self->_process_request(POST $uri->as_string, $params, 'X-HTTP-Method' => 'DELETE', Content_Type => 'form-data', Content => $params );
}

=head2 put(path, params, options)

Performs a C<PUT> request, which is used for updating data in the service.

=over

=item path

The path to the REST interface you wish to call. You can abbreviate and leave off the C</api/> part if you wish.

=item params

A hash reference of parameters you wish to pass to the web service.

=item options

=over

=item upload

Defaults to 0. If 1 then when you pass a param that is an array reference, the value of that array reference will be assumed to be a file name and will attempt to be uploaded per the inner workings of L<HTTP::Request::Common>.

=back

=back

=cut

sub put {
    my ($self, $path, $params, $options) = @_;
    my $uri = $self->_create_uri($path);
    my %headers = ( 'X-HTTP-Method' => 'PUT',Content => $params );
    if ($options->{upload}) {
        $headers{Content_Type} = 'form-data';
    }
    return $self->_process_request( POST $uri->as_string,  %headers);
}

=head2 post(path, params, options)

Performs a C<POST> request, which is used for creating data in the service.

=over

=item path

The path to the REST interface you wish to call. You can abbreviate and leave off the C</api/> part if you wish.

=item params

A hash reference of parameters you wish to pass to the web service.

=item options

=over

=item upload

Defaults to 0. If 1 then when you pass a param that is an array reference, the value of that array reference will be assumed to be a file name and will attempt to be uploaded per the inner workings of L<HTTP::Request::Common>.

=back

=back

=cut

sub post {
    my ($self, $path, $params, $options) = @_;
    my $uri = $self->_create_uri($path);
    my %headers = ( Content => $params );
    if ($options->{upload}) {
        $headers{Content_Type} = 'form-data';
    }
    return $self->_process_request( POST $uri->as_string, %headers );
}

sub _create_uri {
    my $self = shift;
    my $path = shift;
    unless ($path =~ m/^\/api/) {
        $path = '/api/'.$path;
    }
    return URI->new($self->uri.$path);
}

sub _process_request {
    my $self = shift;
    $self->_process_response($self->agent->request( @_ ));
}

sub _process_response {
    my $self = shift;
    my $response = shift;
    my $result = eval { from_json($response->decoded_content) }; 
    if ($@) {
        ouch 500, 'Server returned unparsable content.', { error => $@, content => $response->decoded_content };
    }
    elsif ($response->is_success) {
        return $result->{result};
    }
    else {
        ouch $result->{error}{code}, $result->{error}{message}, $result->{error}{data};
    }
}

=head1 PREREQS

L<HTTP::Thin>
L<Ouch>
L<HTTP::Request::Common>
L<HTTP::CookieJar>
L<JSON>
L<URI>
L<Moo>

=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/Wing-Client>

=item Bug Reports

L<http://github.com/rizen/Wing-Client/issues>

=back

=head1 AUTHOR

JT Smith <jt_at_plainblack_dot_com>

=head1 LEGAL

This module is Copyright 2013 Plain Black Corporation. It is distributed under the same terms as Perl itself. 

=cut

1;
