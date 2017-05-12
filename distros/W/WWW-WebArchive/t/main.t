#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

use App::Options;

my ($dir);

$dir = ".";
$dir = "t" if (! -f "main.t");

use_ok("WWW::WebArchive", "Loaded WWW::WebArchive OK");

exit(0);


exit 0;

