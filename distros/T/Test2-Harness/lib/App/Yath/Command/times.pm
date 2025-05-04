package App::Yath::Command::times;
use strict;
use warnings;

our $VERSION = '2.000005';

use Test2::Util::Times qw/render_duration/;

use Test2::Harness::Util::File::JSONL;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase qw{
    <log_file
    <fields
};

use Getopt::Yath;
include_options(
    'App::Yath::Options::Yath',
);

sub summary { "Get times from a test log" }

sub group { 'log parsing' }

sub cli_args { "[--] event_log.jsonl[.gz|.bz2] [Field1] [Field2]" }

sub description {
    return <<"    EOT";
This command will consume the log of a previous run, and output all timing data
from shortest test to longest. You can specify a sort order by listing fields
in your desired order after the log file on the command line.
    EOT
}

my @NUMERIC = qw/total startup events cleanup/;
my %NUMERIC = map { $_ => 1 } @NUMERIC;

my @ALPHA = qw/file/;
my %ALPHA = map { $_ => 1 } @ALPHA;

my @FIELDS = (@NUMERIC, @ALPHA);
my %FIELDS = map { $_ => 1 } @FIELDS;

sub run {
    my $self = shift;

    my $args = $self->args;

    shift @$args if @$args && $args->[0] eq '--';

    $self->{+LOG_FILE} = shift @$args or die "You must specify a log file";
    die "'$self->{+LOG_FILE}' is not a valid log file" unless -f $self->{+LOG_FILE};
    die "'$self->{+LOG_FILE}' does not look like a log file" unless $self->{+LOG_FILE} =~ m/\.jsonl(\.(gz|bz2))?$/;

    my %seen;
    my @fields;
    for my $field (@$args, @FIELDS) {
        $field = lc($field);
        next if $seen{$field}++;
        die "'$field' is not a valid field\n" unless $FIELDS{$field};
        push @fields => $field;
    }

    $self->{+FIELDS} = \@fields;

    my $stream = Test2::Harness::Util::File::JSONL->new(name => $self->{+LOG_FILE});

    my @jobs;
    while (1) {
        my @events = $stream->poll(max => 1000) or last;

        for my $event (@events) {
            my $stamp  = $event->{stamp}      or next;
            my $job_id = $event->{job_id}     or next;
            my $f      = $event->{facet_data} or next;

            next unless $f->{harness_job_end};

            my $job = {};
            $job->{file} = $f->{harness_job_end}->{rel_file}        if $f->{harness_job_end} && $f->{harness_job_end}->{rel_file};
            $job->{time} = $f->{harness_job_end}->{times}->{totals} if $f->{harness_job_end} && $f->{harness_job_end}->{times};

            push @jobs => $job;
        }
    }

    my @rows;
    my $totals = {file => 'TOTAL'};

    @jobs = sort { $self->sort_compare($a, $b) } @jobs;

    for my $job (@jobs) {
        my $data = $job->{time};
        push @rows => $self->build_row({%$data, file => $job->{file}});
        $totals->{$_} += $data->{$_} for @NUMERIC;
    }

    push @rows => [map { '--' } @fields];
    push @rows => $self->build_row($totals);

    require Term::Table;
    my $table = Term::Table->new(
        header => [map { ucfirst($_) } @fields],
        rows   => \@rows,
    );

    print "$_\n" for $table->render;

    return 0;
}

sub build_row {
    my $self = shift;
    my ($data) = @_;

    return [map { $NUMERIC{$_} && defined($data->{$_}) ? render_duration($data->{$_}) : $data->{$_} } @{$self->{+FIELDS}}];
}

sub sort_compare {
    my $self = shift;
    my ($ja, $jb) = @_;

    my $order = $self->{+FIELDS};

    my $ta = $ja->{time};
    my $tb = $jb->{time};

    for my $field (@$order) {
        my $fa = $ta->{$field};
        my $fb = $tb->{$field};

        my $da = defined $fa;
        my $db = defined $fb;

        next unless $da || $db;
        return 1  if $da && !$db;
        return -1 if $db && !$da;

        my $delta = $ALPHA{$field} ? lc($fa) cmp lc($fb) : $fa <=> $fb;
        return $delta if $delta;
    }

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::times - Get times from a test log

=head1 DESCRIPTION

This command will consume the log of a previous run, and output all timing data
from shortest test to longest. You can specify a sort order by listing fields
in your desired order after the log file on the command line.


=head1 USAGE

    $ yath [YATH OPTIONS] times [COMMAND OPTIONS] [COMMAND ARGUMENTS]

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

