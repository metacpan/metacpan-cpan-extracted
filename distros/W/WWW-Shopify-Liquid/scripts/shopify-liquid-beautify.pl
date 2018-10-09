#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Shopify::Liquid;
use Getopt::Long;
use File::Find;
use File::Slurp;
use Pod::Usage;


=head1 NAME

shopify-liquid-beautify.pl - Beautifies liquid files.

=head1 SYNOPSIS

shopify-liquid-beautify.pl [files]

	files		The list of files and folders to beautify.
			If no files are specified, content is read
			from standard input.
	
	--verbose	Displays extra info.
	--quiet		Suppress everything except errors.
	
	--help		Displays this messaqge.
	--fullhelp	Displays the full pod doc.

This tool beautifies liquid files.

=cut

=head1 EXAMPLES

	shopify-liquid-beautify.pl *.liquid
	
Will beautify all liquid files in the oflder.

=cut

my @ARGS;

GetOptions(
	'help' => \my $help,
	'fullhelp' => \my $fullhelp,
	'verbose' => \my $verbose,
	'quiet' => \my $quiet,
	'compress' => \my $compress,
	'<>' => sub { push(@ARGS, $_[0]); }
);

pod2usage(-verbose => 2) if ($fullhelp);
pod2usage() if $help;

use WWW::Shopify::Liquid;
use WWW::Shopify::Liquid::Beautifier;

my $liquid = WWW::Shopify::Liquid->new;
$liquid->lexer->unparse_spaces(1);
my $beautifier = WWW::Shopify::Liquid::Beautifier->new;
$beautifier->register_tag($_) for (@{$liquid->tags});

eval {
	sub beautify {
		my ($text, $compress) = @_;
		if ($compress){
            return $liquid->lexer->unparse_text($beautifier->compress($liquid->lexer->parse_text($text)));
        } else {
            return $liquid->lexer->unparse_text($beautifier->beautify($liquid->lexer->parse_text($text)));
        }
	}
	
	die "One or more of those files doesn't exist or is a directory." if int(grep { !-e $_ || -d $_ } @ARGS) > 0;
	
	if (@ARGS) {
		write_file($_, beautify(scalar(read_file($_)),$compress)) for (@ARGS);
	} else {
		my $accumulator = '';
		while (my $line = <STDIN>) {
			$accumulator .= $line;
		}
		print beautify($accumulator);
	}
	
	exit(0);
};
if (my $exp = $@) {
	$exp =~ s/ at .*? line \d+.//;
	chomp($exp);
	print STDERR "$exp\n";
	exit(-1);
}
