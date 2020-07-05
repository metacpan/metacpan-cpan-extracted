#!perl

use strict;
use warnings;
use Test::More 0.98;

use URI::Escape::Path;

is(uri_escape('/foo bar'), '/foo%20bar');
done_testing;
