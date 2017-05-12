#!/usr/bin/perl

use strict;
use warnings;

use XML::RSS;

# print an error unless there are 2 command-line args
&syntax unless @ARGV == 2;

# get rss file and version to convert to from
# the command line
my ($file,$version) = @ARGV;

# create new instance
my $rss = XML::RSS->new;

# set output version
$rss->{output} = $version unless $version eq 'default';

# parse the rss file
$rss->parsefile(shift);

# output the new RSS to STDOUT
print $rss->as_string;

sub syntax {
    die "Syntax: convert.pl <file.rss> <version>\n    ex: convert.pl fm.rdf 1.0\n\n";
}

