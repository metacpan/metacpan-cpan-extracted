#===============================================================================
#
#         FILE:  special_tags.t
#
#  DESCRIPTION:  Test special tags
#
#       AUTHOR:  Andrew Fresh (AAF), andrew@cpan.org
#      COMPANY:  Red River Communications
#      CREATED:  01/09//10 17:43
#     REVISION:  $AFresh1: special_tags.t,v 1.6 2010/02/13 23:06:34 andrew Exp $
#===============================================================================

use strict;
use warnings;

use Test::More tests => 30;

my $class;
BEGIN { 
	$class = 'Text::Todo::Entry';
	use_ok( $class, "use $class" ) 
}

diag("Testing special tags in $class $Text::Todo::Entry::VERSION");

my %sample = (
    text     => '(B) @home @work send email to mailto:andrew@cpan.org DUE:2011-01-01 +say_thanks',

    known_tags => {
        context => '@',
        project => '+',
        due_date => 'DUE:',
    },

    extra_tags => { 'email' => 'mailto:' },

    priority  => 'B',
    contexts  => [ 'home', 'work' ],
    projects  => ['say_thanks'],
    due_dates => ['2011-01-01'],
    emails    => ['andrew@cpan.org'],
);

my $e = new_ok($class, [ {text => $sample{text}, tags => { due_date => 'DUE:' }} ]);

is( $e->text,     $sample{text},     'Make sure entry matches' );
is( $e->priority, $sample{priority}, 'check priority' );

my $known_tags = $sample{known_tags};
check_tags($e, $known_tags);

foreach my $key (keys %{ $sample{extra_tags} }) {
    ok( $e->learn_tag( $key, $sample{extra_tags}{$key} ), "Learn tag [$key]");
    $known_tags->{ $key } = $sample{extra_tags}{$key};
}
check_tags($e, $known_tags);

#done_testing();

sub check_tags {
    my ($e, $known_tags) = @_;

    is_deeply( $e->known_tags, $known_tags, 'check known_tags' );
    
    foreach my $key (keys %{ $known_tags }) {
        my $t = $key . 's';
        my $in = 'in_' . $key;

        is_deeply( [ $e->$t ], $sample{$t}, "check [$t]" );

        ok( !$e->$in(''), "check not [$in]");

        foreach my $value (@{ $sample{$t} }) {
            ok( $e->$in($value), "check [$in] [$value]");
        }
    }
}
