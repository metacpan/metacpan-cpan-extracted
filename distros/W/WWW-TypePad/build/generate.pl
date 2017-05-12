#!/usr/bin/perl
use strict;
use Data::Dump 'pp';
use Template;
use JSON;
use LWP::Simple;
use FindBin qw($Bin);
use String::CamelCase qw(camelize decamelize);
use lib "$Bin/../lib";
use WWW::TypePad::CodeGen;

my $host = shift || "api.typepad.com";

my $file = "method-mappings.json";
warn "Downloading $file\n";
LWP::Simple::mirror("http://$host/client-library-helpers/$file", "$Bin/$file");

my $json  = do { open my $fh, "<", "$Bin/$file" or die $!; join '', <$fh> };
my $mappings = decode_json($json);

for my $key (keys %$mappings) {
    WWW::TypePad::CodeGen::handle_object($key, $mappings->{$key})
}

