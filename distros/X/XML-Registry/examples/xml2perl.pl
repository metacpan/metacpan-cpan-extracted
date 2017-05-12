#!/usr/bin/perl -w

# INCLUDES
use strict;
use XML::Parser;
use XML::Registry;

# MAIN
# check for command line argument
die "Syntax: xml2perl.pl <filename>\n\n" unless $ARGV[0];

# create new parser instance
my $parser = new XML::Parser(Style => 'Tree');

# parse the file into a tree
my $tree = $parser->parsefile($ARGV[0]);

# create new instance of XML::Registry
my $registry = new XML::Registry;

# print the results
print $registry->xml2pl($tree);

