package App::Yath::Plugin::DB;
use strict;
use warnings;

our $VERSION = '2.000005';

use App::Yath::Schema::Util qw/schema_config_from_settings/;
use Test2::Harness::Util qw/mod2file/;
use Test2::Util::UUID qw/looks_like_uuid/;

use Getopt::Yath;
use parent 'App::Yath::Plugin';

include_options(
    'App::Yath::Options::DB',
    'App::Yath::Options::Publish',
    'App::Yath::Options::Yath',
);

option_group {group => 'db', prefix => 'db', category => "Database Options"} => sub {
    option coverage => (
        type => 'Bool',
        description => 'Pull coverage data directly from the database (default: off)',
        default => 0,
    );

    option durations => (
        type => 'Bool',
        description => 'Pull duration data directly from the database (default: off)',
        default => 0,
    );

    option duration_limit => (
        type => 'Scalar',
        description => 'Limit the number of runs to look at for durations data (default: 25)',
        default => 25,
    );

    option publisher => (
        type => 'Scalar',
        description => 'When using coverage or duration data, only use data uploaded by this user',
    );
};

#
# Plugin API implementations
#

sub get_coverage_tests {
    my ($plugin, $settings, $changes) = @_;

    my $db = $settings->check_group('db') or return;
    return unless $db->coverage;

    my $coverages = $plugin->get_coverage_rows($settings, $changes) or return;

    my $tests = $plugin->test_map_from_coverage_rows($coverages);

    return $plugin->search_entries_from_test_map($tests, $changes, $settings);
}

sub duration_data {
    my ($plugin, $settings) = @_;
    my $db = $settings->check_group('db') or return;
    return unless $db->durations;

    my $config  = schema_config_from_settings($settings);
    my $schema  = $config->schema;
    my $pname   = $settings->yath->project                              or die "--project is required.\n";
    my $project = $schema->resultset('Project')->find({name => $pname}) or die "Invalid project '$pname'.\n";

    my $out = $project->durations(user => $db->publisher, limit => $db->duration_limit);

    return $out;
}

sub grab_rerun {
    my $this = shift;
    my ($rerun, %params) = @_;

    return (0) if $rerun =~ m/\.jsonl(\.gz|\.bz2)?/;

    my $settings  = $params{settings};
    my $mode_hash = $params{mode_hash} //= {all => 1};

    my $config  = schema_config_from_settings($settings);
    my $schema  = $config->schema;

    my ($ok, $err, $run);
    if ($rerun eq '-1') {
        my $project_name = $settings->yath->project;
        my $username = $settings->yath->user // $ENV{USER};
        $ok = eval { $run = $schema->vague_run_search(query => {}, project_name => $project_name, username => $username); 1 };
        $err = $@;
    }
    else {
        $ok = eval { $run = $schema->vague_run_search(query => {}, source => $rerun); 1 };
        $err = $@;
    }

    unless ($run) {
        print $ok ? "No previous run found\n" : "Error getting rerun data from yath database: $err\n";
        return (1);
    }

    print "Re-Running " . join(', ', sort keys %$mode_hash) . " tests from run id: " . $run->run_id . "\n";

    my $data = $run->rerun_data;

    return (1, $data);
}

#
# The rest of these are implementation details
#

sub get_coverage_searches {
    my ($plugin, $settings, $changes) = @_;

    my ($changes_exclude_loads, $changes_exclude_opens);
    if ($settings->check_group('finder')) {
        my $finder = $settings->finder;
        $changes_exclude_loads = $finder->changes_exclude_loads;
        $changes_exclude_opens = $finder->changes_exclude_opens;
    }

    my @searches;
    for my $source_file (keys %$changes) {
        my $changed_sub_map = $changes->{$source_file};
        my @changed_subs = keys %$changed_sub_map;

        my $search = {'source_file.filename' => $source_file};
        unless ($changed_sub_map->{'*'} || !@changed_subs) {
            my %seen;

            my @inject;
            push @inject => '*'  unless $changes_exclude_loads;
            push @inject => '<>' unless $changes_exclude_opens;

            $search->{'source_sub.subname'} = {'IN' => [grep { !$seen{$_}++} @inject, @changed_subs]};
        }

        push @searches => $search;
    }

    return @searches;
}

sub get_coverage_rows {
    my ($plugin, $settings, $changes) = @_;

    my $db = $settings->check_group('db') or return;
    return unless $db->coverage;

    my $config  = schema_config_from_settings($settings);
    my $schema  = $config->schema;
    my $pname   = $settings->yath->project                              or die "--project is required.\n";
    my $project = $schema->resultset('Project')->find({name => $pname}) or die "Invalid project '$pname'.\n";
    my $run     = $project->last_covered_run(user => $db->publisher)   or return;

    my @searches = $plugin->get_coverage_searches($settings, $changes) or return;
    return $run->expanded_coverage({'-or' => \@searches});
}

