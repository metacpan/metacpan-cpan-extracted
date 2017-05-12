package Time::ETA;
$Time::ETA::VERSION = '1.2.0';
# ABSTRACT: calculate estimated time of accomplishment


use warnings;
use strict;

use Carp;
use Time::HiRes qw(
    gettimeofday
    tv_interval
);

use YAML;

my $true = 1;
my $false = '';

our $SERIALIZATION_API_VERSION = 3;


sub new {
    my ($class, %params) = @_;
    my $self = {};
    bless $self, $class;

    croak "Expected to get parameter 'milestones'. Stopped" if not defined $params{milestones};
    croak "Parameter 'milestones' should be positive integer. Stopped" if not $self->_is_positive_integer($params{milestones});

    $self->{_milestones} = $params{milestones};
    $self->{_passed_milestones} = 0;
    $self->{_elapsed} = 0;
    $self->{_start} = [gettimeofday];
    $self->{_is_paused} = $false;

    return $self;
}


sub get_elapsed_seconds {
    my ($self) = @_;

    my $elapsed_seconds;

    if ($self->is_completed()) {
        $elapsed_seconds = tv_interval($self->{_start}, $self->{_end});
    } else {
        $elapsed_seconds = tv_interval($self->{_start}, [gettimeofday]);
    }

    return $elapsed_seconds;
}


sub get_elapsed_time {
    my ($self) = @_;

    my $time = $self->_get_time_from_seconds($self->get_elapsed_seconds());

    return $time;
}


sub get_remaining_seconds {
    my ($self) = @_;

    croak "There is not enough data to calculate estimated time of accomplishment. Stopped" if not $self->can_calculate_eta();

    return 0 if $self->is_completed();

    my $elapsed_before_milestone = tv_interval($self->{_start}, $self->{_milestone_pass});
    my $elapsed_after_milestone = tv_interval($self->{_milestone_pass}, [gettimeofday()]);

    my $remaining_milestones = $self->{_milestones} - $self->{_passed_milestones};

    my $one_milestone_completion_time = $elapsed_before_milestone/$self->{_passed_milestones};
    my $remaining_seconds = ($one_milestone_completion_time * $remaining_milestones) - $elapsed_after_milestone;

    return $remaining_seconds;
}


sub get_remaining_time {
    my ($self) = @_;

    my $time = $self->_get_time_from_seconds($self->get_remaining_seconds());

    return $time;
}


sub get_completed_percent {
    my ($self) = @_;

    my $completed_percent = (100 * $self->{_passed_milestones}) / $self->{_milestones};

    return $completed_percent;
}


sub is_completed {
    my ($self) = @_;

    return ($self->{_passed_milestones} == $self->{_milestones})
        ? $true
        : $false
        ;
}


sub pass_milestone {
    my ($self) = @_;

    if ($self->{_passed_milestones} < $self->{_milestones}) {
        $self->{_passed_milestones}++;
    } else {
        croak "You have already completed all milestones. It it incorrect to run pass_milestone() now. Stopped";
    }

    my $dt = [gettimeofday];

    $self->{_milestone_pass} = $dt;

    if ($self->{_passed_milestones} == $self->{_milestones}) {
        $self->{_end} = $dt;
    }

    return $false;
}


sub can_calculate_eta {
    my ($self) = @_;

    if ($self->{_passed_milestones} > 0) {
        return $true;
    } else {
        return $false;
    }
}


sub pause {
    my ($self) = @_;

    croak "The object is already paused. Can't pause paused. Stopped" if $self->is_paused();

    my $elapsed_seconds = tv_interval($self->{_start}, [gettimeofday]);
    $self->{_elapsed} += $elapsed_seconds;
    $self->{_start} = undef;

    $self->{_is_paused} = $true;

    return $false;
}


sub is_paused {
    my ($self) = @_;

    return $self->{_is_paused};
}


sub resume {
    my ($self, $string) = @_;

    croak "The object isn't paused. Can't resume. Stopped" if not $self->is_paused();

    # Setting the start time
    # Start time is the current time minus time that has already pass
    my $timeofday = [gettimeofday];
    my $start = ($timeofday->[0] * 1_000_000 + $timeofday->[1]) - int($self->{_elapsed} * 1_000_000);
    $self->{_start} = [int($start / 1_000_000), $start % 1_000_000];

    $self->{_elapsed} = 0;
    $self->{_is_paused} = $false;

    return $false;
}


