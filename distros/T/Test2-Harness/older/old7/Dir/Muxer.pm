package Test2::Harness::Schema::Dir::Job::Muxer;
use strict;
use warnings;

use Carp qw/croak/;
use Time::HiRes qw/time/;
use Test2::Harness::Util::JSON qw/decode_json/;

use Test2::Harness::Util::File::Stream;
use Test2::Harness::Util::File::JSONL;
use Test2::Harness::Util::File::Value;

use Test2::Harness::Schema::Dir::Job::TAP qw{
    parse_stdout_tap
    parse_stderr_tap
};

use Test2::Harness::Util::HashBase qw{
    -run_id -job_id -job_root
    -events_file -events_exists -_events_buffer -_events_index
    -stderr_file -stderr_exists -_stderr_buffer -_stderr_index -_stderr_id
    -stdout_file -stdout_exists -_stdout_buffer -_stdout_index -_stdout_id
    -start_file  -start_exists  -_start_buffer
    -stop_file   -stop_exists   -_stop_buffer
    -exit_file   -exit_exists   -_exit_buffer
    -_lookup
};

sub init {
    my $self = shift;

    croak "'run_id' is a required attribute"
        unless $self->{+RUN_ID};

    croak "'job_id' is a required attribute"
        unless $self->{+JOB_ID};

    croak "'job_root' is a required attribute"
        unless $self->{+JOB_ROOT};

    $self->{+_EVENTS_INDEX} = 0;
    $self->{+_STDOUT_INDEX} = 0;
    $self->{+_STDERR_INDEX} = 0;
    $self->{+_STDOUT_ID}    = 0;
    $self->{+_STDERR_ID}    = 0;
    $self->{+_EVENTS_BUFFER} ||= [];
    $self->{+_STDOUT_BUFFER} ||= [];
    $self->{+_STDERR_BUFFER} ||= [];

    $self->{+_LOOKUP} = {};
}

sub complete {
    my $self = shift;

    return 0 unless $self->{+STOP_EXISTS};
    return 0 if $self->_have_buffer;
    return 1;
}

sub fetch {
    my $self = shift;
    my ($event_id) = @_;

    # STDERR and STDOUT depend on this attribute being correct
    unless ($self->{+EVENTS_EXISTS}) {
        my $events_file = $self->{+EVENTS_FILE} || $self->_open_file('events.json');
        $self->{+EVENTS_EXISTS} = $events_file->exists;
    }

    my $lookup = $self->{+_LOOKUP}->{$event_id} or return undef;

    my $file = $self->_open_file($lookup->{file});
    my $line = $file->read_line(from => $lookup->{start_pos});

    # Strip off extensions
    my $short_name = $lookup->{file};
    $short_name =~ s/\..*$//;

    my $meth = "_process_${short_name}_line";
    return $self->$meth($event_id, $lookup, $line);
}

sub poll {
    my $self = shift;
    my ($max) = @_;

    return if $self->complete;

    $self->_fill_buffers($max);

    my (@out, @new);

    # If we have a max number of events then we need to pass that along to the
    # inner-pollers, but we need to pass around how many MORE we need, this sub
    # will return the amount we still need.
    # If this finds that we do not need any more it will exit the loop instead
    # of returning a number.
    my $check = defined($max) ? sub {
        no warnings 'exiting';
        my $want = $max - scalar(@out) - scalar(@new);
        last if $want < 1;
        return $want;
    } : sub { undef };

    while(!defined($max) || @out < $max) {
        # Micro-optimization, 'start' only ever has 1 thing, so do not enter
        # the sub if we do not need to.
        push @new => $self->_poll_start($check->()) if $self->{+_START_BUFFER};

        # Do not re-order these. Everything syncs to event, so put it last. We
        # want STDOUT to appear before STDERR typically so we poll stderr first
        # to give stdout more time to fill. We will only work so hard to order
        # stdout/stderr, this is as far as we go.
        push @new => $self->_poll_stderr($check->());
        push @new => $self->_poll_stdout($check->());
        push @new => $self->_poll_event($check->());

        # 'exit' and 'stop' MUST come last, so do not even think about grabbing
        # them until @new is empty.
        unless (@new) {
            # Micro-optimization, 'exit' and 'stop' only ever have 1 thing, so do
            # not enter the subs if we do not need to.
            push @new => $self->_poll_exit($check->()) if $self->{+_EXIT_BUFFER};
            push @new => $self->_poll_stop($check->()) if $self->{+_STOP_BUFFER};
        }

        return @out unless @new;

        push @out => @new;
        @new = ();
    }

    return @out;
}

