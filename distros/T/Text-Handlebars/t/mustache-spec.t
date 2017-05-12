#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

use Test::Requires 'JSON', 'Path::Class';

for my $file (dir('t', 'mustache-spec', 'specs')->children) {
    next unless $file =~ /\.json$/;
    my $tests = decode_json($file->slurp);
    note("running " . $file->basename . " tests");
    for my $test (@{ $tests->{tests} }) {
        local $TODO = "unimplemented"
            if $file->basename eq 'partials.json'
            && $test->{name} =~ /standalone/i
            && $test->{name} !~ /line endings/i;

        my $opts = {
            suffix => '.mustache',
            path   => [
                map { +{ "$_.mustache" => $test->{partials}{$_} } }
                    keys %{ $test->{partials} }
            ],
        };
        render_ok(
            $opts,
            $test->{template},
            fix_data($test->{data}),
            $test->{expected},
            "$test->{name}: $test->{desc}"
        );
    }
}

sub fix_data {
    my ($data) = @_;

    if (ref($data) eq 'HASH') {
        if ($data->{__tag__} && $data->{__tag__} eq 'code') {
            return eval $data->{perl};
        }
        else {
            return { map { $_ => fix_data($data->{$_}) } keys %$data };
        }
    }
    elsif (ref($data) eq 'ARRAY') {
        return [ map { fix_data($_) } @$data ];
    }
    else {
        return $data;
    }
}

done_testing;
