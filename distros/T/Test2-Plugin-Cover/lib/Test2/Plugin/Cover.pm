package Test2::Plugin::Cover;
use strict;
use warnings;

use Test2::API qw/test2_add_callback_exit context/;
use Path::Tiny qw/path/;
use Carp qw/croak/;
use File::Spec();

my $SEP = File::Spec->catfile('', '');

our $VERSION = '0.000018';

# Directly modifying this is a bad idea, but for the XS to work it needs to be
# a package var, not a lexical.
our $FROM = '*';
my $FROM_MODIFIED = 0;
my $FROM_MANAGER;

my $ROOT;

my %REPORT;
our @TOUCHED;
our @OPENED;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;

my $IMPORTED = 0;
sub import {
    my $class = shift;
    my %params = @_;

    return if $params{no_event};

    if ($IMPORTED++) {
        croak "$class has already been imported, too late to add params" if keys %params;
        return;
    }

    my $ran = 0;
    $ROOT = $params{root} if $params{root};
    $ROOT //= path('.')->realpath;
    my $callback = sub { return if $ran++; $class->report(%params, ctx => $_[0], root => $ROOT) };

    test2_add_callback_exit($callback);

    # Fallback if we fork.
    eval 'END { local $?; $callback->() }; 1' or die $@;
}

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
    @TOUCHED = ();
    @OPENED  = ();
    %REPORT  = ();
}

sub set_root { $ROOT = pop };

sub get_from   { $FROM }
sub set_from   { $FROM_MODIFIED++; $FROM = pop }
sub clear_from { $FROM = '*' }
sub was_from_modified { $FROM_MODIFIED ? 1 : 0 }
sub set_from_manager  { $FROM_MODIFIED++; $FROM_MANAGER = pop }

sub filter {
    my $class = shift;
    my ($file, %params) = @_;

    my $root = $params{root} // path('.')->realpath;

    my $path = $INC{$file} ? path($INC{$file}) : path($file);
    $path = $path->realpath if $path->exists;

    return () unless $root->subsumes($file);

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
    # file separator we will condifer it a valid file.
    return $file if $file =~ m/\S+\.\S+$/i || $file =~ m/\Q$SEP\E/;

    return;
}

my %FILTER = (
    $0 => 1,
    __FILE__, 1,
);

my %SPECIAL_SUBS = (
    '__ANON__'  => 1,
    'eval'      => 1,
    'BEGIN'     => 1,
    'CHECK'     => 1,
    'END'       => 1,
    'INIT'      => 1,
    'UNITCHECK' => 1,
);

sub _process {
    my $class = shift;
    my %params = @_;

    my $filter  = $class->can('filter');
    my $extract = $class->can('extract');

    my $seen  = $REPORT{_seen}  //= {files => {}, touched => {}, opened => {}};
    my $files = $REPORT{files} //= [];
    my $submap = $REPORT{submap} //= {};
    my $openmap = $REPORT{openmap} //= {};

    my @touched = @TOUCHED;
    my @opened  = @OPENED;

    my $changed = 0;
    my $handle_file = sub {
        my ($raw) = @_;
        return unless $raw;

        my $file = $class->$extract($raw, %params) // return;
        return if $FILTER{$file};

        my $path = $class->$filter($file, %params) // return;
        return if $FILTER{$path};

        unless ($seen->{files}->{$file}++) {
            push @$files => $path;
            $REPORT{sorted} = 0;
        }

        return $path;
    };

    while (my $touch = shift @touched) {
        my $path = $handle_file->($touch->{file}) or next;

        my $sub_name = $touch->{sub_name};

        my $fmap  = $submap->{$path} //= {};
        my $fseen = $seen->{touched}->{$path} //= {};

        my $fqsn;
        if ($sub_name && !$SPECIAL_SUBS{$sub_name}) {
            $fqsn = $sub_name;
        }
        else {
            $fqsn = '*';
        }

        my $smap  = $fmap->{$fqsn}  //= [];
        my $sseen = $fseen->{$fqsn} //= {};

        my $called_by = $touch->{called_by} // '*';
        push @$smap => $called_by unless $sseen->{$called_by}++;
    }

    for my $set (@opened) {
        my ($raw, $called_by) = @$set;
        my $path = $handle_file->($raw) // next;

        my $oseen = $seen->{opened}->{$path} //= {};

        $called_by //= '*';
        push @{$openmap->{$path}} => $called_by unless $oseen->{$called_by}++;
    }

    @TOUCHED = ();
    @OPENED = ();

    return \%REPORT;
}

sub _sort {
    my $class = shift;
    my %params = @_;

    $class->_process(%params) if @TOUCHED || @OPENED;
    return if $REPORT{sorted};

    @{$REPORT{files}} = sort @{$REPORT{files}};

    return;
}

sub files {
    my $class = shift;
    my %params = @_;

    $class->_process(%params) if @TOUCHED || @OPENED;
    $class->_sort(%params) unless $REPORT{sorted};

    return $REPORT{files};
}

sub submap {
    my $class = shift;
    my %params = @_;

    $class->_process(%params) if @TOUCHED || @OPENED;

    return $REPORT{submap};
}

sub openmap {
    my $class = shift;
    my %params = @_;

    $class->_process(%params) if @TOUCHED || @OPENED;

    return $REPORT{openmap};
}

