package App::Yath::Command::times;
use strict;
use warnings;

our $VERSION = '1.000038';

use Test2::Util::Times qw/render_duration/;

use Test2::Harness::Util::File::JSONL;

use App::Yath::Options;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase qw/-log_file <fields/;

include_options(
    'App::Yath::Options::Debug',
);

sub summary { "Get times from a test log" }

sub group { 'log' }

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

    $ yath [YATH OPTIONS] times [COMMAND OPTIONS]

=head2 YATH OPTIONS

=head3 Developer

=over 4

=item --dev-lib

=item --dev-lib=lib

=item -D

=item -D=lib

=item -Dlib

=item --no-dev-lib

Add paths to @INC before loading ANYTHING. This is what you use if you are developing yath or yath plugins to make sure the yath script finds the local code instead of the installed versions of the same code. You can provide an argument (-Dfoo) to provide a custom path, or you can just use -D without and arg to add lib, blib/lib and blib/arch.

Can be specified multiple times


=back

=head3 Environment

=over 4

=item --persist-dir ARG

=item --persist-dir=ARG

=item --no-persist-dir

Where to find persistence files.


=item --persist-file ARG

=item --persist-file=ARG

=item --pfile ARG

=item --pfile=ARG

=item --no-persist-file

Where to find the persistence file. The default is /{system-tempdir}/project-yath-persist.json. If no project is specified then it will fall back to the current directory. If the current directory is not writable it will default to /tmp/yath-persist.json which limits you to one persistent runner on your system.


=item --project ARG

=item --project=ARG

=item --project-name ARG

=item --project-name=ARG

=item --no-project

This lets you provide a label for your current project/codebase. This is best used in a .yath.rc file. This is necessary for a persistent runner.


=back

=head3 Help and Debugging

=over 4

=item --show-opts

=item --no-show-opts

Exit after showing what yath thinks your options mean


=item --version

=item -V

=item --no-version

Exit after showing a helpful usage message


=back

=head3 Plugins

=over 4

=item --no-scan-plugins

=item --no-no-scan-plugins

Normally yath scans for and loads all App::Yath::Plugin::* modules in order to bring in command-line options they may provide. This flag will disable that. This is useful if you have a naughty plugin that it loading other modules when it should not.


=item --plugins PLUGIN

=item --plugins +App::Yath::Plugin::PLUGIN

=item --plugins PLUGIN=arg1,arg2,...

=item --plugin PLUGIN

=item --plugin +App::Yath::Plugin::PLUGIN

=item --plugin PLUGIN=arg1,arg2,...

=item -pPLUGIN

=item --no-plugins

Load a yath plugin.

Can be specified multiple times


=back

=head2 COMMAND OPTIONS

=head3 Git Options

=over 4

=item --git-change-base master

=item --git-change-base HEAD^

=item --git-change-base df22abe4

=item --no-git-change-base

Find files changed by all commits in the current branch from most recent stopping when a commit is found that is also present in the history of the branch/commit specified as the change base.


=back

=head3 Help and Debugging

=over 4

=item --dummy

=item -d

=item --no-dummy

Dummy run, do not actually execute anything

Can also be set with the following environment variables: C<T2_HARNESS_DUMMY>


=item --help

=item -h

=item --no-help

exit after showing help information


=item --keep-dirs

=item --keep_dir

=item -k

=item --no-keep-dirs

Do not delete directories when done. This is useful if you want to inspect the directories used for various commands.


=back

=head3 YathUI Options

=over 4

=item --yathui-api-key ARG

=item --yathui-api-key=ARG

=item --no-yathui-api-key

Yath-UI API key. This is not necessary if your Yath-UI instance is set to single-user


=item --yathui-grace

=item --no-yathui-grace

If yath cannot connect to yath-ui it normally throws an error, use this to make it fail gracefully. You get a warning, but things keep going.


=item --yathui-long-duration 10

=item --no-yathui-long-duration

Minimum duration length (seconds) before a test goes from MEDIUM to LONG


=item --yathui-medium-duration 5

=item --no-yathui-medium-duration

Minimum duration length (seconds) before a test goes from SHORT to MEDIUM


=item --yathui-mode summary

=item --yathui-mode qvf

=item --yathui-mode qvfd

=item --yathui-mode complete

=item --no-yathui-mode

Set the upload mode (default 'qvfd')


=item --yathui-project ARG

=item --yathui-project=ARG

=item --no-yathui-project

The Yath-UI project for your test results


=item --yathui-retry

=item --no-yathui-retry

How many times to try an operation before giving up

Can be specified multiple times


=item --yathui-url http://my-yath-ui.com/...

=item --uri http://my-yath-ui.com/...

=item --no-yathui-url

Yath-UI url


=back

=head1 SOURCE

The source code repository for Test2-Harness can be found at
F<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

