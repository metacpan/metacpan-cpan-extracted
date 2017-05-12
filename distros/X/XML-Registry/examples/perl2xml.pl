#!/usr/bin/perl -w

# INCLUDES
use strict;
use vars qw($VAR1 $tree $el $index);
use XML::Registry;

# MAIN
# check for command line argument
die "Syntax: xml2perl.pl <filename>\n\n" unless $ARGV[0];

# open file
open(XML,$ARGV[0]) || die "Cannot open $ARGV[0] for read: $!";

# read file into $pdump
my $pdump = eval(join("",<XML>));

# create new instance of XML::Registry
my $registry = new XML::Registry;

# print the results
print $registry->pl2xml($pdump);
