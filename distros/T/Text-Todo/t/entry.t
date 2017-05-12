#===============================================================================
#
#         FILE:  entry.t
#
#  DESCRIPTION:  Test entry commands
#
#       AUTHOR:  Andrew Fresh (AAF), andrew@cpan.org
#      COMPANY:  Red River Communications
#      CREATED:  07/10/09 11:32:39
#     REVISION:  $AFresh1: entry.t,v 1.13 2010/01/15 19:50:15 andrew Exp $
#===============================================================================

use strict;
use warnings;

use Test::More tests => 41;

my $class;
BEGIN { 
	$class = 'Text::Todo::Entry';
	use_ok( $class, "use $class" ) 
}

diag("Testing entry $class $Text::Todo::Entry::VERSION");

my %sample = (
    text     => '(B) @home @work send email to andrew@cpan.org + +say_thanks',
    priority => 'B',
    known_tags => { context => '@', project => '+' },
    contexts => [ 'home', 'work' ],
    projects => [ '', 'say_thanks' ],
    prepend  => 'before',
    append   => 'or something',
    new_project => 'notnapping',
    new_context => 'car',
);

my $e = new_ok($class);
is_deeply( $e->known_tags, $sample{known_tags}, 'check known_tags' );

ok( $e->replace( $sample{text} ), 'Update entry' );
is( $e->text,     $sample{text},     'Make sure entry matches' );
is( $e->priority, $sample{priority}, 'check priority' );
is_deeply( [ $e->contexts ], $sample{contexts}, 'check contexts' );
is_deeply( [ $e->projects ], $sample{projects}, 'check projects' );

$sample{text} =~ s/^( \s* \( $sample{priority} \))/$1 $sample{prepend}/xms;
ok( $e->prepend( $sample{prepend} ), 'Prepend entry' );
is( $e->text,     $sample{text},     'Make sure entry matches' );
is( $e->priority, $sample{priority}, 'check priority' );
is_deeply( [ $e->contexts ], $sample{contexts}, 'check contexts' );
is_deeply( [ $e->projects ], $sample{projects}, 'check projects' );

$sample{text} .= ' ' . $sample{append};
ok( $e->append( $sample{append} ), 'Append entry' );
is( $e->text,     $sample{text},     'Make sure entry matches' );
is( $e->priority, $sample{priority}, 'check priority' );
is_deeply( [ $e->contexts ], $sample{contexts}, 'check contexts' );
is_deeply( [ $e->projects ], $sample{projects}, 'check projects' );

ok( !$e->in_project( $sample{new_project} ), 'not in new project yet' );
push @{ $sample{projects} }, $sample{new_project};
$sample{text} .= ' +' . $sample{new_project};
ok( $e->append( '+' . $sample{new_project} ), 'Add project' );
is( $e->text, $sample{text}, 'Make sure entry matches' );
ok( $e->in_project( $sample{new_project} ), 'now in new project' );

ok( !$e->in_context( $sample{new_context} ), 'not in new context yet' );
push @{ $sample{contexts} }, $sample{new_context};
$sample{text} .= ' @' . $sample{new_context};
ok( $e->append( '@' . $sample{new_context} ), 'Add context' );
is( $e->text, $sample{text}, 'Make sure entry matches' );
ok( $e->in_context( $sample{new_context} ), 'now in new context' );

$sample{text} =~ s/^\(B\)\s*/(A) /gxms;
$sample{priority} = 'A';
ok( $e->pri('A'), 'Set priority to A' );
is( $e->text,     $sample{text}, 'Make sure entry matches' );
is( $e->priority, 'A',           'New priority is set' );

$sample{text} =~ s/^\(A\)\s*//gxms;
$sample{priority} = '';
ok( $e->depri(), 'Deprioritize' );
is( $e->text,     $sample{text}, 'Make sure entry matches' );
is( $e->priority, undef,         'New priority is set' );

my $done_date = sprintf "%04d-%02d-%02d",
    ( (localtime)[5] + 1900 ),
    ( (localtime)[4] + 1 ),
    ( (localtime)[3] );
my $done_marker = "x $done_date ";

ok( !$e->done, 'not done' );
ok( $e->do,    'mark as done' );
is( $e->done, $done_date, 'now done' );
is( $e->text, $done_marker . $sample{text}, 'Make sure entry matches' );

ok( $e->replace(''), 'Blank entry' );
is( $e->text,     '',    'Make sure entry is blank' );
is( $e->priority, undef, 'check priority is undef' );
is_deeply( [ $e->contexts ], [], 'check contexts are empty' );
is_deeply( [ $e->projects ], [], 'check projects are empty' );

# replace
# app => 'append',
# prep => 'prepend',
# dp => 'dpri',
# p => 'pri',
