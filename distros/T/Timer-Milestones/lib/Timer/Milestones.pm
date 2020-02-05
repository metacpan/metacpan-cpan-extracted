package Timer::Milestones;

use strict;
use warnings;

use parent 'Exporter';

use Carp;
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(start_timing add_milestone stop_timing);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Have you updated the version number in the POD below?
our $VERSION = '0.001';
$VERSION = eval $VERSION;

=head1 NAME

Timer::Milestones - measure code execution time succinctly by setting milestones

=head1 VERSION

This is version 0.001.

=head1 SYNOPSIS

 use Timer::Milestones qw(start_timing mark_milestone stop_timing
     time_method);

 start_timing();
 time_method('Some::ThirdParty::Module::do_slow_thing');
 my @objects = _set_up_objects();
 mark_milestone('Everything set up');
 for my $object (@objects) {
     _do_something_potentially_slow($object);
 }
 mark_milestone('Telling the user')
 for my $object (@objects) {
     _inform_user($object);
 }
 ...
 stop_timing();

Spits out to STDERR e.g.

 START: Tue Feb  4 16:03:08 2020
      3 s (  0.28%)
 Everything set up
      5 min 30 s ( 31.22%)
          3 min  7 s Some::ThirdParty::Module::do_slow_thing
 Telling the user
     12 min  7 s ( 68.78%)
          8 min 30 s Some::ThirdParty::Module::do_slow_thing (x3)
 END: Tue Feb  4 16:20:48 2020

=head1 DESCRIPTION

At its simplest, Timer::Milestones is yet another timer module. It is designed
to have the smallest possible interface, so adding timing calls to your code
doesn't make it look unreadable. It can also time execution time of functions
in other modules, as a more informative (and quicker!) alternative to running
everything under Devel::NYTProf.

=head2 Functional vs OO interface

You can use Timer::Milestones via a functional interface:

 use Timer::Milestones qw(start_timing mark_milestone stop_timing);
 start_timing();
 ...;
 mark_milestone('Half-way through');
 ...;
 stop_timing();

Or via an OO interface:

 use Timer::Milestones;
 {
     my $timer = Timer::Milestones->new;
     # $timer->start_timing automatically called
     ...;
     $timer->mark_milestone('Half-way through');
     ...;
 }
 # $timer->stop_timing automatically called when $timer is destroyed

The OO interface is simpler if you're timing a monolithic block of code. If you
need to add timing calls throughout code scattered across multiple files, you're
better off with the functional interface as you don't need to pass a
Timer::Milestone object around.

=head2 Milestones and reports

At its simplest, the report you get will include when timing started and when
timing ended. These are displayed in your locale's local time, on the assumption
that that's what makes sense to you.

As soon as you add milestones, you will also be told how much time passed
between the start, each milestone, and the end. Times are specified in both
human-friendly periods (a number of milliseconds; seconds; minutes and seconds;
or hours and minutes), and percentages of the total elapsed time.

If you decide that you want to L<time individual functions as
well|/time_function>, they'll be mentioned with the milestones they follow. If
you provide a coderef to summarise the arguments passed to them that will be
included; if you decide that you don't need to see individual timings for each
function call, just an overall time, you'll get a shorter list of function
calls and an overall time.

=head2 Basic functionality

=head3 new

 Out: $timer

Creates a new Timer::Milestones object, and calls L</start_timing> on it.

=cut

sub new {
    # Start off with an empty hashref
    my $invocant = shift;
    my $self = bless {} => ref($invocant) || $invocant;

    # Accept replacement coderefs for get_time and notify_report (mostly
    # used in tests), and otherwise populate them with default values.
    if (my %params = @_) {
        for my $coderef_param (qw(get_time notify_report)) {
            if (ref($params{$coderef_param}) eq 'CODE') {
                $self->{$coderef_param} = $params{$coderef_param};
            }
        }
    }
    $self->{get_time}      ||= $self->_default_get_time;
    $self->{notify_report} ||= $self->_default_notify_report;

    # Start timing, and return this object.
    $self->start_timing;
    return $self;
}

