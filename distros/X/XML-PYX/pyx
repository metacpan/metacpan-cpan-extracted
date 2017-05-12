#!/usr/bin/perl

use XML::PYX;

my $p = XML::PYX::Parser::ToCSF->new;

if (@ARGV && $ARGV[0] eq '-l') {
	shift @ARGV;
	$XML::PYX::Lame = 1;
}

if (@ARGV) { $p->parsefile($ARGV[0]); }
else { $p->parse(\*STDIN); }