my %CATEGORIES = (
    '*'  => 'loads',
    '<>' => 'opens',
);
sub test_map_from_coverage_rows {
    my ($plugin, $coverages) = @_;

    my %tests;
    while (my $cover = $coverages->next()) {
        my $test = $cover->test_filename or next;

        if (my $manager = $cover->manager_package) {
            unless ($tests{$test}) {
                if (eval { require(mod2file($manager)); 1 }) {
                    $tests{$test} = {manager => $manager, subs => [], loads => [], opens => []};
                }
                else {
                    warn "Error loading manager '$manager'. Running entire test '$test'.\nError:\n====\n$@\n====\n";
                    $tests{$test} = 0;
                    next;
                }
            }

            my $cat = $CATEGORIES{$cover->source_subname} // 'subs';
            push @{$tests{$test}->{$cat}} => @{$cover->metadata};
        }
        else {
            $tests{$test} //= 0;
        }
    }

    return \%tests;
}

sub search_entries_from_test_map {
    my ($plugin, $tests, $changes, $settings) = @_;

    my @out;
    for my $test (keys %$tests) {
        my $meta = $tests->{$test};
        my $manager = $meta ? delete $meta->{manager} : undef;

        unless ($meta && $manager) {
            push @out => $test;
            next;
        }

        unless (eval { push @out => [ $test, $manager->test_parameters($test, $meta, $changes, undef, $settings) ]; 1 }) {
            warn "Error processing coverage data for '$test' using manager '$manager'. Running entire test to be safe.\nError:\n====\n$@\n====\n";
            push @out => $test;
        }
    }

    return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Plugin::DB - FIXME

=head1 DESCRIPTION

=head1 PROVIDED OPTIONS

=head2 Database Options

=over 4

=item --db-config ARG

=item --db-config=ARG

=item --no-db-config

Module that implements 'MODULE->yath_db_config(%params)' which should return a App::Yath::Schema::Config instance.

Can also be set with the following environment variables: C<YATH_DB_CONFIG>


=item --db-coverage

=item --no-db-coverage

Pull coverage data directly from the database (default: off)


=item --db-driver Pg

=item --db-driver MySQL

=item --db-driver SQLite

=item --db-driver MariaDB

=item --db-driver Percona

=item --db-driver PostgreSQL

=item --no-db-driver

DBI Driver to use

Can also be set with the following environment variables: C<YATH_DB_DRIVER>


=item --db-dsn ARG

=item --db-dsn=ARG

=item --no-db-dsn

DSN to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_DSN>


=item --db-duration-limit ARG

=item --db-duration-limit=ARG

=item --no-db-duration-limit

Limit the number of runs to look at for durations data (default: 25)


=item --db-durations

=item --no-db-durations

Pull duration data directly from the database (default: off)


=item --db-host ARG

=item --db-host=ARG

=item --no-db-host

hostname to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_HOST>


=item --db-name ARG

=item --db-name=ARG

=item --no-db-name

Name of the database to use

Can also be set with the following environment variables: C<YATH_DB_NAME>


=item --db-pass ARG

=item --db-pass=ARG

=item --no-db-pass

Password to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_PASS>


=item --db-port ARG

=item --db-port=ARG

=item --no-db-port

port to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_PORT>


=item --db-publisher ARG

=item --db-publisher=ARG

=item --no-db-publisher

When using coverage or duration data, only use data uploaded by this user


=item --db-socket ARG

=item --db-socket=ARG

=item --no-db-socket

socket to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_SOCKET>


=item --db-user ARG

=item --db-user=ARG

=item --no-db-user

Username to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_USER>, C<USER>


=back

=head2 Harness Options

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

=head2 Publish Options

=over 4

=item --publish-buffer-size 100

=item --no-publish-buffer-size

Maximum number of events, coverage, or reporting items to buffer before flushing them (each has its own buffer of this size, and each job has its own event buffer of this size)


=item --publish-flush-interval 2

=item --publish-flush-interval 1.5

=item --no-publish-flush-interval

When buffering DB writes, force a flush when an event is recieved at least N seconds after the last flush.


=item --publish-force

=item --no-publish-force

If the run has already been published, override it. (Delete it, and publish again)


=item --publish-mode qvf

=item --publish-mode qvfd

=item --publish-mode summary

=item --publish-mode complete

=item --no-publish-mode

Set the upload mode (default 'qvfd')


=item --publish-retry

=item --publish-retry=COUNT

=item --no-publish-retry

How many times to retry an operation before giving up

Note: Can be specified multiple times, counter bumps each time it is used.


=item --publish-user ARG

=item --publish-user=ARG

=item --no-publish-user

User to publish results as


=back

=head2 Yath Options

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

