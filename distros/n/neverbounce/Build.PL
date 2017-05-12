#!/usr/bin/perl -w
use strict;
use Module::Build;
my $build = Module::Build->new(
    module_name => 'neverbounce',
    license  => 'perl',
    requires => {
        "perl"                  =>  "5.006",
        "Convert::Base64"       =>  "0",
        "Data::Dumper"          =>  "0",
        "HTTP::Request::Common" =>  "0",
        "JSON"                  =>  "0",
        "LWP::Protocol::https"  =>  "0",
        "LWP::UserAgent"        =>  "0",
        "Test::Manifest"        =>  "0.9",
        "Test::More"            =>  "0",
    },
);
$build->create_build_script;

