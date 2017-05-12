#!perl
#
# This file is part of XML-Ant-BuildFile
#
# This software is copyright (c) 2014 by GSI Commerce.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use utf8;
use Modern::Perl;    ## no critic (UselessNoCritic,RequireExplicitPackage)

use Test::Most tests => 8;
use English '-no_match_vars';
use Readonly;
use Path::Class;

our $CLASS;

BEGIN {
    Readonly our $CLASS => 'XML::Ant::BuildFile::Project';
    eval "require $CLASS; $CLASS->import()";
}
Readonly my $TESTFILE => file('t/filelist.xml');

my $project
    = new_ok( $CLASS => [ file => $TESTFILE ], 'from Path::Class::File' );
$project = new_ok(
    $CLASS => [ file => $TESTFILE->stringify() ],
    'from path string',
);

is( $project->name, 'test', 'project name' );
cmp_bag(
    [ $project->target_names ],
    [qw(simple double nested)],
    'target names',
);

is( $project->num_filelists(), 3, 'filelists' );

cmp_deeply(
    [ $project->map_filelists( sub { $ARG->id } ) ],
    [ ('filelist') x 3 ],
    'filelist ids',
);

cmp_deeply(
    [ $project->map_filelists( sub { $ARG->directory->stringify() } ) ],
    [ (q{t}) x 3 ],
    'filelist dirs',
);

cmp_deeply(
    [   map { $ARG->stringify() }
            $project->map_filelists( sub { $ARG->files } )
    ],
    [ map { file( 't', $ARG )->stringify() } qw(a a b a b) ],
    'files'
);
