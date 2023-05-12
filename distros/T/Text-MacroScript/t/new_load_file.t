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

t_spew($test1, norm_nl(<<'END'));
Test text with hello
%DEFINE hello [world]
Test text with hello
END

t_spew($test2, norm_nl(<<'END'));
%DEFINE world [WORLD]
END

# API call - check that load_file does not output text
$ms = new_ok('Text::MacroScript');
is $ms->expand("hello"), "hello";
t_capture(__LINE__, sub {$ms->load_file($test1)}, "", "", 0);
is $ms->expand("hello"), "world";
t_capture(__LINE__, sub {$ms->load_file($test2)}, "", "", 0);
is $ms->expand("hello"), "WORLD";

# Constructor
$ms = new_ok('Text::MacroScript' => [ -file => [ $test1, $test2 ] ] );
is $ms->expand("hello"), "WORLD";

# %LOAD
$ms = new_ok('Text::MacroScript');
is $ms->expand("hello"), "hello";
is $ms->expand("%LOAD[$test1]"), "";
is $ms->expand("%LOAD[$test2]"), "";
is $ms->expand("hello"), "WORLD";

unlink $test3;
$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%LOAD")};
is $@, "Error at file - line 1: Expected [FILENAME]\n";

$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%LOAD[$test3]")};
check_error(__LINE__-1, $@, "Error at file - line 1: Open '$test3' failed: OS-ERROR\n");

# test error reporting line with %LOAD
t_spew($test1, norm_nl(<<END));
%LOAD[$test2]
%DEFINE
END

t_spew($test2, norm_nl(<<'END'));
%DEFINE A [1]
END

$ms = new_ok('Text::MacroScript');
eval {$ms->load_file($test1)};
check_error(__LINE__-1, $@, "Error at file $test1 line 2: Expected NAME\n");

ok unlink($test1, $test2, $test3);
done_testing;
