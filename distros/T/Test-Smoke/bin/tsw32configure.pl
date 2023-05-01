#! /usr/bin/perl -w
use strict;
$|++;

use File::Spec::Functions;
use FindBin;
use lib $FindBin::Bin;
use lib catdir($FindBin::Bin, 'lib');
use lib catdir($FindBin::Bin, updir(), 'lib');

use Test::Smoke::App::RunApp;
run_smoke_app("W32Configure");
