#! /usr/local/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl config_fail.t'

#########################
# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 39 };
use WordNet::SenseRelate::TargetWord;
ok(1);

# Test failure when scalar is passed as option.
my ($wsd, $error) = WordNet::SenseRelate::TargetWord->new("scalar", 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure.");
is($wsd,  undef);

# Test failure when array ref is passed as option.
($wsd, $error) = WordNet::SenseRelate::TargetWord->new([("preprocess", "scalar", "preprocessconfig", "scalar")], 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure.");
is($wsd,  undef);

# Test failure when scalar is passed as preprocess value
my %options = (preprocess => "scalar",
               preprocessconfig => [],
               context => 'WordNet::SenseRelate::Context::NearestWords',
               contextconfig => {(windowsize => 4,
                                  contextpos => 'n')},
               algorithm => 'WordNet::SenseRelate::Algorithm::Local',
               algorithmconfig => {(measure => 'WordNet::Similarity::res')});

($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (preprocess).");
is($wsd,  undef);

# Test failure when hash-ref is passed as preprocess value
$options{preprocess} = {};
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (preprocess).");
is($wsd,  undef);

# Test failure when scalar is passed as preprocessconfig value
$options{preprocess} = [];
$options{preprocessconfig} = "scalar";
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (preprocessconfig).");
is($wsd,  undef);

# Test failure when hash-ref is passed as preprocessconfig value
$options{preprocessconfig} = {};
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (preprocessconfig).");
is($wsd,  undef);

# Test failure when hash-ref is passed as context value
$options{preprocessconfig} = [];
$options{context} = {};
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (context).");
is($wsd,  undef);

# Test failure when array-ref is passed as context value
$options{context} = [];
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (context).");
is($wsd,  undef);

# Test failure when scalar is passed as contextconfig value
$options{context} = "WordNet::SenseRelate::Context::NearestWords";
$options{contextconfig} = "scalar";
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (contextconfig).");
is($wsd,  undef);

# Test failure when array-ref is passed as contextconfig value
$options{contextconfig} = [];
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (contextconfig).");
is($wsd,  undef);

# Test failure when hash-ref is passed as postprocess value
$options{contextconfig} = {("windowsize" => 4, "contextpos" => 'n')};
$options{postprocess} = {};
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (postprocess).");
is($wsd,  undef);

# Test failure when scalar is passed as postprocess value
$options{postprocess} = "scalar";
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (postprocess).");
is($wsd,  undef);

# Test failure when scalar is passed as postprocessconfig value
$options{postprocess} = [];
$options{postprocessconfig} = "scalar";
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (postprocessconfig).");
is($wsd,  undef);

# Test failure when hash-ref is passed as postprocessconfig value
$options{postprocessconfig} = {};
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (postprocessconfig).");
is($wsd,  undef);

# Test failure when hash-ref is passed as algorithm value
$options{postprocessconfig} = [];
$options{algorithm} = {};
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (algorithm).");
is($wsd,  undef);

# Test failure when array-ref is passed as algorithm value
$options{algorithm} = [];
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (algorithm).");
is($wsd,  undef);

# Test failure when scalar is passed as algorithmconfig value
$options{algorithm} = "WordNet::SenseRelate::Algorithm::Local";
$options{algorithmconfig} = "scalar";
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (algorithmconfig).");
is($wsd,  undef);

# Test failure when array-ref is passed as algorithmconfig value
$options{algorithmconfig} = [];
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, "WordNet::SenseRelate::TargetWord->new() -- Malformed 'options' data structure (algorithmconfig).");
is($wsd,  undef);

# With everything fixed... no error
$options{algorithmconfig} = {("measure" => 'WordNet::Similarity::res')};
($wsd, $error) = WordNet::SenseRelate::TargetWord->new(\%options, 0);
is($error, undef);
ok($wsd);