my %FILE_MAP = (
    'events.jsonl' => [EVENTS_FILE, 'Test2::Harness::Util::File::JSONL'],
    'stdout'       => [STDOUT_FILE, 'Test2::Harness::Util::File::Stream'],
    'stderr'       => [STDERR_FILE, 'Test2::Harness::Util::File::Stream'],
    'start'        => [START_FILE,  'Test2::Harness::Util::File::Value'],
    'stop'         => [STOP_FILE,   'Test2::Harness::Util::File::Value'],
    'exit'         => [EXIT_FILE,   'Test2::Harness::Util::File::Value'],
);

sub _open_file {
    my $self = shift;
    my ($file) = @_;

    my $map = $FILE_MAP{$file} or croak "'$file' is not a known job file";
    my ($key, $type) = @$map;

    my $path = File::Spec->catfile($self->{+JOB_ROOT}, $file);

    return $self->{$key} ||= $type->new(name => $path);
}

sub _fill_buffers {
    my $self = shift;
    my ($max) = @_;
    # NOTE 1: 'max' will only effect stdout, stderr, and events.jsonl, the
    # other files only have 1 value each so they will not eat too much memory.
    #
    # NOTE 2: 'max' only effects how many items are ADDED to the buffer, not
    # how many are in the buffer, that is good enough, poll() will take care of
    # the actual event limiting. We only use this here to make sure the buffer
    # grows slowly, this is important if max is used to avoid eating memory. We
    # still need to add to the buffers each time though in case we are waiting
    # for a sync event before we flush.

    # Do not read anything until the start file is present and read.
    unless ($self->{+START_EXISTS}) {
        my $start_file = $self->{+START_FILE} || $self->_open_file('start');
        return unless $start_file->exists;
        $self->{+_START_BUFFER} = $start_file->read_line or return;
        $self->{+START_EXISTS} = 1;
    }

    my $events_buff = $self->{+_EVENTS_BUFFER};
    my $stdout_buff = $self->{+_STDOUT_BUFFER};
    my $stderr_buff = $self->{+_STDERR_BUFFER};

    my $events_file = $self->{+EVENTS_FILE} || $self->_open_file('events.json');
    my $stdout_file = $self->{+STDOUT_FILE} || $self->_open_file('stdout');
    my $stderr_file = $self->{+STDERR_FILE} || $self->_open_file('stderr');

    # Cache the result of the exists check on success, files can come into
    # existence at any time though so continue to check if it fails.
    push @$stdout_buff => $stdout_file->poll_with_index(max => $max) if $self->{+STDOUT_EXISTS} ||= $stdout_file->exists;
    push @$stderr_buff => $stderr_file->poll_with_index(max => $max) if $self->{+STDERR_EXISTS} ||= $stderr_file->exists;
    push @$events_buff => $events_file->poll_with_index(max => $max) if $self->{+EVENTS_EXISTS} ||= $events_file->exists;

    # Do not look for stop/exit until we are done with the other streams
    return if @$stdout_buff || @$stderr_buff || @$events_buff;

    my $ended = 0;
    unless ($self->{+EXIT_EXISTS}) {
        my $exit_file = $self->{+EXIT_FILE} || $self->_open_file('exit');

        if ($exit_file->exists) {
            if (my $line = $exit_file->read_line) {
                $self->{+_EXIT_BUFFER} = $line;
                $self->{+EXIT_EXISTS}  = 1;
                $ended++;
            }
        }
    }

    unless ($self->{+STOP_EXISTS}) {
        my $stop_file = $self->{+STOP_FILE} || $self->_open_file('stop');

        if ($stop_file->exists) {
            if (my $line = $stop_file->read_line) {
                $self->{+_STOP_BUFFER} = $line;
                $self->{+STOP_EXISTS}  = 1;
                $ended++;
            }
        }
    }

    return unless $ended;

    # If we found exit/stop we need one last buffer fill on the other sources.
    # If we do not do this we have a race condition. Ignore the max for this.
    push @$stdout_buff => $stdout_file->poll_with_index() if $self->{+STDOUT_EXISTS} ||= $stdout_file->exists;
    push @$stderr_buff => $stderr_file->poll_with_index() if $self->{+STDERR_EXISTS} ||= $stderr_file->exists;
    push @$events_buff => $events_file->poll_with_index() if $self->{+EVENTS_EXISTS} ||= $events_file->exists;
}

