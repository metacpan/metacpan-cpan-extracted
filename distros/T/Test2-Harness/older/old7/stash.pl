
__END__


use Test2::Harness::Run;
use Test2::Harness::Run::Worker;


print "TEMP DIR: $dir\n";

my $run = Test2::Harness::Run->new(
    id => 1,
    dir => $dir,
    job_count => 4,
    libs => ['./lib'],
    event_stream => 1,
    search => ['./t'],
    env_vars => { AAAA => 1 },
    preload => ['Scalar::Util'],
);

$run->save_config;

my $worker = Test2::Harness::Run::Worker->new(
    run => $run,
);

$worker->spawn;
while (!$worker->proc->complete) {
    local $| = 1;
    print ".";
    $worker->proc->wait(WNOHANG);
    sleep 0.2;
}
print "\n";
$run->save('run.json');

__END__


    $env->{HARNESS_IS_VERBOSE}    = $self->{+VERBOSE} || 0;
    $env->{T2_HARNESS_IS_VERBOSE} = $self->{+VERBOSE} || 0;



__END__
package Test2::Harness::Run;
use strict;
use warnings;

use File::Find();
use File::Spec();
use Test2::Harness::Worker::TestFile;
use Test2::Harness::Run::Job;
use Test2::Harness::Util::File::JSON;
use Test2::Harness::Util::File::JSONL;

use Test2::Util qw/IS_WIN32/;

use Carp qw/croak croak/;
use Scalar::Util qw/blessed/;

use Test2::Harness::Util::HashBase qw{
    -id
    -dir -data
    -_jobs -_jobs_file

    -job_count
    -switches
    -libs -lib -blib
    -preload

    -output_merging
    -event_stream

    -chdir
    -search
    -unsafe_inc

    -env_vars
};

my @CONFIG_KEYS = (
    ID(),
    JOB_COUNT(),
    SWITCHES(),
    LIBS(), LIB(), BLIB(),
    PRELOAD(),
    OUTPUT_MERGING(),
    EVENT_STREAM(),
    CHDIR(),
    SEARCH(),
    UNSAFE_INC(),
    ENV_VARS()
);

sub TO_JSON {
    my $self = shift;

    return {
        %{$self->config_data},

        jobs => [map { $_->TO_JSON } @{$self->jobs}],
        system_env_vars => {%ENV},
    };
}

sub config_data {
    my $self = shift;
    my %out = map { ($_ => $self->{$_}) } @CONFIG_KEYS;
    return \%out;
}

sub save {
    my $self = shift;
    my ($file, %params) = @_;
    my $run = Test2::Harness::Util::File::JSON->new(name => $file, %params);
    $run->write($self->TO_JSON);
}

sub save_config {
    my $self = shift;
    my $run = Test2::Harness::Util::File::JSON->new(name => $self->path('config.json'));
    $run->write($self->config_data);
}

sub load_config {
    my $self = shift;

    my $fh = Test2::Harness::Util::File::JSON->new(name => $self->path('config.json'));
    my $data = $fh->read;
    $self->{$_} = $data->{$_} for @CONFIG_KEYS;
}

sub init {
    my $self = shift;

    # Put this here, before loading data, loaded data means a replay without
    # actually running tests, this way we only die if we are starting a new run
    # on windows.
    croak "preload is not supported on windows"
        if IS_WIN32 && $self->{+PRELOAD};

    my $file;
    if (my $path = delete $self->{path}) {
        if (-f $path) {
            $file = $path;
        }
        elsif (-d $path) {
            $self->{+DIR} = $path;
        }
        else {
            croak "'$path' is not a valid file or directory";
        }
    }

    $file ||= delete $self->{file};

    if ($file) {
        my $run_file = Test2::Harness::Util::File::JSON->new(name => $file);
        $self->{+DATA} = $run_file->read;
    }

    $self->{+ID} ||= $self->{+DATA}->{id}
        if $self->{+DATA};

    croak "One of 'dir', 'data', 'file' or 'path' is required"
        unless $self->{+DIR} || $self->{+DATA};

    $self->load_config if delete $self->{load_config};

    croak "The 'id' attribute is required"
        unless $self->{+ID};

    $self->{+CHDIR}          ||= undef;
    $self->{+SEARCH}         ||= ['t'];
    $self->{+PRELOAD}        ||= undef;
    $self->{+SWITCHES}       ||= [];
    $self->{+LIBS}           ||= [];
    $self->{+LIB}            ||= 0;
    $self->{+BLIB}           ||= 0;
    $self->{+OUTPUT_MERGING} ||= 0;
    $self->{+JOB_COUNT}      ||= 1;

    $self->{+EVENT_STREAM} = 1 unless defined $self->{+EVENT_STREAM};

    unless(defined $self->{+UNSAFE_INC}) {
        if (defined $ENV{PERL_USE_UNSAFE_INC}) {
            $self->{+UNSAFE_INC} = $ENV{PERL_USE_UNSAFE_INC};
        }
        else {
            $self->{+UNSAFE_INC} = 1;
        }
    }

    my $env = $self->{+ENV_VARS} ||= {};
    $env->{PERL_USE_UNSAFE_INC} = $self->{+UNSAFE_INC} unless defined $env->{PERL_USE_UNSAFE_INC};

    $env->{T2_HARNESS_RUN_DIR} = $self->{+DIR} if $self->{+DIR};
    $env->{T2_HARNESS_RUN_ID}  = $self->{+ID};
    $env->{T2_HARNESS_JOBS}    = $self->{+JOB_COUNT};
    $env->{HARNESS_JOBS}       = $self->{+JOB_COUNT};
}

