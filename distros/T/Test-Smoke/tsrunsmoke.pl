#! /usr/bin/perl -w
use strict;

use FindBin;
use lib $FindBin::Bin;
use lib 'lib';

use Test::Smoke::App::Options;
use Test::Smoke::App::RunSmoke;

my $app = Test::Smoke::App::RunSmoke->new(
    Test::Smoke::App::Options->runsmoke_config()
);

if (my $error = $app->configfile_error) {
    die "$error\n";
}
$app->run();
