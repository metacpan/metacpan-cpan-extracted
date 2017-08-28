#!/usr/bin/env perl

use utf8;
use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

# VERSION
use English '-no_match_vars';
use Test::Most tests => 1;
use Path::Class;
use Readonly;
use XML::Ant::BuildFile::Project;

my $tests;
Readonly my $PROJECT =>
    XML::Ant::BuildFile::Project->new( file => 't/yui-build.xml' );

my @concat_tasks = $PROJECT->target('concat-files')->tasks('concat');

my %concat_hash = map {
    $_->destfile->stringify() => map { $_->as_string }
        $_->all_resources
} @concat_tasks;

my %expected_unix = (
    't/target/yui/concat/site.css' =>
        [qw(t/css/one.css t/css/two.css t/images/three.css)],
    't/target/yui/concat/site.js' =>
        [qw(t/js/one.js t/js/two.js t/images/three.js)],
);

cmp_deeply(
    \%concat_hash,
    {   map {
            unix_filestr_to_native($_) => join q{ },
                map { unix_filestr_to_native($_) } @{ $expected_unix{$_} },
        } keys %expected_unix,
    },
    'concat',
) or explain \%concat_hash;

sub unix_filestr_to_native { file( split q{/}, $_[0] )->stringify() }
