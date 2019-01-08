package WebService::Auth0::HTTPClient;

use Moo;
use URI;
use HTTP::Request::Common ();
use JSON::MaybeXS ();

has domain => (
  is=>'ro',
  required=>1 );

has ua => (
  is=>'bare',
  handles=>['request'],
  required=>1 );

sub GET { shift->request(HTTP::Request::Common::GET @_) }
sub POST { shift->request(HTTP::Request::Common::POST @_) }
sub PUT { shift->request(HTTP::Request::Common::PUT @_) }
sub DELETE { shift->request(HTTP::Request::Common::DELETE @_) }
sub PATCH { shift->request(HTTP::Request::Common::request_type_with_data('PATCH', @_)) }

sub encode_json { shift; JSON::MaybeXS::encode_json(shift) }

sub _prepare_json_req {
  my ($self, $uri, $json) = @_;
  return ( $uri,
    'content-type' => 'application/json',
    Content => $self->encode_json($json) );
}

sub POST_JSON {
  my $self = shift;
  return $self->POST($self->_prepare_json_req(@_));
}

sub PUT_JSON {
  my $self = shift;
  return $self->PUT($self->_prepare_json_req(@_));
}

sub PATCH_JSON {
  my $self = shift;
  return $self->PATCH($self->_prepare_json_req(@_));
}

sub uri_for {
  my $self = shift;
  my @query = ();
  if(my $type = ref($_[-1]||'')) {
    if($type eq 'ARRAY') {
      @query = @{pop(@_)};
    } elsif($type eq 'HASH') {
      @query = %{pop(@_)};
    }
  }
  @query = map { ref($_)||'' eq 'ARRAY' ? join(',', @$_): $_ } @query;
  my $uri = URI->new("https://${\$self->domain}/");
  $uri->path_segments(@_);
  $uri->query_form(@query) if @query;
  return $uri;
}

=head1 NAME

WebService::Auth0::HTTPClient - Common HTTP Client methods

=head1 SYNOPSIS

    N/A

=head1 DESCRIPTION

A Base class for managment API endpoints

=head1 METHODS

This class defines the following methods:

=head2 request

=head2 GET

=head2 POST

=head2 POST_JSON

=head2 DELETE

=head2 PATCH

=head2 PATCH_JSON

=head2 uri_for

=head1 ATTRIBUTES

This class defines the following attributes:

=head2 ua

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
