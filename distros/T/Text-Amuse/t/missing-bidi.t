#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 3;
use Text::Amuse::Functions qw/muse_to_object/;

my $muse =<<EOF;
#lang en

This i just a test. <<<به ویکی‌پدیا خوش‌آمدید>>>

[[image.png]]

EOF

{
    my $obj = muse_to_object($muse);
    ok $obj->is_bidi, "is bidi";
    ok !$obj->is_rtl, "not rtl";
}

{
    my $obj = muse_to_object($muse);
    my @attachments = $obj->attachments;
    ok scalar(@attachments), "Found attachments";
}