sub serialize {
    my ($self) = @_;

    my $data = {
        _version => $SERIALIZATION_API_VERSION,
        _milestones => $self->{_milestones},
        _passed_milestones => $self->{_passed_milestones},
        _start  => $self->{_start},
        _milestone_pass => $self->{_milestone_pass},
        _end  => $self->{_end},
        _is_paused => $self->{_is_paused},
        _elapsed => $self->{_elapsed},
    };

    my $string = Dump($data);

    return $string;
}


sub spawn {
    my ($class, $string) = @_;

    croak "Can't spawn Time::ETA object. No serialized data specified. Stopped" if not defined $string;

    my $data;

    eval {
        $data = Load($string);
    };

    if ($@) {
        croak "Can't spawn Time::ETA object. Got error from YAML parser:\n" . $@ . "Stopped";
    }

    croak "Can't spawn Time::ETA object. Got incorrect serialized data. Stopped" if ref $data ne "HASH";

    croak "Can't spawn Time::ETA object. Serialized data does not contain version. Stopped" if not defined $data->{_version};

    my $v = _get_version();
    croak "Can't spawn Time::ETA object. Version $v can work only with serialized data version $SERIALIZATION_API_VERSION. Stopped"
        if $data->{_version} ne $SERIALIZATION_API_VERSION;

    croak "Can't spawn Time::ETA object. Serialized data contains incorrect number of milestones. Stopped"
        if not _is_positive_integer(undef, $data->{_milestones});

    croak "Can't spawn Time::ETA object. Serialized data contains incorrect number of passed milestones. Stopped"
        if not _is_positive_integer_or_zero(undef, $data->{_passed_milestones});

    if (not $data->{_is_paused}) {
        _check_gettimeofday(
            undef,
            value => $data->{_start},
            name => "start time"
        );
    }

    if (defined $data->{_end}) {
        _check_gettimeofday(
            undef,
            value => $data->{_end},
            name => "end time"
        );
    }

    if (defined $data->{_milestone_pass}) {
        _check_gettimeofday(
            undef,
            value => $data->{_milestone_pass},
            name => "last milestone pass time"
        );
    }

    my $self = {
        _milestones => $data->{_milestones},
        _passed_milestones => $data->{_passed_milestones},
        _start  => $data->{_start},
        _milestone_pass => $data->{_milestone_pass},
        _end  => $data->{_end},
        _is_paused => $data->{_is_paused},
        _elapsed => $data->{_elapsed},
    };

    bless $self, $class;

    return $self;
}


sub can_spawn {
    my ($class, $string) = @_;

    eval {
        my $eta = spawn($class, $string);
    };

    if (not $@) {
        return $true;
    } else {
        return $false;
    }
}

sub _check_gettimeofday {
    my ($self, %params) = @_;

    croak "Expected to get 'name'" unless defined $params{name};

    croak "Can't spawn Time::ETA object. Serialized data contains incorrect data for $params{name}. Stopped"
        if ref $params{value} ne "ARRAY";

    croak "Can't spawn Time::ETA object. Serialized data contains incorrect seconds in $params{name}. Stopped"
        if not _is_positive_integer_or_zero(undef, $params{value}->[0]);

    croak "Can't spawn Time::ETA object. Serialized data contains incorrect microseconds in $params{name}. Stopped"
        if not _is_positive_integer_or_zero(undef, $params{value}->[1]);

    return $false;
}

sub _is_positive_integer_or_zero {
    my ($self, $maybe_number) = @_;

    return $false if not defined $maybe_number;

    # http://www.perlmonks.org/?node_id=614452
    my $check_result = $maybe_number =~ m{
        \A      # beginning of string
        \+?     # optional plus sign
        [0-9]+  # mandatory digits, including zero
        \z      # end of string
    }xms;

    return $check_result;
}

sub _is_positive_integer {
    my ($self, $maybe_number) = @_;

    return $false if not defined $maybe_number;

    return $false if $maybe_number eq '0';
    return $false if $maybe_number eq '+0';

    return _is_positive_integer_or_zero(undef, $maybe_number);
}

sub _get_time_from_seconds {
    my ($self, $input_sec) = @_;

    my $text;
    {
        # This is a quick solution. This like make code more robust.
        # With this like the code will fail if $input_sec is not a number.
        use warnings FATAL => 'all';

        my $left_sec;
        my $hour = int($input_sec/3600);
        $left_sec = $input_sec - ($hour * 3600);

        my $min = int($left_sec/60);
        $left_sec = $left_sec - ($min * 60);

        $text =
            sprintf("%01d", $hour) . ":"
            . sprintf("%02d", $min) . ":"
            . sprintf("%02d", $left_sec)
            ;
    }

    return $text;
}