# Passed a list of arguments, returns a similar list of arguments beginning
# with a Timer::Milestones object - the first argument, if it was such an
# object, or otherwise a singleton, followed by the other arguments.
{
    my $singleton;

    sub _object_and_arguments {
        my (@arguments) = @_;
        
        unless (blessed($arguments[0])
            && $arguments[0]->isa('Timer::Milestones'))
        {
            $singleton ||= __PACKAGE__->new;
            unshift @arguments, $singleton
        }
        return @arguments;
    }
}


=head3 start_timing

If timing hadn't already been started, starts timing. Otherwise does nothing.
Automatically called by L</new>, but you'll need to call it explicitly when
using the functional interface.

=cut

sub start_timing {
    my ($self) = _object_and_arguments(@_);
    unless (exists $self->{milestones}) {
        $self->add_milestone('START');
    }
}

=head3 add_milestone

 In: $name (optional)

Adds another milestone. If supplied with a name, uses that name for the 
milestone; otherwise, generates a name from the place it was called from
(package, function, line number).

Throws an exception if a timing report has already been generated by
L</generate_report>.

=cut

sub add_milestone {
    my ($self, $milestone_name) = _object_and_arguments(@_);

    # Can't add milestones if we've decided that we're finished.
    if ($self->{timing_stopped}) {
        croak 'Stopped timing already';
    }

    # Build up a milestone structure with the name provided, or a suitable
    # default.
    my $milestone = { name => $milestone_name || $self->_milestone_name };

    # End the previous milestone, if there was one; reuse the time it ended
    # if we can.
    if (my $previous_milestone = $self->_end_previous_milestone) {
        $milestone->{started} = $previous_milestone->{ended};
    } else {
        $milestone->{started} = $self->_now
    }

    # Remember this new milestone.
    push @{ $self->{milestones} }, $milestone;

    # We can now usefully generate a new report.
    delete $self->{generated_report};

    return $milestone;
}

sub _milestone_name {
    # Where we were called from (skipping over add_milestone which called *us*):
    my ($package, $filename, $line) = caller(1);
    # The subroutine the calling code was called from, if any. It will be
    # fully-qualified, so no need to mention the package.
    if (my $calling_subroutine = (caller(2))[3]) {
        return "$calling_subroutine (line $line of $filename)";
    } else {
        return "Line $line of $package ($filename)";
    }
}

=head3 generate_intermediate_report

 Out: $report

Returns a report on the milestones that have elapsed so far, or undef if a
report has previously been generated and no new milestones have been
reached since then.

=cut

sub generate_intermediate_report {
    my ($self) = _object_and_arguments(@_);
    
    $self->_generate_report;
}

sub _generate_report {
    my ($self) = @_;

    # If we've got nothing new since the last time since we said anything,
    # don't say anything.
    return if $self->{generated_report};

    # There's also nothing to say if we don't have any milestones.
    return if !$self->{milestones};

    # Build up a report.
    my ($previous_milestone, @elements, @function_calls);
    for my $milestone (@{ $self->{milestones} }) {
        # If this is the first milestone, mention when this milestone started,
        # as it's the start of it all.
        if (!$previous_milestone) {
            push @elements,
                {
                type => 'time',
                name => $milestone->{name},
                time => $milestone->{started},
                };
        }

        # But if we *do* have a previous milestone, we can now report how long
        # it took to get to this one.
        if ($previous_milestone) {
            my $elapsed_time = $previous_milestone->{ended}
                - $previous_milestone->{started};
            push @elements,
                { type => 'interval',  elapsed_time => $elapsed_time };
            push @elements, @function_calls if @function_calls;
            push @elements,
                { type => 'milestone', name => $milestone->{name} };
        }
        
        # Remember this milestone for when we reach the next one.
        $previous_milestone = $milestone;

        # If there were any function calls in this milestone, remember them.
        @function_calls = ();
        if ($milestone->{function_calls}) {
            for my $function_call (@{ $milestone->{function_calls} }) {
                $self->_add_function_call_to_list($function_call,
                    \@function_calls);
            }
        }
    }

    # If we've ended, also remember that.
    if ($self->{timing_stopped}) {
        push @elements,
            {
            type         => 'interval',
            elapsed_time => $previous_milestone->{ended}
                - $previous_milestone->{started}
            };
        push @elements, @function_calls if @function_calls;
        push @elements,
            {
            type => 'time',
            name => 'END',
            time => $self->{timing_stopped}
            };
    }

    # Now that we've got all the elements, generate a report from them.
    my $report = $self->_generate_report_from_elements(@elements);

    # Remember that we generated a report, so we don't produce it again.
    $self->{generated_report} = 1;

    # And return the report we generated.
    return $report;
}

