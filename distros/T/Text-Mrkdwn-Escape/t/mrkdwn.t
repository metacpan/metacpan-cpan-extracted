#!/usr/bin/env perl

use strict;
use warnings;
use 5.026;

use Text::Mrkdwn::Escape qw/ escape_to_mrkdwn /;
use Test::More;

is(escape_to_mrkdwn("hello world"), "hello world");
is(escape_to_mrkdwn("hello world!"), "hello world\\!");
is(escape_to_mrkdwn("hello world!!"), "hello world\\!\\\!");
is(escape_to_mrkdwn("hello world! !"), "hello world\\! \\!");
is(escape_to_mrkdwn("\n== moo ==\n"), "\n\\=\\= moo \\=\\=\n");

done_testing();
