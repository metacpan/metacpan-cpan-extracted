#!/usr/bin/perl -w
use strict; $|++;

my @lines = `cvs log`;
my %messages;

for ( my $i=0; $i<=$#lines; $i++ ) {
  next  unless  $lines[$i] =~ m|^date: (\d{4}/\d{2}/\d{2}) |;
  my $date = $1;
  $messages{"$date -- $lines[++$i]"}++;
}

print sort keys %messages;
