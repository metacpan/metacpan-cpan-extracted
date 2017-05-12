package WWW::Mechanize::Tor;

use strict;
use warnings;
use LWP::UserAgent::Tor;
use WWW::Mechanize;

our $VERSION = '0.01';

use parent qw(LWP::UserAgent::Tor WWW::Mechanize);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Mechanize::Tor - rotate your ips

=head1 VERSION

version 0.01

=head1 SYNOPSIS
 
  use WWW::Mechanize::Tor;

  my $mech = WWW::Mechanize::Tor->new(
      tor_control_port => 9051,            # empty port on default range(49152 .. 65535)
      tor_port         => 9050,            # empty port on default range(49152 .. 65535)
      tor_ip           => '127.0.0.1',     # localhost on default
      tor_config       => 'path/to/torrc', # tor default config path
  );

  if ($mech->rotate_ip) {
      say 'got another ip';
  }
  else {
      say 'Try again?';
  }

=head1 DESCRIPTION

Inherits directly form LWP::UserAgent::Tor instead of LWP::UserAgent. Launches tor proc in background
and connects to it via socket. Every method call of C<rotate_ip> will send a request to change the
exit node and return 1 on sucess.

=head1 METHODS

=head2 rotate_ip

  $mech->rotate_ip;

Try to get another exit node via tor.
Returns 1 for success and 0 for failure.

=head1 ACKNOWLEDGEMENTS

Inspired by a script of ac0v overcoming some limitations (no more!) of web scraping...

=head1 LICENSE

This is released under the Artistic License.

=head1 AUTHOR

spebern <bernhard@specht.net>

=cut
