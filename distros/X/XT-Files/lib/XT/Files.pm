package XT::Files;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Class::Tiny 1;

use Role::Tiny::With ();

Role::Tiny::With::with 'XT::Files::Role::Logger';

use Carp           ();
use File::Basename ();
use File::Find     ();
use Module::Load   ();
use Scalar::Util   ();
use version 0.77 ();

use XT::Files::File;

use constant MODULE_NAME_RX => qr{ ^ [A-Za-z_] [0-9A-Za-z_]* (?: :: [0-9A-Za-z_]+ )* $ }xs;    ## no critic (RegularExpressions::RequireLineBoundaryMatching)

#
# CLASS METHODS
#

sub BUILD {
    my ( $self, $args ) = @_;

    $self->{_excludes} = [];
    $self->{_file}     = {};

    if ( exists $args->{'-config'} ) {
        if ( defined $args->{'-config'} ) {
            $self->_load_config( $args->{'-config'} );
        }

        # -config exists but is not defined, no configuration requested
    }
    else {
        # We did not get "config => undef" and therefore try to load the
        # default config file
        $self->_load_default_config();
    }

    return;
}

{
    # The XT::Files singleton
    my $xtf;

    sub initialize {
        my $class = shift;

        Carp::croak( __PACKAGE__ . q{ is already initialized} ) if $class->_is_initialized;

        $xtf = $class->new(@_);
        return $xtf;
    }

    sub instance {
        my ($class) = @_;

        if ( !$class->_is_initialized ) {

            # ignore args
            $class->initialize;
        }

        return $xtf;
    }

    sub _is_initialized {
        my ($class) = @_;

        return 1 if defined $xtf;
        return;
    }
}

#
# OBJECT METHODS
#

sub plugin {
    my ( $self, $plugin_name, $plugin_version, $keyvals_ref ) = @_;

    my $plugin_pkg = $self->_expand_config_plugin_name($plugin_name);

    Module::Load::load($plugin_pkg);

    if ( defined $plugin_version ) {
        $self->log_fatal("Not a valid version '$plugin_version'") if !version::is_lax($plugin_version);
        $self->log_fatal( "$plugin_pkg version $plugin_version required--this is only version " . $plugin_pkg->VERSION ) if version->parse( $plugin_pkg->VERSION ) < version->parse($plugin_version);
    }

    $self->log_fatal("$plugin_pkg doesn't have a run method") if !$plugin_pkg->can('run');
    $self->log_fatal("$plugin_pkg doesn't have a new method") if !$plugin_pkg->can('new');

    my $plugin = $plugin_pkg->new( xtf => $self );

    $plugin->run($keyvals_ref);

    return;
}

sub files {
    my ($self) = @_;

    my $exclude_regex;
    my @excludes = @{ $self->{_excludes} };
    if (@excludes) {
        $exclude_regex = join q{|}, @excludes;
    }

    my @result;
  RESULT_FILE:
    for my $name ( sort keys %{ $self->{_file} } ) {

        # skip ignored files
        next RESULT_FILE if !defined $self->{_file}->{$name};

        # skip excluded files
        next RESULT_FILE if defined $exclude_regex && File::Basename::fileparse($name) =~ $exclude_regex;

        # skip non-existing files
        next RESULT_FILE if !-e $name;

        push @result, $self->{_file}->{$name};
    }

    return @result;
}

#
# File
#

sub bin_file {
    my ( $self, $name ) = @_;

    my $file = XT::Files::File->new( name => $name, is_script => 1 );
    $self->file( $name, $file );
    return;
}

sub file {
    my ( $self, $name, $file ) = @_;

    if ( @_ > 2 ) {
        if ( defined $file ) {
            $self->log_fatal(q{File is not of class 'XT::Files::File'}) if !defined Scalar::Util::blessed($file) || !$file->isa('XT::Files::File');
        }

        $self->{_file}->{$name} = $file;
    }

    return $self->{_file}->{$name};
}

