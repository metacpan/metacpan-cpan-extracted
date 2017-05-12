#! /usr/bin/perl -w
use strict;

use FindBin;
use lib $FindBin::Bin;
use lib 'lib';

use Test::Smoke::App::Reporter;
use Test::Smoke::App::Options;

my $app = Test::Smoke::App::Reporter->new(
    Test::Smoke::App::Options->reporter_config()
);

if (my $error = $app->configfile_error) {
    die "$error\n";
}

$app->run();
