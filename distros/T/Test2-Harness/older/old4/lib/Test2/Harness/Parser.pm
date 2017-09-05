package Test2::Harness::Parser;
use strict;
use warnings;

use Carp qw/confess croak/;

use Test2::Event::Harness;
use Test2::Harness::Util qw/maybe_top_file file_stamp/;
use Test2::Harness::Util::ActiveFile;

use Test2::Harness::HashBase qw{
    -job_id -job_dir -harness
    -test_file
    -exit
    -stderr_fh -stdout_fh -events_fh
    -stderr_ln -stdout_ln -events_ln
};

sub init {
    my $self = shift;

    croak "'harness' is a required attribute" unless defined $self->{+HARNESS};
    croak "'job_id' is a required attribute" unless defined $self->{+JOB_ID};
    croak "'job_dir' is a required attribute" unless $self->{+JOB_DIR};

    $self->{+EVENTS_LN} = 0;
    $self->{+STDOUT_LN} = 0;
    $self->{+STDERR_LN} = 0;
}

sub poll {
    my $self = shift;

    return if defined $self->{+EXIT};

    my @events;

    my $job_dir = $self->{+JOB_DIR};

    unless ($self->{+TEST_FILE}) {
        my $job_file = File::Spec->catfile($job_dir, 'job');
        $self->{+TEST_FILE} = maybe_top_file($job_file) or return;
        chomp($self->{+TEST_FILE});
        push @events => Test2::Event::Harness->new(
            facet_data => {
                harness => {
                    details   => $self->{+TEST_FILE},
                    job_id    => $self->{+JOB_ID},
                    job_start => 1,
                    job_end   => 0,
                    stamp     => file_stamp($job_file),
                    source    => 'job',
                    line      => 1,
                },
                info => [
                    {
                        details => $self->{+TEST_FILE},
                        tag     => 'LAUNCH',
                        debug   => 0,
                    }
                ],
            },
        );
    }

    push @events => $self->_poll_streams;

    my $exit_file = File::Spec->catfile($job_dir, 'exit');
    $self->{+EXIT} = maybe_top_file($exit_file);
    if (defined $self->{+EXIT}) {
        chomp($self->{+EXIT});

        # Allow streams to send us any final lines that may not be newline
        # terminated
        $_->set_done(1) for grep {$_} @{$self}{STDOUT_FH(), STDERR_FH(), EVENTS_FH()};
        push @events => $self->_poll_streams;

        my $facet_data = {
            harness => {
                details   => $self->{+TEST_FILE},
                job_id    => $self->{+JOB_ID},
                job_start => 0,
                job_end   => 1,
                stamp     => file_stamp($exit_file),
                source    => 'exit',
                line      => 1,
                exit      => $self->{+EXIT},
            },
            info => [
                {
                    details => $self->{+TEST_FILE},
                    tag     => 'FINISH',
                    debug   => 0,
                },
            ],
        };

        $facet_data->{errors} = [{
            tag => 'EXIT',
            fail => 1,
            details => "Test returned $self->{+EXIT}",
        }] if $self->{+EXIT} != 0;

        push @events => Test2::Event::Harness->new(facet_data => $facet_data);
    }

    return @events;
}

sub _poll_streams {
    my $self = shift;

    my @events;

    push @events => $self->read_events_stream();
    push @events => $self->read_stdout_stream();
    push @events => $self->read_stderr_stream();

    return @events;
}

sub read_events_stream {
    my $self = shift;

    $self->{+EVENTS_FH} ||= Test2::Harness::Util::ActiveFile->maybe_open_file(
        File::Spec->catfile($self->{+JOB_DIR}, 'events'),
        done => defined $self->{+EXIT},
    ) or return;

    my @events;
    while (my $json = $self->{+EVENTS_FH}->read_line) {
        my $ln = ++($self->{+EVENTS_LN});
        my $event = Test2::Event::Harness->load_from_stream_line($self->{+JOB_ID}, $ln, $json);
        push @events => $event;
    }
    return @events;
}

sub read_stderr_stream {
    my $self = shift;

    $self->{+STDERR_FH} ||= Test2::Harness::Util::ActiveFile->maybe_open_file(
        File::Spec->catfile($self->{+JOB_DIR}, 'stderr'),
        done => defined $self->{+EXIT},
    ) or return;

    my @events;
    while (my $line = $self->{+STDERR_FH}->read_line) {
        my $ln = ++($self->{+STDERR_LN});

        my %harness_facet = (
            job_id => $self->{+JOB_ID},
            source => 'stderr',
            line   => $ln,
            raw    => $line,
        );

        if ($line =~ m/^\s*# /) {
            my $facet_data = $self->parse_tap_line($line);

            # Clarify this is a diag
            $facet_data->{info}->[0]->{debug} = 1;
            $facet_data->{info}->[0]->{tag} = 'DIAG';

            $facet_data->{harness} = {
                %harness_facet,
                %{$facet_data->{harness} || {}},
                source => 'stderr-tap',
                raw    => $line,
            };

            push @events => Test2::Event::Harness->new(facet_data => $facet_data);
        }
        else {
            push @events => Test2::Event::Harness->new_from_output($line, %harness_facet);
        }
    }
    return @events;
}

