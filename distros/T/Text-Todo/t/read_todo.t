#
#===============================================================================
#
#         FILE:  50.read_todo.t
#
#  DESCRIPTION:  Reads in a sample todo.txt and makes sure it got it correctly
#
#       AUTHOR:  Andrew Fresh (AAF), andrew@cpan.org
#      COMPANY:  Red River Communications
#      CREATED:  07/09/09 11:45:52
#     REVISION:  $AFresh1: read_todo.t,v 1.9 2010/01/15 19:44:32 andrew Exp $
#===============================================================================

use strict;
use warnings;
use File::Spec;
use File::Temp qw/ tempdir /;
use Test::More tests => 138;

my $todo_file = File::Spec->catfile( 't', 'todo1.txt' );
my $tempdir = tempdir( 'todotxt-XXXXXXX', CLEANUP => 1 );
my $dup_todo_file = File::Spec->catfile( $tempdir, 'todo50_dup.txt' );

#my $new_todo_file = File::Spec->catfile( $tempdir, 'todo50_new.txt' );

my @todos = (
    {   text     => '(B) +GarageSale @phone schedule Goodwill pickup',
        priority => 'B',
        contexts => ['phone'],
        projects => ['GarageSale'],
        done     => undef,
    },
    {   text =>
            '+GarageSale @home post signs around the neighborhood DUE:2006-08-01',
        priority => undef,
        contexts => ['home'],
        projects => ['GarageSale'],
        done     => undef,
    },
    {   text     => 'X eat meatballs @home',
        priority => undef,
        contexts => ['home'],
        projects => [],
        done     => 'X',
    },
    {   text     => '(A) @phone thank Mom for the meatballs WAIT',
        priority => 'A',
        contexts => ['phone'],
        projects => [],
        done     => undef,
    },
    {   text     => '',
        priority => undef,
        contexts => [],
        projects => [],
        done     => undef,
    },
    {   text     => '@shopping Eskimo pies',
        priority => undef,
        contexts => ['shopping'],
        projects => [],
        done     => undef,
    },
    {   text     => 'email andrew@cpan.org for help +report_bug @wherever',
        priority => undef,
        contexts => ['wherever'],
        projects => ['report_bug'],
        done     => undef,
    },
    {   text     => 'x 2009-01-01 completed with a date',
        priority => undef,
        contexts => [],
        projects => [],
        done     => '2009-01-01',
    },
);

my %extra_todo = (
    text     => '+test+everything hope there are no bugs @continually',
    priority => undef,
    contexts => ['continually'],
    projects => ['test+everything'],
    done     => undef,
);

BEGIN { use_ok( 'Text::Todo', 'use Text::Todo' ) }

diag("Testing read Text::Todo $Text::Todo::VERSION");

my $todo = new_ok( 'Text::Todo' => [], 'Empty todo' );

#ok( $todo->load(), 'Load no file');

ok( $todo->load($todo_file), "Load file [$todo_file]" );

#my $bad_todo = new_ok('Text::Todo' => [ $new_todo_file ]);

ok( $todo->save($dup_todo_file), "Save to tempfile" );

my $dup_todo = new_ok( 'Text::Todo' => [$dup_todo_file], 'New todo' );

ok( $todo->load($todo_file), "Load file [$todo_file]" );

my $new_todo = new_ok( 'Text::Todo' => [], 'Empty todo' );

for my $id ( 0 .. $#todos ) {
    my $t = ok( $new_todo->add( $todos[$id]->{text} ), "Add Todo [$id]" );
}

foreach my $t ( $todo, $dup_todo, $new_todo ) {
    my $list;
    my $file = $t->file || 'unsaved';
    ok( $list = $t->list, 'Get list from ' . $file );

    for my $id ( 0 .. $#todos ) {
        test_todo( $todos[$id], $list->[$id], $id );
    }
}

sub test_todo {
    my ( $sample, $read, $id ) = @_;

    is( $read->text,     $sample->{text},     "check text [$id]" );
    is( $read->priority, $sample->{priority}, "check priority [$id]" );
    is( $read->done,     $sample->{done},     "check completion [$id]" );
    is_deeply(
        [ $read->contexts ],
        $sample->{contexts},
        "check contexts [$id]"
    );
    is_deeply(
        [ $read->projects ],
        $sample->{projects},
        "check projects [$id]"
    );
}
