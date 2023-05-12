#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.
#
# test expand_file

use strict;
use warnings;
use Capture::Tiny 'capture';
use Test::More;

use_ok 'Text::MacroScript';
require_ok 't/mytests.pl';

sub void(&) { $_[0]->(); () }

my $ms;
my($out,$err,@res);
my $test1 = "test1~";
my $test2 = "test2~";

# open file failed
$ms = new_ok('Text::MacroScript');
unlink $test1;
eval { $ms->expand_file; };
check_error(__LINE__-1, $@, "Missing filename __LOC__\n");

eval { $ms->expand_file($test1); };
check_error(__LINE__-1, $@, "Error at file - line 1: Open '$test1' failed: OS-ERROR\n");

# API
t_spew($test1, "hello\nworld\n");
$ms = new_ok('Text::MacroScript');
@res = $ms->expand_file($test1);
is_deeply \@res, ["hello\n", "world\n"];
($out,$err,@res) = capture { void { $ms->expand_file($test1); } };
is $out, "hello\nworld\n";
is $err, "";

# API read from home dir
if (-d path("~") && -w _) {
	my $file = path("~", $test1);
	t_spew($file, "hello\nworld\n");
	@res = $ms->expand_file($file);
	is_deeply \@res, ["hello\n", "world\n"];
}
else {
	diag "directory '~' not writeable";
}

# %INCLUDE
$ms = new_ok('Text::MacroScript');
is $ms->expand("%INCLUDE[$test1]"), "hello\nworld\n";

$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%INCLUDE")};
is $@, "Error at file - line 1: Expected [FILENAME]\n";

unlink $test2; 
$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%INCLUDE[$test2]")};
check_error(__LINE__-1, $@, "Error at file - line 1: Open '$test2' failed: OS-ERROR\n");

unlink($test1, $test2, path("~", $test1));
done_testing;
