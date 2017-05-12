#! /usr/bin/perl -w
use strict;

use FindBin;
use lib $FindBin::Bin;
use lib 'lib';

use Test::Smoke::App::Archiver;
use Test::Smoke::App::Options;

my $app = Test::Smoke::App::Archiver->new(
    Test::Smoke::App::Options->archiver_config()
);

if (my $error = $app->configfile_error) {
    die "$error\n";
}

$app->run();