# Provided with a function call hashref and an arrayref of function call
# elements, adds or combines the function call with what we have already.

sub _add_function_call_to_list {
    my ($self, $function_call, $call_elements) = @_;

    my $elapsed_time = $function_call->{ended} - $function_call->{started};

    # If we're not summarising calls, we're going to add another element,
    # so just do that.
    if (!$function_call->{summarise_calls}) {
        my $element = {
            type          => 'function_call',
            function_name => $function_call->{function_name},
            elapsed_time  => $elapsed_time,
        };
        if (exists $function_call->{argument_summary}) {
            $element->{arguments_seen} = [
                {
                    call_count       => 1,
                    argument_summary => $function_call->{argument_summary},
                }
            ];
        }
        push @$call_elements, $element;
        return;
    }

    # OK, find out which element we're going to use.
    my ($element)
        = grep { $_->{function_name} eq $function_call->{function_name} }
        @$call_elements;
    if (!$element) {
        push @{$call_elements},
            {
            type          => 'function_call',
            function_name => $function_call->{function_name},
            elapsed_time  => 0,
            };
        $element = $call_elements->[-1];
    }
    $element->{elapsed_time} += $elapsed_time;

    # If we're summarising arguments as well, store that information inside
    # this element, once for each argument summary we see.
    if (exists $function_call->{argument_summary}) {
        my ($matching_arguments) = grep {
            $_->{argument_summary} eq $function_call->{argument_summary}
        } @{ $element->{arguments_seen} ||= [] };
        if (!$matching_arguments) {
            push @{ $element->{arguments_seen} },
                { argument_summary => $function_call->{argument_summary} };
            $matching_arguments = $element->{arguments_seen}[-1];
        }
        $matching_arguments->{call_count}++;
    }

    # No matter what, remember that this function was called again.
    $element->{call_count}++;
}


sub _generate_report_from_elements {
    my ($self, @elements) = @_;

    # Work out how much time passed between all intervals so far.
    my $total_elapsed_time = 0;
    for my $element (grep { $_->{type} eq 'interval' } @elements) {
        $total_elapsed_time += $element->{elapsed_time};
    }

    # In case all our timestamps are equal (which *can* happen if you're
    # testing very, very fast code, or Time::HiRes isn't working), tweak the
    # total elapsed time to merely be *very small*, to avoid a divide by zero
    # error later on when we work out percentages.
    $total_elapsed_time ||= 0.000_001;

    # Now we can report all of this: static times, and intervals between them.
    my $report;
    for my $element (@elements) {
        if ($element->{type} eq 'time') {
            $report .= $element->{name} . ': '
                . localtime($element->{time}) . "\n";
        } elsif ($element->{type} eq 'milestone') {
            $report .= $element->{name} . "\n";
        } elsif ($element->{type} eq 'interval') {
            my $elapsed_time_ratio
                = $element->{elapsed_time} / $total_elapsed_time;
            $report .= sprintf(
                "    %s (%6.2f%%)\n",
                $self->_human_elapsed_time($element->{elapsed_time}),
                $elapsed_time_ratio * 100
            );
        } elsif ($element->{type} eq 'function_call') {
            my $function_name = $element->{function_name};
            if ($element->{call_count}) {
                $function_name .= ' (x' . $element->{call_count} . ')';
            }
            $report .= sprintf("        %6s %s\n",
                $self->_human_elapsed_time($element->{elapsed_time}),
                $function_name
            );
            if ($element->{arguments_seen}) {
                for my $arguments (@{ $element->{arguments_seen}}) {
                    $report .= (' ' x 12) . $arguments->{argument_summary};
                    if ($arguments->{call_count} > 1) {
                        $report .= ' (x' . $arguments->{call_count} . ')';
                    }
                    $report .= "\n";
                }
            }
        } else {
            croak 'What the hell is an element of type '
                . $element->{type} . '?';
        }        
    }
    return $report;
}

