#! /usr/bin/env -S perl -w
use strict;
$|++;

use File::Spec::Functions;
use FindBin;
use lib catdir($FindBin::Bin, 'lib');
use lib catdir($FindBin::Bin, updir(), 'lib');

use Test::Smoke::App::RepostFromArchive;
use Test::Smoke::App::Options;

my $app = Test::Smoke::App::RepostFromArchive->new(
    Test::Smoke::App::Options->reposter_config()
);

if (my $error = $app->configfile_error) {
    die "$error\n";
}

$app->run();

