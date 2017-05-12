#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";

use UR;
use Sub::Install;

class Foo::TestCmd1 {
    is => 'Command::V1',
    has => [
        arg1 => { is => 'Text', doc => 'first arg', example_values => [q(foo bar baz)] },
        execute => { is => 'Integer' }, # HACK to get around needing an execute() method
    ],
};

my $text = Foo::TestCmd1->help_usage_complete_text;
$text =~ s/\e\[\d+(?>(;\d+)*)m//g; # Strip out ANSI escape sequences
like($text,
    qr(arg1\s+Text.*?first arg.*?example:.*?foo bar baz)s,
    "arg1 has example values for Foo::TestCmd1");


class Foo::TestCmd2 {
    is => 'Command::V2',
    has => [
        arg1 => { is => 'Text', doc => 'first arg', example_values => [q(foo bar baz)] },
#        execute => { is => 'Integer' }, # HACK to get around needing an execute() method
    ],
};

$text = Foo::TestCmd2->help_usage_complete_text;
$text =~ s/\e\[\d+(?>(;\d+)*)m//g; # Strip out ANSI escape sequences
# This regex differs from the above in that there's no type info after the arg name
# in Command::V2 output
like($text,
    qr(arg1.*?first arg.*?example:.*?foo bar baz)s,
    "arg1 has example values for Foo::TestCmd2");


