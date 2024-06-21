package WWW::Chain::UA::LWP;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Using LWP::UserAgent to execute WWW::Chain chains
$WWW::Chain::UA::LWP::VERSION = '0.007';
use Moo;
extends 'LWP::UserAgent';

with qw( WWW::Chain::UA );

use HTTP::Cookies;
use Scalar::Util 'blessed';
use Safe::Isa;

sub request_chain {
  my ( $self, $chain ) = @_;
  die __PACKAGE__."->request_chain needs a WWW::Chain object as parameter"
    unless ( blessed($chain) && $chain->$_isa('WWW::Chain') );
  $self->cookie_jar({}) unless $self->cookie_jar;
  while (!$chain->done) {
    my @responses;
    for (@{$chain->next_requests}) {
      my $response = $self->request($_);
      push @responses, $response;
    }
    $chain->next_responses(@responses);
  }
  return $chain;
}

1;

__END__

=pod

=head1 NAME

WWW::Chain::UA::LWP - Using LWP::UserAgent to execute WWW::Chain chains

=head1 VERSION

version 0.007

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
