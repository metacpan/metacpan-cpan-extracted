#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use File::Spec;

my $m;
BEGIN { use_ok($m = "Test::TAP::HTMLMatrix") }

my $detail = $m->detail_template;

ok(-e $detail, "detail file exists");
like($detail, qr/detailed_view\.html$/, "name looks OK");
ok(File::Spec->file_name_is_absolute($detail), "abs path");

my $summary = $m->summary_template;

ok(-e $summary, "summary file exists");
like($summary, qr/summary_view\.html$/, "name looks OK");
ok(File::Spec->file_name_is_absolute($summary), "abs path");

my $css = $m->css_file;

ok(-e $css, "css file exists");
like($css, qr/htmlmatrix\.css$/, "name looks OK");
ok(File::Spec->file_name_is_absolute($css), "abs path");