sub _get_version {
    no warnings 'uninitialized';
    my $v = "$Time::ETA::VERSION";
    return $v;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::ETA - calculate estimated time of accomplishment

=head1 VERSION

version 1.2.0

=head1 SYNOPSIS

    use Time::ETA;

    my $eta = Time::ETA->new(
        milestones => 12,
    );

    foreach (1..12) {
        do_work();
        $eta->pass_milestone();
        print "Will work " . $eta->get_remaining_seconds() . " seconds more\n";
    }

=head1 DESCRIPTION

You have a long lasting progress that consist of the number of more or less
equal tasks. You need to calculate when the progress will finish. This module
is designed to solve this task.

Time::ETA is designed to work with the programms that don't output anything
to user console. This module is created to calculate ETA in cron scripts and
background running programms. If you need an easy way to output process
progress in terminal, please look at the exelent L<Term::ProgressBar>.

To work with Time::ETA you need to create object with constructor new().

Then you run your tasks (just execute subs that containg the code of that
tasks) and after each task you run pass_milestone() method to tell Time::ETA
object that you have completed part of your process.

Any time in you programme you can use methods to understand what is going on
and how soon the process will finish. That are methods is_completed(),
get_completed_percent(), get_elapsed_seconds(), get_remaining_seconds().

This module has build-in feature for serialisation. You can run method
serialize() to get the text string with the object state. And you can restore
your object from that string with spawn() method.

Time::ETA version numbers uses Semantic Versioning standart.
Please visit L<http://semver.org/> to find out all about this great thing.

=head1 METHODS

=head2 new

B<Get:> 1) $class 2) %params

B<Return:> 1) $self with Time::ETA object

This is the constructor. It needs one mandatory parameter - the number of
milestones that should be completed.

Here is the example. Let's imagine that we are generating timetable for the
next year. We have method generate_month() that is executed for every month.
To create Time::ETA object that can calculate estimated time of timetable
generation you need to write:

    my $eta = Time::ETA->new(
        milestones => 12,
    );

=head2 get_elapsed_seconds

B<Get:> 1) $self

B<Return:> 1) $elapsed_seconds - float number

Method return number of seconds that have passed from object creation time.

    print $eta->get_elapsed_seconds();

It can output something like 1.35024 and it means that a bit more than one
second have passed from the moment the new() constructor has executed.

If the process is finished this method will return process run time in
seconds.

=head2 get_elapsed_time

B<Get:> 1) $self

B<Return:> 1) $text_time - scalar with the text representation of elapsed
time.

Method return elapsed time in the form "H:MM:SS". For example it can return
"11:54:12", it means that the process is running for 11 hours, 54 minutes and
12 seconds.

This method returns the same number as get_elapsed_seconds(), but in format
that is easy for humans to understand.

=head2 get_remaining_seconds

B<Get:> 1) $self

B<Return:> 1) $elapsed_seconds - float number

Method return estimated seconds how long the process will work.

    print $eta->get_remaining_seconds();

It can return number like 14.872352 that means that the process will end in
nearly 15 seconds. The accuaccuracy of this time depends on the time lengths
of every milestone. The more equal milestones time to each other, the more
precise is the prediction.

This method will die in case it haven't got enough information to calculate
estimated time of accomplishment. The method will die untill pass_milestone()
is run for the first time. After pass_milestone() run at least once,
get_remaining_seconds() has enouth data to caluate ETA. To find out if ETA can
be calculated you can use method can_calculate_eta().

There is one more method that you can use to get information about remaining
time. The method is called get_remaining_time(). It return the time in format
"H:MM:SS" and works exaclty as this method.

If the process is finished this method will return 0.

=head2 get_remaining_time

B<Get:> 1) $self

B<Return:> 1) $text_time - scalar with the text representation of remaing
time.

Method return estimated time in the form "H:MM:SS". For example it can return
"12:04:44", it means that the process is expected to finish in 12 hours, 4
minutes and 44 seconds.

This method returns the same number as get_remaining_seconds(), but in format
that is easy for humans to understand.

Method works the same as get_remaining_seconds(). In case it is not possible
to calulate remaining time the method will die. You can use method
can_calculate_eta() to find out if it is possible to get remaing time.

If the process is finished this method will return "0:00:00".

=head2 get_completed_percent

B<Get:> 1) $self

