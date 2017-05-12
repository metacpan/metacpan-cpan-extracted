#!/usr/bin/perl -w
use lib "./blib/lib", "./etc", "./t";

use Text::Refer;
use Checker;
use strict;

print "1..20\n";
$OUTPUT = 0;

# Parse file:
my $parser = new Text::Refer::Parser;
my $ref;
my %refs;
open FH, "testin/small.bib" or die "open: $!";
while ($ref = $parser->input(\*FH))  {
    
    $refs{$ref->label} = $ref; 
}
defined($ref) or die "error parsing input";

# Count records:
check keys %refs == 3, 
    "did we read 3 records?";

# Get record #2:
$ref = $refs{'Abad90a'};
check $ref, 
    "did we get the Abad90a record?";

# Verify named get:
my @a  = $ref->author;
my $as = $ref->author;
check @a == 4, 
    "ref->author [a] yielded 4 elements";
check $a[0] eq "Martin Abadi",
    "ref->author [a] got correct first author";
check $a[3] eq "Jean-Jacques L\\'evy",
    "ref->author [a] got correct last author";
check $as eq "Jean-Jacques L\\'evy",
    "ref->author [s] got correct last author";

# Verify attr get:
@a  = $ref->attr('A');
$as = $ref->attr('A');
check @a == 4, 
    "ref->attr(A) [a] yielded 4 elements";
check $a[0] eq "Martin Abadi",
    "ref->attr(A) [a] got correct first author";
check $a[3] eq "Jean-Jacques L\\'evy",
    "ref->attr(A) [a] got correct last author";
check $as eq "Jean-Jacques L\\'evy",
    "ref->attr(A) [s] got correct last author";

# Verify basic get:
@a  = $ref->get('A');
$as = $ref->get('A');
check @a == 4, 
    "ref->get(A) [a] yielded 4 elements";
check $a[0] eq "Martin Abadi",
    "ref->get(A) [a] got correct first author";
check $a[3] eq "Jean-Jacques L\\'evy",
    "ref->get(A) [a] got correct last author";
check $as eq "Jean-Jacques L\\'evy",
    "ref->get(A) [s] got correct last author";




my @new = ('Able', 'Baker', 'Charley');

# Verify named set:
$ref->author(\@new);
@a = $ref->author;
check +((join '|', @a) eq (join '|', @new)),
    "ref->author([new]) worked";

# Verify named singleton set:
$ref->author("Able");
@a = $ref->author;
check +((join '|', @a) eq "Able"),
    "ref->author(\$new) worked";

# Verify attr set:
$ref->attr('A' => \@new);
@a = $ref->author;
check +((join '|', @a) eq (join '|', @new)),
    "ref->attr(A, [new]) worked";

# Verify set:
$ref->set('A', @new);
@a = $ref->author;
check +((join '|', @a) eq (join '|', @new)),
    "ref->author(\@new) worked";

# Convert to quick string:
my $str1 = <<EOF;
%L Abad90a
%A Able
%A Baker
%A Charley
%C Palo Alto, California
%D Feb. 6, 1990
%I DEC Systems Research Center
%K misc lambda fp binder (shelf)
%R Technical Report 54
%T Explicit Substitutions
EOF
$str1 =~ s/[\r\n]*/\n/g;
my $str2;

$str2 = $ref->as_string;
$str2 =~ s/[\r\n]*/\n/g;
check $str1 eq $str2,
    "ref->as_string worked";

my $str2 = $ref->as_string(Quick=>1);
$str2 =~ s/[\r\n]*/\n/g;
check $str1 eq $str2,
    "ref->as_string(Quick=>1) worked";


1;



