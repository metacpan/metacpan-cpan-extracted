package Test2::Harnes::Run::Job;
use strict;
use warnings;

use File::Spec;

use Carp qw/croak/;

use Time::HiRes qw/time/;

use Test2::Harness::Util::ActiveFile;

use Test2::Harness::Util qw/read_file write_file_atomic/;
use Test2::Harness::Util::JSON qw/decode_json encode_json/;

use Test2::Harness::HashBase qw{
    -id -dir -test_file -run -pid -start_stamp -end_stamp -exit
};

sub STDOUT_FILE()      { 'stdout' }         # STDOUT text
sub STDERR_FILE()      { 'stderr' }         # STDERR text
sub EVENTS_FILE()      { 'events.json' }    # Serialized events
sub MUXED_FILE()       { 'muxed' }          # Output from the 3 files above muxed together with time stamps
sub NAME_FILE()        { 'name' }           # test_file
sub PID_FILE()         { 'pid' }            # test pid
sub START_STAMP_FILE() { 'start_stamp' }    # When test started
sub END_STAMP_FILE()   { 'end_stamp' }      # When test started
sub EXIT_FILE()        { 'exit' }           # exit code for the script (written at end, not written if script exitis never observed)
sub ABOUT_FILE()       { 'about.json' }     # {name, pid, stamp, exit} (written at end)
sub RESULT_FILE()      { 'result.json' }    # Events post-processing, and a final pass/fail result

my %CACHE;

sub create {
    my $class = shift;
    my %params = @_;

    my $dir = $params{dir} or croak "'dir' is a required attribute";

    mkdir($dir) or die "Could not make directory '$dir': $!"
        unless -d $dir;

    my $self = $class->new(%params);

    write_file_atomic($self->path(NAME_FILE),        $self->{+TEST_FILE});
    write_file_atomic($self->path(PID_FILE),         $self->{+PID});
    write_file_atomic($self->path(START_STAMP_FILE), time());

    return $self;
}

sub load {
    my $self = shift;
    my ($dir) = @_;

    croak "'$dir' is not a valid job directory"
        unless $dir && -d $dir;


}

sub init {
    my $self = shift;

    croak "The 'id' attribute is required"          unless $self->{+ID};
    croak "The 'dir' attribute is required"         unless $self->{+DIR};
    croak "The 'pid' attribute is required"         unless $self->{+PID};
    croak "The 'test_file' attribute is required"   unless $self->{+TEST_FILE};
    croak "The 'start_stamp' attribute is required" unless $self->{+START_STAMP};
    croak "The 'run' attribute is required"         unless $self->{+RUN};
}

sub finish {
    my $self = shift;
    my ($exit) = @_;

    croak "Already finished"
        if grep { -e $self->path($_) } END_STAMP_FILE, EXIT_FILE, ABOUT_FILE;

    $self->{+EXIT} = $exit;
    my $end_stamp = $self->{+END_STAMP} = time();

    write_file_atomic($self->path(END_STAMP_FILE), $end_stamp);
    write_file_atomic($self->path(EXIT_FILE),      $exit);

    write_file_atomic(
        $self->path(ABOUT_FILE),
        encode_json(
            {
                id          => $self->{+ID},
                test_file   => $self->{+TEST_FILE},
                exit        => $exit,
                start_stamp => $self->{+START_STAMP},
                end_stamp   => $self->{+END_STAMP},
                pid         => $self->{+PID},
            }
        )
    );
}

sub path {
    my $self = shift;
    return $self->{+DIR} unless @_;
    File::Spec->catfile($self->{+DIR}, @_);
}


1;

__END__


sub RUN_FILE()     { 'run.json' }
sub JOBS_FILE()    { 'jobs.json' }
sub RUNNING_FILE() { 'running.json' }

my %CACHE;

sub create {
    my $class = shift;
    my %params = @_;

    my $dir = $params{dir} or croak "'dir' is a required attribute";

    mkdir($dir) or die "Could not make directory '$dir': $!"
        unless -d $dir;

    my $self = $class->new(%params);

    my $run_file = $self->path(RUN_FILE);
    my %config = map {( $_ => $self->{$_} )} grep { !m/^_/ } keys %$self;
    my $json = encode_json(\%config);
    write_file_atomic($run_file, $json);

    return $self;
}

sub load {
    my $class = shift;
    my ($dir) = @_;

    croak "$class\->load() requires a directory as the first argument"
        unless $dir && -d $dir;

    return $CACHE{$dir} ||= $class->new(%{$class->read_run_json($dir)}, dir => $dir);
}

sub read_run_json {
    my $proto = shift;
    my ($dir) = @_;

    $dir ||= $proto->{+DIR} if ref($proto);

    croak "no directory specified"
        unless $dir;

    my $run_file = File::Spec->catfile($dir, RUN_FILE);

    croak "Could not find " . RUN_FILE
        unless -f $run_file;

    my $json = read_file($run_file);
    return decode_json($json);
}

sub init {
    my $self = shift;

    croak "The 'id' attribute must be set, and must be a true value"
        unless $self->{+ID};

    croak "The 'dir' attribute is required"
        unless $self->{+DIR};

    croak "The '$self->{+DIR}' directory does not exist"
        unless -d $self->{+DIR};
}

sub first_job {
    my $self = shift;
    $self->{+_JOB} = 0;
    return $self->next_job;
}

sub next_job {
    my $self =shift;
    my $j = $self->{+_JOB};

    my $jobs = $self->job_data;

    return undef unless @$jobs > $j;
    my $job = $jobs->[$j];
    $self->{+_JOB}++;

    return Test2::Harness::Run::Job->load(
        id        => $job->{id},
        dir       => $self->path($job->id),
        test_file => $job->{test_file},
        run       => $self,
    );
}

sub finished {
    my $self = shift;
    return 0 unless $self->path(RUN_FILE);
    return 1 if -e $self->path(JOBS_FILE);
    return 0;
}

sub running {
    my $self = shift;
    return 0 unless -e $self->path(RUN_FILE);
    return 0 if -e $self->path(JOBS_FILE);
    return 1 if -e $self->path(RUNNING_FILE);
    return undef;
}

sub started {
    my $self = shift;
    return 1 if -e $self->path(RUN_FILE);
    return 0;
}

sub job_data {
    my $self = shift;
    return $self->{+_ALL_JOBS} if $self->{+_ALL_JOBS};

    my $all_file = $self->path(JOBS_FILE);
    if (-e $all_file) {
        my $json = read_file($all_file);
        return $self->{+_ALL_JOBS} = decode_json($json);
    }

    my $jobs = $self->{+_JOBS} ||= [];

    my $running = $self->{+_RUNNING} ||= Test2::Harness::Util::ActiveFile->maybe_open_file($self->path(RUNNING_FILE));
    return $jobs unless $running;

    while (my $line = $running->read_line) {
        push @$jobs => decode_json($line);
    }

    return $jobs;
}

1;
