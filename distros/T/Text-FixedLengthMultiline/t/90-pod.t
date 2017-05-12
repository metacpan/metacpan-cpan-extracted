#!perl
use strict;
use warnings;
use Test::More ($ENV{RELEASE_TESTING} ? ()
				      : (skip_all => 'only for release Kwalitee'));

use Test::Pod;
all_pod_files_ok();
