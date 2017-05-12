#! /usr/bin/perl -w
use strict;

use FindBin;
use lib $FindBin::Bin;
use lib 'lib';

use Test::Smoke::App::Options;
use Test::Smoke::App::SyncTree;

my $app = Test::Smoke::App::SyncTree->new(
    Test::Smoke::App::Options->synctree_config()
);

if (my $error = $app->configfile_error) {
    die "$error\n";
}
$app->run();