sub ignore_file {
    my ( $self, $name ) = @_;

    $self->file( $name, undef );
    return;
}

sub module_file {
    my ( $self, $name ) = @_;

    my $file = XT::Files::File->new( name => $name, is_module => 1 );
    $self->file( $name, $file );
    return;
}

sub pod_file {
    my ( $self, $name ) = @_;

    my $file = XT::Files::File->new( name => $name, is_pod => 1 );
    $self->file( $name, $file );
    return;
}

sub remove_file {
    my ( $self, $name ) = @_;

    delete $self->{_file}->{$name};
    return;
}

sub test_file {
    my ( $self, $name ) = @_;

    my $file = XT::Files::File->new( name => $name, is_test => 1, is_script => 1 );
    $self->file( $name, $file );
    return;
}

#
# Directory
#

sub bin_dir {
    my ( $self, $name ) = @_;

    for my $file ( $self->_find_new_files($name) ) {
        $self->bin_file( $file, $name );
    }

    return;
}

sub module_dir {
    my ( $self, $name ) = @_;

    for my $file ( $self->_find_new_files($name) ) {
        if ( $file =~ m{ [.] pm $ }xsm ) {
            $self->module_file( $file, $name );
        }
        elsif ( $file =~ m{ [.] pod $ }xsm ) {
            $self->pod_file( $file, $name );
        }
    }

    return;
}

sub test_dir {
    my ( $self, $name ) = @_;

    for my $file ( $self->_find_new_files($name) ) {
        if ( $file =~ m{ [.] t $ }xsm ) {
            $self->test_file( $file, $name );
        }
    }

    return;
}

#
# Excludes
#

sub exclude {
    my ( $self, $exclude ) = @_;

    push @{ $self->{_excludes} }, $exclude;
    return;
}

#
# PRIVATE METHODS
#

sub _expand_config_plugin_name {
    my ( $self, $plugin_name ) = @_;

    my $package_name = $plugin_name;
    if ( $package_name !~ s{ ^ = }{}xsm ) {
        $package_name = "XT::Files::Plugin::$plugin_name";
    }

    $self->log_fatal("'$plugin_name' is not a valid plugin name") if $package_name !~ MODULE_NAME_RX;

    return $package_name;
}

sub _find_new_files {
    my ( $self, $dir ) = @_;

    my @files;

    if ( !-d $dir ) {
        $self->log_debug("Directory $dir does not exist or is not a directory");
        return;
    }

    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if -l $File::Find::name || !-f _;
                push @files, $File::Find::name;
            },
        },
        $dir,
    );

    @files = grep { !exists $self->{_file}->{$_} } @files;

    return @files;
}

sub _global_keyval {    ## no critic  (Subroutines::RequireFinalReturn)
    my ( $self, $key, $value ) = @_;

    if ( $key eq ':version' ) {
        $self->log_fatal("Not a valid version '$value'") if !version::is_lax($value);
        $self->log_fatal( __PACKAGE__ . " version $value required--this is only version " . __PACKAGE__->VERSION ) if version->parse( __PACKAGE__->VERSION ) < version->parse($value);
        return;
    }

    $self->log_fatal("Invalid entry '$key = $value'");
}

