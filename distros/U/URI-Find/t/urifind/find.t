#!/usr/bin/perl -w
# vim:set ft=perl:

use strict;
use Test::More;
use File::Spec;

ok(my $ifile = File::Spec->catfile(qw(t urifind sciencenews)),
    "Test file found");
my $urifind = File::Spec->catfile(qw(blib script urifind));
my @data = `$^X $urifind $ifile`;

is(@data, 13, "Correct number of elements");
is((grep /mailto:/ => @data), 4, "Found 4 mailto links");
is((grep /http:/ => @data),   9, "Found 9 mailto links");

@data = `$^X $urifind $ifile -p`;
my $count = 0;
is(@data, 13, "*Still* correct number of elements");
is((grep /^\Q$ifile/ => @data), @data,
    "All elements are prefixed with the path when $urifind invoked with -p");

@data = `$^X $urifind -n $ifile /dev/null`;
is(@data, 13, "*Still* correct number of elements");
is((grep !/^\Q$ifile/ => @data), (@data),
    "All elements are not prefixed with the path when ($urifind,".
    " '/dev/null') invoked with -n");

@data = `$^X $urifind -S http $ifile`;
is(@data, 9, "Correct number of 'http' elements");

@data = `$^X $urifind -S mailto $ifile`;
is(@data, 4, "Correct number of 'mailto' elements");

@data = `$^X $urifind -S mailto -S http $ifile`;
is(@data, 13, "Correct number of ('http', 'mailto') elements");

@data = `$^X $urifind < $ifile`;
is(@data, 13, "Correct number elements when given data on STDIN");

@data = `$^X $urifind -S http -P \.org $ifile`;
is(@data, 8, "Correct number elements when invoked with -P \.org -S http");

@data = `$^X $urifind --schemeless $ifile`;
chomp @data;
is_deeply \@data, [map { "$_" } qw(
    http://66.33.90.123
    http://efwd.dnsix.com
    mailto:eletter@lists.sciencenews.org
    mailto:eletter-help@lists.sciencenews.org
    mailto:eletter-unsubscribe@lists.sciencenews.org
    mailto:eletter-subscribe@lists.sciencenews.org
    http://www.sciencenews.org
    http://www.sciencenews.org/20030705/fob1.asp
    http://www.sciencenews.org/20030705/fob5.asp
    http://www.sciencenews.org/20030705/bob8.asp
    http://www.sciencenews.org/20030705/mathtrek.asp
    http://www.sciencenews.org/20030705/food.asp
    http://www.sciencenews.org
    http://www.sciencenews.org/20030705/toc.asp
    http://www.sciencenews.org
    http://www.sciencenews.org/20030705/fob2.asp
    http://www.sciencenews.org/20030705/fob3.asp
    http:/%
)];

done_testing;
