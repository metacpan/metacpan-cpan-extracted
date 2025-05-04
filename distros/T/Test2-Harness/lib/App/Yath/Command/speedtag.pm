package App::Yath::Command::speedtag;
use strict;
use warnings;

our $VERSION = '2.000005';

use Test2::Harness::Util qw/clean_path/;
use Test2::Harness::Util::File::JSONL;
use Test2::Harness::Util::File::JSON;

use Cwd qw/getcwd/;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase qw{
    <log_file
    <max_short
    <max_medium
};

use Getopt::Yath;
include_options(
    'App::Yath::Options::Yath',
);

option_group {group => 'speedtag', category => 'Speedtag Options'} => sub {
    option generate_durations_file => (
        type => 'Auto',
        alt  => ['durations', 'duration'],

        description => "Write out a duration json file, if no path is provided 'duration.json' will be used. The .json extension is added automatically if omitted.",

        long_examples => ['', '=/path/to/durations.json'],

        autofill => sub { clean_path('durations.json') },

        normalize => sub {
            my $val = shift;
            $val .= '.json' unless $val =~ m/\.json$/;
            return clean_path($val);
        },
    );

    option pretty => (
        type        => 'Bool',
        description => "Generate a pretty 'durations.json' file when combined with --generate-durations-file. (sorted and multilines)",
        default     => 0,
    );
};

sub group { 'log parsing' }

sub summary { "Tag tests with duration (short medium long) using a source log" }

sub cli_args { "[--] event_log.jsonl[.gz|.bz2] max_short_duration_seconds max_medium_duration_seconds" }

sub description {
    return <<"    EOT";
This command will read the test durations from a log and tag/retag all tests
from the log based on the max durations for each type.
    EOT
}

sub init {
    my $self = shift;

    $self->{+MAX_SHORT}  //= 15;
    $self->{+MAX_MEDIUM} //= 30;
}

