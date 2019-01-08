package WebService::Auth0::UA::LWP;

use Moo;
use LWP::UserAgent;
use JSON::MaybeXS;
use Future;

has options => (is=>'ro', required=>1, default=>sub { +{} });
has ua => (
  is=>'ro',
  lazy=>1,
  required=>1,
  default=>sub {
    LWP::UserAgent->new(
      keep_alive => 10,
      agent => 'WebService::Auth0::UA::LWP/1.0',
      requests_redirectable => [],
      %{ $_[0]->options });
  },
);

sub request {
  my ($self, $request) = @_;
  my $response = $self->ua->request($request);
  my $json_err;
  my $data = do {
    # Required because I often see 204 no content but with
    # application/json as the content type
    if($response->code == 204) {
      undef;
    } else {
      eval {
        $response->content_type eq 'application/json' ? 
          decode_json($response->decoded_content) :
            $response;
      } || do {
        $json_err = $@;
      };
    }
  };

  if($json_err) {
    return Future->fail(
      $json_err,
      json => $request,
      $response);
  } elsif($response->is_success) {
    return Future->done($data);
  } elsif($response->is_redirect) {
    return Future->done($response->header('location'), $data);
  } else {
    return Future->fail(
      $response->message,
      "http_${\$response->code}" => $request,
      $data);
  }
}

1;

=head1 NAME

WebService::Auth0::UA::LWP - Use LWP for connection

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS

This class defines the following methods:

=head1 SEE ALSO
 
L<LWP>, L<Futures>

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