sub _human_elapsed_time {
    my ($self, $elapsed_time) = @_;

    my @unit_specs = $self->_unit_specs;
    unit_spec:
    for my $unit_spec (@unit_specs) {
        next unit_spec
            if $unit_spec->{max} && $elapsed_time >= $unit_spec->{max};
        return sprintf(
            $unit_spec->{label_format},
            $unit_spec->{transform}
            ? $unit_spec->{transform}->($elapsed_time)
            : $elapsed_time
        );
    }
}

sub _unit_specs {
    (
        {
            max          => 1,
            label_format => '%3d ms',
            transform    => sub { (shift) * 1_000 },
        },
        {
            max => 60,
            label_format => '%2d s',
        },
        {
            max          => 60 * 60,
            label_format => '%2d min %2d s',
            transform    => sub {
                my $seconds = shift;
                ($seconds / 60, $seconds % 60)
            },
        },
        {
            label_format => '%d h %2d min',
            transform    => sub {
                my $seconds = shift;
                my $minutes = $seconds / 60;
                ($minutes / 60, $minutes % 60)
            },
        }
    );
}

=head3 generate_final_report

 Out: $report

Stops timing, and returns a report for all of the milestones.

=cut

sub generate_final_report {
    my ($self) = _object_and_arguments(@_);

    if (!$self->{timing_stopped}) {
        my $milestone = $self->_end_previous_milestone;
        $self->{timing_stopped} = $milestone->{ended};
        delete $self->{generated_report};
    }

    return $self->_generate_report;
}

=head3 stop_timing

Stops timing, and spits out the result of L</generate_intermediate_report> to
STDERR. This is called automatically in OO mode when the object goes out of
scope. This does nothing if you've already called L</generate_final_report>.

=cut

sub stop_timing {
    my ($self) = _object_and_arguments(@_);
    if (my $report = $self->generate_final_report) {
        $self->{notify_report} ||= $self->_default_notify_report;
        return $self->{notify_report}->($report);
    }
}

sub _default_notify_report {
    sub { my $report = shift; print STDERR $report }
}

# Makes sure that we have a list of milestones; if we also had a previous
# milestone, marks it as having ended now.

sub _end_previous_milestone {
    my ($self) = @_;
    $self->{milestones} ||= [];
    if (my $previous_milestone = $self->{milestones}[-1]) {
        $previous_milestone->{ended} = $self->_now;
        return $previous_milestone;
    }
    return;
}

# Returns the current time, via the get_time coderef. The main use for this
# level of indirection is (a) supporting Time::HiRes if it's installed, and
# otherwise falling back to the standard time function, and (b) making it
# possible to mock time, which we'll need in the tests.

sub _now {
    my ($self) = @_;

    $self->{get_time} ||= $self->_default_get_time;
    return $self->{get_time}->();
}

