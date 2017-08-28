#!/usr/bin/env perl

use utf8;
use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

# VERSION
use Test::Most tests => 2;
use English '-no_match_vars';
use Readonly;
use Path::Class;
use XML::Ant::BuildFile::Project;

my $project = XML::Ant::BuildFile::Project->new( file => 't/yui-build.xml' );

my %paths = $project->paths;

cmp_bag(
    [ keys %paths ],
    [   qw(site.css.concat
            site.js.concat
            site.css.min
            site.js.min),
    ],
    'path ids',
);

cmp_deeply(
    {   map {
            $_->[0] => map {"$_"}
                $_->[1]->as_string
        } $project->path_pairs
    },
    {   'site.css.concat' => target_yui('concat/site.css'),
        'site.js.concat'  => target_yui('concat/site.js'),
        'site.css.min'    => target_yui('mincat/css/min/site.css'),
        'site.js.min'     => target_yui('mincat/js/min/site.js'),
    },
    'path location pairs',
);

sub target_yui { unix_filestr_to_native("t/target/yui/$_[0]") }

sub unix_filestr_to_native { file( split q{/}, $_[0] )->stringify() }
