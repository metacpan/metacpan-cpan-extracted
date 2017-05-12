#!/usr/bin/perl -wT
use strict;
use lib qw(.);
use Untaint;

my $pattern = qr(^k\w+);

my $foo = $ARGV[0];

if (is_tainted($foo)) {
	print "\$foo is tainted. Attempting to launder\n";
	$foo = untaint($pattern, $foo);
}else{
	print "\$foo is not tainted!!\n";
}

