#!/usr/bin/perl
use strict; use warnings;

use Test::More;

eval "use Test::Pod::Spelling::CommonMistakes";
if ( $@ ) {
    plan skip_all => 'Test::Pod::Spelling::CommonMistakes required for testing POD';
} else {
    all_pod_files_ok();
}
