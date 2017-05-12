#!perl -T
use strict;
use warnings qw(all);

use Test::Builder::Tester tests => 1;
use Test::More;

use Test::Mojibake;

ALL_FILES_NONE_FOUND: {
    ## no critic (ProhibitNoWarnings)
    no warnings qw(redefine);
    my @plan;
    *Test::Builder::plan = sub { shift; @plan = @_ };

    all_files_encoding_ok(qw(t/_INEXISTENT_));

    is_deeply(
        \@plan,
        [ skip_all => 'could not find any files to test' ],
        'tests are skipped when there are no files to test'
    );
}
