#! /usr/bin/perl -w
use strict;
$|++;

use File::Spec::Functions;
use FindBin;
use lib catdir($FindBin::Bin, 'lib');
use lib catdir($FindBin::Bin, updir(), 'lib');

use Test::Smoke::App::Options;
use Test::Smoke::App::SyncTree;

my $app = Test::Smoke::App::SyncTree->new(
    Test::Smoke::App::Options->synctree_config()
);

if (my $error = $app->configfile_error) {
    die "$error\n";
}
$app->run();
