#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Carp;
use File::Spec;
use File::Basename;

eval <<'EOF';
require Test::CPAN::Meta::JSON;
require Test::CPAN::Meta::YAML;
EOF

if ($@) {
    plan skip_all =>
        'Test::CPAN::Meta::JSON and Test::CPAN::Meta::YAML needed to test MYMETA.* files';
}
else {
    plan tests => 4;
}

# Provide a relative path to a META.json or MYMETA.json file.
# We will assume that there is a META.yml or MYMETA.yml in the same directory.

my ($json_file, $yaml_file, $msg);

# sanity check
croak "Makefile not found.  Have you run 'perl Makefile.PL' yet?"
    unless -f './Makefile';

$json_file = File::Spec->catfile( '.', 'MYMETA.json');
croak "Could not locate $json_file" unless -f $json_file;

$msg = basename($json_file) . " tested okay";
Test::CPAN::Meta::JSON::meta_spec_ok($json_file,undef,$msg);

($yaml_file) = $json_file =~ s{^(.*?)\.json}{$1.yml}r;
croak "Could not locate $yaml_file" unless -f $yaml_file;

$msg = basename($yaml_file) . " tested okay";
Test::CPAN::Meta::YAML::meta_spec_ok($yaml_file,undef,$msg);