sub _poll_start {
    my $self = shift;
    # Intentionally ignoring the max argument, this only ever returns 1 item,
    # and would not be called if max was 0.

    my $buffer = delete $self->{+_START_BUFFER} or return;
    my ($start_pos, $end_pos, $value) = @$buffer;

    my $event_id = 'start';
    my $lookup = {
        file      => 'start',
        start_pos => $start_pos,
        end_pos   => $end_pos,
    };

    $self->{+_LOOKUP}->{$event_id} = $lookup;

    return $self->_process_start_line($event_id, $lookup, $value);
}

sub _poll_stop {
    my $self = shift;
    # Intentionally ignoring the max argument, this only ever returns 1 item,
    # and would not be called if max was 0.

    my $buffer = delete $self->{+_STOP_BUFFER} or return;
    my ($start_pos, $end_pos, $value) = @$buffer;

    my $event_id = 'stop';
    my $lookup   = {
        file      => 'stop',
        start_pos => $start_pos,
        end_pos   => $end_pos,
    };

    $self->{+_LOOKUP}->{$event_id} = $lookup;

    return $self->_process_stop_line($event_id, $lookup, $value);
}

sub _poll_exit {
    my $self = shift;
    # Intentionally ignoring the max argument, this only ever returns 1 item,
    # and would not be called if max was 0.

    my $buffer = delete $self->{+_EXIT_BUFFER} or return;
    my ($start_pos, $end_pos, $value) = @$buffer;

    my $event_id = 'exit';
    my $lookup   = {
        file      => 'exit',
        start_pos => $start_pos,
        end_pos   => $end_pos,
    };

    $self->{+_LOOKUP}->{$event_id} = $lookup;

    return $self->_process_exit_line($event_id, $lookup, $value);
}

sub _poll_event {
    my $self = shift;
    # Intentionally ignoring the max argument, this only ever returns 1 item,
    # and would not be called if max was 0.

    my $buffer = $self->{+_EVENTS_BUFFER};
    return unless @$buffer;

    my $line_info = $buffer->[0];
    my ($start_pos, $end_pos, $event_data, $file) = @$line_info;
    my $id       = $event_data->{stream_id};

    # We need to wait for these to catch up.
    return if $id > $self->{+_STDOUT_INDEX};
    return if $id > $self->{+_STDERR_INDEX};

    # All cought up, time for the event!
    shift @$buffer;
    $self->{+_EVENTS_INDEX} = $id;

    my $event_id = "event-$id";
    $file ||= 'events.jsonl';
    my $lookup = {
        file      => $file,
        start_pos => $start_pos,
        end_pos   => $end_pos,
    };

    $self->{+_LOOKUP}->{$event_id} = $lookup;

    return $self->_process_events_line($event_id, $lookup, $event_data);
}

sub _poll_stdout {
    my $self = shift;
    my ($max) = @_;

    return if $self->{+_STDOUT_INDEX} > $self->{+_EVENTS_INDEX};

    my $buffer = $self->{+_STDOUT_BUFFER};
    return unless @$buffer;

    my @out;
    while (my $line_info = shift @$buffer) {
        my ($start_pos, $end_pos, $line) = @$line_info;
        chomp($line);

        if ($line =~ m/^T2-HARNESS-ESYNC: (\d+)$/) {
            $self->{+_STDOUT_INDEX} = $1;
            last;
        }

        my $id = $self->{+_STDOUT_ID}; # Do not bump yet!
        my $event_id = "stdout-$id";
        my $lookup = {
            file      => 'stdout',
            start_pos => $start_pos,
            end_pos   => $end_pos,
        };

        my $event_data = $self->_process_stdout_line($event_id, $lookup, $line);

        if(my $sid = $event_data->{stream_id}) {
            $self->{+_STDOUT_INDEX} = $sid;
            push @{$self->{+_EVENTS_BUFFER}} => [$start_pos, $end_pos, $event_data, 'stdout'];
            last;
        }

        # Now we bump it!
        $self->{+_STDOUT_ID}++;

        $self->{+_LOOKUP}->{$event_id} = $lookup;

        last if $max && @out >= $max;
    }

    return @out;
}

