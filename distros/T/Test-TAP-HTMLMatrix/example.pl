#!/usr/bin/perl

use strict;
use warnings;

use Test::TAP::HTMLMatrix;
use Test::TAP::Model::Visual;
use Test::TAP::Model::Consolidated;

# make a successful test run
my $model_ok = Test::TAP::Model::Visual->new_with_tests(glob("t/*.t"));
$model_ok->desc_string("real run");

# make a dummy run with some failures
my $model_failing = do { local $ENV{TEST_FAIL_RANDOMLY} = 1; Test::TAP::Model::Visual->new_with_tests(glob("t/*.t")) };
$model_failing->desc_string("dummy failures");

my $v = Test::TAP::HTMLMatrix->new(Test::TAP::Model::Consolidated->new($model_ok, $model_failing));

# control the HTML output
$v->has_inline_css(1);
#$v->no_javascript(1);

# this is the most popular view:
print $v->detail_html;

# you can also get a more compact summary:
#print $v->summary_html;

# or a directory with both files and some css
# $v->output_dir("example_html");
