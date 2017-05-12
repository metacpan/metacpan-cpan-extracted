#!/usr/bin/perl
#
# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2002 Murat Uenalan. All rights reserved.
# Note: This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.

our $VERSION = '0.2.1';

use warnings; use strict;

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.

use Getopt::Long;

use Pod::Usage;

our %opts = ( host => 'localhost', port => 4800, passwd => undef );

	GetOptions (\%opts, 'help|?', 'man', 'debug!', 'port=i', 'host=s', 'passwd=s' ) or pod2usage(2);

	pod2usage(1) if $opts{help};

	#pod2usage( -verbose => 2 ) if $opts{man};

	qx{perldoc Winamp::Control} if $opts{man};

##
##

use Winamp::Control;

	my $winamp = Winamp::Control->new( host => $opts{host}, port => $opts{port}, port => $opts{passwd} );

	if( my $ver = $winamp->getversion )
	{
		printf "\nConnected to Winamp (Ver: %s)\n", $ver;

		print "Current playlist:\n\t", join "\n\t", $winamp->getplaylisttitle(), "\n";

		printf "\nCurrently playing: %s\n", $winamp->getcurrenttitle() if $winamp->isplaying();

		print "File entry:\n\t", $winamp->getplaylistfile( a => $winamp->getlistpos ), "\n";

		my $com = shift @ARGV;

		print "Returned ($com): " , $winamp->$com( ), "\n" if $com;
	}
	else
	{
		warn 'Unable to connect to winamp/httpQ';
	}

__END__

=head1 NAME

winampctl - control winamp over a network

=head1 SYNOPSIS

winamp [options] [command ...]

 Options:
   -help            brief help message
   -man             full documentation

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-host>

Host running winamp/httpQ (default: localhost).

=item B<-port>

Port to connect to httpQ (default: 4800).

=item B<-passwd>

Plain text password for httpQ (default: none) if set in the httpQ preferences.

=back

=head1 DESCRIPTION

B<winampctl> will simply call the command as a method to the Winamp::Control
object, without any sanity checks.

=cut