sub run {
    my $self = shift;

    my $settings = $self->settings;
    my $args     = $self->args;

    shift @$args if @$args && $args->[0] eq '--';

    my $initial_dir = clean_path(getcwd());

    $self->{+LOG_FILE} = shift @$args or die "You must specify a log file";
    die "'$self->{+LOG_FILE}' is not a valid log file"       unless -f $self->{+LOG_FILE};
    die "'$self->{+LOG_FILE}' does not look like a log file" unless $self->{+LOG_FILE} =~ m/\.jsonl(\.(gz|bz2))?$/;

    $self->{+MAX_SHORT}  = shift @$args if @$args;
    $self->{+MAX_MEDIUM} = shift @$args if @$args;

    die "max short duration must be an integer, got '$self->{+MAX_SHORT}'"  unless $self->{+MAX_SHORT}  && $self->{+MAX_SHORT}  =~ m/^\d+$/;
    die "max short duration must be an integer, got '$self->{+MAX_MEDIUM}'" unless $self->{+MAX_MEDIUM} && $self->{+MAX_MEDIUM} =~ m/^\d+$/;

    my $stream = Test2::Harness::Util::File::JSONL->new(name => $self->{+LOG_FILE});

    my $durations_file = $self->settings->speedtag->generate_durations_file;
    my %durations;

    while (1) {
        my @events = $stream->poll(max => 1000) or last;

        for my $event (@events) {
            my $stamp  = $event->{stamp}      or next;
            my $job_id = $event->{job_id}     or next;
            my $f      = $event->{facet_data} or next;

            next unless $f->{harness_job_end};

            my $job = {};
            $job->{file} = clean_path($f->{harness_job_end}->{file})         if $f->{harness_job_end} && $f->{harness_job_end}->{file};
            $job->{time} = $f->{harness_job_end}->{times}->{totals}->{total} if $f->{harness_job_end} && $f->{harness_job_end}->{times};

            next unless $job->{file} && $job->{time};

            my $dur;
            if ($job->{time} < $self->{+MAX_SHORT}) {
                $dur = 'short';
            }
            elsif ($job->{time} < $self->{+MAX_MEDIUM}) {
                $dur = 'medium';
            }
            else {
                $dur = 'long';
            }

            my $fh;
            unless (open($fh, '<', $job->{file})) {
                warn "Could not open file $job->{file} for reading\n";
                next;
            }

            my @lines;
            my $injected;
            my ($old, $new);
            for my $line (<$fh>) {
                if ($line =~ m/^(\s*)#(\s*)HARNESS-(CAT(EGORY)?|DUR(ATION))-(LONG|MEDIUM|SHORT)$/i) {
                    next if $injected++;
                    $old  = $line;
                    $line = "${1}#${2}HARNESS-DURATION-" . uc($dur) . "\n";
                    $new  = $line;
                }
                push @lines => $line;
            }

            unless ($injected) {
                my $new_line = "# HARNESS-DURATION-" . uc($dur) . "\n";
                my @header;
                while (@lines && $lines[0] =~ m/^(#|use\s|package\s)/) {
                    push @header => shift @lines;
                }

                unshift @lines => (@header, $new_line);

                $old = "<NO TAG FOUND>";
                $new = $new_line;
            }

            close($fh);

            if ($durations_file) {
                my $tfile = $job->{file};
                $tfile =~ s{^\Q$initial_dir\E/+}{};
                $durations{$tfile} = uc($dur);
            }

            if ($settings->harness->dummy) {
                print "Would tag (dummy) file $job->{file} with duration '$dur'\n";
                chomp($old);
                chomp($new);
                print "Old Header: $old\nNew Header: $new\n\n";
                next;
            }

            unless (open($fh, '>', $job->{file})) {
                warn "Could not open file $job->{file} for writing\n";
                next;
            }

            print $fh @lines;
            close($fh);

            print "Tagged '$dur': $job->{file}\n";
        }
    }

    if ($durations_file) {
        my $jfile = Test2::Harness::Util::File::JSON->new(name => $durations_file, pretty => $self->settings->speedtag->pretty);
        $jfile->write(\%durations);
    }

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::speedtag - Tag tests with duration (short medium long) using a source log

=head1 DESCRIPTION

This command will read the test durations from a log and tag/retag all tests
from the log based on the max durations for each type.


=head1 USAGE

    $ yath [YATH OPTIONS] speedtag [COMMAND OPTIONS] [COMMAND ARGUMENTS]

=head2 OPTIONS

=head3 Harness Options

=over 4

=item -d

=item --dummy

=item --no-dummy

Dummy run, do not actually execute anything

Can also be set with the following environment variables: C<T2_HARNESS_DUMMY>

The following environment variables will be cleared after arguments are processed: C<T2_HARNESS_DUMMY>


=item --procname-prefix ARG

=item --procname-prefix=ARG

=item --no-procname-prefix

Add a prefix to all proc names (as seen by ps).

The following environment variables will be set after arguments are processed: C<T2_HARNESS_PROC_PREFIX>


=back

=head3 Speedtag Options

=over 4

=item --duration

=item --durations

=item --generate-durations-file

=item --duration=/path/to/durations.json

=item --durations=/path/to/durations.json

=item --generate-durations-file=/path/to/durations.json

=item --no-generate-durations-file

Write out a duration json file, if no path is provided 'duration.json' will be used. The .json extension is added automatically if omitted.


=item --pretty

=item --no-pretty

Generate a pretty 'durations.json' file when combined with --generate-durations-file. (sorted and multilines)


=back

=head3 Yath Options

=over 4

=item --base-dir ARG

=item --base-dir=ARG

=item --no-base-dir

Root directory for the project being tested (usually where .yath.rc lives)


=item -D

=item -Dlib

=item -Dlib

=item -D=lib

=item -D"lib/*"

=item --dev-lib

=item --dev-lib=lib

=item --dev-lib="lib/*"

=item --no-dev-lib

This is what you use if you are developing yath or yath plugins to make sure the yath script finds the local code instead of the installed versions of the same code. You can provide an argument (-Dfoo) to provide a custom path, or you can just use -D without and arg to add lib, blib/lib and blib/arch.

Note: This option can cause yath to use exec() to reload itself with the correct libraries in place. Each occurence of this argument can cause an additional exec() call. Use --dev-libs-verbose BEFORE any -D calls to see the exec() calls.

Note: Can be specified multiple times


=item --dev-libs-verbose

=item --no-dev-libs-verbose

Be verbose and announce that yath will re-exec in order to have the correct includes (normally yath will just call exec() quietly)


=item -h

=item -h=Group

=item --help

=item --help=Group

=item --no-help

exit after showing help information


=item -p key=val

=item -p=key=val

=item -pkey=value

=item -p '{"json":"hash"}'

=item -p='{"json":"hash"}'

=item -p:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -p :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -p=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugin key=val

=item --plugin=key=val

=item --plugins key=val

=item --plugins=key=val

=item --plugin '{"json":"hash"}'

=item --plugin='{"json":"hash"}'

=item --plugins '{"json":"hash"}'

=item --plugins='{"json":"hash"}'

=item --plugin :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugin=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugins :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugins=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-plugins

Load a yath plugin.

Note: Can be specified multiple times


=item --project ARG

=item --project=ARG

=item --project-name ARG

=item --project-name=ARG

=item --no-project

This lets you provide a label for your current project/codebase. This is best used in a .yath.rc file.


=item --scan-options key=val

=item --scan-options=key=val

=item --scan-options '{"json":"hash"}'

=item --scan-options='{"json":"hash"}'

=item --scan-options(?^:^--(no-)?(?^:scan-(.+))$)

=item --scan-options :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --scan-options=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-scan-options

=item /^--(no-)?scan-(.+)$/

Yath will normally scan plugins for options. Some commands scan other libraries (finders, resources, renderers, etc) for options. You can use this to disable all scanning, or selectively disable/enable some scanning.

Note: This is parsed early in the argument processing sequence, before options that may be earlier in your argument list.

Note: Can be specified multiple times


=item --show-opts

=item --show-opts=group

=item --no-show-opts

Exit after showing what yath thinks your options mean


=item --user ARG

=item --user=ARG

=item --no-user

Username to associate with logs, database entries, and yath servers.

Can also be set with the following environment variables: C<YATH_USER>, C<USER>


=item -V

=item --version

=item --no-version

Exit after showing a helpful usage message


=back


=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