sub _load_config {
    my ( $self, $config ) = @_;

    my $type_section = 1;
    my $type_keyval  = 2;

    open my $fh, '<', $config or $self->log_fatal("Cannot read file '$config': $!");

    my $in_global_section = 1;
    my @lines;
    my $line_counter = 0;
  LINE:
    while ( defined( my $line = <$fh> ) ) {
        $line_counter++;

        # skip empty lines or comment
        next LINE if $line =~ m{ ^ \s* (?: [#;] | $ ) }xsm;

        # remove leading whitespace
        $line =~ s{ ^ \s* }{}xsm;

        # remove tailing whitespace
        $line =~ s{ \s* $ }{}xsm;

        if ( $line =~ m{ ^ \[ }xsm ) {
            $self->log_fatal("Syntax error in config on line $line_counter") if $line !~ m{ ^ \[ ( .+ ) \] $ }xsm;
            my $section = $1;    ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)
            push @lines, [ $type_section, $line_counter, $section ];
            $in_global_section = 0;
            next LINE;
        }

        my ( $key, $value ) = split /\s*=\s*/xsm, $line, 2;
        $self->log_fatal("Syntax error in config on line $line_counter") if !defined $key || !defined $value || $key eq q{} || $value eq q{};
        #
        if ($in_global_section) {
            $self->_global_keyval( $key, $value );
            next LINE;
        }

        push @lines, [ $type_keyval, $line_counter, $key, $value ];
    }
    close $fh or $self->logger->log_fatal("Cannot read file '$config': $!");

    while (@lines) {
        my $section = ${ $lines[0] }[2];
        shift @lines;

        my @keyvals;
        my $plugin_version;

      LINE_KEYVAL:
        while (@lines) {
            last LINE_KEYVAL if $lines[0][0] == $type_section;

            if ( $lines[0][2] eq ':version' ) {
                $plugin_version = $lines[0][3];
            }
            else {
                push @keyvals, [ @{ $lines[0] }[ 2, 3 ] ];
            }

            shift @lines;
        }

        $self->plugin( $section, $plugin_version, \@keyvals );
    }

    return;
}

sub _load_default_config {
    my ($self) = @_;

    my $config;
  FILE:
    for my $file ( '.xtfilesrc', 'xtfiles.ini' ) {
        next FILE if !-e $file;
        $self->log_fatal("Multiple default config files found: '$config' and '$file'") if defined $config;
        $config = $file;
    }

    if ( !defined $config ) {
        my $default_config = '[Default]';
        $config = \$default_config;
    }

    return $self->_load_config($config);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XT::Files - standard interface for author tests to find files to check

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

In your distribution, add a C<XT::Files> configuration file (optional):

    [Default]
    dirs = 0

    [Dirs]
    bin = script
    module = lib
    test = t
    test = xt

In a C<.t> file (optional):

    use XT::Files;

    my $xt = XT::Files->initialize( -config => undef ));
    $xt->bin_dir('bin');
    $xt->module_dir('lib');
    $xt->test_dir('t');

In a C<Test> module (optional):

    use Test::XTFiles;

    my @files = Test::XTFiles->new->all_perl_files;

=head1 DESCRIPTION

Author tests often iterate over your distributions files to check them.
Unfortunately, every XT test uses its own code and defaults, to find the files
to check, which means they often don't fit the need of your distribution.
Common problems are not checking F<bin> or F<script> or, if they do, assuming
Perl files in F<bin> or F<script> end in C<.pl>.

The idea of C<XT::Files> is that it's the C<Test>s that know what they want
to check (e.g. module files), but it's the distribution that knows where
these files can be found (e.g. in the F<lib> directory and in the F<t/lib>
directory).

Without C<XT::Files> you are probably adding the same code to multiple F<.t>
files under F<xt> that iterate over a check function of the test.

C<XT::Files> is a standard interface that makes it easy for author tests to
ask the distribution for the kind of files it would like to test. And it can
easily be used for author tests that don't support C<XT::Files> to have the
same set of files tested with every test.

Note: This is for author tests only. Your own distributions tests already
know which files to test.

=head1 USAGE

=head2 Usage for distribution authors

The distribution can (and should) use an C<XT::Files> configuration file.
The default names for the file is either C<.xtfilesrc> or C<xtfiles.ini>
in the root directory of your distribution. Only one of these files must
exist. If you put it in a different location or name it differently, you
have to load it in every F<.t> file

    XT::Files->initialize( -config => 'maint/xt_files.txt' );

The config file contain a global section and a section for every used plugin.
Comments start with either C<#> or C<;>.

The same plugin can be run multiple times by adding multiple sections with
the same name. Sections of the same name are not merged.

    # require at least this version of XT::Files
    :version = 0.001

    # XT::Files::Plugin::Default
    # the default configuration plugin
    [Default]
    # add the default directories (this is the default)
    dirs = 1
    # add the default excludes (this is the default)
    excludes = 1

    # XT::Files::Plugin::Dirs
    # add directories with the bin_dir, module_dir or test_dir method
    # from XT::Files
    [Dirs]
    bin = maint
    module = maint/lib
    test = maint/t

    # XT::Files::Plugin::Files
    # add files with the bin_file, module_file or test_file method
    # from XT::Files
    [Files]
    bin = maint/config.pl
    pod = maint/contribute.pod
    module = maint/config.pm

    # XT::Files::Plugin::Excludes
    # add exclude patterns
    [Excludes]
    exclude = [.]old$

    # add a directory to @INC to load plugins contained in the distribution
    [lib]
    lib = maint/plugin

    # load a plugin from outside of the XT::Files::Plugin namesapce
    # this is most likely used to load a plugin contained in the distribution
    [=Local::MyPlugin]

The configuration is used to tell tests which files are what. A file can be
of the following types.

=over 4

=item * bin

These are executable Perl files. For most distributions they live in F<bin>
or F<script>. They might, or might not, have a C<.pl> extension. These files
might, or might not, contain a Pod documentation.

You can also add scripts in additional locations, e.g. in C<maint> to the
list of files to be tested with your author tests.

=item * module

These are Perl modules. For most distributions they live in the F<lib>
directory. Normally they have a C<.pm> extension. These files might, or might
not, contain a Pod documentation.

=item * pod

This is for Pod files. Normally they end in C<.pod>. Your scripts or modules
which contain Pod documentation are not of type pod.

=item * test

This is for test files. These files normally have a C<.t> extension. Test
files are also bin files.

=back

All file names should be in UNIX format (forward slashes as directory
separator) as all files found by C<XT::Files> are added in this way. If you
add a directory or file with a different directory separator the result
is undefined.

=head2 Usage for author test authors

Writing an author test with C<XT::Files> support is straightforward. All you
have to do is decide what kind of files your author test is going to test and
request these files from L<Test::XTFiles>:

    use Test::XTFiles;

    # all Perl scripts and tests
    my @files = Test::XTFiles->new->all_executable_files;

    # all modules
    my @files = Test::XTFiles->new->all_module_files;

    # all perl files (scripts, modules and tests)
    my @files = Test::XTFiles->new->all_perl_files;

    # all files with Pod in it
    use Pod::Simple::Search;
    my @files = grep { Pod::Simple::Search->new->contains_pod($_) }
        Test::XTFiles->new->all_files;

Don't try to be clever, that's the distributions job. Ask what makes sense to
test - it's the distributions fault if a file is not correctly classified. And
it's much easier for a distribution author to fix the distributions config
file then it is for the test author to guess correctly.

=head2 Methods from XT::Files

All file names passed to methods should be in UNIX format (forward slashes
as directory separator) as all files found by C<XT::Files> are added in this
way. If you add a directory with a different directory separator the result
is undefined.

=head2 new( [ -config => CONFIG ] )

Returns a new C<XT::Files> object.

Supports the C<-config> argument which needs one of the following arguments.

=over 4

=item * C<undef>: No configuration is loaded and the object is not initialized.
This can be useful if you would like to build up your configuration
programmatically.

=item * A file name: The file is C<open>ed and the configuration is read from
this file.

=item * A reference to a string: The configuration is read from this string.

=back

Note: This does neither create the C<XT::Files> singleton nor return it.
This is probably not what you want. Unless you know exactly why you need
a C<XT::Files> object that differs from the singleton you should use
C<initialize> or C<instance> which both create and return the singleton.

=head2 initialize ( [ -config => CONFIG ] )

Checks if the singleton exists and C<croak>s if it does. Otherwise calls
C<new> with the same arguments and saves the C<XT::Files> object returned
by C<new> in the singleton, before returning it.

This is most likely the initialization you should use in your F<.t> file if
you need the object.

    my $xt = XT::Files->initialize;
    $xt->bin_file('maint/cleanup.pl');

=head2 instance

Checks if the C<XT::Files> singleton exists and calls C<initialize> without
arguments if it does not. Then returns the singleton.

This method silently discards all arguments. If the singleton does not exist,
it will always use the default configuration which is the C<XT::Files> config
file or, if that does not exist, the L<XT::Files::Plugin::Default> plugin.

This is the method that is called by L<Test::XTFiles>'s C<new> method.

=head2 files

Returns all files to be tested as L<XT::Files::File> objects.

You should probably use one or multiple of the methods of L<Test::XTFiles>
if you need to obtain a list of files to be tested, either in a C<Test>
test or in a F<.t> test file.

=head2 exclude( PATTERN )

Adds an exclude pattern. The C<files> method tries to match the basename of
every file against these patterns and skips the file if it matches.

Use this to exclude temporary or backup files you have in your workspace.

=head2 bin_dir( DIRECTORY )

Scans the directory for files and adds them all as executable files. Files
that already have an entry are skipped.

There are no further checks that every file in the directory is a Perl
script. Use this method to add directories like F<bin> or F<script>.

If you have a directory that contains Perl scripts and other files, add them
selectively with C<bin_file> from within your F<.t> test file or use the
L<XT::Files::Plugin::Files> plugin from your configuration file.

=head2 module_dir( DIRECTORY )

Scans the directory for files and adds all files ending in F<.pm> as module
file and every file ending in F<.pod> as pod file. Other files are skipped.
Files that already have an entry are skipped.

=head2 test_dir( DIRECTORY )

Scans the directory for files and adds all files anding in F<.t> as test
file. Other files are skipped. Files that already have an entry are skipped.

=head2 bin_file( FILENAME )

Adds the file FILENAME to the list of files to be tested and marks it as a
Perl script file. If there is already an entry for FILENAME, the existing
entry is replaced with a new entry.

=head2 ignore_file( FILENAME )

Ignores a file from being tested. This method adds an C<undef> entry for
FILENAME. Use this to e.g. remove a single file from a directory:

    $xt->bin_dir('maint');
    $xt->ignore_file('maint/bugs.csv');

=head2 module_file( FILENAME )

Adds the file FILENAME to the list of files to be tested and marks it as a
Perl module file. If there is already an entry for FILENAME, the existing
entry is replaced with a new entry.

=head2 pod_file( FILENAME )

Adds the file FILENAME to the list of files to be tested and marks it as a
Pod file. If there is already an entry for FILENAME, the existing
entry is replaced with a new entry.

A Pod file is a file which typically ends in F<.pod>. This is not for other
files (e.g. modules or scripts) that also contain Pod.

=head2 remove_file( FILENAME )

Removes the entry for FILENAME from the list of files to be tested.

This differs from C<ignore_file> in that later calls to the C<*_dir> methods
can add a new file for a removed file, but not for an ignored file.

=head2 test_file( FILENAME )

Adds the file FILENAME to the list of files to be tested and marks it as a
test file. If there is already an entry for FILENAME, the existing
entry is replaced with a new entry.

=head2 file( FILENAME, [ FILE OBJECT ] )

Returns the file entry for FILENAME when called with a single argument.

With two arguments, the FILE OBJECT must either be C<undef> or a
L<XT::Files::File> object.

You should probably use one of the existing C<*_file> methods to add new
files but this method can be used to e.g. add a modulino.

    my $file = XT::Files::File->new(
        name => 'bin/my_modulino',
        is_module => 1,
        is_script => 1
    );
    $xt->file($file->name, $file);

=head2 plugin( NAME, VERSION, KEYVALS_REF )

Loads and runs a plugin. All plugins must have a C<new> and a C<run> method.

If the name starts with a C<=>, the leading C<=> is removed and the remaining
string is used as package name. Otherwise C<XT::Files::Plugin::> is prepended
to the string and this is used as package name.

The C<plugin> method uses L<Module::Load> to load the plugin. If a VERSION
is defined it checks that L<version>s C<parse> of the VERSION isn't lower
then the plugins version. VERSION can be undef which means every version is
accepted.

Then it calls the plugins C<new> method and passes C<$self> as the C<xtf>
argument and expects an object of the plugin in return.

    my $plugin_object = NAME->new( xtf => $self );

After that it calls the plugins C<run> method and passes it the KEYVALS_REF.

=head1 EXAMPLES

=head2 Example 1 Use a test that supports C<XT::Files> with default config

Because the L<Test::Pod::Links> supports C<XT::Files> we can just use the
following two lines for our author test F<.t> file.

    use Test::Pod::Links 0.003;

    all_pod_files_ok();

When C<Test::Pod::Links> asks C<XT::Files> for all the pod files to check,
C<XT::Files> checks if the distribution has an C<XT::Files> config file.
If the config file exists it is parsed and processed, otherwise the
L<XT::Files::Plugin::Default> is loaded to load the default C<XT::Files>
configuration.

=head2 Example 2 Use a test that supports XT::Files with default config files

In your distribution's C<.xtfilesrc> or C<xtfiles.ini> file you can configure
the structure of your distribution.

    [Default]
    dirs=0

    [Dirs]
    bin = bin
    module = lib
    test = t
    test = xt

The run the test the same as in Example 1

    use Test::Pod::Links

    all_pod_files_ok();

But this time the file list is generated depending on your config file and not
on the defaults from the L<XT::Files::Plugin::Default> plugin.

=head2 Example 3 Use a test that supports C<XT::Files> but ignore default config file

The following example lets you programmatically configure the C<XT::Files>
file list omitting a config file, if it exists and only loading the excludes
config from the L<XT::Files::Plugin::Default> plugin.

We recommend that you always configure C<XT::Files> with a config file but
this example could be used if some special logic is required.

    use XT::Files;
    use Test::Pod::Links

    my $xt = XT::Files->initialize( -config => undef );

    $xt->plugin( 'Default', undef, [ dirs => 0 ] );

    $xt->bin_dir('bin');
    $xt->lib_dir('lib');
    $xt->test_dir('t');
    $xt->test_dir('xt');

    all_pod_files_ok();

=head2 Example 4 Use a test that supports C<XT::Files> with the config file but add test directory

This initializes the config, either from the config file or, if no config
file exists, with the L<XT::Files::Plugin::Default> plugin. Then it adds
an additional two directories. This can be used if you want to check some
files with only some author tests.

    use XT::Files;
    use Test::Pod::Links

    my $xt = XT::Files->instance;
    $xt->test_dir('t');
    $xt->test_dir('xt');

    all_pod_files_ok();

=head2 Example 5 Use a test that does not support C<XT::Files>

If a test does not support C<XT::Files> we have to fall back to the old
iterating over the files and call the C<files_ok> (or similar) function.
This allows us to use the same logic to generate the file list as all tests
that support C<XT::Files> use.

    use Test::More 0.88;
    use Test::XTFiles;
    use Test::Something;

    for my $file (Test::XTFiles->new->all_files()) {
      files_ok($file);
    }

    done_testing();

=head1 SEE ALSO

L<Test::XTFiles>,
L<XT::Files::File>,
L<XT::Files::Plugin::Default>,
L<XT::Files::Plugin::Dirs>,
L<XT::Files::Plugin::Excludes>,
L<XT::Files::Plugin::Files>,
L<XT::Files::Plugin::lib>,
L<XT::Files::Plugin>,
L<XT::Files::Role::Logger>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/XT-Files/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/XT-Files>

  git clone https://github.com/skirmess/XT-Files.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
