#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More;

my @types = qw/error warning status/;

plan tests => (4 * @types);

my $test_obj = UR::Value->create('test value');

for my $type (@types) {
    my $accessor = "${type}_message";

    my $dump = "dump_${type}_messages";
    $test_obj->$dump(0);

    my $return_val_with_format_string = $test_obj->$accessor('Hello, I like %s.', 'turkey sandwiches');
    is($return_val_with_format_string, 'Hello, I like turkey sandwiches.',
        "When given multiple arguments, $type treats it like a format string");

    my $val_with_invalid_format_string = 'Hello, this is not a valid format string %J';
    my $return_val_without_format_string = $test_obj->$accessor($val_with_invalid_format_string);
    is($val_with_invalid_format_string, $return_val_without_format_string,
        "When given a single argument, $type does not run it through sprintf");

    my $warn_msg;
    {
        local $SIG{__WARN__} = sub {
            $warn_msg = $_[0];
        };
        $test_obj->$accessor('%J', 'foo');
    }
    like($warn_msg,
        qr/Invalid conversion in sprintf|Redundant argument in sprintf/,
        "When given an invalid format string, $type throws a warning");

    my $file = __FILE__;
    like($warn_msg,
        qr/$file/,
        "When given an invalid format string, $type throws a warning from correct perspective");
}
