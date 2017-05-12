package Test::Verbose;

$VERSION = 0.010;

#BEGIN {
#    *CORE::GLOBAL::chdir = \&my_chdir;
#}
#
#sub my_chdir {
#    warn $_[0], " at ", join " ", map defined $_ ? $_ : "undef", caller(0), "\n";
#    CORE::chdir( $_[0] );
#}

=head1 NAME

Test::Verbose - Run 'make TEST_VERBOSE=1' on one or more test files

=head1 SYNOPSIS

    # from the command line.  man tv for more details.
    $ tv lib/Foo.pm    # test this module
    $ tv t/*.t         # run these tests

    # from a module
    use Test::Verbose qw( test_verbose );
    test_verbose( @module_and_test_script_filenames );

For more control, you can use the object oriented interface.

See also the L<tv> command.

=head1 DESCRIPTION

Given a list of test scripts, source file names, directories and/or
package names, attempts to find and execute the appropriate test
scripts.

This (via the associated tv command) is useful when developing code or
test scripts: just map "tv %" to a key in your editor and press it
frequently (where "%" is your editor's macro for "the file being
edited).

Before doing anything, this module identifies the working directory for
the project by scanning the current directory and it's ancestors,
stopping at the first directory that contains a "t" directory.

If an explicitly named item (other than POD files) cannot be tested, an
exception is thrown.

Here is how each name passed in is treated:

=over

=item test script

An explicitly mentioned test script is selected, no source files need be
parsed.  Names of test scripts are recognized by ending in ".t" and, if
they exist on the filesystem, by being a file (and not a directory).

=item source file

Source files ending in ".pl", ".pm", or ".pod" are run through
C<podchecker>, then perl -cw before any tests are run.  This
forces useful POD and does a quick shortcircuit syntax check of the
source files before the possibly length make test gets run.

Source files are parsed (very naively) looking for C<package> declarations
and for test scripts listed in special POD comments:

    =for test_script foo.t bar.t
        baz.t

Also, all test scripts are parsed looking for C<use> and C<require>
statements and for POD that looks like:

    =for file lib/Foo.pm

or

    =for package Foo

.  All test scripts pertaining to a given file and any packages in it
are then selected.

Before any test scripts are run, source files are run through
L<podchecker|podchecker> and through C<perl -cw>.  The former is to
check POD, something normal test suites don't do, and the latter is
because running C<make test ...> for a distribution with a lot of
modules can be slow and I want to give per-module feedback ASAP.

The paths listed in C<=for file> must be paths relative to the project
root and not contain "..".  Hmmm, they can also be absolute paths, but
why would you do that?

Names of source files are recognized by not ending in ".t" and not
looking like a package name or, if they do look like a package name, by
existing on the filesystem.

=item directory

Directories are travered looking for files with the extensions ".t",
".pm", ".pod", or ".pl".  These are then treated as though they had been
explicitly named.  Note that this notion of "looks like a source file"
differs from that used when a source file is explicitly passed (where
any extension other than .t may be used).

=item package name

If a name looks like a legal package name (Contains only word characters
and "::" digraphs) and does not exist on the filesystem, then it is
assumed to be a package name.  In this case, all explicitly mentioned
source files and test script files are scanned as normal, as well as
those found by scanning the main project directory and (only) it's lib
and t subdirectories.  Files found there are not selected, but are used
to determine what tests to run for a package.

=back

=head1 .tvrc file

If a .tvrc file is found in a project's root directory, it is run just
before any tests.  This allows you to set important env. vars:

    $ENV{DBI_USER}="barries";
    $ENV{DBI_PASS}="yuck";

    $tv->pure_perl = 1;

This support is experimental but should be ok for now.  Options set here
may be overridden on the command line.

=head1 FUNCTIONS

    test_verbose( @names );
    test_verbose( @names, \%options );

Shortcut for

    my $tv = Test::Verbose->new( %options )->test( @names );

=cut

@EXPORT_OK = qw( test_verbose is_win32 );
@ISA = qw( Exporter );

use strict;

use constant debugging => $ENV{TVDEBUG} ? 1 : 0;
use constant is_win32  => $^O =~ /Win32/i;
use constant MAKE      => is_win32 ? "nmake.exe" : "make";

BEGIN {
    require Exporter;
    require Carp;
    require Cwd;
    require File::Spec;
}

sub test_verbose {
    my $options = ref $_[-1] eq "HASH" ? pop : {};
    return Test::Verbose->new( %$options )->test( @_ );
}

=head1 METHODS

=over

=item new 

Takes a list of options:

=over

=item Debug

Runs the test scripts directly using perl C<-d>.  Causes ExtUtils to
be ignored.

=item Dir

What directory to look for t/ and run make(1) in.  Undefined causes
the instance to search for a directory containing a directory named "t"
in the current directory and its parents.

=item JustPrint

Print out the command to be executed.

=item ExtUtils

Don't use C<make test TEST_VERBOSE=1 ...>, use
C<perl '-MExtUtils::Command::MM' -e 'test_harness(1,\'lib\')' ...>
instead.
Useful if you don't have a Makefile.PL; might not work on all versions
of perl.

=back

=cut

sub new {
    my $proto = shift;
    my $self = bless {}, ref $proto ? ref $proto : $proto;

    $self->load_rc;

    my %options = @_;

    for ( keys %options ) {
        $self->{$_} = $options{$_}
            if defined $options{$_};
    }

    $self->{TestPOD} = $self->{Compile} = $self->{RunTests} = 1
        unless $self->{TestPOD} || $self->{Compile} || $self->{RunTests};

    $self->{TestPOD}   = 0 if $self->{NoPOD};
    $self->{Compile}   = 0 if $self->{NoCompile};
    $self->{RunTests}  = 0 if $self->{NoTests};

    $self->{DoubleQuiet} ||= $self->{TripleQuiet};
    $self->{Quiet}       ||= $self->{DoubleQuiet};

    return $self;
}

=item load_rc

Scans for and loads the .tvrc file.

NOTE: may be expanded in the future to load multiple RC files.

So far, only a few attributes are available, will add more as I need
to.

For 100% pure perl modules, a common .tvrc is:

    $tv->pure_perl = 1;

.  And a way to shush tv from printing out all the good news is:

    $tv->quiet = 1;  

=cut

sub load_rc {
    my $self = shift;

    my $rc_file = ".tvrc";

    my $d = $self->dir;

    $self->{ConfigClass} = join "", "Test::Verbose::Config::", int $self;
    
    $rc_file = -e $rc_file
        ? do {
            open RC_FILE, "<$rc_file" or die "$!: $rc_file";
            local $/ = undef;
            my $code = <RC_FILE>;
            close RC_FILE;
            my $self_class = ref $self;
            bless $self, $self->{ConfigClass};
            my $fn = File::Spec->rel2abs( $rc_file, $d );
            join "",
                "package $self->{ConfigClass};\n",
                "no strict;\n",
                "\@ISA = qw( ", $self_class, " );\n",
                "use strict;\n",
                "our \$tv;",
                "sub AUTOLOAD {};\n",
                "#line 1 $fn\n",
                $code,
                "\n",
                "1;";
        }
        : undef;

    if ( defined $rc_file ) {
        {
            no strict "refs";
            ${"$self->{ConfigClass}::tv"} = $self;
        }

        eval $rc_file or die $@;
    }

}

=item dir

    my $dir = $tv->dir;
    $tv->dir( undef );   ## clear old setting
    $tv->dir( "foo" );   ## prevent chdir( ".." ) searching
    $tv->dir = "foo";

Looks for t/ or lib/ in the current directory or in any parent directory.
C<chdir()>s up the directory tree until t/ is found, then back to the
directory it started in, so make sure you have permissions to C<chdir()>
up and back.

Passing a Dir => $dir option to new prevents this method for searching
for a name,

=cut

sub dir: lvalue {
    my $self = shift;

    $self->{Dir} = shift if @_;
    
    if ( defined wantarray && ! defined $self->{Dir} ) {
        warn "tv: searching for project directory\n" if debugging;
        my $cwd = Cwd::cwd;
        ## cd up until we find a directory that has a "t" subdirectory
        ## this is for folks whose editor's working directories might be
        ## down in t/ or lib/, etc.
        my $last_d = $cwd;
        until ( -d "t" || -d "lib" ) {
            chdir( File::Spec->updir )
                or die "tv: $! while cd()ing upwards looking for t/ or lib/";
            my $new_d = Cwd::cwd;
            die "tv: could not find t/ or lib/ in any parent of $cwd\n"
                if length $new_d eq length $last_d;
            $last_d = $new_d;
        }
        $self->{Dir} = Cwd::cwd;
        warn "tv: ...found $self->{Dir}\n" if debugging;
        chdir $cwd or die "tv: $! chdir()ing back to '$cwd'";
    }

    $self->{Dir};
}


=item pure_perl

    $tv->pure_perl = 1;
    print $tv->pure_perl;

=cut

sub pure_perl: lvalue {
    my $self = shift;
    $self->{PurePerl} = shift if @_;
    $self->{PurePerl};
}

=item quiet

    $tv->quiet = 1;

=cut

sub quiet: lvalue {
    my $self = shift;
    $self->{Quiet} = shift if @_;
    $self->{Quiet};
}

=item double_quiet

    $tv->double_quiet = 1;

=cut

sub double_quiet: lvalue {
    my $self = shift;
    $self->{DoubleQuiet} = shift if @_;
    $self->{DoubleQuiet};
}

=item triple_quiet

    $tv->triple_quiet = 1;

=cut

sub triple_quiet: lvalue {
    my $self = shift;
    $self->{DoubleQuiet} = shift if @_;
    $self->{DoubleQuiet};
}

=item is_test_script

    $self->is_test_script;         ## tests $_
    $self->is_test_script( $name );

Returns true if the name looks like the name of a test script (ends in .t).
File does not need to exist.

Overload this to alter Test::Verbose's perceptions.

=cut

sub is_test_script {
    my $self = shift;
    local $_ = shift if @_;
    /\.t\z/ && ( ! -e || -f _ );
}


=item is_pod_file

    $self->is_pod_file;         ## tests $_
    $self->is_pod_file( $name );

Returns true if the name looks like the name of a pod file (ends in
.pod).  File does not need to exist, but must be a file if it
does.

Overload this to alter Test::Verbose's perceptions.

=cut

sub is_pod_file {
    my $self = shift;
    local $_ = shift if @_;
    /\.(pod)\z/ && ( ! -e || -f _ );
}


=item is_source_file

    $self->is_source_file;         ## tests $_
    $self->is_source_file( $name );

Returns true if the name looks like the name of a source file (ends in
.pm, .pod or .pl).  File does not need to exist, but must be a file if it
does.

This is only used when traversing directory trees, otherwise a file name
(ie not a package) is assumed to be a source file if it is not a test
file.

Overload this to alter Test::Verbose's perceptions.

=cut

sub is_source_file {
    my $self = shift;
    local $_ = shift if @_;
    /\.(pm|pl|pod)\z/ && ( ! -e || -f _ );
}


=item is_package

    $self->is_test_script; ## tests $_
    $self->is_test_script( $name );

Returns trues if the name looks like the name of a package (contains
only /\w/ and "::") and is not a name that exists (ie C<! -e>).

Overload this to alter Test::Verbose's perceptions.

=cut


sub is_package {
    my $self = shift;
    local $_ = shift if @_;
    /\A(\w|::)+\z/ && ! -e;
}


=item unhandled

    $self->unhandled( @_ );

die()s with any unhandled names.

Overload this to alter the default.

=cut

sub unhandled {
    my $self = shift;

    warn "tv: no test scripts found for: ", join( ", ", @_ ), "\n",
            "Try adding '=for test_script ...' to the source",
            @_ > 1 ? "s" : "",
            " or 'use ...;' or '=for package ...' to the test scripts\n";
}

=item look_up_scripts

    my @scripts = $tv->look_up_test_scripts( @_ );

Looks up the scripts for any names that don't look like test scripts.

die()s if a non-test script cannot be found.

use =for tv dont_test to prevent this error.

All test scripts returned will have the form "t/foo.t", and the result
is sorted.  No test script name will be returned more than once.

=cut

sub test_scripts_for {
    my $self = shift;

    my @test_scripts;

    local $self->{Names} = [ $self->_traverse_dirs( @_ ) ];

    for ( @{$self->{Names}} ) {
        if ( $self->is_test_script ) {
            push @test_scripts, $_;
        }
        elsif ( $self->is_package ) {
            my @t = $self->test_scripts_for_package;
            if ( @t ) {
                push @test_scripts, @t;
            }
            else {
                push @{$self->{Unhandled}}, $_;
            }
        }
        elsif ( -d ) {
Carp::confess "BUG: this code branch should be unreachable";
#            my @t = $self->test_scripts_for_dir;
#            if ( @t ) {
#                push @test_scripts, @t;
#            }
#            else {
#                push @{$self->{Unhandled}}, $_;
#            }
        }
        elsif ( $self->is_pod_file ) {
            push @{$self->{PodChecks}}, $_;
            push @test_scripts, $self->test_scripts_for_pod_file;
            # It is not an error for a pod file to not have a test
            # script.
        }
        else {
            # It's a code file
            push @{$self->{CompileChecks}}, $_;
            my @t = $self->test_scripts_for_file;
            if ( @t ) {
                push @test_scripts, @t;
            }
            else {
                push @{$self->{Unhandled}}, $_;
            }
        }
    }

    my %seen;
    return sort grep !$seen{$_}++, map {
        ## Make all test scripts look like "t/foo.t"
        $_ = File::Spec->canonpath( $_ );
        s{^(?![\\/])(t[\\/])?}{t/};
        $_;
    } @test_scripts
}


sub _slurp_and_split {
    my @items = split /\s+/, $1;
    local $_;
    while (<F>) {
        last if /^$/;
        push @items, split /\s+/;
    }

    return grep length, @items;
}


sub _traverse_dirs {
    my $self = shift;
    my @names = @_;

    return map {
        my $dir = $_;
        -d $dir
            ? do {
                my @results;
                warn "tv: traversing $_\n" if debugging;
                require File::Find;
                File::Find::find(
                    sub {
                        if (
                            -f
                                && ( $self->is_source_file ||
                                     $self->is_test_script
                                 )
                        ) {
                            push @results, $File::Find::name;
                            push @{$self->{FilesInDir}->{$dir}},
                                $File::Find::name;
                        }
                    },
                    $_
                );
                @results ? @results : $_;
            }
            : $dir;
    } @names;
}


sub _scan_source_files {
    my $self = shift;

    my @files = grep ! $self->is_package && ! $self->is_test_script,
        @{$self->{Names}};

    if ( grep $self->is_package, @{$self->{Names}} ) {
        ## Scan all likely source files to look for those that
        ## might contain the package.
        push @files,
            $self->_traverse_dirs( File::Spec->catdir( $self->dir, 'lib') ),
            do {
                # Look for source files in the project dir's top level.
                opendir D, $self->dir;
                my @f = grep
                    -f && $self->is_source_file,
                    readdir D;
                close D;
                @f = map File::Spec->catdir( $self->dir, $_ ), @f;
            };
    }

    my $cwd = Cwd::cwd;

    for my $code_file ( @files ) {
        warn "tv: scanning code file $code_file\n" if debugging;
        open F, $code_file or die "tv: $!: $code_file";
        my $abs_fn = File::Spec->canonpath(
            File::Spec->rel2abs( $code_file, $cwd )
        );

        my $package = "main";
        local $/ = "\n";
        local $_;
        while (<F>) {
            if ( /^=for\s+test_scripts?\s+(.*)/ ) {
                my @scripts = _slurp_and_split;
                warn "tv: $abs_fn, $package =for test_scripts ",
                    join( " ", @scripts ), "\n"
                    if debugging;
                push @{$self->{Files}->{$abs_fn}}, @scripts;
                push @{$self->{Packages}->{$package}}, @scripts;
            }
            elsif ( /^\s*package\s+(\S+)\s*;/ ) {
                $package = $1;
                warn "tv: $abs_fn declares $package\n" if debugging;
                push @{$self->{PackagesForFile}->{$abs_fn}}, $package;
            }
            elsif ( /^=/ ) {
                push @{$self->{PodChecks}}, $code_file
                    unless grep $_ eq $code_file, @{$self->{PodChecks}};
            }
        }
        close F or die "tv: $! closing $code_file";
    }

    1;
}


sub _scan_test_scripts {
    my $self = shift;

    my $cwd = Cwd::cwd;

    chdir $self->dir or Carp::croak "$!: ", $self->dir, "\n";
    my @all_test_scripts = grep /.t\z/, $self->_traverse_dirs( "t" );
    chdir $cwd or Carp::croak "$!: $cwd\n";

    warn "tv: no test scripts (t/*.t) found for project\n" unless @all_test_scripts;

    for my $test_script ( @all_test_scripts ) {
        warn "tv: scanning test script $test_script\n" if debugging;
        open F, File::Spec->catfile( $self->dir, $test_script )
            or Carp::croak "$!: $test_script\n";

        local $/ = "\n";
        local $_;
        while (<F>) {
            if ( /^=for\s+packages?\s+(.*)/ ) {
                my @pkgs = _slurp_and_split;
                warn "tv: $test_script =for packages ", join( " ", @pkgs ), "\n"
                    if debugging;
                map push( @{$self->{Packages}->{$_}}, $test_script ), @pkgs;
            }
            elsif ( /^=for\s+files?\s+(.*)/ ) {
                my @files = map
                    File::Spec->canonpath(
                        File::Spec->rel2abs( $_, $self->dir )
                    ), _slurp_and_split;
                warn "tv: $test_script =for files ", join( " ", @files ), "\n"
                    if debugging;
                map
                    push( @{$self->{Files}->{$_}}, $test_script ),
                    @files;
            }
            elsif ( /\s*(use|require)\s+([\w:]+)/ ) {
                warn "tv: $test_script $1s $2\n" if debugging;
                push @{$self->{Packages}->{$2}}, $test_script;
            }
        }
        close F or die "tv: $! closing $test_script";
    }

    1;
}


sub test_scripts_for_package {
    my $self = shift;
    local $_ = shift if @_;

    $self->{ScannedSourceFiles} ||= $self->_scan_source_files;
    $self->{ScannedTestScripts} ||= $self->_scan_test_scripts;

    return exists $self->{Packages}->{$_}
        ? @{$self->{Packages}->{$_}}
        : ();
}


sub test_scripts_for_file {
    my $self = shift;
    local $_ = shift if @_;

    $self->{ScannedSourceFiles} ||= $self->_scan_source_files;
    $self->{ScannedTestScripts} ||= $self->_scan_test_scripts;

    local $_ = File::Spec->canonpath(
        File::Spec->rel2abs( $_, Cwd::cwd )
    );

    return (
        exists $self->{Files}->{$_}
            ? @{$self->{Files}->{$_}}
            : (),
        exists $self->{PackagesForFile}->{$_}
            ? map $self->test_scripts_for_package,
                @{$self->{PackagesForFile}->{$_}}
            : (),
    );
}


sub test_scripts_for_pod_file {
    my $self = shift;
    local $_ = shift if @_;

    $self->{ScannedSourceFiles} ||= $self->_scan_source_files;
    $self->{ScannedTestScripts} ||= $self->_scan_test_scripts;

    local $_ = File::Spec->canonpath(
        File::Spec->rel2abs( $_, Cwd::cwd )
    );

    return
        exists $self->{Files}->{$_}
            ? @{$self->{Files}->{$_}}
            : ();
}


#sub test_scripts_for_dir {
#    my $self = shift;
#    local $_ = shift if @_;
#
#    $self->{ScannedSourceFiles} ||= $self->_scan_source_files;
#    $self->{ScannedTestScripts} ||= $self->_scan_test_scripts;
#
#    return
#        exists $self->{FilesInDir}->{$_}
#            ? map
#                $self->is_test_script
#                    ? $_
#                    : $self->test_scripts_for_file,
#                @{$self->{FilesInDir}->{$_}}
#            : ();
#}


=item test

    $self->test( @test_scripts );

chdir()s to C<$self->dir> and C<exec()>s make test.

=cut

sub _esc {
    map
        m{[^\w./\\=:-]}
            ? do {
                local $_ = $_;
                s/([\\'])/\\$1/g;
                "'$_'";
            }
            : $_,
        @_;
}

sub call_config_handler {
    my $self = shift;
    my $handler = shift;

    my $sub = $self->{ConfigClass}->can( $handler );
    return unless $sub;

    $sub->( $self, @_ );
}


sub test {
    my $self = shift;

    my $cwd = Cwd::cwd;
    my $d = $self->dir;
    chdir $d or die "tv: $!: $d";

    ## TODO: an option to name the log file.
    open LOG, ">tv.log" unless $self->{NoLog};

    $self->call_config_handler( "before_testing_do", @_ );

    $self->{PodChecks}     = [];
    $self->{CompileChecks} = [];
    $self->{Unhandled}     = [];

    my @scripts = @_ ? $self->test_scripts_for( @_ ) : ();

    if ( $self->{TestPOD} && @{$self->{PodChecks}} ) {
        ## NOTE: not using $^X here because podchecker may be from a
        ## newer perl.  Could lead to unexpected behavior, but very, very
        ## probably not.
        warn "tv\$ podchecker ", join( " ", _esc @{$self->{PodChecks}} ), "\n"
            if $self->{JustPrint} || !$self->{DoubleQuiet};
        ## TODO: log the output of this
        system "podchecker", @{$self->{PodChecks}}
            and die "tv: POD checks failed, not running further tests.\n"
            unless $self->{JustPrint};
    }

    if ( $self->{Compile} && @{$self->{CompileChecks}} ) {
        warn "tv\$ perl -Ilib -cw ",
            join( " ", _esc @{$self->{CompileChecks}} ),
            "\n"
            if $self->{JustPrint} || !$self->{DoubleQuiet};

        ## TODO: log the output of this
        system $^X, "-Ilib", "-cw", @{$self->{CompileChecks}}
            and die "tv: compile test failed, not running further tests.\n"
            unless $self->{JustPrint};
    }

    $self->unhandled( @{$self->{Unhandled}} )
        if @{$self->{Unhandled}};

    return 0 unless $self->{RunTests} && @scripts;

    my $debug = $self->{Debug} || $self->{DebugRun};

    my @cmds =
        $debug
                ? (
                    [ MAKE, "pm_to_blib" ],
                    map [ $^X, "-w", "-Iblib/lib", "-d", $_ ], @scripts
                )
            : $self->{PurePerl}
                ? map [ $^X, "-w", "-Ilib", $_ ], @scripts
            : $self->{ExtUtils}
                ? [
                    $^X,
                    qw( -MExtUtils::Command::MM -e ),
                    "test_harness(1,'lib')",
                    @scripts
                ]
                : [ MAKE, qw( test TEST_VERBOSE=1 ),
                    @_
                        ? "TEST_FILES=" . join " ", @scripts
                        : (),
                ];

    my $nonlazy_dyn_link = $self->{ExtUtils} || $debug;
    local $ENV{PERL_DL_NONLAZY} = 1 if $nonlazy_dyn_link;

    my $db_opts = $ENV{PERLDB_OPTS} || "";
    if ( $self->{DebugRun} ) {
        $db_opts = " $db_opts" if length $db_opts;
        $db_opts = "NonStop$db_opts";
    }
    local $ENV{PERLDB_OPTS} = $db_opts if length $db_opts;

    warn <<TOHERE if $self->{DebugRun};

tv: ** Running in debug mode, use interrupt (often ^C), \$DB::single=1, **
tv: ** or rerun with -dd if you need to enter the debugger on startup. **

TOHERE

    my @result_codes;

    for ( @cmds ) {
        my $cmd = join " ", _esc @$_;

        $cmd = qq{PERL_DL_NONLAZY=1 $cmd}      if $nonlazy_dyn_link;
        $cmd = qq{PERLDB_OPTS="$db_opts" $cmd} if length $db_opts;

        warn "tv\$ $cmd\n"
            if $self->{JustPrint} || !$self->{DoubleQuiet};

        next if $self->{JustPrint};

        require IPC::Open3;

        ## Collect both stderr and stdout in to one stream; don't
        ## want select() and this lets the OS interleave output
        ## better, I hope.
        my $pid = IPC::Open3::open3( \*STDIN, my $out, undef, @$_ );
        die "tv: $!: $cmd\n" unless defined $pid;

        my @out;
        my $saw_lone_not;
        my $last_ok_line = "";
        my $saw_ok;
        while ( <$out> ) {
            print LOG;
            print unless $self->{Quiet};
            push @out, $_ if $self->{Quiet};

            $saw_lone_not = 1, next if /^not\s*$/;

            my ( $not, $ok, $what, $number, $why ) =
                /\A((?:not\s+)?)(ok\b)\s*(\d*)(?:#\s*(\S+))?/;

            next unless $ok;

            $saw_ok = 1;

            if ( $ok
                && ! $saw_lone_not
                && ( ! $not || ( $why || "" ) =~ /TODO/i )
            ) {
                @out = ();
            }
            elsif (
                $not || ( $saw_lone_not && $ok )
                && $self->{Quiet}
                && ! $self->{DoubleQuiet}
            ) {
                if ( defined $cmd && @cmds > 1 ) {
                    print $cmd, ":\n" if $self->{Quiet};
                    $cmd = undef;
                }
                print $saw_lone_not ? "not $_" : $_;
            }
            $saw_lone_not = 0;
            $last_ok_line = ( $saw_lone_not ? "not " : "" ) . $_ if $ok;
        }

        ## Emit the next bit even in DoubleQuiet mode; it's usually
        ## the All tests sucessful.  At least when I'm driving it ;).
        if ( ! $self->{TripleQuiet} && @out ) {
            if ( defined $cmd && @cmds > 1 ) {
                print $cmd, ":\n" if $self->{DoubleQuiet};
                $cmd = undef;
            }
            print
                $saw_ok ? "tv: after last 'ok/not ok':\n" : $last_ok_line,
                @out;
        }

        waitpid $pid, 0 or warn "$! waiting on PID $pid";

        push @result_codes, $? >> 8;
    }

    close LOG;

    (grep $_, @result_codes )[0] || 0;
}

=back

=head1 ASSumptions and LIMITATIONS

=over

=item * 

Test scripts with spaces in their filenames will screw up, since these
are interpolated in to a single, space delimited make(1) variable like so:

    make test TEST_VERBOSE=1 "TEST_FILES=t/spaced out name.t"

=item *

Your make must be called "make".  I will alter this assumption as soon
as I need this on Win32 again.  Feel free to submit patches.

=item *

Speaking of which, although this module has a nod to portability, it
has not been tested on platforms other than Unix, so there be dragons
there.  They should be easy to fix, so please patch away.

=item *

The source code scanners look for /^\s*(use|require)\s+([\w:])/ (in test
scripts) and /^\s*package\s+(\S+);/, and so are easily fooled.

=back

=cut

=head1 COPYRIGHT

    Copyright 2002 R. Barrie Slaymaker, All Rights Reserver

=head1 LICENSE

You may use this module under the terms of the BSD, GNU, or Artistic
licenses.

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=cut

1;
