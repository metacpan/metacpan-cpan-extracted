package WWW::PubNub::Message;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: PubNub Message
$WWW::PubNub::Message::VERSION = '0.001';
use Moo;
use Scalar::Util qw( looks_like_number );

has pubnub => (
  is => 'ro',
  required => 1,
);

has response => (
  is => 'ro',
  required => 1,
);

has request => (
  is => 'ro',
  required => 1,
);

has message => (
  is => 'ro',
  required => 1,
);

has channel => (
  is => 'ro',
  predicate => 1,
);

sub get {
  my ( $self, $key ) = @_;
  return $self->message unless defined $key;
  if (ref $self->message eq 'ARRAY') {
    return $self->message->[$key] if looks_like_number($key);
  } elsif ($self->message eq 'HASH') {
    return $self->message->{$key};
  }
  return;
}

1;

__END__

=pod

=head1 NAME

WWW::PubNub::Message - PubNub Message

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 pubnub

This attribute holds the L<WWW::PubNub> object which was responsible for this message.

=head2 request

This attribute holds the L<HTTP::Request> object which was responsible for this message.

=head2 response

This attribute holds the L<HTTP::Response> object which was responsible for this message.

=head1 SPONSORING

This distribution is sponsored by L<RealEstateCE.com|http://realestatece.com/>.

=head1 SUPPORT

IRC

  /msg Getty on irc.perl.org or chat.freenode.net.

Repository

  https://github.com/Getty/p5-www-pubnub
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/Getty/p5-www-pubnub/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
