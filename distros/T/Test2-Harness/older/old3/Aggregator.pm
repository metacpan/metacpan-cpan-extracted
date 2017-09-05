package Test2::Harness::Aggregator;
use strict;
use warnings;

use Carp qw/croak confess/;

use Test2::Harness::HashBase qw/-harness -run_id -run_dir/;

sub init {
    my $self = shift;

    croak "the 'harness' attribute is required" unless $self->{+HARNESS};
    croak "the 'run_id'  attribute is required" unless $self->{+RUN_ID};
    croak "the 'run_dir' attribute is required" unless $self->{+RUN_DIR};
}

sub append { confess "append() is not implemented" }

1;
package Test2::Harness::Aggregator::Default;
use strict;
use warnings;

use Carp qw/croak confess/;

use parent 'Test2::Harness::Aggregator';
use Test2::Harness::HashBase qw/-jobs/;

sub init {
    my $self = shift;

    $self->SUPER::init();

    $self->{+JOBS} = [];
}

sub DEFAULT_JOB_SET { {plan => 0, asserts => 0, fail => 0, events => [], parnet => undef} }

my %ALLOWED_SOURCES = (
    'events'     => 1,
    'stdout-tap' => 1,
);
sub append {
    my $self = shift;

    my $jobs = $self->{+JOBS};

    my @events;
    for my $event (sort event_sort @_) {
        my $f = $event->facet_data;

        # We do not care about buffered events, and we will not process events
        # from STDERR or non-tap stdout, too hard to mux them.
        if ($f->{trace}->{buffered} || !$ALLOWED_SOURCES($f->{harness}->{source})) {
            push @events => $event;
            next;
        }

        my $job_id = $f->{harness}->{job_id};
        my $nested = $f->{trace}->{nested} || 0;

        my $job = $jobs->[$job_id] ||= [];
        my $set = $job->[$nested] ||= $self->DEFAULT_JOB_SET

        if($f->{parent}) {
            $job->[$nested + 1] ||= $self->DEFAULT_JOB_SET;
            $job->[$nested + 1]->{parent} = $event;
        }

        die "We only need to handle subtest in TAP, and probably on the parser end";

        while ($#$subtests > $nested) {
            my $st_nested = $#$subtests;
            my $st_set = pop @$subtests;

            if ($nested != $st_nested - 1) {
                push @events => $self->finish_set($st_set);
                $job->[-1]->{errors}++;
                next;
            }

            $event = $self->finish_set($st_set, $event);
        }

        $event = $self->finish_set($set, $event) if $f->{harness}->{job_end};

        if ($f->{plan}) {
            if ($set->{plan}) {
                push @{$f->{errors}} => {
                    tag => 'HARNESS',
                    fail => 1,
                    details => 'Multiple plans detected!';
                };
            }
            else {
                $set->{plan} = $f->{plan};
            }
        }

        if ($f->{assert}) {
            $set->{asserts}++;
            $set->{fail}++ unless $f->{assert}->{pass};
        }

        $set->{fail}++ if $f->{control}->{halt};
        $set->{fail}++ if $f->{control}->{terminate};
        $set->{fail}++ if $f->{errors} && grep { $_->{fail} } @{$f->{errors}};

        push @{$set->{events}} => $event;
        push @events => $event;
    }

    return @events;
}

sub event_sort {
    # No way to sort witohut harness facet
    my $ah = $a->{harness} or return 0;
    my $bh = $b->{harness} or return 0;

    # Now sort by stamp
    return $ah->{stamp} <=> $bh->{stamp}
        if $ah->{stamp} && $bh->{stamp};

    return 0;
}

sub finish_set {
    my $self = shift;
    my ($set, $event) = @_;

    my $parent = $set->{parent};

    # Abrupt end
    if (!$event || !$parent) {
        # Create a parent event, with a fatal error
    }

    if($event->{parent}->{buffered} = 2) {
    # Have parent, and event is second parent (brace)

    # Event matches parent

}



1;
