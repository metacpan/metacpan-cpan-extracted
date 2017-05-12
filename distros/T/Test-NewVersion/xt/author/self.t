use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::NewVersion;

all_new_version_ok();

is(Test::Builder->new->current_test, 1, 'one file was tested');

done_testing;
