use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::NewVersion;
use File::pushd 'pushd';

use lib 't/lib';
use NoNetworkHits;

{
    my $wd = pushd('t/corpus/pod');
    all_new_version_ok();
}

is(
    Test::Builder->new->current_test,
    1,
    '.pod file with no namespaces is skipped',
);

done_testing;
