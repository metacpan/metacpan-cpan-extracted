#!/usr/bin/env perl -w

#This script has been taken from a forum somewhere in the vast Internet space :)
#Its purpose is to generate the HTML from POD and apply some CSS as it will look like on CPAN
#Typical use: perl pod2cpanhtml.pl lib/PDF/Table.pm pdftable.html

use strict;
use warnings;
use Pod::Simple::HTML;

our $VERSION = '1.07'; # VERSION
our $LAST_UPDATE = '1.07'; # manually update whenever code is changed

my $parser = Pod::Simple::HTML->new();

my ($IN, $OUT);

if (defined $ARGV[0]) {
    open $IN, '<', $ARGV[0]  or die "Couldn't open $ARGV[0]: $!\n";
} else {
    $IN = \*STDIN;
}

if (defined $ARGV[1]) {
    open $OUT, '>', "$ARGV[1]" or die "Couldn't open $ARGV[1]: $!\n";
} else {
    $OUT = \*STDOUT;
}

$parser->index(1);
# site no longer exists. TBD see if there is some good replacement out there,
# preferably one that doesn't require turning a phone to landscape mode in
# order to see text at a decent size.
#$parser->html_css('http://search.cpan.org/s/style.css');

$parser->output_fh(*$OUT);
$parser->parse_file(*$IN);

