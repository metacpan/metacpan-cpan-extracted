#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;
use Getopt::Long;
use File::Find;
use File::Slurp;
use Pod::Usage;


=head1 NAME

shopify-liquid-verify.pl - Verifies the syntax of liquid files.

=head1 SYNOPSIS

shopify-liquid-verify.pl [files]

	files		The list of files and folders to check.

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

	shopify-liquid-verify.pl *

Will essentially look at all files in the folder, and give you a print out of their status.

	shopify-liquid-verify.pl * --base WWW::Shopify::Liquid::Extended
	
If WWW::Shopify::Liquid::Extended exists, and is installed in a normal inclusion pathway,
this class will be used to perform the verification.

	shopify-liquid-verify.pl test.liquid --base ~/MyLiquidClass.pm
	
Will load MyLiquidClass.pm and attempt to determine the primary class, and use that for 
the base verification.


	shopify-liquid-verify.pl  test.liquid --base ~/MyLiquidClass.pm --class NewLiquid
	
Will load MyLiquidClass.pm and specifically tell it to use NewLiquid as hte base class.

=cut

my @ARGS;

GetOptions(
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

	die "Requires file as argument." unless int(@ARGS) > 0;

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

	my $errors = 0;
	$class = 'WWW::Shopify::Liquid' if !$class;
	print "Using liquid class $class.\n" if $verbose;
	my $liquid = $class->new;
	for my $potential (@ARGS) {
		die "File $potential doesn't exist." unless -e $potential;
		my @files;
		if (-d $potential) {
			find({ no_chdir => 1, wanted => sub {
				push(@files, $_) if !-d $_;
			} }, $potential);
		} else {
			@files = $potential;
		}
		for my $file (@files) {
			eval { 
				$liquid->verify_file($file);
			};
			if (my $exp = $@) {
				print STDERR "Error with $file: $exp.\n";
				$errors++;
			} else {
				print "$file syntax OK.\n" unless $quiet;
			}
		}
	}
	exit($errors);
};
if (my $exp = $@) {
	$exp =~ s/ at .*? line \d+.//;
	chomp($exp);
	print STDERR "$exp\n";
	exit(-1);
}