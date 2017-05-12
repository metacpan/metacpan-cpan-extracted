#!perl -w -- (emacs/sublime) -*- tab-width: 4; mode: perl -*-
#$Id$

# Script Summary

=head1 NAME

digest-md5 - Find and print the executable path(s)

=head1 VERSION

This document describes C<digest-md5> ($Version$).

=head1 SYNOPSIS

digest-md5 [B<<option(s)>>] B<<filename(s)>>

=begin HIDDEN-OPTIONS

Options:

		--version       version message
	-?, --help          brief help message

=end HIDDEN-OPTIONS

=head1 OPTIONS

=over

=item --version

=item --usage

=item --help, -?

=item --man

Print the usual program information

=back

=head1 REQUIRED ARGUMENTS

=over

=item <filename(s)>

FILENAMES for digest.

=back

=head1 DESCRIPTION

B<digest-md5> will calculate and print the hexadecimal MD5 digest for each FILENAME.

=cut

# VERSION: major.minor.release[.build]]  { minor is ODD => alpha/beta/experimental; minor is EVEN => stable/release }
# generate VERSION from $Version$ SCS tag
# $defaultVERSION 	:: used to make the VERSION code resilient vs missing keyword expansion
# $generate_alphas	:: 0 => generate normal versions; true/non-0 => generate alpha version strings for ODD numbered minor versions
use version qw(); our $VERSION; { my $defaultVERSION = '0.1.0'; my $generate_alphas = 0; $VERSION = ( $defaultVERSION, qw( $Version$ ))[-2]; if ($generate_alphas) { $VERSION =~ /(\d+)\.(\d+)\.(\d+)(?:\.)?(.*)/; $VERSION = $1.'.'.$2.((!$4&&($2%2))?'_':'.').$3.($4?((($2%2)?'_':'.').$4):q{}); $VERSION = version::qv( $VERSION ); }; } ## no critic ( ProhibitCallsToUnexportedSubs ProhibitCaptureWithoutTest ProhibitNoisyQuotes ProhibitMixedCaseVars ProhibitMagicNumbers)

use Pod::Usage;
use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat);

#use Carp::Assert;

use strict;
use warnings;
use diagnostics;

use File::Spec;

use Digest::MD5;

@ARGV = Win32::CommandLine::argv() if eval { require Win32::CommandLine; };

# getopt
my %ARGV = ();
GetOptions (\%ARGV, 'help|h|?|usage', 'man', 'version|ver|v') or pod2usage(2);
#Getopt::Long::VersionMessage() if $ARGV{'version'};
pod2usage(-verbose => 99, -sections => '', -message => (File::Spec->splitpath($0))[2]." v$::VERSION") if $ARGV{'version'};
pod2usage(1) if $ARGV{'help'};
pod2usage(-verbose => 2) if $ARGV{'man'};

pod2usage(1) if @ARGV < 1;

foreach (@ARGV)
	{
	#print '#args = '.scalar(@ARGV)."\n";
	if (@ARGV > 1) { print "$_: "; }

	open(FILE, $_) or die "Can't open '$_': $!";
    binmode(FILE);

    print Digest::MD5->new->addfile(*FILE)->hexdigest, "\n";

    close(FILE);
	}
