@rem = q{--*-Perl-*--
@::# (emacs/sublime) -*- mode: perl; tab-width: 4; coding: dos; -*-
@echo off

setlocal

:: 4NT/TCC
::DISABLE command aliasing (aliasing may loop); disable over-interpretation of % characters; disable redirection; disable backquote removal from commands
if 01 == 1.0 ( setdos /x-14567 )

perl -x -S %0 %*
if NOT %errorlevel% == 0 (
	exit /B %errorlevel%
	)

goto endofperl

@rem };
#!perl -w --
#NOTE: use '#line NN' (where NN = actual_line_number + 1) to set perl line # for errors/warnings
#line 22
#$Id: quote.pl,v 0.3.3.179015 ( r124:73041c265478 [mercurial] ) 2009/02/23 19:14:03 rivy $

# Script Summary

=head1 NAME

quote - Convert STDIN to dos quoted strings

=head1 VERSION

This document describes C<quote> ($Version: 0.3.3.179015 $).

=head1 SYNOPSIS

quote [B<<option(s)>>] [B<<filename(s)>>]

=begin HIDDEN-OPTIONS

Options:

		--version       version message
	-?, --help          brief help message

=end HIDDEN-OPTIONS

=head1 OPTIONS

=over

=item --all, -a

Quote all output

=item --combine, -c

Combine INPUT into one line seperated by SPACE.

=back

=head1 OPTIONAL ARGUMENTS

=over

=item <filename(s)>

FILENAMES...

=back

=head1 OPTIONS

=over

=item --version

=item --usage

=item --help, -?

=item --man

Print the usual program information

=back

=head1 DESCRIPTION

B<quote> will read INPUT (either STDIN or B<<filename(s)>> and "quote" each input line, printing the results to STDOUT. "Quoting" each argument converts it into a token which, when interpreted by C<CMD.EXE>, results in the original token.

=cut

# VERSION: major.minor.release[.build]]  { minor is ODD => alpha/beta/experimental; minor is EVEN => stable/release }
# generate VERSION from $Version: 0.3.3.179015 $ SCS tag
# $defaultVERSION 	:: used to make the VERSION code resilient vs missing keyword expansion
# $generate_alphas	:: 0 => generate normal versions; true/non-0 => generate alpha version strings for ODD numbered minor versions
use version qw(); our $VERSION; { my $defaultVERSION = '0.1.0'; my $generate_alphas = 0; $VERSION = ( $defaultVERSION, qw( $Version: 0.3.3.179015 $ ))[-2]; if ($generate_alphas) { $VERSION =~ /(\d+)\.(\d+)\.(\d+)(?:\.)?(.*)/; $VERSION = $1.'.'.$2.((!$4&&($2%2))?'_':'.').$3.($4?((($2%2)?'_':'.').$4):q{}); $VERSION = version::qv( $VERSION ); }; } ## no critic ( ProhibitCallsToUnexportedSubs ProhibitCaptureWithoutTest ProhibitNoisyQuotes ProhibitMixedCaseVars ProhibitMagicNumbers)

use Pod::Usage;
use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat);

#use Carp::Assert;

use strict;
use warnings;
#use diagnostics;

#use File::quote;
use File::Spec;

use Env::Path qw(PATH);

@ARGV = Win32::CommandLine::argv() if eval { require Win32::CommandLine; };

# getopt
my %ARGV = ();
GetOptions (\%ARGV, 'help|h|?|usage', 'man', 'version|ver|v', 'auto', 'dosify|dos|cmd|msdos|d', 'unixify|unix|u', 'all|a', 'combine|c') or pod2usage(2);
Getopt::Long::VersionMessage() if $ARGV{'version'};
pod2usage(1) if $ARGV{'help'};
pod2usage(-verbose => 2) if $ARGV{'man'};

#pod2usage(1) if @ARGV < 1;

if (!($ARGV{dosify} or $ARGV{unixify}))
	{
	if ($^O eq 'MSWin32') { $ARGV{dosify} = 1; }
	else { $ARGV{unixify} = 1; }
	}

if ($ARGV{unixify}) { die "unixify not implemented"; }

my $sep = qq{\n};
if ($ARGV{combine}) { $sep = q{ }; }

while(<>)
{
	chomp($_);
	print _dosify($_, {quote_all => $ARGV{all}}).$sep;
}

sub	_dosify {
	# _dosify( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
	# quote string, returning a string quote will be interpreted/parsed by DOS/CMD as the input string when input to the command line
	# CMD/DOS quirks: quote double-quotes:: {\\} => {\\} UNLESS followed by a double-quote mark when {\\} => {\} and {\"} => {"} (and doesn't end the quote)
	#	:: EXAMPLES: {a"b"c d} => {[abc][d]}, {a"\b"c d} => {[a\bc][d]}, {a"\b\"c d} => {[a\b"c d]}, {a"\b\"c" d} => {[a\b"c"][d]}
	#				 {a"\b\\"c d} => {[a\b\c][d]}, {a"\b\\"c" d} => {[a\b\c d]}, {a"\b\\"c d} => {[a\b\c][d]}, {a"\b\\c d} => {[a\b\\c d]}
	my %opt	= (
		quote_all => 0, 	# = true/false [default = false]	# if true, surround all output arguments with double-quotes
		);

	my $me = (caller(0))[3];	## no critic ( ProhibitMagicNumbers )	## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
	my $opt_ref;
	$opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));	## no critic (ProhibitPostfixControls)	## pop last argument only if it's a HASH reference (assumed to be options for our function)
	if ($opt_ref) { for (keys %{$opt_ref}) { if (exists $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' for function ".$me; return; } } }
	if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; } ## no critic ( RequireInterpolationOfMetachars ) #
	if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

	@_ = @_ ? @_ : $_ if defined wantarray;		## no critic (ProhibitPostfixControls)	## break aliasing if non-void return context

	# TODO: check these characters for necessity => PIPE characters [<>|] and internal double quotes for sure, [:]?, [*?] glob chars needed?, what about glob character set chars [{}]?
	my $dos_special_chars = '"<>|';
	my $dc = quotemeta( $dos_special_chars );
	for (@_ ? @_ : $_)
		{
		#print "_ = $_\n";
		s:\/:\\:g;								# forward to back slashes
		if ( $opt{quote_all} or ($_ =~ qr{(\s|[$dc])}))
			{
			#print "in qr\n";
			s:":\\":g;							# CMD: preserve double-quotes with backslash	# TODO: change to $dos_escape	## no critic (ProhibitUnusualDelimiters)
			s:([\\]+)\\":($1 x 2).q{\\"}:eg;	# double backslashes in front of any \" to preserve them when interpreted by DOS/CMD
			$_ = q{"}.$_.q{"};					# quote the final token
			};
		}

	return wantarray ? @_ : "@_";
}

__END__
:endofperl
