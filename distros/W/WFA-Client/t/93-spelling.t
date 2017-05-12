#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;

SKIP: {
    skip 'Skipping release tests', 1 unless $ENV{RELEASE_TESTING};

    eval "use Test::Spellunker;";
    add_stopwords('xml');
    all_pod_files_spelling_ok();
}

done_testing();
