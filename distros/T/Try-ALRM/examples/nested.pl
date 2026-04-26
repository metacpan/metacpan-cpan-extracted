#!/usr/bin/env perl

use strict;
use warnings;

use Try::ALRM qw/tries timeout/;

my $OUTER_TIMEOUT = 10;
my $OUTER_TRIES   = 2;

my $INNER_TIMEOUT = 3;
my $INNER_TRIES   = 2;

Try::ALRM::retry {
    my ($outer_attempt) = @_;

    printf "Outer attempt %d/%d ...\n", $outer_attempt, tries;

    Try::ALRM::retry {
        my ($inner_attempt) = @_;

        printf "\tInner attempt %d/%d ...\n", $inner_attempt, tries;

        # Simulate a slow operation that may time out.
        sleep 5;

        print "\tInner operation completed\n";
    }
    Try::ALRM::ALRM {
        my ($inner_attempt) = @_;

        print "\tInner timed out";

        if ( $inner_attempt < tries ) {
            print " - retrying inner operation ...\n";
        }
        else {
            print " - inner operation failed ...\n";
        }
    }
    Try::ALRM::finally {
        my ( $attempts, $success ) = @_;

        printf "\tInner %s after %d of %d attempts, timeout %d seconds\n",
            $success ? "success" : "failure",
            $attempts,
            tries,
            timeout;
    }
    timeout => $INNER_TIMEOUT,
    tries   => $INNER_TRIES;

    print "Outer operation continuing after nested retry block\n";
}
Try::ALRM::ALRM {
    my ($outer_attempt) = @_;

    print "Outer timed out";

    if ( $outer_attempt < tries ) {
        print " - retrying outer operation ...\n";
    }
    else {
        print " - outer operation failed ...\n";
    }
}
Try::ALRM::finally {
    my ( $attempts, $success ) = @_;

    printf "Outer %s after %d of %d attempts, timeout %d seconds\n",
        $success ? "success" : "failure",
        $attempts,
        tries,
        timeout;
}
timeout => $OUTER_TIMEOUT,
tries   => $OUTER_TRIES;
