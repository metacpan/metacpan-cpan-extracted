package Test2::Plugin::Cover;
use strict;
use warnings;

use Test2::API qw/test2_add_callback_exit context/;
use Path::Tiny qw/path/;
use Scalar::Util qw/reftype/;
use Carp qw/croak carp/;
use File::Spec();

my $SEP = File::Spec->catfile('', '');

our $VERSION = '0.000028';

# Directly modifying this is a bad idea, but for the XS to work it needs to be
# a package var, not a lexical.
our $FROM = '*';
my $FROM_MODIFIED = 0;
my $FROM_MANAGER;

our ($ENABLED, $ROOT, $LOAD_ROOT, %REPORT, @OPENS, $TRACE_OPENS);
BEGIN {
    $TRACE_OPENS = 0;
    $ENABLED = 0;
    # realpath can die (deleted cwd), never let that kill the module load.
    $LOAD_ROOT = "" . (eval { path('.')->realpath } // eval { path('.')->absolute } // path('.'));
    $ROOT = $LOAD_ROOT;
}

my %FILTER;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;

my $IMPORTED = 0;
sub import {
    my $class = shift;
    my %params = @_;

    if ($params{disabled}) {
        $class->disable;
        return;
    }

    $class->enable;

    return if $params{no_event};

    if ($IMPORTED++) {
        croak "$class has already been imported, too late to add params" if keys %params;
        return;
    }

    $class->reload;

    my $ran = 0;
    $ROOT = "" . $params{root} if $params{root};

    # A failed report should not be able to break test teardown, losing the
    # coverage data (with a warning) is better than breaking the test.
    my $callback = sub {
        return if $ran++;
        local ($@, $!);
        eval { $class->report(%params, ctx => $_[0], root => $ROOT); 1 }
            or warn "$class could not send the coverage report: $@";
    };

    test2_add_callback_exit($callback);

    # Fallback if we fork.
    eval 'END { local $?; $callback->() }; 1'
        or carp "$class could not install the END block fallback, coverage may be lost in forked processes: $@";
}

sub reload {
    $ROOT = $LOAD_ROOT // "" . path('.')->realpath;
    %FILTER = map {-f $_ ? ($_ => 1) : ()} $0, __FILE__, File::Spec->rel2abs($0), File::Spec->rel2abs(__FILE__);
}

sub enabled { $ENABLED }
sub enable  { $ENABLED = 1 }
sub disable { $ENABLED = 0 }

sub full_reset {
    reset_from();
    reset_coverage();
}

sub reset_from {
    $FROM = '*';
    $FROM_MODIFIED = 0;
    $FROM_MANAGER = undef;
}

sub reset_coverage {
    %REPORT  = ();
}

sub set_root { $ROOT = "" . pop };

sub get_from   { $FROM //= '*' }
sub set_from   { my $from = pop; return unless _validate_from($from); $FROM_MODIFIED++; $FROM = $from }
sub clear_from { $FROM = '*' }
sub was_from_modified { $FROM_MODIFIED ? 1 : 0 }
sub set_from_manager  { $FROM_MODIFIED++; $FROM_MANAGER = pop }

# 'from' values end up serialized into the coverage event, catch things here
# that cannot survive that. This warns and rejects instead of dying, coverage
# collection should never introduce new exceptions into the code it is
# observing, we just collect what data we can.
sub _validate_from {
    my ($val, $seen) = @_;
    return 1 unless ref $val;

    my $type = reftype($val) // '';
    if ($type eq 'CODE' || $type eq 'GLOB') {
        carp "'from' values must be serializable, they may not be (or contain) $type references, ignoring this 'from' value";
        return 0;
    }

    $seen //= {};
    return 1 if $seen->{"$val"}++;

    if ($type eq 'HASH') {
        for my $v (values %$val) { return 0 unless _validate_from($v, $seen) }
    }
    elsif ($type eq 'ARRAY') {
        for my $v (@$val) { return 0 unless _validate_from($v, $seen) }
    }
    elsif ($type eq 'SCALAR' || $type eq 'REF') {
        return 0 unless _validate_from($$val, $seen);
    }

    return 1;
}

sub touch_data_file {
    my $class = shift;
    my ($file, $from) = @_;
    croak "A file is required" unless $file;
    return unless $ENABLED;
    $from //= $FROM;

    $REPORT{$file}{'<>'}{$from} = $from;
    return;
}

sub touch_source_file {
    my $class = shift;
    my ($file, $subs, $from) = @_;
    croak "A file is required" unless $file;
    return unless $ENABLED;

    $subs //= ['*'];
    $subs = [$subs] unless 'ARRAY' eq ref($subs);

    $from //= $FROM;

    $REPORT{$file}{$_}{$from} = $from for @$subs;

    return;
}

sub filter {
    my $class = shift;
    my ($file, %params) = @_;

    my $root = path($params{root} // '.');
    $root = $root->realpath if $root->exists;

    my $path = $INC{$file} ? path($INC{$file}) : path($file);
    $path = $path->realpath if $path->exists;

    # Compare the resolved path, not the raw input, so symlinked roots and
    # files resolve consistently with the relative() call below.
    return () unless $root->subsumes($path);

    return $path->relative($root)->stringify();
}

sub extract {
    my $class = shift;
    my ($file) = @_;

    # If we opened a file with 2-arg open
    $file =~ s/^[\+\-]?(?:>{1,2}|<|\|)[\+\-]?//;

    # Sometimes things get nested and we need to extract and then extract again...
    while (1) {
        # No hope :-(
        return if $file =~ m/^\(eval( \d+\)?)$/;

        # Easy
        return $file if -e $file;

        my $start = $file;

        # Moose like to write "blah blah (defined at filename line 123)"
        $file = $1 if $file =~ m/(?:defined|declared) (?:at|in) (.+) at line \d+/;
        $file = $1 if $file =~ m/(?:defined|declared) (?:at|in) (.+) line \d+/;
        $file = $1 if $file =~ m/\(eval \d+\)\[(.+):\d+\]/;
        $file = $1 if $file =~ m/\((.+)\) line \d+/;
        $file = $1 if $file =~ m/\((.+)\) at line \d+/;

        # Extracted everything away
        return unless $file;

        # Not going to change anymore
        last if $file eq $start;
    }

    # These characters are rare in file names, but common in calls where files
    # could not be determined, so we probably failed to extract. If this
    # assumption is wrong for someone they can write a custom extract, this is
    # not a bug.
    return if $file =~ m/([\[\]\(\)]|->|\beval\b)/;

    # If we have a foo.bar pattern, or a string that contains this platforms
    # file separator we will consider it a valid file.
    return $file if $file =~ m/\S+\.\S+$/i || $file =~ m/\Q$SEP\E/;

    return;
}

my %HIDDEN_SUBS = (
    '__ANON__'  => 1,
    'eval'      => 1,
);

my %SPECIAL_SUBS = (
    'BEGIN'     => 1,
    'CHECK'     => 1,
    'END'       => 1,
    'INIT'      => 1,
    'UNITCHECK' => 1,
);

sub files {
    my $class = shift;
    my %params = @_;

    my $report = $class->_process(%params);

    return [sort keys %$report];
}

sub data {
    my $class = shift;
    my %params = @_;

    my $report = $class->_process(%params);

    my $out = {};

    for my $file (keys %$report) {
        my $rval = $report->{$file} // next;
        my $oval = $out->{$file} = {};
        my %seen;

        for my $sub (keys %$rval) {
            next if $HIDDEN_SUBS{$sub};

            my $key = $SPECIAL_SUBS{$sub} ? '*' : $sub;
            push @{$oval->{$key}} => grep { !$seen{$key}{_from_key($_)}++ } values %{$rval->{$sub}};
        }

        @$_ = sort { _from_key($a) cmp _from_key($b) } @$_ for values %$oval;
    }

    return $out;
}

# Sort/dedup key for 'from' values. References are keyed by serialized
# content, not address, so output order is stable between runs and
# identical structures from separate set_from() calls collapse into one.
sub _from_key {
    my ($val) = @_;
    return "s:$val" unless ref $val;

    require Data::Dumper;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;

    return "r:" . Data::Dumper::Dumper($val);
}

sub report {
    my $class = shift;
    my %params = @_;

    my $data    = $class->data(%params);
    my $details = "This test covered " . scalar(keys %$data) . " source files.";
    my $type    = $FROM_MODIFIED ? 'split' : 'flat';

    my $ctx   = $params{ctx} // context();
    my $event = $ctx->send_ev2(
        about => {package => __PACKAGE__, details => $details},

        coverage => {
            files        => $data,
            details      => $details,
            test_type    => $type,
            from_manager => $FROM_MANAGER,
        },

        info => [{tag => 'COVERAGE', details => $details, debug => $params{verbose}}],
    );
    $ctx->release unless $params{ctx};

    return $event;
}

sub _process {
    my $class = shift;
    my %params = @_;

    my $filter  = $class->can('filter');
    my $extract = $class->can('extract');

    my $clone = _clone_report();
    my %report;

    for my $raw (keys %$clone) {
        next unless $raw;
        next if $FILTER{$raw};

        # A single bad entry (custom extract/filter that dies, a file deleted
        # mid-processing, etc) must not cost us the rest of the report.
        my $file;
        unless (eval { $file = $class->$extract($raw, %params); 1 }) {
            warn "$class could not extract a filename from '$raw', skipping it: $@";
            next;
        }
        next unless defined $file;
        next if $FILTER{$file};

        my $path;
        unless (eval { $path = $class->$filter($file, %params); 1 }) {
            warn "$class could not filter '$file', skipping it: $@";
            next;
        }
        next unless defined $path;
        next if $FILTER{$path};

        my $from = $clone->{$raw};

        # Merge
        my $into = $report{$path} //= {};

        for my $sub (keys %$from) {
            my $src = $from->{$sub} or next;
            my $dst = $into->{$sub} //= {};
            %$dst = (%$dst, %$src);
        }
    }

    return \%report;
}

# Copy the fixed 3-level {file}{sub}{from_key} structure of %REPORT so later
# processing cannot modify the live data. The innermost 'from' values are
# intentionally shared, not cloned - they can be arbitrary user structures
# and cloning them (Storable) dies on things like code refs.
sub _clone_report {
    my %clone;

    for my $file (keys %REPORT) {
        my $subs = $REPORT{$file} or next;
        $clone{$file} = {map { ($_ => {%{$subs->{$_}}}) } keys %$subs};
    }

    return \%clone;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::Cover - Fast and Minimal file coverage info.

=head1 DESCRIPTION

This plugin will collect minimal file coverage info, and will do so with
minimal performance impact.

Every time a subroutine is called this tool will do its best to find the
filename the subroutine was defined in, and add it to a list. Also, anytime you
attempt to open a file with C<open()> or C<sysopen()> the file will be added to
the list. This list will be attached to a test2 event just before the test
exits. In most formatters the event will only show up as a comment on STDOUT
C< # This test covered N source files. >. However tools such as
L<Test2::Harness::UI> can make full use of the coverage information contained
in the event.

=head1 INTENDED USE CASE

This tool is not intended to record comprehensive coverage information, if you
want that use L<Devel::Cover>.

This tool is intended to obtain and maintain lists of files that were opened,
or which define subs which were executed by any given test. This information is
useful if you want to determine what test files to run after any given code
change.

The collected coverage data is contained in test2 events, if you use
L<Test2::Harness> aka C<yath> then this data can be logged and consumed by
other tools such as L<Test2::Harness::UI>.

=head1 PERFORMANCE

Unlike tools that need to record comprehensive coverage (L<Devel::Cover>), This
module is only concerned about what files you open, or defined subs executed
directly or indirectly by a given test file. As a result this module can get
away with a tiny bit of XS code that only fires when a subroutine is called.
Most coverage tools fire off XS for every statement.

=head1 LIMITATIONS

This tool uses XS to inject a little bit of C code that runs every time a
subroutine is called, or every time C<open()> or C<sysopen()> is called. This C
code obtains the next op that will be run and tries to pull the filename from
it. C<eval>, XS, Moose, and other magic can sometimes mask the filename, this
module only makes a minimal attempt to find the filename in these cases.

Originally this module only collected the filenames touched by a test. Now in
addition to that data it can give you separate lists of files where subs were
called, and files that were touched via open(). Additionally the sub list
includes the info about what subs were called. In all of these cases it is also
possible to know what sections of your test called the subs or opened the
files.

=head2 THINGS THAT WILL NOT SHOW UP

=over 4

=item goto

C<goto &sub> does not enter the sub the normal way, the target sub (and its
file, if different) will not be recorded. The sub doing the C<goto> is
recorded normally.

=item constants

Constants created with C<use constant>, and any other subs inlined at compile
time, never trigger a runtime sub call, so the file defining them will not be
recorded unless something else in it is called.

=item XS subs

XS subs have no perl source file. Calls to them are recorded against the file
of the next perl statement that executes, which is usually the caller's file.

=item threads

Coverage data is collected per-thread and is not merged. Data collected inside
spawned ithreads is lost unless you merge it yourself.

=item exotic open() forms

Only 2 and 3 argument C<open()> calls are recorded. The list form for piping
to programs (C<< open($fh, '-|', $prog, @args) >>) and 1-arg C<open()> are
ignored.

=back

=head2 REAL EXAMPLES

The following data was gathered using prove to run the full L<Moose> test suite:

    # Prove on its own
    Files=478, Tests=17326, 64 wallclock secs ( 1.62 usr  0.46 sys + 57.27 cusr  4.92 csys = 64.27 CPU)

    # Prove with Test2::Plugin::Cover (no coverage event)
    Files=478, Tests=17326, 67 wallclock secs ( 1.61 usr  0.46 sys + 60.98 cusr  5.31 csys = 68.36 CPU)

    # Prove with Devel::Cover
    Files=478, Tests=17324, 963 wallclock secs ( 2.39 usr  0.58 sys + 929.12 cusr 31.98 csys = 964.07 CPU)

I<no coverage event> - No report was generated. This was done to only measure
the effect of the XS that adds the data collection overhead, and not the cost
of the perl code that generates the report event at the end of every test.

The L<Moose> test suite was also run using L<Test2::Harness> aka C<yath>

    # Without Test2::Plugin::Cover
    Wall Time: 62.51 seconds CPU Time: 69.13 seconds (usr: 1.84s | sys: 0.08s | cusr: 60.77s | csys: 6.44s)

    # With Test2::Plugin::Cover (no coverage event)
    Wall Time: 75.46 seconds CPU Time: 82.00 seconds (usr: 1.96s | sys: 0.05s | cusr: 72.64s | csys: 7.35s)

As you can see, there is a performance hit, but it is fairly small, specially
compared to L<Devel::Cover>. This is not to say anything bad about
L<Devel::Cover> which is amazing, but a bad choice for the use case
L<Test2::Plugin::Cover> was written to address.

=head1 SYNOPSIS

=head2 INLINE

    use Test2::Plugin::Cover;

    ...

    # Arrayref of files covered so far
    my $covered_files = Test2::Plugin::Cover->files;

=head2 COMMAND LINE

You can tell prove to use the module this way:

    HARNESS_PERL_SWITCHES=-MTest2::Plugin::Cover prove ...

For yath:

    yath test --cover-files ...

=head2 SUPPRESS REPORT

You can suppress the final report (only collect data, do not send the Test2
event)

CLI:

    HARNESS_PERL_SWITCHES=-MTest2::Plugin::Cover=no_event,1 prove ...

INLINE:

    use Test2::Plugin::Cover no_event => 1;

=head1 KNOWING WHAT CALLED WHAT

If you use a system like L<Test::Class>, L<Test::Class::Moose>, or
L<Test2::Tools::Spec> then you divide your tests into subtests (or similar). In
these cases it would be nice to track what subtest (or equivalent) touched what
files.

There are 3 methods related to this, C<set_from()>, C<get_from()>, and
C<clear_from()> which you can use to manage this meta-data:

    subtest foo => sub {
        # Note, this is a simple string, but the 'from' data can also be a data
        # structure.
        Test2::Plugin::Cover->set_from("foo");

        # subroutine() from Some.pm will be recorded as having been called by 'foo'.
        Some::subroutine();

        Test2::Plugin::Cover->clear_from();
    };

Doing this manually for all blocks is not ideal, ideally you would hook your
tool, such as L<Test::Class> to call C<set_from()> and C<clear_from()> for you.
Adding such a hook is left as an exercise to the reader, and if you make one
for a popular tool please upload it to cpan and add a ticket or send an email
for me to link to it here.

Once you have these hooks in place the data will not only show files and subs
that were called, but what called them.

Please see the C<set_from()> documentation for details on values.

=head1 CLASS METHODS

=over 4

=item $class->touch_source_file($file)

=item $class->touch_source_file($file, $sub)

=item $class->touch_source_file($file, \@subs)

=item $class->touch_source_file($file, $subs, $from)

This can be used to manually add coverage data. The first argument is the
source file to be "touched" by coverage. The second argument is optional, and
may be either a subroutine name, or an arrayref of subroutine names. The third
argument is optional and can be used to override the default "from" value,
which is normally determined for you automatically.

If no subroutines are specified it will default to using '*', which means the
entire file is considered to be touched.

=item $class->touch_data_file($file)

=item $class->touch_data_file($file, $from)

This can be used to manually add coverage data. The first argument is the file
to be "touched" by coverage data. Optionally you can override the 'from' value
which is normally determined automatically.

This is the same as calling C<< $class->touch_source_file($file, '<>') >>.

Both touch methods are no-ops while coverage is disabled, see C<disable()>.

=item $class->enable()

=item $class->disable()

=item $bool = $class->enabled()

Toggle or check enabled status. When disabled no coverage is recorded.

=item $class->reload()

Reset filter if $0 or __FILE__ have changed. This is advanced usage, you will
probably never need this.

=item $val = $class->get_from()

Get the current 'from' value. The default is C<'*'> when nothing has set a from
value.

=item $class->set_from($val)

Set a 'from' value. This can be anything, a string, a hashref, etc. Be advised
though that it will usually be serialized to JSON, so make sure anything you
put in it will be serializable as json.

If the value is, or contains, a CODE or GLOB reference it cannot be
serialized into the final report, so a warning will be issued and the value
will be ignored (the previous 'from' value stays in effect). This is not
fatal because enabling coverage should never introduce new exceptions into
the code being observed.

=item $class->clear_from()

Resets the clear value to C<'*'>

=item $bool = $class->was_from_modified()

This will return true if anything has called C<set_from()> or
C<set_from_manager>. This can be reset back to false using C<reset_from()>,
which also clears the 'from' and 'from_manager' values.

=item $class->set_from_manager($module)

This should be set to a module that implements the following method:

    sub test_parameters {
        my $class = shift;
        my ($test_file, \@from_values) = @_;

        ...

        return {
            # If true - run the test
            # If false - skip the test
            # If not present or undef - run the test
            run => $bool,

            # The following are optional
            argv  => [ ... ],
            env   => { ... },
            stdin => "...",
        };

        # OR
        # If true - run the test
        # If false - skip the test
        # If undef or empty list - run the test
        return $bool;
    }

This will be used by L<Test2::Harness> to determine what data needs to be
passed to a test given a set of 'from' values to instruct the test to run the
necessary parts/subtests/groups/methods/etc.

The 'argv' data will be prepended before any other arguments provided to the
test.

The 'env' hashref will be merged with any other env vars needed, with these
taking priority.

The 'stdin' string will be used as STDIN for the test.

=item $arrayref = $class->files()

=item $arrayref = $class->files(root => $path)

This will return an arrayref of all files touched so far.

The list of files will be sorted alphabetically, and duplicates will be
removed.

If a root path is provided it may be a L<Path::Tiny> instance or a plain
string. This path will be used to filter out any files not under the root
directory.

The running test file (C<$0>) and this plugin's own file are always excluded
from the results.

=item $hashref = $class->data()

=item $hashref = $class->data(root => $path)

This returns the processed coverage data that goes into the report event:

    {
        # Files where subs were called
        'lib/Foo.pm' => {
            some_sub => [ list of 'from' values that called it ],

            # Called BEGIN/END/etc blocks, or subs whose name could not be
            # determined, fall under '*'.
            '*' => [ ... ],
        },

        # Files opened with open()/sysopen(), or touched as data files
        'data.json' => { '<>' => [ ... ] },
    }

Duplicate 'from' values are removed (compared by content, not reference), and
each list is sorted deterministically. The C<root> parameter behaves as it
does in C<files()>.

=item $event = $class->report(%options)

This will send a Test2 event containing coverage information. It will also
return the event.

Options:

=over 4

=item root => Path::Tiny->new("...")

Normally this is set to the current directory at module load-time. This is used
to filter out any source files that do not live under the current directory.
This may be a L<Path::Tiny> instance or a plain string.

=item verbose => $BOOL

If this is set to true then the comment stating how many source files were
touched will be printed as a diagnostics message instead so that it shows up
without a verbose harness.

=item ctx => DO NOT USE

This is used ONLY when the L<Test2::API> is doing its final book-keeping. Most
users will never want to use this.

=back

=item $class->reset_coverage()

This will completely clear all coverage data so far.

=item $class->reset_from()

This will clear the 'from' value, as well as reset the 'was_from_modified'
state to false.

=item $class->full_reset()

Calls both C<reset_coverage()> and C<reset_from()>.

=item $file_or_undef = $class->filter($file)

=item $file_or_undef = $class->filter($file, root => Path::Tiny->new('...'))

This method is used as a callback when getting the final list of covered source
files. The default implementation removes any files that are not under the
current directory which lets you focus on files in the distribution you are
testing. You may return a modified filename if you wish to normalize it here,
the default implementation will turn it into a relative path.

If you provide a custom C<root> parameter, it may be a L<Path::Tiny> instance
or a plain string.

A custom filter callback should look something like this:

    sub {
        my $class = shift;
        my ($file, %params) = @_;

        # clean_filename() does not exist, it is just an example
        $file = clean_filename($file, %params);

        # should_show() does not exist, it is just an example
        return $file if should_show(%params);

        # Return undef or an empty list if you do NOT want to show the file.
        return;
    }

Please take a look at the source to see what and how C<filter()> is implemented
if you want all the details on how it works.

=item $file_or_undef = $class->extract($file)

=item $file_or_undef = $class->extract($file, %params)

This method is responsible for extracting a sensible filename from whatever the
XS found. Some magic such as C<eval> or L<Moose> can set the C<filename> to
strings like C<'(eval 123)'> or C<'foo bar (defined at FILE line LINE)'> or
even nonsensical strings, or text with no filenames.

If a sensible file name can be extracted it will be returned, otherwise undef
(or an empty list) is returned.

The default implementation does not use any parameters, but they are passed in
for custom implementations to use.

A custom extract callback should look something like this:

    sub {
        my $class = shift;
        my ($file, %params) = @_;

        # It is a valid file
        return $file if -e $file;

        # Do not use this, just an example
        return $1 if $file =~ m/($VALID_FILE_REGEX)/;

        # Cannot find a file here
        return;
    }

=back

=head1 TRACING OPENS

For debugging you can ask the plugin to record where every C<open()> and
C<sysopen()> call happened:

    $Test2::Plugin::Cover::TRACE_OPENS = 1;

Every recorded open will push an arrayref onto
C<@Test2::Plugin::Cover::OPENS>:

    [$filename, $file, $line, $package]

Where C<$filename> is what was being opened, and C<$file>, C<$line> and
C<$package> describe the code doing the open. This is a debugging aid only,
the data is not included in coverage events.

=head1 SEE ALSO

L<Devel::Cover> is by far the best and most complete coverage tool for perl. If
you need comprehensive coverage use L<Devel::Cover>. L<Test2::Plugin::Cover> is
only better for a limited use case.

=head1 SOURCE

The source code repository for Test2-Plugin-Cover can be found at
F<https://github.com/Test-More/Test2-Plugin-Cover>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

