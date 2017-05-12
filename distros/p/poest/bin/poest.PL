#!/usr/bin/env perl
# $Id: poest.PL,v 1.1 2003/04/08 00:27:30 cwest Exp $

#!/usr/bin/env perl

use Config;
use File::Basename qw[basename dirname];
use Cwd;

my $origdir = cwd;
chdir dirname $0;
my $file = basename( $0, '.PL' );
$file .= '.com' if $^O eq 'VMS';

open OUT, "> $file" or die "Can't create $file: $!";

print OUT <<HEADER, do{ local $/ = undef; <DATA> };
#!$Config{perlpath}
HEADER

close OUT;

chmod 0755, $file;

chdir $origdir;

__END__
use strict;
$^W = 1;

use Getopt::Std;
use Carp;

use lib qw[lib ../lib];
use POEST::Server;

use vars qw[$VERSION];

$VERSION = '0.01_03pre-alpha';

=head1 NAME

poest - Perl and POE based SMTP Server

=head1 SYNOPSIS

 poest start Config POEST::Config::General ConfigFile /etc/poest.conf

=head1 CONFIGURATION

All configuration parameters are passed on the command line after
the command.  They are passed as is to the contructor for
L<POEST::Server|POEST::Server>.

=head1 COMMANDS

=cut

my @commands = qw[start stop run usage help];

my $command = shift;

usage() unless $command && grep { $_ eq $command } @commands;

DOIT: {
	no strict 'refs';
	&{ $command };
	exit(0);
}

=head2 start

Start and fork the daemon.

=back

=cut

sub start {
	my $poest = POEST::Server->new( @ARGV )->start;
}

=head2 stop

Stop the daemon.

=cut

sub stop {
	POEST::Server->new( @ARGV )->stop;
}

=head2 run

Run poest in the forground.  No pid file will be created, no forking
will be done.  C<STD*> will remain open.

=cut

sub run {
	POEST::Server->new( @ARGV )->run;
}

=head2 usage

Shows usage.  For more detail see help.

=cut

sub usage {
    my $commands = join '|', @commands;
	print "poest $commands [args ...]\n";
	exit(0);
}

=head2 help

Detailed usage instructions.

=cut

sub help {
  system( "perldoc $0" );
  exit(0);
}

1;

__END__

=pod

=head1 AUTHOR

Casey West, <F<casey@dyndns.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 DynDNS.org

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

THIS PACKAGE IS PROVIDED WITH USEFULNESS IN MIND, BUT WITHOUT GUARANTEE
OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. USE IT AT YOUR
OWN RISK.

For more information, please visit http://opensource.dyndns.org

=head1 SEE ALSO

L<perl>, L<POEST::Server>.

=cut
