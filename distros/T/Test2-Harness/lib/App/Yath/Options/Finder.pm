package App::Yath::Options::Finder;
use strict;
use warnings;

our $VERSION = '2.000005';

use Test2::Harness::Util qw/fqmod/;
use List::Util qw/first/;
use Getopt::Yath;

my %RERUN_MODES = (
    all     => "Re-Run all tests from a previous run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that.",
    failed  => "Re-Run failed tests from a previous run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that.",
    retried => "Re-Run retried tests from a previous run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that.",
    passed  => "Re-Run passed tests from a previous run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that.",
    missed  => "Run missed tests from a previously aborted/stopped run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that.",
);

option_group {group => 'finder', category => "Finder Options"} => sub {
    option class => (
        name    => 'finder',
        field   => 'class',
        type    => 'Scalar',
        default => 'App::Yath::Finder',

        mod_adds_options => 1,
        long_examples    => [' MyFinder', ' +App::Yath::Finder::MyFinder'],
        description      => 'Specify what Finder subclass to use when searching for files/processing the file list. Use the "+" prefix to specify a fully qualified namespace, otherwise App::Yath::Finder::XXX namespace is assumed.',

        normalize => sub { fqmod($_[0], 'App::Yath::Finder') },
    );

    option extensions => (
        type => 'List',
        alt  => ['ext', 'extension'],
        split_on => ',',

        description => 'Specify valid test filename extensions, default: t and t2',
        normalize   => sub { $_[0] =~ s/^\.+//g; $_[0] },
        default     => sub { qw/t t2/ },
    );

    option no_long => (
        type => 'Bool',

        description => "Do not run tests that have their duration flag set to 'LONG'",
    );

    option only_long => (
        type => 'Bool',

        description => "Only run tests that have their duration flag set to 'LONG'",
    );

    option show_changed_files => (
        type => 'Bool',

        description => "Print a list of changed files if any are found",
    );

    option changed_only => (
        type => 'Bool',

        description => "Only search for tests for changed files (Requires a coverage data source, also requires a list of changes either from the --changed option, or a plugin that implements changed_files() or changed_diff())",
    );

    option rerun => (
        type => 'Auto',

        description   => "Re-Run tests from a previous run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that.",
        long_examples => ['', '=path/to/log.jsonl', '=plugin_specific_string'],

        autofill => sub {
            my $log = first { -e $_ } qw{ ./lastlog.jsonl ./lastlog.jsonl.bz2 ./lastlog.jsonl.gz };
            return $log // -1;
        },
    );

    option rerun_plugins => (
        type => 'List',
        alt => ['rerun-plugin'],

        description   => "What plugin(s) should be used for rerun (will fallback to other plugins if the listed ones decline the value, this is just used to set an order of priority)",
        long_examples => [' Foo', ' +App::Yath::Plugin::Foo'],

        mod_adds_options => 1,
        normalize => sub { fqmod($_[0], 'App::Yath::Plugin') },
    );

    my $modes = join '|' => sort keys %RERUN_MODES;
    option rerun_modes => (
        type => 'BoolMap',

        default => sub { all => 1 },

        pattern => qr/rerun-($modes)(=.+)?/,

        long_examples => [' ' . join(',', sort keys %RERUN_MODES)],

        requires_arg => 1,

        normalize => sub {
            map { die "'$_' is not a valid run mode" unless $RERUN_MODES{$_}; $_ => 1 } split /[\s,]+/, $_[0];
        },

        description => join(" " => "Pick which test categories to run.", map { sprintf("%-8s %s", "$_:", $RERUN_MODES{$_}) } sort keys %RERUN_MODES),

        trigger => sub {
            my $opt = shift;
            my %params = @_;
            return unless $params{action} eq 'set';
            $params{settings}->finder->rerun(1) unless $params{settings}->finder->rerun;
        },

        custom_matches => sub {
            my $opt = shift;
            my ($input, $state) = @_;

            my $pattern = $opt->pattern;

            return unless $input =~ $pattern;

            my ($no, $key, $val) = ($1, $2, $3);

            if ($val) {
                $val =~ s/^=//;
                $state->{settings}->finder->rerun($val);
            }

            return ($opt, 1, [$key => $no ? 0 : 1]);
        },

        notes => "This will turn on the 'rerun' option. If the --rerun-MODE form is used, you can specify the log file with --rerun-MODE=logfile.",
    );

    option changed => (
        type          => 'PathList',
        split_on      => ',',
        description   => "Specify one or more files as having been changed.",
        long_examples => [' path/to/file'],
    );

    option changes_exclude_files => (
        alt           => ['changes-exclude-file'],
        type          => 'PathList',
        split_on      => ',',
        description   => 'Specify one or more files to ignore when looking at changes',
        long_examples => [' path/to/file'],
    );

    option changes_exclude_patterns => (
        alt           => ['changes-exclude-pattern'],
        type          => 'PathList',
        split_on      => ',',
        description   => 'Ignore files matching this pattern when looking for changes. Your pattern will be inserted unmodified into a `$file =~ m/$pattern/` check.',
        long_examples => [" '(apple|pear|orange)'"],
    );

    option changes_filter_files => (
        alt           => ['changes-filter-file'],
        type          => 'PathList',
        split_on      => ',',
        description   => 'Specify one or more files to check for changes. Changes to other files will be ignored',
        long_examples => [' path/to/file'],
    );

    option changes_filter_patterns => (
        alt           => ['changes-filter-pattern'],
        type          => 'List',
        split_on      => ',',
        description   => 'Specify a pattern for change checking. When only running tests for changed files this will limit which files are checked for changes. Only files that match this pattern will be checked. Your pattern will be inserted unmodified into a `$file =~ m/$pattern/` check.',
        long_examples => [" '(apple|pear|orange)'"],
    );

    option changes_diff => (
        type          => 'Scalar',
        description   => "Path to a diff file that should be used to find changed files for use with --changed-only. This must be in the same format as `git diff -W --minimal -U1000000`",
        long_examples => [' path/to/diff.diff'],
    );

    option changes_plugin => (
        type => 'Scalar',
        description => "What plugin should be used to detect changed files.",
        long_examples => [' Git', ' +App::Yath::Plugin::Git'],
    );

    option changes_include_whitespace => (
        type => 'Bool',
        description => "Include changed lines that are whitespace only (default: off)",
        default => 0,
    );

    option changes_exclude_nonsub => (
        type => 'Bool',
        description => "Exclude changes outside of subroutines (perl files only) (default: off)",
        default => 0,
    );

    option changes_exclude_loads => (
        type => 'Bool',
        description => "Exclude coverage tests which only load changed files, but never call code from them. (default: off)",
        default => 0,
    );

    option changes_exclude_opens => (
        type => 'Bool',
        description => "Exclude coverage tests which only open() changed files, but never call code from them. (default: off)",
        default => 0,
    );

    option durations => (
        type => 'Scalar',

        long_examples  => [' file.json', ' http://example.com/durations.json'],
        short_examples => [' file.json', ' http://example.com/durations.json'],

        description => "Point at a json file or url which has a hash of relative test filenames as keys, and 'SHORT', 'MEDIUM', or 'LONG' as values. This will override durations listed in the file headers. An exception will be thrown if the durations file or url does not work.",
    );

    option maybe_durations => (
        type => 'Scalar',

        long_examples  => [' file.json', ' http://example.com/durations.json'],
        short_examples => [' file.json', ' http://example.com/durations.json'],

        description => "Point at a json file or url which has a hash of relative test filenames as keys, and 'SHORT', 'MEDIUM', or 'LONG' as values. This will override durations listed in the file headers. An exception will be thrown if the durations file or url does not work.",
    );

    option durations_threshold => (
        type        => 'Scalar',
        alt         => ['Dt'],
        default     => 0,
        description => "Only fetch duration data if running at least this number of tests. Default: 0"
    );

    option exclude_files => (
        alt => ['exclude-file'],
        type  => 'PathList',
        field => 'exclude-files',

        long_examples  => [' t/nope.t'],
        short_examples => [' t/nope.t'],

        description => "Exclude a file from testing",
    );

    option exclude_patterns => (
        alt => ['exclude-pattern'],
        type  => 'List',
        field => 'exclude-patterns',

        long_examples  => [' nope'],
        short_examples => [' nope'],

        description => "Exclude a pattern from testing, matched using m/\$PATTERN/",
    );

    option exclude_lists => (
        alt  => ['exclude-list'],
        type => 'PathList',

        long_examples  => [' file.txt', ' http://example.com/exclusions.txt'],
        short_examples => [' file.txt', ' http://example.com/exclusions.txt'],

        description => "Point at a file or url which has a new line separated list of test file names to exclude from testing. Starting a line with a '#' will comment it out (for compatibility with Test2::Aggregate list files).",
    );

    option default_search => (
        type    => 'PathList',
        default => sub { './t', './t2', './test.pl' },

        description => "Specify the default file/dir search. defaults to './t', './t2', and 'test.pl'. The default search is only used if no files were specified at the command line",
    );

    option default_at_search => (
        type    => 'PathList',
        default => sub { './xt' },

        description => "Specify the default file/dir search when 'AUTHOR_TESTING' is set. Defaults to './xt'. The default AT search is only used if no files were specified at the command line",
    );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Options::Finder - FIXME

=head1 DESCRIPTION

=head1 PROVIDED OPTIONS

=head2 Finder Options

=over 4

=item --changed path/to/file

=item --no-changed

Specify one or more files as having been changed.

Note: Can be specified multiple times


=item --changed-only

=item --no-changed-only

Only search for tests for changed files (Requires a coverage data source, also requires a list of changes either from the --changed option, or a plugin that implements changed_files() or changed_diff())


=item --changes-diff path/to/diff.diff

=item --no-changes-diff

Path to a diff file that should be used to find changed files for use with --changed-only. This must be in the same format as `git diff -W --minimal -U1000000`


=item --changes-exclude-file path/to/file

=item --changes-exclude-files path/to/file

=item --no-changes-exclude-files

Specify one or more files to ignore when looking at changes

Note: Can be specified multiple times


=item --changes-exclude-loads

=item --no-changes-exclude-loads

Exclude coverage tests which only load changed files, but never call code from them. (default: off)


=item --changes-exclude-nonsub

=item --no-changes-exclude-nonsub

Exclude changes outside of subroutines (perl files only) (default: off)


=item --changes-exclude-opens

=item --no-changes-exclude-opens

Exclude coverage tests which only open() changed files, but never call code from them. (default: off)


=item --changes-exclude-pattern '(apple|pear|orange)'

=item --changes-exclude-patterns '(apple|pear|orange)'

=item --no-changes-exclude-patterns

Ignore files matching this pattern when looking for changes. Your pattern will be inserted unmodified into a `$file =~ m/$pattern/` check.

Note: Can be specified multiple times


=item --changes-filter-file path/to/file

=item --changes-filter-files path/to/file

=item --no-changes-filter-files

Specify one or more files to check for changes. Changes to other files will be ignored

Note: Can be specified multiple times


=item --changes-filter-pattern '(apple|pear|orange)'

=item --changes-filter-patterns '(apple|pear|orange)'

=item --no-changes-filter-patterns

Specify a pattern for change checking. When only running tests for changed files this will limit which files are checked for changes. Only files that match this pattern will be checked. Your pattern will be inserted unmodified into a `$file =~ m/$pattern/` check.

Note: Can be specified multiple times


=item --changes-include-whitespace

=item --no-changes-include-whitespace

Include changed lines that are whitespace only (default: off)


=item --changes-plugin Git

=item --changes-plugin +App::Yath::Plugin::Git

=item --no-changes-plugin

What plugin should be used to detect changed files.


=item --default-at-search ARG

=item --default-at-search=ARG

=item --default-at-search '*.*'

=item --default-at-search='*.*'

=item --default-at-search '["json","list"]'

=item --default-at-search='["json","list"]'

=item --default-at-search :{ ARG1 ARG2 ... }:

=item --default-at-search=:{ ARG1 ARG2 ... }:

=item --no-default-at-search

Specify the default file/dir search when 'AUTHOR_TESTING' is set. Defaults to './xt'. The default AT search is only used if no files were specified at the command line

Note: Can be specified multiple times


=item --default-search ARG

=item --default-search=ARG

=item --default-search '*.*'

=item --default-search='*.*'

=item --default-search '["json","list"]'

=item --default-search='["json","list"]'

=item --default-search :{ ARG1 ARG2 ... }:

=item --default-search=:{ ARG1 ARG2 ... }:

=item --no-default-search

Specify the default file/dir search. defaults to './t', './t2', and 'test.pl'. The default search is only used if no files were specified at the command line

Note: Can be specified multiple times


=item --durations file.json

=item --durations http://example.com/durations.json

=item --no-durations

Point at a json file or url which has a hash of relative test filenames as keys, and 'SHORT', 'MEDIUM', or 'LONG' as values. This will override durations listed in the file headers. An exception will be thrown if the durations file or url does not work.


=item --Dt ARG

=item --Dt=ARG

=item --durations-threshold ARG

=item --durations-threshold=ARG

=item --no-durations-threshold

Only fetch duration data if running at least this number of tests. Default: 0


=item --exclude-file t/nope.t

=item --exclude-files t/nope.t

=item --no-exclude-files

Exclude a file from testing

Note: Can be specified multiple times


=item --exclude-list file.txt

=item --exclude-lists file.txt

=item --exclude-list http://example.com/exclusions.txt

=item --exclude-lists http://example.com/exclusions.txt

=item --no-exclude-lists

Point at a file or url which has a new line separated list of test file names to exclude from testing. Starting a line with a '#' will comment it out (for compatibility with Test2::Aggregate list files).

Note: Can be specified multiple times


=item --exclude-pattern nope

=item --exclude-patterns nope

=item --no-exclude-patterns

Exclude a pattern from testing, matched using m/$PATTERN/

Note: Can be specified multiple times


=item --ext ARG

=item --ext=ARG

=item --extension ARG

=item --extension=ARG

=item --extensions ARG

=item --extensions=ARG

=item --ext '["json","list"]'

=item --ext='["json","list"]'

=item --ext :{ ARG1 ARG2 ... }:

=item --ext=:{ ARG1 ARG2 ... }:

=item --extension '["json","list"]'

=item --extension='["json","list"]'

=item --extensions '["json","list"]'

=item --extensions='["json","list"]'

=item --extension :{ ARG1 ARG2 ... }:

=item --extension=:{ ARG1 ARG2 ... }:

=item --extensions :{ ARG1 ARG2 ... }:

=item --extensions=:{ ARG1 ARG2 ... }:

=item --no-extensions

Specify valid test filename extensions, default: t and t2

Note: Can be specified multiple times


=item --finder MyFinder

=item --finder +App::Yath::Finder::MyFinder

=item --no-finder

Specify what Finder subclass to use when searching for files/processing the file list. Use the "+" prefix to specify a fully qualified namespace, otherwise App::Yath::Finder::XXX namespace is assumed.


=item --maybe-durations file.json

=item --maybe-durations http://example.com/durations.json

=item --no-maybe-durations

Point at a json file or url which has a hash of relative test filenames as keys, and 'SHORT', 'MEDIUM', or 'LONG' as values. This will override durations listed in the file headers. An exception will be thrown if the durations file or url does not work.


=item --no-long

=item --no-no-long

Do not run tests that have their duration flag set to 'LONG'


=item --only-long

=item --no-only-long

Only run tests that have their duration flag set to 'LONG'


=item --rerun

=item --rerun=path/to/log.jsonl

=item --rerun=plugin_specific_string

=item --no-rerun

Re-Run tests from a previous run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that.


=item --rerun-modes all,failed,missed,passed,retried

=item --no-rerun-modes

=item /^--(no-)?rerun-(all|failed|missed|passed|retried)(=.+)?$/

Pick which test categories to run. all:     Re-Run all tests from a previous run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that. failed:  Re-Run failed tests from a previous run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that. missed:  Run missed tests from a previously aborted/stopped run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that. passed:  Re-Run passed tests from a previous run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that. retried: Re-Run retried tests from a previous run from a log file (or last log file). Plugins can intercept this, such as the database plugin which will grab a run UUID and derive tests to re-run from that.

Note: This will turn on the 'rerun' option. If the --rerun-MODE form is used, you can specify the log file with --rerun-MODE=logfile.

Note: Can be specified multiple times


=item --rerun-plugin Foo

=item --rerun-plugins Foo

=item --rerun-plugin +App::Yath::Plugin::Foo

=item --rerun-plugins +App::Yath::Plugin::Foo

=item --no-rerun-plugins

What plugin(s) should be used for rerun (will fallback to other plugins if the listed ones decline the value, this is just used to set an order of priority)

Note: Can be specified multiple times


=item --show-changed-files

=item --no-show-changed-files

Print a list of changed files if any are found


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