sub _poll_stderr {
    my $self = shift;
    my ($max) = @_;

    return if $self->{+_STDERR_INDEX} > $self->{+_EVENTS_INDEX};

    my $buffer = $self->{+_STDERR_BUFFER};
    return unless @$buffer;

    my @out;
    while (my $line_info = shift @$buffer) {
        my ($start_pos, $end_pos, $line) = @$line_info;
        chomp($line);

        if ($line =~ m/^T2-HARNESS-ESYNC: (\d+)$/) {
            $self->{+_STDERR_INDEX} = $1;
            last;
        }

        my $id = $self->{+_STDERR_ID}++;
        my $event_id = "stderr-$id";
        my $lookup = {
            file      => 'stderr',
            start_pos => $start_pos,
            end_pos   => $end_pos,
        };

        push @out => $self->_process_stderr_line($event_id, $lookup, $line);

        $self->{+_LOOKUP}->{$event_id} = $lookup;

        last if $max && @out >= $max;
    }

    return @out;
}

sub _process_events_line {
    my $self = shift;
    my ($event_id, $lookup, $event_data) = @_;

    $event_data->{job_id}   = $self->{+JOB_ID};
    $event_data->{run_id}   = $self->{+RUN_ID};
    $event_data->{event_id} = $event_id;

    $event_data->{facet_data}->{stream} = $lookup;

    return $event_data;
}

sub _process_stderr_line {
    my $self = shift;
    my ($event_id, $lookup, $line) = @_;

    chomp($line);

    my $facet_data;
    $facet_data = parse_stderr_tap($line) unless $self->{+EVENTS_EXISTS};
    $facet_data ||= {info => [{details => $line, tag => 'STDERR', debug => 1}]};
    $facet_data->{stream} = $lookup;

    return {
        job_id     => $self->{+JOB_ID},
        run_id     => $self->{+RUN_ID},
        event_id   => $event_id,
        facet_data => $facet_data,
    };
}

sub _process_stdout_line {
    my $self = shift;
    my ($event_id, $lookup, $line) = @_;

    chomp($line);

    my $event_data;

    if ($line =~ m/^T2-HARNESS-EVENT: (\d+) (.*)/) {
        my ($sid, $json) = ($1, $2);

        $event_data = decode_json($json);
        $event_data->{stream_id} = $sid;
    }
    else {
        my $facet_data;
        $facet_data = parse_stdout_tap($line) unless $self->{+EVENTS_EXISTS};
        $facet_data ||= {info => [{details => $line, tag => 'STDOUT', debug => 0}]};
        $event_data = {facet_data => $facet_data};
    }

    $event_data->{facet_data}->{stream} = $lookup;

    return {
        %$event_data,

        job_id   => $self->{+JOB_ID},
        run_id   => $self->{+RUN_ID},
        event_id => $event_id,
    };
}

sub _process_start_line {
    my $self = shift;
    my ($event_id, $lookup, $value) = @_;

    chomp($value);

    return {
        event_id => $event_id,
        job_id   => $self->{+JOB_ID},
        run_id   => $self->{+RUN_ID},
        stamp    => $value,

        facet_data => {
            harness => {details => "Job $self->{+JOB_ID} started at $value"},
            stream  => $lookup,
        }
    };
}

sub _process_stop_line {
    my $self = shift;
    my ($event_id, $lookup, $value) = @_;

    chomp($value);

    return {
        event_id => $event_id,
        job_id   => $self->{+JOB_ID},
        run_id   => $self->{+RUN_ID},
        stamp    => $value,

        facet_data => {
            harness => {details => "Job $self->{+JOB_ID} stopped at $value"},
            stream  => $lookup,
        }
    };
}

sub _process_exit_line {
    my $self = shift;
    my ($event_id, $lookup, $value) = @_;

    chomp($value);

    return {
        event_id => $event_id,
        job_id   => $self->{+JOB_ID},
        run_id   => $self->{+RUN_ID},

        facet_data => {
            harness => {details => "Job $self->{+JOB_ID} exited $value"},
            control => {details => "Test script exited $value", terminate => $value},
            stream => $lookup
        }
    };
}

sub _have_buffer {
    my $self = shift;

    # These are scalar buffers
    return 1 if $self->{+_START_BUFFER};
    return 1 if $self->{+_STOP_BUFFER};
    return 1 if $self->{+_EXIT_BUFFER};

    # These are array buffers
    return 1 if @{$self->{+_EVENTS_BUFFER}};
    return 1 if @{$self->{+_STDOUT_BUFFER}};
    return 1 if @{$self->{+_STDERR_BUFFER}};

    return 0;
}

1;
