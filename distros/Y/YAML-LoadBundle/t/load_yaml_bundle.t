#!/usr/bin/perl
use strict;
use warnings;

use YAML::XS;
use Test::More;

use YAML::LoadBundle qw( load_yaml_bundle );

my $bundle = {
    books => {
        programming_perl => {
            title => 'Programming Perl, 3rd Ed.',
            author => [
                'Larry Wall',
                'Tom Christiansen',
                'Jon Orwant',
            ],
            publishing => {
                company => q[O'Reilly],
                location => 'Cambridge',
                year => 2000,
            },
        },
        advanced_perl_programming => {
            title => 'Advanced Perl Programming, 2nd Ed.',
            author => 'Simon Cozens',
            publishing => {
                company => q[O'Reilly],
                location => 'Cambridge',
                year => 2005,
            },
        },
        design_patterns => {
            title => 'Design Patterns',
            author => [
                'Erich Gamma',
                'Richard Helm',
                'Ralph Johnson',
                'John Vlissides',
            ],
            publishing => {
                company => 'Addison-Wesley',
                location => 'Boston',
                year => '1995',
            },
        },
    },
};

my $got = load_yaml_bundle('t/yaml_dir');
note Dump($got);
is_deeply($got, $bundle, "YAML dir matches expected config");
done_testing;