sub report {
    my $class = shift;
    my %params = @_;

    $class->_process(%params) if @TOUCHED || @OPENED;
    $class->_sort(%params) unless $REPORT{sorted};

    my $files   = $REPORT{files};
    my $submap  = $REPORT{submap};
    my $openmap = $REPORT{openmap};
    my $type    = $FROM_MODIFIED ? 'split' : 'flat';

    my $details = "This test covered " . @$files . " source files.";

    my $ctx   = $params{ctx} // context();
    my $event = $ctx->send_ev2(
        about => {package => __PACKAGE__, details => $details},

        coverage => {
            files        => $files,
            submap       => $submap,
            openmap      => $openmap,
            details      => $details,
            test_type    => $type,
            from_manager => $FROM_MANAGER,
        },

        info => [{tag => 'COVERAGE', details => $details, debug => $params{verbose}}],

        harness_job_fields => [
            {name => "files_covered", details => $details, data => {files => $files, submap => $submap, openmap => $openmap}},
        ],
    );
    $ctx->release unless $params{ctx};

    return $event;
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
exits. In most formaters the event will only show up as a comment on STDOUT
C< # This test covered N source files. >. However tools such as
L<Test2::Harness::UI> can make full use of the coverage information contained
in the event.

=head2 NOTE: SYSOPEN HOOK DISABLED

The sysopen hook is currently disabled because of an unknown segv error on some
platforms. I am not certain if it will be enabled again. calls to subs, and
calls to open are still hooked.

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
addition to that data it can give you seperate lists of files where subs were
called, and files that were touched via open(). Additionally the sub list
includes the info about what subs were called. In all of these cases it is also
possible to know what secgtions of your test called the subs or opened the
files.

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

    # A mapping of what subs were called in which files
    my $subs_called = Test2::Plugin::Cover->submap;

    # A mapping of what files were opened, and where possible what section of
    # the test triggered the opening.
    my $openmap = Test2::Plugin::Cover->openmap;

=head2 COMMAND LINE

You can tell prove to use the module this way:

    HARNESS_PERL_SWITCHES=-MTest2::Plugin::Cover prove ...

For yath:

    yath test --cover-files ...

=head2 SUPPRESS REPORT

You can suppess the final report (only collect data, do not send the Test2
event)

CLI:

    HARNESS_PERL_SWITCHES=-MTest2::Plugin::Cover=no_event,1 prove ...

INLINE:

    use Test2::Plugin::Cover no_event => 1;

=head1 KNOWING WHAT CALLED WHAT

If you use a system like L<Test::Class>, L<Test::Class::Moose>, or
L<Test2::Tools::Spec> then you divide your tests into subtests (or similar). In
these cases it would be nice to track what subtest (or equivelent) touched what
files.

There are 3 methods telated to this, C<set_from()>, C<get_from()>, and
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
Adding such a hook is left as an exercide to the reader, and if you make one
for a popular tool please upload it to cpan and add a ticket or send an email
for me to link to it here.

Once you have these hooks in place the data will not only show files and subs
that were called, but what called them.

Please see the C<set_from()> documentation for details on values.

=head1 CLASS METHODS

=over 4

=item $val = $class->get_from()

Get the current 'from' value. The default is C<'*'> when nothing has set a from
value.

=item $class->set_from($val)

Set a 'from' value. This can be anything, a string, a hashref, etc. Be advised
though that it will usually be serialized to JSON, so make sure anything you
put in it will be serializable as json.

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

The 'argv' data will be prepended befor any other arguments provided to the
test.

The 'env' hashref will be merged with any other env vars needed, with these
taking priority.

The 'stdin' string will be used as STDIN for the test.

=item $arrayref = $class->files()

=item $arrayref = $class->files(root => $path)

This will return an arrayref of all files touched so far.

The list of files will be sorted alphabetically, and duplicates will be
removed.

If a root path is provided it B<MUST> be a L<Path::Tiny> instance. This path
will be used to filter out any files not under the root directory.

=item $hashref = $class->submap()

=item $hashref = $class->submap(root => $path)

Returns a structure like this:

    { Source => { subname => \@called_by }

Example:

    {
        'SomeModule.pm' => {
            # The wildcard is used when a proper sub name cannot be determined
            '*' => { ... },

            'subname' => [
                '*',     # The wildcard is used when no 'called by' can be determined
                $FROM_A,
                $FROM_B,
                ...
            ],
        },
        ...
    }

If a root path is provided it B<MUST> be a L<Path::Tiny> instance. This path
will be used to filter out any files not under the root directory.

=item $hashref = $class->openmap()

=item $hashref = $class->openmap(root => $path)

Returns a structure like this:

    {
        # the items in this list can be anything, strings, numbers,
        # data structures, etc.
        # A naive attempt is made to avoid duplicates in this list,
        # so the same string or reference will not appear twice, but 2
        # different references with identical contents may appear.
        "some_file.ext" => [
            '*',        # The wildcard is used when no 'called by' can be determined
            $FROM_A,
            $FROM_b,
        ],
    }

If a root path is provided it B<MUST> be a L<Path::Tiny> instance. This path
will be used to filter out any files not under the root directory.

=item $event = $class->report(%options)

This will send a Test2 event containing coverage information. It will also
return the event.

Options:

=over 4

=item root => Path::Tiny->new("...")

Normally this is set to the current directory at module load-time. This is used
to filter out any source files that do not live under the current directory.
This B<MUST> be a L<Path::Tiny> instance, passing a string will not work.

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

If you provide a custom C<root> parameter, it B<MUST> be a L<Path::Tiny>
instance, passing a string will not work.

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

