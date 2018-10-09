#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Shopify::Liquid;
use Getopt::Long;
use File::Find;
use File::Slurp;
use Pod::Usage;


=head1 NAME

shopify-liquid-compile.pl - Compile a file, or watch a file/directory for changes, and recompile as needed.

=head1 SYNOPSIS

shopify-liquid-compile.pl action [files]

	action		The action to take. Can be either 'compile'
			or 'watch'.

	files		The list of files and folders to check.
	
	--json		Takes in either a file name, or a JSON
			string. If filename, will also check
			for changes to this file before recompiling.

	--base		Optionally specifies the path to a base
			liquid implementation. If no --class
			is specified attempts to determine
			the class. Takes paths or package names.
			
	--class		Specifically sets the class to use for
			the liquid parser. By default, this is
			WWW::Shopify::Liquid. If --base is used,
			will attempt to automatically determine.
	
	--verbose	Displays extra info.
	--quiet		Suppress everything except errors.
	
	--help		Displays this messaqge.
	--fullhelp	Displays the full pod doc.

This tool essentially prints out whether or not it thinks a file's
liquid is correct, in terms of sytnax. If it finds an issue, it'll
point out the first error in that file. Otherwise it'll print OK.

By default, the behaviour of this script is recursive, meaning if
you specify a directory amongst your file listing, this script
will expand it and look at the subfolders.

=cut

=head1 EXAMPLES

	shopify-liquid-compile.pl *.liquid
	
=cut

my @ARGS;

GetOptions(
	'json=s' => \my $json,
	'help' => \my $help,
	'fullhelp' => \my $fullhelp,
	'base=s' => \my @bases,
	'class=s' => \my $class,
	'verbose' => \my $verbose,
	'quiet' => \my $quiet,
	'<>' => sub { push(@ARGS, $_[0]); }
);

pod2usage(-verbose => 2) if ($fullhelp);
pod2usage() if $help;

eval {

	die "Requires action as argument, and at least one file." unless int(@ARGS) > 1;
	

	if (@bases) {
		for my $base (@bases) {
			die "Can't find base $base." unless -e $base;
			if ($base =~ m/::/) {
				eval("require $base;") or die "Can't compile base $base.";
				if (my $exp = $@) {
					die $exp;
				}
				$class = $base;
			} else {
				require($base) or die "Can't compile base.";
				($class) = map { $_ =~ /\s*package\s+(.*?\:\:Liquid);/ ? ($1) : () } (read_file($base)) if !$class;
			}
		}
	}

	my $action = shift(@ARGS);

	my $errors = 0;
	$class = 'WWW::Shopify::Liquid' if !$class;
	print "Using liquid class $class.\n" if $verbose;
	my $liquid = $class->new;
	write_file($_ =~ s/\.liquid//r, $liquid->render_file({ }, $_)) for (@ARGS);
	
	
};
if (my $exp = $@) {
	$exp =~ s/ at .*? line \d+.//;
	chomp($exp);
	print STDERR "$exp\n";
	exit(-1);
}
