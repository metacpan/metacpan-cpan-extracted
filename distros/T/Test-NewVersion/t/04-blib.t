use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::NewVersion;
use File::pushd 'pushd';

use lib 't/lib';
use NoNetworkHits;

{
    my $wd = pushd('t/corpus/blib');
    all_new_version_ok();
}

is(
    Test::Builder->new->current_test,
    1,
    'one file was tested, although there are two files in lib/',
);

done_testing;
