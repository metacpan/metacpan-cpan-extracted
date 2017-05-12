#!/usr/bin/perl -wT
use strict;
use lib qw(.);
use Untaint;

my $pattern = qr(^[kv]\w+);

my @foo = ("not tainted", @ARGV);
my @new;
my $new;
if (is_tainted(@foo)) {
	print "\@foo is tainted. Attempting to launder\n";
	@new = untaint($pattern, ($ARGV[0], $ARGV[1], @foo));
}else{
	print "\@foo is not tainted!!\n";
}


