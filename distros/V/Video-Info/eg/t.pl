#!/usr/bin/perl

my $s = shift;

my $key = '';

foreach my $f (split '',$s){
	my $b = sprintf "%x",ord($f);
	$b = length($b)>1 ? $b : "0$b";
	$key .= $b;
}

print $key, "\n";
