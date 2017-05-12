#! /usr/bin/perl
#
use strict;
use warnings;

use Test::More tests => 2;
use CracTools::DigitagCT::Structure;
use CracTools::SAMReader::SAMline;

my $tag1 = "ATAGCTTCAGCGTCCATGGCA";
my $line1 = CracTools::SAMReader::SAMline->new("r1\t0\tref\t16\t30\t21M\t*\t0\t0\t$tag1\t*\n");

my $struct = CracTools::DigitagCT::Structure->new();

$struct->addTag($line1);
is($struct->nbOccurences($tag1),1,'nbOccurences (1)');
$struct->addTag($line1);
is($struct->nbOccurences($tag1),2,'nbOccurences (2)');