B<Return:> 1) $completed_percent - float number in the range from zero to 100
(including zero and 100)

Method returns the percentage of the process completion. It will return 0 if
no milestones have been passed and it will return 100 if all the milestones
have been passed.

    $eta->get_completed_percent();

For example, if one milestone from 12 have been completed the method will
return 8.33333333333333

=head2 is_completed

B<Get:> 1) $self

B<Return:> 1) $boolean - true value if the process is completed or false value
if the process is running.

You can also use get_completed_percent() to find our how much of the process
is finished.

=head2 pass_milestone

B<Get:> 1) $self

B<Return:> it returns nothing that can be used

This method tells the object that one part of the task (called milestone) have
been completed. You need to run this method as many times as many milestones
you have specified in the object new() constructor.

    $eta->pass_milestone();

You need to run this method at least once after start or after resuming
(in dependence of what has been happen later) to make method
get_remaining_seconds() work.

=head2 can_calculate_eta

B<Get:> 1) $self

B<Return:> $boolean

This method returns bool value that gives information if there is enough
data in the object to calculate process estimated time of accomplishment.

It will return true value if method pass_milestone() have been run at least
once, if the method pass_milestone() haven't been run it will return false.

This method is used to check if it is safe to run method
get_remaining_seconds(). Method get_remaining_seconds() dies in case there is
no data to calculate ETA.

    if ( $eta->can_calculate_eta() ) {
        print $eta->get_remaining_seconds();
    }

When the process is complete can_calculate_eta() returns true value, but
get_remaining_seconds() return 0.

=head2 pause

B<Get:> 1) $self

B<Return:> it returns nothing that can be used

This method tells the object that execution of the task have been paused.

Method dies in case the object is already paused.

    $eta->pause();

=head2 is_paused

B<Get:> 1) $self

B<Return:> $boolean

This method returns bool value that gives information if the object is paused.

It will return true if method pause() has been run and no resume() method
was run after that. Otherwise it will return false.

This method is used to check whether it is safe to run method resume().
Method resume() dies in the case the object is not paused.

    if ( $eta->is_paused() ) {
        $eta->resume();
    }

=head2 resume

B<Get:> 1) $self

B<Return:> it returns nothing that can be used

This method tells the object that execution of the task is continued
after pause.

If the object is not paused the method dies.

=head2 serialize

B<Get:> 1) $self

B<Return:> 1) $string with serialized object

Object Time::ETA has build-in serialaztion feature. For example you need to
store the state of this object in the database. You can run:

    my $string = $eta->serialize();

As a result you will get $string with text data that represents the whole
object with its state. Then you can store that $string in the database and
later with the method spawn() to recreate the object in the same state it was
before the serialization.

=head2 spawn

B<Get:> 1) $class 2) $string with serialized object

B<Return:> 1) $self

This is actually an object constructor. It recieves $string that contaings
serialized object data and creates an object.

    my $eta = Time::ETA->spawn($string);

The $string is created by the method serialized().

spawn() die if $string is incorrect. You can check if it is possible to
respawn object from a $string with the method can_spawn().

=head2 can_spawn

B<Get:> 1) $class 2) $string with serialized object

B<Return:> 1) $bool - true value if it is possible to recreate object from
serialized $string, otherwise false value

    my $can_spawn = Time::ETA->can_spawn($string);

Methos spawn() that is used to create object from the serialized $string dies
in case the $string is incorrect. This method is added to the object to
simplify the check process.

=begin comment _get_version

To fix problem 'Use of uninitialized value $Time::ETA::VERSION' when working
with code that is not build with Dist::Zilla.


=end comment

=head1 SEE ALSO

=over

=item L<PBS::ProgressBar>

=item L<Progress::Any>

=item L<Progress::PV>

=item L<Term::ProgressBar::Quiet>

=item L<Term::ProgressBar::Simple>

=item L<Term::ProgressBar>

=item L<Text::ProgressBar::ETA>

=item L<Time::Progress>

=item L<http://blogs.perl.org/users/steven_haryanto/2014/02/getting-a-progress-report-from-a-running-program.html>

=back

=head1 CONTRIBUTORS

=over 4

=item * Dmitry Lukiyanchuk (WTERTIUS)

=back

=head1 SOURCE CODE

The source code for this module and scripts is hosted on GitHub
L<https://github.com/bessarabov/Time-ETA>

=head1 BUGS

Please report any bugs or feature requests in GitHub Issues
L<https://github.com/bessarabov/Time-ETA/issues>

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
