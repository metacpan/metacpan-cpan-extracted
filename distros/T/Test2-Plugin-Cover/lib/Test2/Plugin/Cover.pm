package Test2::Plugin::Cover;
use strict;
use warnings;

use Test2::API qw/test2_add_callback_exit context/;
use Path::Tiny qw/path/;
use Carp qw/croak/;
use File::Spec();

my $SEP = File::Spec->catfile('', '');

our $VERSION = '0.000009';

our %FILES;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

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
    my $root = path('.')->realpath;
    my $callback = sub { return if $ran++; $class->report(%params, ctx => $_[0], root => $root) };

    test2_add_callback_exit($callback);

    # Fallback if we fork.
    eval 'END { local $?; $callback->() }; 1' or die $@;
}

sub clear { %FILES = () }

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

sub files {
    my $class = shift;
    my %params = @_;

    my $filter  = $params{filter}  // $class->can('filter');
    my $extract = $params{extract} // $class->can('extract');

    my %seen = ($0 => 1);
    my @files = sort map { my $f = $class->$extract($_, %params); ($f && !$seen{$f}++) ? ($class->$filter($f, %params)) : () } keys %FILES;
    return \@files;
}

sub report {
    my $class = shift;
    my %params = @_;

    my $files = $class->files(%params);

    my $details = "This test covered " . @$files . " source files.";

    my $ctx = $params{ctx} // context();
    my $event = $ctx->send_ev2(
        about    => {package => __PACKAGE__, details => $details},
        coverage => {files => $files, details => $details},

        info => [{tag => 'COVERAGE', details => $details, debug => $params{verbose}}],

        harness_job_fields => [
            {name => "files_covered", details => $details, data => $files},
        ]
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

This tool DOES NOT cover anything beyond files in which subs executed by the
test were defined. If you want sub names, lines executed, and more, use
L<Devel::Cover>.

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

This also works for L<Test2::Harness> aka C<yath>, but yath may have a flag to
enable this for you by the time you are reading these docs.

=head2 SUPPRESS REPORT

You can suppess the final report (only collect data, do not send the Test2
event)

CLI:

    HARNESS_PERL_SWITCHES=-MTest2::Plugin::Cover=no_event,1 prove ...

INLINE:

    use Test2::Plugin::Cover no_event => 1;

=head1 CLASS METHODS

=over 4

=item $arrayref = $class->files()

=item $arrayref = $class->files(filter => \&filter, extract => \&extract)

This will return an arrayref of all files touched so far. If no C<filter> or
C<extract> callbacks are provided then C<< $class->filter() >> and
C<< $class->extract() >> will be used as defaults.

The list of files will be sorted alphabetically, and duplicates will be
removed.

Custom filter callbacks should match the interface for
C<< $class->filter() >>.

Custom extract callbacks should match the interface for
C<< $class->extract() >>.

=item $event = $class->report(%options)

This will send a Test2 event containing coverage information. It will also
return the event.

Options:

=over 4

=item root => Path::Tiny->new("...")

Normally this is set to the current directory at module load-time. This is used
to filter out any source files that do not live under the current directory.
This B<MUST> be a L<Path::Tiny> instance, passing a string will not work.

=item filter => sub { ... }

Normally C<< $class->filter() >> is used.

=item extract => sub { ... }

Normally C<< $class->extract() >> is used.

=item verbose => $BOOL

If this is set to true then the comment stating how many source files were
touched will be printed as a diagnostics message instead so that it shows up
without a verbose harness.

=item ctx => DO NOT USE

This is used ONLY when the L<Test2::API> is doing its final book-keeping. Most
users will never want to use this.

=back

=item $class->clear()

This will completely clear all coverage data so far.

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