sub all_libs {
    my $self = shift;

    my @libs;

    push @libs => 'lib' if $self->{+LIB};
    push @libs => 'blib/lib', 'blib/arch' if $self->{+BLIB};
    push @libs => @{$self->{+LIBS}} if $self->{+LIBS};

    return @libs;
}

sub path {
    my $self = shift;
    croak "'path' only works when using a directory" unless $self->{+DIR};
    return $self->{+DIR} unless @_;
    return File::Spec->catfile($self->{+DIR}, @_);
}

sub jobs_file {
    my $self = shift;
    $self->{+_JOBS_FILE} ||= Test2::Harness::Util::File::JSONL->new(name => $self->path('jobs.jsonl'));
}

sub jobs {
    my $self = shift;

    return $self->{+_JOBS} ||= [map { Test2::Harness::Run::Job->new(data => $_) } @{$self->{+DATA}->{jobs}}]
        if $self->{+DATA};

    $self->poll_jobs;

    return $self->{+_JOBS};
}

sub poll_jobs {
    my $self = shift;

    # Return everything the first time, empty every other time
    if ($self->{+DATA}) {
        return if $self->{poll_jobs}++;
        return @{$self->jobs};
    }

    my $jobs = $self->{+_JOBS} ||= [];
    my $file = $self->jobs_file;

    my @new = map {
        my $id = $_->{id};
        my $dir = $self->path($id);
        Test2::Harness::Run::Job->new(%{$_}, dir => $dir);
    } $file->poll;

    push @$jobs => @new;
    return @new;
}

sub add_job {
    my $self = shift;
    my ($job) = @_;

    croak "'add_jobs' only works when using a directory"
        unless $self->{+DIR};

    $self->jobs_file->write({id => $job->id, test_file => $job->test_file});

    return $job;
}

sub find_tests {
    my $self  = shift;
    my $tests = $self->{+SEARCH};

    my (@files, @dirs);

    for my $item (@$tests) {
        push @files => Test2::Harness::Worker::TestFile->new(filename => $item) and next if -f $item;
        push @dirs  => $item and next if -d $item;
        die "'$item' does not appear to be either a file or a directory.\n";
    }

    my $curdir = File::Spec->curdir();
    CORE::chdir($self->{+CHDIR}) if $self->{+CHDIR};

    my $ok = eval {
        File::Find::find(
            sub {
                no warnings 'once';
                return unless -f $_ && m/\.t2?$/;
                push @files => Test2::Harness::Worker::TestFile->new(filename => $File::Find::name);
            },
            @dirs
        );
        1;
    };
    my $error = $@;

    CORE::chdir($curdir);

    die $error unless $ok;

    return sort { $a->filename cmp $b->filename } @files;
}

sub perl_command {
    my $self   = shift;
    my %params = @_;

    my @cmd = ($^X);

    my @libs;
    if ($params{include_harness_lib}) {
        require Test2::Harness;
        my $path = $INC{"Test2/Harness.pm"};
        $path =~ s{Test2/Harness\.pm$}{};
        $path = File::Spec->rel2abs($path);
        push @libs => $path;
    }

    push @libs => $self->all_libs;
    push @libs => @{$params{libs}}  if $params{libs};

    push @cmd => @{$self->{+SWITCHES}} if $self->{+SWITCHES};
    push @cmd => @{$params{switches}}  if $params{switches};

    push @cmd => map { "-I$_" } @libs;

    return @cmd;
}

1;

package Test2::Harness::Run::Job;
use strict;
use warnings;

