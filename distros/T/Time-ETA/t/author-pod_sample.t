#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Differences;

use Capture::Tiny qw(capture_merged);
use Time::ETA::MockTime;

my $true = 1;
my $false = '';

sub do_work {
    sleep 1;
}

sub sample_from_pod {

    # sample start
    use Time::ETA;

    my $eta = Time::ETA->new(
        milestones => 12,
    );

    foreach (1..12) {
        do_work();
        $eta->pass_milestone();
        print "Will work " . $eta->get_remaining_seconds() . " seconds more\n";
    }
    # sample end

    return $false;
}

sub check_sample_from_pod {

    my $output = capture_merged {
        sample_from_pod();
    };

    my $expected_output = "Will work 11 seconds more
Will work 10 seconds more
Will work 9 seconds more
Will work 8 seconds more
Will work 7 seconds more
Will work 6 seconds more
Will work 5 seconds more
Will work 4 seconds more
Will work 3 seconds more
Will work 2 seconds more
Will work 1 seconds more
Will work 0 seconds more
";

    eq_or_diff(
        $output,
        $expected_output,
        'Sample from POD works as expected',
    );
}

sub main {
    check_sample_from_pod();

    done_testing();
}

main();
__END__
