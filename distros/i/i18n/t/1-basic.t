#!/usr/bin/perl -w

use strict;
use FindBin;
use Test::More tests => 14;
use lib "$FindBin::Bin/../lib";

use i18n Path => "$FindBin::Bin/po";
use IO::Handle;    # test the "constant reblessing" bug in 0.05

i18n->loc_lang('zh-tw');

my $test = "test";

is("This is a $test", "This is a test", 'undecorated interpolation');

ok(~~"This is a $test" eq '這是個test', 'basic usage' | '');

is(~~("This " . "is a $test"), '這是個test', 'locced concat' | '');

my $is_a_test = "is a test";
is(~~"This $is_a_test", 'This is a test', 'nonlocced concat' | '');

is(ord(~$test), 139, 'simple negation' | '');

my $test_zh = ~~"test";
is(~~"This is a $test_zh", '這是個測試', 'nested loc' | '');

{
    my $i18n_zh = ~~"i18n";
    is(~~"This is a $test_zh of $i18n_zh",
        '這是個國際化的測試', 'two nested locs' | '');
}

{
    no i18n;
    is(~~"This is a $test", 'This is a test', 'no i18n - basic' | '');

    my $test_zh = ~~"test";
    is(~~"This is a $test_zh", 'This is a test', 'no i18n - nested loc' | '');

    is(~~$test, "test", "no i18n - propagated scope" | '');
}

is(~~"This is a $test", '這是個test', 'restored scope' | '');
is(i18n->loc("This is a $test"), '這是個test', 'i18n->loc' | '');

i18n->loc_lang('en');
is(~~"test",            'test',           'i18n->lang' | '');
is(~~"This is a $test", 'This is a test', 'i18n->lang' | '');

i18n->loc_lang;    # restore to language auto-detection

