package Test2::Harness::Pipeline::Assembler;
use strict;
use warnings;

use Carp qw/croak/;

use Test2::Event::Harness;

use parent 'Test2::Harness::Pipeline';
use Test2::Harness::HashBase qw{
    -counter
    -subtests_by_hid
    -subtests_by_nest
};

sub init {
    my $self = shift;

    $self->{+COUNTER} = 1;
    $self->{+SUBTESTS_BY_HID}  = {};
    $self->{+SUBTESTS_BY_NEST} = [];
}

sub process {
    my $self = shift;

    my $by_nest = $self->{+SUBTESTS_BY_NEST};
    my $by_hid  = $self->{+SUBTESTS_BY_HID};

    my @out;
    for my $e (@_) {
        my $f = $e->facet_data;
        my $nested = $f->{trace}->{nested};

        if ($f->{harness}->{job_end}) {
            for my $st (@$by_nest, values %$by_hid) {
                my ($se, $sf) = $self->end_subtest($st);
                push @out => $self->sub_process_event($se, $sf);
            }

            @$by_nest = ();
            %$by_hid = ();
        }

        if (!$f->{parent}) {
            push @out => $self->sub_process_event($e, $f);
            next;
        }

        my ($is_st, $is_hid);
        if ($is_hid = $f->{parent}->{hid}) {
            # We are getting an event stream, here is the actual subtest in
            # full, buffered events have already been seen
            $is_st = $self->get_subtest(hid => $is_hid, nested => $nested + 1);
            $is_st->{parent} = $e;
            $is_st->{started} = 1;
            $is_st->{ended} = 1;
        }
        elsif ($f->{harness}->{subtest_start}) {
            # TAP stream, buffered subtest start
            $is_st = $self->get_subtest(nested => $nested + 1);
            $is_st->{parent} = $e;
            $is_st->{started} = 1;

            # This should not be seen yet...
            next;
        }
        elsif ($f->{harness}->{subtest_end}) {
            # TAP stream, buffered subtest end (but only if we had a start)
            $is_st = $self->get_subtest(nested => $nested + 1, no_vivify => 1);
            $is_st->{ended} = 1 if $is_st && $is_st->{started};
        }
        elsif ($nested && @$by_nest && $nested < @$by_nest) {
            # TAP stream, unbuffered subtest just ended

            # Abrupt end to deeper subtests?
            if (@$by_nest > ($nested + 1)) {
                for my $n (($nested + 2) .. (1 + @$by_nest)) {
                    $n->{ended} = 1;
                    $n->{ended_early} = 1;
                }
            }

            $is_st = $self->get_subtest(nested => $nested + 1);
            $is_st->{ended} = 1;
            $is_st->{parent} = $e;
        }

        # Close out any ended subtests
        if ($is_st && $is_st->{ended}) {
            my @ended;
            if ($is_hid) {
                # Only this one will have ended
                @ended = (delete $by_hid->{$is_hid})
            }
            else {
                # Look for ended ones in the nested subtests
                my @keep;
                for my $st (reverse @$by_nest) {
                    if ($st->{ended}) {
                        push @ended => $st;
                    }
                    else {
                        push @keep => $st;
                    }
                }
                @$by_nest = reverse @keep;
            }

            for my $st (@ended) {
                my ($se, $sf) = $self->end_subtest($st);
                push @out => $self->sub_process_event($se, $sf);
            }
        }
        else {
            push @out => $self->sub_process_event($e, $f);
        }
    }

    return @out;
}

sub end_subtest {
    my $self = shift;
    my ($st) = @_;

    my $se = delete $st->{parent} || Test2::Event::Harness->new(
        facet_data => {
            trace  => {nested => $st->{nested}},
            assert => {pass   => 0, details => 'UNKNOWN SUBTEST'},
            harness => {
                job_id        => $self->{+JOB_ID},
                source        => __PACKAGE__,
                subtest_start => 1,
                subtest_end   => undef,
            },
            errors => [
                {
                    tag     => 'PARSER',
                    fail    => 1,
                    details => 'No "parent" event for subtest!',
                },
            ],
        },
    );

    my $sf = $se->facet_data;
    $sf->{harness}->{subtest} = $st;

    unless ($sf->{assert}) {
        $sf->{assert} = {
            pass    => 0,
            details => 'UNKNOWN_SUBTEST',
        };
        push @{$sf->{errors}} => {
            tag     => 'PARSER',
            fail    => 1,
            details => 'Subtest was terminated with out an assertion!',
        };
    }

    $sf->{parent}->{hid}      ||= $st->{hid};
    $sf->{parent}->{children} ||= $st->{children};
    $sf->{parent}->{details}  ||= $sf->{assert}->{details};

    push @{$sf->{errors}} => {
        tag     => 'PARSER',
        fail    => 1,
        details => 'Subtest appears to have come to an abrupt end!',
    } if $st->{ended_early};

    return ($se, $st);
}

sub sub_process_event {
    my $self = shift;
    my ($e, $f) = @_;
    $f ||= $e->facet_data;
    my $nested = $f->{trace}->{nested};

    # Non-nested events do not get buffered
    return $e unless $nested;

    # Put the event into the proper subtest
    if (my $in_hid = $f->{trace}->{hid}) {
        my $in_st = $self->get_subtest(hid => $in_hid, nested => $nested);
        push @{$in_st->{children}} => $e;
    }
    else {
        my $in_st = $self->get_subtest(nested => $nested);
        push @{$in_st->{children}} => $e;
    }

    return Test2::Event::Harness->new(
        facet_data => {
            %$f,
            # New references for any facets we might need to change
            trace => {%{$f->{trace}}, buffered => 1},
            exists $f->{parent} ? (parent => {%{$f->{parent}}}) : (),
        }
    );
}

sub get_subtest {
    my $self   = shift;
    my %params = @_;

    if (my $hid = $params{hid}) {
        my $by_hid = $self->{+SUBTESTS_BY_HID};
        return $by_hid->{$hid} if $params{no_vivify};
        return $by_hid->{$hid} ||= {
            children => [],
            hid => $hid,
            nested => $params{nested},
            parent => undef,
            started => 0,
            ended => 0
        };
    }
    elsif (my $nested = $params{nested}) {
        my $by_nest = $self->{+SUBTESTS_BY_NEST};
        return $by_nest->{$nested} if $params{no_vivify};
        return $by_nest->{$nested} ||= {
            children => [],
            hid => "AUTO~$nested~" . $self->{+COUNTER}++,
            nested => $nested,
            parent => undef,
            started => 0,
            ended => 0
        };
    }

    croak "Must specify either 'hid' or 'nested' parameter";
}

1;