sub read_stdout_stream {
    my $self = shift;

    $self->{+STDOUT_FH} ||= Test2::Harness::Util::ActiveFile->maybe_open_file(
        File::Spec->catfile($self->{+JOB_DIR}, 'stdout'),
        done => defined $self->{+EXIT},
    ) or return;

    my @events;
    while (my $line = $self->{+STDOUT_FH}->read_line) {
        my $ln = ++($self->{+STDOUT_LN});

        my %harness_facet = (
            job_id => $self->{+JOB_ID},
            source => 'stdout',
            line   => $ln,
            raw    => $line,
        );

        if (my $facet_data = $self->parse_tap_line($line)) {
            $facet_data->{harness} = {
                %harness_facet,
                %{$facet_data->{harness} || {}},
                source => 'stdout-tap',
                raw    => $line,
            };
            push @events => Test2::Event::Harness->new(facet_data => $facet_data);
        }
        else {
            push @events => Test2::Event::Harness->new_from_output($line, %harness_facet);
        }
    }
    return @events;
}

sub parse_tap_line {
    my $self = shift;
    my ($line) = @_;

    my ($lead, $str) = ($line =~ m/^(\s+)(.+)$/) ? ($1, $2) : ('', $line);
    $lead =~ s/\t/    /g;
    my $nest = length($lead) / 4;

    my @types = qw/buffered_subtest comment plan bail version/;
    for my $type (@types) {
        my $sub = "parse_tap_$type";
        my $facet_data = $self->$sub($str) or next;
        $facet_data->{trace}->{nested} = $nest;
        return $facet_data;
    }

    return undef;
}

sub parse_tap_buffered_subtest {
    my $self = shift;
    my ($line) = @_;

    # End of a buffered subtest.
    return {parent => {}, harness => {subtest_end => 1}} if $line =~ m/^\}/;

    my $facet_data = $self->parse_tap_ok($line) or return undef;
    return $facet_data unless $line =~ /\s*\{\s*\)?\s*$/;

    $facet_data->{parent} = {
        details  => $facet_data->{assert}->{details},
    };
    $facet_data->{harness}->{subtest_start} = 1;

    return $facet_data;
}

sub parse_tap_ok {
    my $self = shift;
    my ($line) = @_;

    my ($pass, $todo, $skip, $num, @errors);

    return undef unless $line =~ s/^(not )?ok\b//;
    $pass = !$1;

    push @errors => "'ok' is not immediately followed by a space."
        if $line && !($line =~ m/^ /);

    if ($line =~ s/^(\s*)(\d+)\b//) {
        my $space = $1;
        $num = $2;

        push @errors => "Extra space after 'ok'"
            if length($space) > 1;
    }

    # Not strictly compliant, but compliant with what Test-Simple does...
    # Standard does not have a todo & skip.
    if ($line =~ s/#\s*(todo & skip|todo|skip)(.*)$//i) {
        my ($directive, $reason) = ($1, $2);

        push @errors => "No space before the '#' for the '$directive' directive."
            unless $line =~ s/\s+$//;

        push @errors => "No space between '$directive' directive and reason."
            if $reason && !($reason =~ s/^\s+//);

        $skip = $reason if $directive =~ m/skip/i;
        $todo = $reason if $directive =~ m/todo/i;
    }

    # Standard says that everything after the ok (except the number) is part of
    # the name. Most things add a dash between them, and I am deviating from
    # standards by stripping it and surrounding whitespace.
    $line =~ s/\s*-\s*//;

    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    my $is_subtest = ($line =~ s/^Subtest: (.+)$/$1/) ? 1 : 0;

    my $facet_data = {
        assert => {
            pass     => $pass,
            no_debug => 1,
            details  => $line,
        },
    };

    $facet_data->{parent} = {
        details => $line,
    } if $is_subtest;

    push @{$facet_data->{amnesty}} => {
        tag     => 'SKIP',
        details => $skip,
    } if defined $skip;

    push @{$facet_data->{amnesty}} => {
        tag     => 'TODO',
        details => $todo,
    } if defined $todo;

    push @{$facet_data->{info}} => {
        details => $_,
        debug => 1,
        tag => 'PARSER',
    } for @errors;

    return $facet_data;
}

sub parse_tap_version {
    my $self = shift;
    my ($line) = @_;

    return undef unless $line =~ s/^TAP version\s//;

    return {
        about => {
            details => $line,
        },
        info => [
            {
                tag     => 'INFO',
                debug   => 0,
                detauls => $line,
            }
        ],
    };
}

sub parse_tap_plan {
    my $self = shift;
    my ($line) = @_;

    return undef unless $line =~ s/^1\.\.(\d+)//;
    my $max = $1;

    my ($directive, $reason);

    if ($max == 0) {
        if ($line =~ s/^\s*#\s*//) {
            if ($line =~ s/^(skip)\S*\s*//i) {
                $directive = uc($1);
                $reason = $line;
                $line = "";
            }
        }

        $directive ||= "SKIP";
        $reason    ||= "no reason given";
    }

    my $facet_data = {
        plan => {
            count   => $max,
            skip    => ($directive && $directive eq 'SKIP') ? 1 : 0,
            details => $reason,
        }
    };

    push @{$facet_data->{info}} => {
        details => 'Extra characters after plan.',
        debug => 1,
        tag => 'PARSER',
    } if $line =~ m/\S/;

    return $facet_data;
}

sub parse_tap_bail {
    my $self = shift;
    my ($line) = @_;

    return undef unless $line =~ s/^Bail out!\s*//;

    return {
        control => {
            halt => 1,
            details => $line,
        }
    };
}

sub parse_tap_comment {
    my $self = shift;
    my ($line) = @_;

    return undef unless $line =~ m/^#/;

    $line =~ s/^#\s//;

    return {
        info => [
            {
                details => $line,
                tag     => 'NOTE',
                debug   => 0,
            }
        ]
    };
}

1;
