#!/usr/bin/perl -w
# $Id: 02struct.t,v 1.2 1999/11/06 00:02:31 aqua Exp $

BEGIN {
    $| = 1; print "1..9\n";
}
END {print "not ok 1\n" unless $loaded;}
use Text::BasicTemplate;
$loaded = 1;
print "ok 1\n";

use strict;

my $bt = new Text::BasicTemplate;
$bt or print "not ";
print "ok 2\n";

$bt->{use_scalarref_lexicon_cache} = 0;

my %ov = (
	  'foo' => 'bar',
	  'bar' => 'foo',
	  'numbers' => [ 1, 2, 3 ],
	  'recipe' => { fee => 'fi',
			fo => 'fum',
			bones => 'bread' }
);


my $ss;

# scalar
$ss = "%foo%";
print "not " unless $bt->parse(\$ss,\%ov) eq 'bar';
print "ok 3\n";

# list, standard opts
$ss = "%numbers%";
my $x = $bt->parse(\$ss,\%ov);
print "not " unless $x eq '1, 2, 3';
print "ok 4\n";

# list, global delimiter option
$ss = "%numbers%";
$bt->{list_delimiter}->{__default} = '|';
print "not " unless $bt->parse(\$ss,\%ov) eq '1|2|3';
print "ok 5\n";

# list, specific delimiter option
$ss = "%numbers%";
$bt->{list_delimiter}->{numbers} = '_';
print "not " unless $bt->parse(\$ss,\%ov) eq '1_2_3';
print "ok 6\n";

# hash, standard opts
$ss = "%recipe%";
print "not " unless $bt->parse(\$ss,\%ov) =~ /((fee=fi|fo=fum|bones=bread)(, )?){3}/;
print "ok 7\n";

# hash, global delimiters
$ss = "%recipe%";
$bt->{hash_delimiter}->{__default} = '^';
$bt->{hash_specifier}->{__default} = '!';
print "not " unless $bt->parse(\$ss,\%ov) =~ /((fee!fi|fo!fum|bones!bread)\^?){3}/;
print "ok 8\n";

# hash, specific delimiters
$ss = "%recipe%";
$bt->{hash_delimiter}->{__default} = '%';
$bt->{hash_specifier}->{__default} = '&';
print "not " unless $bt->parse(\$ss,\%ov) =~ /((fee&fi|fo&fum|bones&bread)%?){3}/;
print "ok 9\n";

# 
#$ss = "%foo% %% %bar%";
#print "not " unless $bt->parse(\$ss,\%ov) eq 'bar % foo';
#print "ok 10\n";
