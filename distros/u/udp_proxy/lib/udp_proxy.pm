package udp_proxy;

use 5.008_008;
use strict;
use warnings;
use POSIX ':signal_h';

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use udp_proxy ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

require XSLoader;
XSLoader::load( 'udp_proxy', $VERSION );

# Preloaded methods go here.

sub new {
	my $invocant = shift;
	my $class = ref( $invocant ) || $invocant;
	
	my( $self ) = constructor( $class, @_ );
	$self->setup_signal_handlers();
	return $self;
}

sub setup_signal_handlers {
	my( $self ) = @_;

	sigaction SIGINT, new POSIX::SigAction sub { $self->interrupt(); exit; };
	sigaction SIGQUIT, new POSIX::SigAction sub { $self->interrupt(); exit; };
	sigaction SIGTERM, new POSIX::SigAction sub { $self->interrupt(); exit; };
}

sub interrupt {
	my( $self ) = @_;

	$self->interruption();
}

1;
__END__
=head1 NAME

udp_proxy - Perl binding for udpxy

=head1 SYNOPSIS

  use udp_proxy;

  my $uph = new udp_proxy({
      interface => 'eth0',
      log     => 'udp_proxy.log',     # or \*LOG, or $fh, or *LOG
      handle  => 'stream.ts',         # like log, but default to stdout if not set.
  });
  $uph->do_relay('rtp', '233.33.210.86', 5050);

=head1 DESCRIPTION

This module binds some udpxy functional to perl. It is possible to
record or transfer unscrambled multicast traffic.

=head1 METHODS

=over 4

=item my $uph = new udp_proxy( \%args );

Method new creates object udp_proxy with some parameters:
 - interface - interface on which object should receive multicast traffic
 - log - filehandle or filename of log file.
 - handle - filehandle or filename for writing MPEG-TS packets.

=item $uph->do_relay( $command, $host, $port );

Method that actualy do the work. Writing data to STDOUT or speciefied handle.
 $command - possible values 'rtp' or 'udp'
 $host - multicast host to which object should join
 $port - port on which transmission is going.

=back

=head2 EXPORT

None by default.

=head1 EXAMPLE

  use udp_proxy;

  my $app = sub {
      my $env = shift;

      return sub {
          my $respond = shift;
          my $writer = $respond->([200, ['Content-Type', 'application/octet-stream']]);
          my $uph = new udp_proxy({
              interface => 'en0',
              log       => $env->{'psgi.errors'},
              handle    => $env->{'psgix.io'},
          });
          $uph->do_relay('rtp', '233.33.210.86', 5050);
          $writer->close();
      };
  };

=head1 SEE ALSO

IO::Socket::Multicast

=head1 AUTHOR

Pavel V. Cherenkov, E<lt>pcherenkov@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2013 by Pavel V. Cherenkov

This library is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.


=cut