sub _default_get_time {
    eval { require Time::HiRes; Time::HiRes::time() }
        ? \&Time::HiRes::time
        : sub { time };
}

sub DESTROY {
    my ($self) = @_;

    $self->stop_timing;
}

=head2 Timing other people's code

Adding calls to L</mark_milestone> throughout your code is all very well, but
sometimes you want to time a small handful of methods deep in someone else's
code (or deep in I<your> code - same difference). By carefully targeting only
a few methods to time, you can avoid the pitfalls of profiling with
L<Devel::NYTProf>, where code that does zillions of fast method calls will
appear to be much slower than it is when not profiling.

=head3 time_function

 In: $function_name
 In: %args (optional)

Supplied with a function name, e.g. C<DBIx::Class::Storage::DBI::_dbh_execute>,
and an optional hash of arguments, wraps it with a temporary shim that records
the time spent inside this function. That shim is removed, and the original
code restored, when timing stops. Details of the functions called are included
between milestones in the resulting report.

Optional arguments are as follows:

=over

=item summarise_arguments

A coderef, which will be passed the arguments passed to the function,
and which should return a scalar that will be included in the report.

=item summarise_calls

If set to a true value, repeated calls to this function will be summarised
rather than listed individually: the first time a function call is found, it
will also mention all subsequent calls.

This can combine with C<summarise_arguments>: calls which result in an
identical return value from that coderef will be combined.

=back

=cut

sub time_function {
    my ($self, $function_name, %args) = _object_and_arguments(@_);

    # There had better be a function of this name.
    no strict 'refs';
    my $orig_code = \&{ $function_name };
    use strict 'refs';
    if (!defined &$orig_code) {
        die "No such function as $function_name";
    }

    # OK, generate a wrapper.
    my $wrapper = sub {
        # Remember how this function was called.
        my @args = @_;
        my $wantarray = wantarray;

        # Take a snapshot before we called it.
        push @{ $self->{milestones}[-1]{function_calls} ||= [] },
            my $function_call = {
            function_name => $function_name,
            started       => $self->_now,
            };

        # Remember that we want to summarise these calls if necessary.
        if ($args{summarise_calls}) {
            $function_call->{summarise_calls} = 1;
        }

        # Include a summary of the arguments provided if necessary.
        if ($args{summarise_arguments}) {
            $function_call->{argument_summary}
                = $args{summarise_arguments}->(@args);
        }

        # Call it.
        my ($scalar_return, @list_return);
        if ($wantarray) {
            @list_return = $orig_code->(@args);
        } elsif (defined $wantarray) {
            $scalar_return = $orig_code->(@args);
        } else {
            $orig_code->(@args);
        }

        # Take a snapshot at the end.
        $function_call->{ended} = $self->_now;

        # And return the original return values.
        if ($wantarray) {
            return @list_return;
        } elsif (defined $wantarray) {
            return $scalar_return;
        } else {
            return;
        }
    };

    # And install that.
    no strict 'refs';
    no warnings 'redefine';
    *{ $function_name } = $wrapper;
    use warnings 'redefine';
    use strict 'refs';

    # Remember that we did this, so we can unwind it all.
    push @{ $self->{wrapped_functions} ||= [] },
        {
        function_name => $function_name,
        orig_code     => $orig_code,
        };
}

=head1 SEE ALSO

L<Timer::Simple>, which is simpler but more verbose.

L<Devel::Timer>, which does some similar things.

L<Devel::NYTProf>, which is probably worth using as a first pass, even if you
don't necessarily trust its idea of what's I<actually> slow.

=head1 AUTHOR

Sam Kington <skington@cpan.org>

The source code for this module is hosted on GitHub
L<https://github.com/skington/timer-milestones> - this is probably the
best place to look for suggestions and feedback.

=head1 COPYRIGHT

Copyright (c) 2020 Sam Kington.

=head1 LICENSE

This library is free software and may be distributed under the same terms as
perl itself.

=cut

1;