use File::Spec;
use Test2::Harness::Event;
use Test2::Harness::Worker::TestFile;
use Test2::Harness::Util::File;
use Test2::Harness::Util::File::JSON;
use Test2::Harness::Util::File::JSONL;
use Test2::Harness::Util::File::Stream;
use Test2::Harness::Util::File::Value;

use Carp qw/croak croak/;
use Time::HiRes qw/time/;

use Test2::Harness::Util::HashBase qw{
    -dir -data -id -test_file -env_vars -_proc -test
    -_poll_ord
    -no_tmp
};

sub init {
    my $self = shift;

    my $file;
    if (my $path = delete $self->{path}) {
        if (-f $path) {
            $file = $path;
        }
        elsif (-d $path) {
            $self->{+DIR} = $path;
        }
        else {
            croak "'$path' is not a valid file or directory";
        }
    }

    $file ||= delete $self->{file};

    if ($file) {
        my $run_file = Test2::Harness::Util::File::JSON->new(name => File::Spec->catfile($file));
        $self->{+DATA} = $run_file->read;
    }

    croak "One of 'dir', 'data', 'file' or 'path' is required"
        unless $self->{+DIR} || $self->{+DATA};

    if ($self->{+DATA}) {
        $self->{+ID}        ||= $self->{+DATA}->{id};
        $self->{+TEST_FILE} ||= $self->{+DATA}->{test_file};
        $self->{+ENV_VARS}  ||= $self->{+DATA}->{env_vars};
    }

    croak "The 'id' attribute is required"
        unless $self->{+ID};

    croak "One of 'test_file' or 'test' must be specified"
        unless $self->{+TEST_FILE} || $self->{+TEST};

    $self->{+TEST_FILE} ||= $self->{+TEST}->filename;
    $self->{+TEST}      ||= Test2::Harness::Worker::TestFile->new(filename => $self->{+TEST_FILE});

    $self->{+ENV_VARS} ||= {};

    my $dir = $self->{+DIR};
    if ($dir && !$self->{+NO_TMP}) {
        my $tmp = File::Spec->catfile($self->{+DIR}, 'tmp');
        if (-d $tmp || mkdir($tmp)) {
            $self->{+ENV_VARS}->{TMP}      = $tmp;
            $self->{+ENV_VARS}->{TEMP}     = $tmp;
            $self->{+ENV_VARS}->{TMPDIR}   = $tmp;
            $self->{+ENV_VARS}->{TEMPDIR}  = $tmp;
        }
        else {
            warn "Could not create temp dir '$tmp': $!";
        }
    }
}

sub complete {
    my $self = shift;

    return 1 if $self->{+DATA};
    return 1 if $self->stop_stamp;
    return 1 if defined $self->exit;

    my $proc = $self->{+_PROC} or return undef;

    return 0 unless $proc->complete;

    $self->set_stop_stamp(time);
    $self->set_exit($proc->exit);

    return 1;
}

sub path {
    my $self = shift;
    croak "'path' only works when using a directory" unless $self->{+DIR};
    return $self->{+DIR} unless @_;
    return File::Spec->catfile($self->{+DIR}, @_);
}

sub events_file {
    my $self = shift;
    $self->{events_File} ||= Test2::Harness::Util::File::JSONL->new(name => $self->path('events.jsonl'));
}

sub _build_events {
    my $self = shift;
    my $ord_in  = shift;

    my $ord = ref($ord_in) ? $ord_in : \$ord_in;
    $$ord ||= 1;

    return map {
        Test2::Harness::Event->new(
            job        => $self,
            facet_data => $_->{facets},
            stamp      => $_->{stamp},
            from_line  => $_->{__FROM__},
            handle     => 'events',
            io_order   => $$ord++,
        );
    } @_;
}

sub events {
    my $self = shift;

    # Do not cache from file
    return $self->_build_events(1, $self->events_file->maybe_read)
        unless $self->{+DATA};

    # Ok to cache from data
    return @{$self->{events} ||= [$self->_build_events(1, @{$self->{+DATA}->{events} || []})]}
        if $self->{+DATA};
}

sub poll_events {
    my $self = shift;

    # Delegate to the file
    return $self->_build_events(\($self->{+_POLL_ORD}), $self->events_file->poll)
        unless $self->{+DATA};

    # Return everything the first time, nothing after that
    return if $self->{poll_events}++;
    return $self->events;
}

