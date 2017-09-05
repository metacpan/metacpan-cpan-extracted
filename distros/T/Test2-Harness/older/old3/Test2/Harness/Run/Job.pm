package Test2::Harness::Run::Job;
use strict;
use warnings;

use IO::Handle;

use Test2::Harness::HashBase qw{
    -id -job_dir
    -file -exit
    -stderr_fh -stdout_fh -events_fh
    -stderr_ts -stdout_ts -events_ts
};

use Test2::Harness::Event;

use Carp qw/croak/;

sub init {
    my $self = shift;

    croak "'id' is a required attribute" unless defined $self->{+ID};
    croak "'job_dir' is a required attribute" unless $self->{+JOB_DIR};
}

sub poll {
    my $self = shift;

    return if defined $self->{+EXIT};

    my $dir = $self->{+JOB_DIR};

    my @events;

    my $job_file = "$dir/job";
    if (!$self->{+FILE} && -e "$dir/job") {
        $self->{+FILE} = top($job_file);
        push @events => [$self->{+ID}, 'job', $self->{+FILE}, stamp($job_file)];
    }

    return unless $self->{+FILE};

    while (1) {
        my $count = @events;
        push @events => $self->read_events();
        push @events => $self->read_stdout();
        push @events => $self->read_stderr();

        # Nothing read
        last if $count == @events;
    }

    my $exit_file = "$dir/exit";
    if (!defined($self->{+EXIT}) && -e "$dir/exit") {
        $self->{+EXIT} = top($exit_file);
        push @events => [$self->{+ID}, 'exit', $self->{+EXIT}, stamp($exit_file)];

        $self->close_handles;
    }

}

sub read_events {
    my $self = shift;
    my $dir = $self->{+JOB_DIR};
    my $fh = $self->{+EVENTS_FH} ||= maybe_open_for_read("$dir/events") || return;
    my $ts = \($self->{+EVENTS_TS});

    return $self->_read_line('events', $fh, $ts);
}

sub read_stdout {
    my $self = shift;
    my $dir = $self->{+JOB_DIR};
    my $fh = $self->{+STDOUT_FH} ||= maybe_open_for_read("$dir/stdout") || return;
    my $ts = \($self->{+STDOUT_TS});

    return $self->_read_line('stdout', $fh, $ts);
}

sub read_stderr {
    my $self = shift;
    my $dir = $self->{+JOB_DIR};
    my $fh = $self->{+STDERR_FH} ||= maybe_open_for_read("$dir/stderr") || return;
    my $ts = \($self->{+STDERR_TS});

    return $self->_read_line('stderr', $fh, $ts);
}

sub _read_line {
    my $self = shift;
    my ($name, $fh, $ts) = @_;

    seek($fh,0,1); # Clear EOF
    while(my $line = <$fh>) {
        chomp($line);
        next unless $line;

        if ($line =~ m/^TEST2-SYNC:\s*(\S+)$/) {
            $$ts = $1;
            next;
        }

        return [$self->{+ID}, $name, $line, $$ts];
    }
}

sub maybe_open_for_read {
    my $file = shift;
    return unless -e $file;
    open(my $fh, '<', $file) or die "Could not open file '$file' for reading: $!";
    $fh->blocking(0);
    return $fh;
}

sub top {
    my $file = shift;

    open(my $fh, '<', $file) or die "Could not open file '$file': $!";
    chomp(my $out = <$fh>);
    close($fh);

    return $out;
}

sub stamp {
    my $file = shift;
    my @stat = stat($file);
    return $stat[9];
}

sub close_handles {
    my $self = shift;

    for my $attr (STDERR_FH(), STDOUT_FH(), EVENTS_FH()) {
        my $fh = $self->{$attr} or next;
        close($fh) or warn "Error closing handle: $!";
    }
}

1;
