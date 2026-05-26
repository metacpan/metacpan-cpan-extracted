package WWW::MailboxOrg::MockIO;

# Pluggbares Test-Backend: implementiert Role::IO ohne echte HTTP-Calls.
# Nimmt vordefinierte Antworten entgegen und zeichnet alle Calls auf.

use Moo;
use WWW::MailboxOrg::JSONRPCResponse;

with 'WWW::MailboxOrg::Role::IO';

has _responses => (
  is      => 'ro',
  default => sub { {} },
);

has _calls => (
  is      => 'ro',
  default => sub { [] },
);

# add_response('method.name', $result_hashref)
# Für eine Error-Response: add_response('method', { _error => { code => -1, message => '...' } })
sub add_response {
  my ( $self, $method, $result ) = @_;
  $self->_responses->{$method} = $result;
  return $self;
}

sub call {
  my ( $self, $req ) = @_;
  push @{ $self->_calls }, $req;

  my $method = $req->method;
  if ( exists $self->_responses->{$method} ) {
    my $data = $self->_responses->{$method};
    if ( ref $data eq 'HASH' && exists $data->{_error} ) {
      return WWW::MailboxOrg::JSONRPCResponse->new(
        error => $data->{_error},
        id    => $req->id,
      );
    }
    return WWW::MailboxOrg::JSONRPCResponse->new(
      result => $data,
      id     => $req->id,
    );
  }

  return WWW::MailboxOrg::JSONRPCResponse->new(
    result => {},
    id     => $req->id,
  );
}

sub last_call  { $_[0]->_calls->[-1] }
sub call_count { scalar @{ $_[0]->_calls } }
sub reset_calls { @{ $_[0]->_calls } = () }

1;