my %ATTRS = (
    stdout      => {file => 'stdout',      type => 'Test2::Harness::Util::File::Stream'},
    stderr      => {file => 'stderr',      type => 'Test2::Harness::Util::File::Stream'},
    muxed       => {file => 'muxed',       type => 'Test2::Harness::Util::File::JSONL'},
    pid         => {file => 'pid',         type => 'Test2::Harness::Util::File::Value'},
    start_stamp => {file => 'start_stamp', type => 'Test2::Harness::Util::File::Value'},
    stop_stamp  => {file => 'stop_stamp',  type => 'Test2::Harness::Util::File::Value'},
    exit        => {file => 'exit',        type => 'Test2::Harness::Util::File::Value'},
);

sub TO_JSON {
    my $self = shift;

    return $self->{+DATA}
        if $self->{+DATA};

    return {
        id        => $self->{+ID},
        test_file => $self->{+TEST_FILE},
        env_vars  => $self->{+ENV_VARS},
        events    => [$self->events_file->maybe_read],
        map { ($_ => $ATTRS{$_}->{type}->isa('Test2::Harness::Util::File::Stream') ? [$self->$_] : $self->$_) } keys %ATTRS,
    };
}

{
    my %SUBS;

    for my $attr (keys %ATTRS) {
        my $spec = $ATTRS{$attr};
        my $file = $spec->{file};
        my $type = $spec->{type};

        my $file_attr = "${attr}_file";

        $SUBS{$file_attr} = sub {
            my $self = shift;
            $self->{$file_attr} ||= $type->new(name => $self->path($file));
        };

        # This includes JSONL, which is a subclass of Stream
        if ($type->isa('Test2::Harness::Util::File::Stream')) {
            $SUBS{$attr} = sub {
                my $self = shift;

                if ($self->{+DATA}) {
                    return @{$self->{$attr}} if defined $self->{$attr};
                    return @{$self->{$attr} = $self->{+DATA}->{$attr} || []};
                }

                # Do not cache it
                return $self->$file_attr->maybe_read;
            };

            $SUBS{"poll_$attr"} = sub {
                my $self = shift;

                # Delegate to the file
                return $self->$file_attr->poll unless $self->{+DATA};

                # Return everything the first time, nothing after that
                return if $self->{"poll_$attr"}++;
                return $self->$attr;
            };
        }
        else {
            $SUBS{"set_$attr"} = sub {
                my $self = shift;
                my ($val) = @_;
                croak "Job is read only" if $self->{+DATA};

                $self->$file_attr->write($val);
                $self->{$attr} = $val;
            };

            $SUBS{$attr} = sub {
                my $self = shift;

                #cache it
                return $self->{$attr} if defined $self->{$attr};

                return $self->{$attr} = $self->{+DATA}->{$attr}
                    if $self->{+DATA};

                return $self->{$attr} = $self->$file_attr->maybe_read;
            };
        }
    }

    no strict 'refs';
    *{__PACKAGE__ . '::' . $_} = $SUBS{$_} for keys %SUBS;
}

sub proc { $_[0]->{+_PROC} }

sub set_proc {
    my $self = shift;
    my ($proc) = @_;

    $self->{+_PROC} = $proc;
    $self->set_pid($proc->pid);

    return $proc;
}

1;
package Test2::Harness;
use strict;
use warnings;


    my $dir = $self->{+DIR};
    if ($dir && !$self->{+NO_TMP}) {
        my $tmp = File::Spec->catfile($self->{+DIR}, 'tmp');
        if (-d $tmp || mkdir($tmp)) {
            $self->{+ENV_VARS}->{TMP}      = $tmp;
            $self->{+ENV_VARS}->{TEMP}     = $tmp;
            $self->{+ENV_VARS}->{TMPDIR}   = $tmp;
            $self->{+ENV_VARS}->{TEMPDIR}  = $tmp;
        }
        else {
            warn "Could not create temp dir '$tmp': $!";
        }
    }

use File::Find();
use File::Spec();
use Test2::Harness::Worker::TestFile;
use Test2::Harness::Run::Job;
use Test2::Harness::Util::File::JSON;
use Test2::Harness::Util::File::JSONL;


use Carp qw/croak confess/;
use Scalar::Util qw/blessed/;


sub perl_command {
    my $self   = shift;
    my %params = @_;

    my @cmd = ($^X);

    my @libs;
    if ($params{include_harness_lib}) {
        require Test2::Harness;
        my $path = $INC{"Test2/Harness.pm"};
        $path =~ s{Test2/Harness\.pm$}{};
        $path = File::Spec->rel2abs($path);
        push @libs => $path;
    }

    push @libs => $self->all_libs;
    push @libs => @{$params{libs}}  if $params{libs};

    push @cmd => @{$self->{+SWITCHES}} if $self->{+SWITCHES};
    push @cmd => @{$params{switches}}  if $params{switches};

    push @cmd => map { "-I$_" } @libs;

    return @cmd;
}


1;
