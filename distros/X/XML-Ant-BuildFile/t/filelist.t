#!/usr/bin/env perl

use utf8;
use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

# VERSION
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
    [ $project->map_filelists( sub { $_->id } ) ],
    [ ('filelist') x 3 ],
    'filelist ids',
);

cmp_deeply(
    [ $project->map_filelists( sub { $_->directory->stringify() } ) ],
    [ (q{t}) x 3 ],
    'filelist dirs',
);

cmp_deeply(
    [ map { $_->stringify() } $project->map_filelists( sub { $_->files } ) ],
    [ map { file( 't', $_ )->stringify() } qw(a a b a b) ],
    'files'
);
