package WWW::Chain::UA::LWP;
our $VERSION = '0.101';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Using LWP::UserAgent to execute WWW::Chain chains

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

=encoding UTF-8

=head1 NAME

WWW::Chain::UA::LWP - Using LWP::UserAgent to execute WWW::Chain chains

=head1 VERSION

version 0.101

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-chain>

  git clone https://github.com/Getty/p5-www-chain.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
