#!/usr/bin/perl -wT
use strict;
use lib qw(.);
use Untaint; 

#$UNTAINT_ALLOW_HASH++;
my $test = {'name' => $ARGV[0],
	'age' => $ARGV[1],
	'time' => 'late',
	'gender' => $ARGV[2]
	};

my $patterns = {'name' => qr(^k\w+),
		'age' => qr(^\d+),
		'gender' => qr(^\w$)
		};

my %new = untaint_hash($patterns, %{$test});

my $name = $new{name};

for (keys %new) {
	print "$_ => $new{$_}\n";
}
if (is_tainted($name)) {
	exit 0;
}else{
	exit 1;
}
#for (sort keys %new) {
#	print $new{$_} . " => $_\n";
#}

