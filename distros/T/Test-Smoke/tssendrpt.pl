#! /usr/bin/perl -w
use strict;

use FindBin;
use lib $FindBin::Bin;
use lib 'lib';

use Test::Smoke::App::Options;
use Test::Smoke::App::SendReport;

my $app = Test::Smoke::App::SendReport->new(
    Test::Smoke::App::Options->sendreport_config()
);

if (my $error = $app->configfile_error) {
    die "$error\n";
}
$app->run();

