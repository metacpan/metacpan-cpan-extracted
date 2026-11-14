package Twilio::Jwt::Client::ScopeURI;

use 5.016;
use warnings;

use Twilio::Exceptions::TwilioException;

our $VERSION = '2.002';

my $PARTS_OF_A_SCOPE = 3;

sub new {
  my ($class, $service, $privilege, $params) = @_;

  return bless { service => $service, privilege => $privilege, params => _pairs($params) }, $class;
}

sub get_service   { return $_[0]{service} }
sub get_privilege { return $_[0]{privilege} }

sub get_params {
  my ($self) = @_;
  return { map { $_->[0] => $_->[1] } @{ $self->{params} } };
}

sub add_param {
  my ($self, $name, $value) = @_;

  $self->{params} = [grep { $_->[0] ne $name } @{ $self->{params} }];
  push @{ $self->{params} }, [$name, $value];
  return $self;
}

sub to_string {
  my ($self) = @_;

  my $uri = "scope:$self->{service}:$self->{privilege}";
  return $uri if !@{ $self->{params} };
  return "$uri?" . $self->build_query($self->{params});
}

sub parse {
  my ($class, $uri) = @_;

  if (($uri // q{}) !~ /\Ascope:/) {
    Twilio::Exceptions::TwilioException->throw('Not a scope URI according to scheme');
  }

  my ($scope, $query) = split /[?]/, $uri, 2;
  my (undef, $service, $privilege) = split /:/, $scope, $PARTS_OF_A_SCOPE;
  if (!length($privilege // q{})) {
    Twilio::Exceptions::TwilioException->throw('Not enough parts for scope URI');
  }

  my @pairs = map { [_decoded_pair($_)] } split /&/, $query // q{};
  return $class->new($service, $privilege, \@pairs);
}

# The same text as http_build_query in PHP, which is what Twilio's clients have always been sent:
# a space is a plus, only these few characters stay as they are, and undefined values are skipped.
sub build_query {
  my ($class, $params) = @_;

  my @given = grep { defined $_->[1] } @{ _pairs($params) };
  return join q{&}, map { _encoded($_->[0]) . q{=} . _encoded($_->[1]) } @given;
}

# Pairs keep the order a caller chose. A hash has none, so its names are sorted.
sub _pairs {
  my ($params) = @_;

  return [@{$params}] if ref $params eq 'ARRAY';

  my %given = %{ $params // {} };
  return [map { [$_, $given{$_}] } sort keys %given];
}

sub _encoded {
  my ($text) = @_;

  my $encoded = _utf8_bytes($text);
  $encoded =~ s/([^A-Za-z0-9\-_. ])/sprintf '%%%02X', ord $1/ge;
  $encoded =~ tr/ /+/;
  return $encoded;
}

# As in Twilio::Http::Client: valid UTF-8 bytes are already encoded, and encoding them again
# would corrupt text from a script without "use utf8".
sub _utf8_bytes {
  my ($value) = @_;
  my $text = "$value";

  if (!utf8::is_utf8($text)) {
    my $probe = $text;
    return $text if utf8::decode($probe);
  }

  utf8::encode($text);
  return $text;
}

sub _decoded_pair {
  my ($pair) = @_;

  my ($name, $value) = split /=/, $pair, 2;
  return (_decoded($name), _decoded($value // q{}));
}

sub _decoded {
  my ($text) = @_;

  $text =~ tr/+/ /;
  $text =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
  utf8::decode($text);
  return $text;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::Client::ScopeURI - One permission inside a capability token

=head1 SYNOPSIS

  my $scope = Twilio::Jwt::Client::ScopeURI->new('client', 'incoming', { clientName => 'me' });
  print $scope->to_string;    # scope:client:incoming?clientName=me

  my $same = Twilio::Jwt::Client::ScopeURI->parse($scope->to_string);

=head1 DESCRIPTION

Used by L<Twilio::Jwt::ClientToken>.

=head1 METHODS

=head2 new

  my $scope = Twilio::Jwt::Client::ScopeURI->new($service, $privilege, $params);

C<$params> is a hash reference, written with its names sorted, or an array reference
of pairs, written in the order given.

=head2 parse

  my $scope = Twilio::Jwt::Client::ScopeURI->parse($uri);

Reads a scope back. It throws L<Twilio::Exceptions::TwilioException> when the text
is not a scope.

=head2 to_string

Returns the text of the scope.

=head2 add_param

  $scope->add_param($name, $value);

Sets a parameter, and returns the scope.

=head2 build_query

  my $query = Twilio::Jwt::Client::ScopeURI->build_query($params);

Returns parameters as a URL query, encoded as PHP's C<http_build_query> does.

=head2 get_service

=head2 get_privilege

=head2 get_params

Return each part of the scope. C<get_params> returns a hash reference.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
