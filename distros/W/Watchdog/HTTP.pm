package Watchdog::HTTP;

use strict;
use Alias;
use base qw(Watchdog::Base);
use HTTP::Request;
use LWP::UserAgent;
use vars qw($VERSION $HOST $PORT $FILE);

$VERSION = '0.02';

=head1 NAME

Watchdog::HTTP - Test status of HTTP service

=head1 SYNOPSIS

  use Watchdog::HTTP;
  $h = new Watchdog::HTTP($name,$host,$port,$file);
  print $h->id, $h->is_alive ? ' is alive' : ' is dead', "\n";

=head1 DESCRIPTION

B<Watchdog::HTTP> is an extension for monitoring an HTTP server.

=cut

my($name,$port,$file) = ('httpd',80,'');

=head1 CLASS METHODS

=head2 new($name,$host,$port,$file)

Returns a new B<Watchdog::HTTP> object.  I<$name> is a string which
will identify the service to a human (default is 'httpd').  I<$host>
is the hostname which is running the service (default is 'localhost').
I<$port> is the port on which the service listens (default is 80).

=cut

sub new($$$) {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  $_[0] = $name unless defined($_[0]);
  $_[2] = $port unless defined($_[2]); 
  my $self  = bless($class->SUPER::new(@_),$class);
  return $self;
}

#------------------------------------------------------------------------------

=head1 OBJECT METHODS

=head2 is_alive()

Returns true if an HTTP B<GET> method succeeds for the URL
B<http://$host:$port/$file> or false if it doesn't.

=cut

sub is_alive() {
  my $self = attr shift;
  my $request  = new HTTP::Request(GET => "http://$HOST:$PORT/$FILE");
  my $ua       = new LWP::UserAgent;
  my $response = $ua->request($request);
  return $response->is_success ? 1 : 0;
}

#------------------------------------------------------------------------------

=head1 SEE ALSO

L<Watchdog::Base>

=head1 AUTHOR

new Maintainer: Clemens Gesell E<lt>clemens.gesell@vegatron.orgE<gt>

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
