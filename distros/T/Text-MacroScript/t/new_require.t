#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Capture::Tiny 'capture';
use Path::Tiny;
use Test::More;

my $ms;
my $test1 = "test1~";
my $test2 = "test2~";
my $test3 = "test3~";

use_ok 'Text::MacroScript';
require_ok 't/mytests.pl';

sub void(&) { $_[0]->(); () }

# OK
t_spew($test1, norm_nl(<<'END'));
sub add {
	my($a, $b) = @_;
	return $a+$b;
}
1;
END

$ms = new_ok('Text::MacroScript');
is $ms->expand("%REQUIRE[$test1]\n"), "";
is $ms->expand("%DEFINE_SCRIPT ADD [add(#0,#1)]"), "";
is $ms->expand("ADD[1|3]"), "4";

# error messages
t_spew($test2, "1+");
t_spew($test3, "%REQUIRE[$test2]\n");
$ms = new_ok('Text::MacroScript');
eval { $ms->expand_file($test3) };
is $@, 
"Error at file $test3 line 1: Eval error: syntax error at $test2 line 1, at EOF\n".
"Compilation failed in require\n";

ok unlink($test1, $test2, $test3);
done_testing;
