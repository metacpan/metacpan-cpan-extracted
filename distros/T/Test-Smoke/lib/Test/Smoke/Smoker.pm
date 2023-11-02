package Test::Smoke::Smoker;
use warnings;
use strict;

our $VERSION = '0.047';

use Config;
use Cwd;
use File::Spec::Functions qw( :DEFAULT abs2rel rel2abs );
use Capture::Tiny 'capture';
use Test::Smoke::LogMixin;
use Test::Smoke::Util qw( get_smoked_Config skip_filter );

BEGIN { eval q{ use Time::HiRes qw( time ) } }
{ my $_orig_dft = select(STDERR); $|++; select(STDOUT); $|++; select($_orig_dft); $|++ }

my %CONFIG = (
    df_ddir           => curdir(),
    df_v              => 0,
    df_run            => 1,
    df_fdir           => undef,
    df_is56x          => 0,
    df_locale         => '',
    df_force_c_locale => 0,
    df_defaultenv     => 0,
    df_perlio_only    => 0,
    df_harness_destruct => 2,

    df_is_vms         => $^O eq 'VMS',
    df_vmsmake        => 'MMK',
    df_harnessonly    => scalar ($^O =~ /VMS/),
    df_hasharness3    => 0,
    df_harness3opts   => '',

    df_is_win32       => $^O eq 'MSWin32',
    df_w32cc          => 'MSVC60',
    df_w32make        => 'nmake',
    df_w32args        => [ ],

    df_makeopt        => "",
    df_testmake       => undef,

    df_skip_tests     => undef,
);

# Define some constants that we can use for
# specifying how far "make" got.
sub BUILD_MINIPERL() { -1 } # but no perl
sub BUILD_PERL    () {  1 } # ok
sub BUILD_NOTHING () {  0 } # not ok

sub HARNESS_RE1 () {
     '(\S+\.t)(?:\s+[\d?]+){0,4}(?:\s+[\d?.]*%)?\s+([\d?]+(?:[-\s]+\d+-?)*)$'
}
sub HARNESS_RE2() { '^\s+(\d+(?:[-\s]+\d+)*-?)$' }


sub HARNESS3_RE_EXTRA() {
     '^\s+(\d[0-9, -]*)'
}

sub HARNESS3_RE_FAILED() {
     '^(?:
          (?:\ \ Failed\ tests?(?:\ number\(s\))?:\ \ )
       )
       (\d[0-9, -]*)'
}

sub HARNESS3_RE_TODO() {
     '^(?:
          (?:\ \ TODO\ passed(?:\ number\(s\))?:\ \ \ )
       )
       (\d[0-9, -]*)'
}


=head1 NAME

Test::Smoke::Smoker - OO interface to do one smoke cycle.

=head1 SYNOPSIS

    use Test::Smoke;
    use Test::Smoke::Smoker;

    open LOGFILE, "> mktest.out" or die "Cannot create 'mktest.out': $!";
    my $buildcfg = Test::SmokeBuildCFG->new( $conf->{cfg} );
    my $policy = Test::Smoke::Policy->new( '../', $conf->{v} );
    my $smoker = Test::Smoke::Smoker->new( \*LOGFILE, $conf );

    foreach my $config ( $buildcfg->configurations ) {
        $smoker->smoke( $config, $policy );
    }

=head1 DESCRIPTION

The Test::Smoke::Smoker module, an OO interface to do one smoke cycle.

=head1 CONSTANTS

=over

=item BUILD_MINIPERL

=item BUILD_NOTHING

=item BUILD_PERL

=item HARNESS3_RE_EXTRA

=item HARNESS3_RE_FAILED

=item HARNESS3_RE_TODO

=item HARNESS_RE1

=item HARNESS_RE2

=back

=head1 METHODS

=head2 Test::Smoke::Smoker->new( \*GLOB, %args )

C<new()> takes a mandatory (opened) filehandle and some other options:

    ddir            build directory
    fdir            The forest source
    v               verbose level: 0..2
    defaultenv      'make test' without $ENV{PERLIO}
    is56x           skip the PerlIO stuff?
    locale          do another testrun with $ENV{LC_ALL}
    force_c_locale  set $ENV{LC_ALL} = 'C' for all smoke runs

    is_win32        is this MSWin32?
    w32cc           the CCTYPE for MSWin32 (MSVCxx BORLAND GCC)
    w32make         the maker to use for CCTYPE

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $fh = shift;

    unless ( ref $fh eq 'GLOB' ) {
        require Carp;
        Carp::croak(sprintf "Usage: %s->new( \\*FH, %%args )", __PACKAGE__);
    }

    my %args_raw = @_ ? UNIVERSAL::isa( $_[0], 'HASH' ) ? %{ $_[0] } : @_ : ();

    my %args = map {
        ( my $key = $_ ) =~ s/^-?(.+)$/lc $1/e;
        ( $key => $args_raw{ $_ } );
    } keys %args_raw;

    my %fields = map {
        my $value = exists $args{$_} ? $args{ $_ } : $CONFIG{ "df_$_" };
        ( $_ => $value )
    } keys %{ Test::Smoke::Smoker->config( 'all_defaults' ) };

    $fields{logfh}  = $fh;
    select( ( select( $fh ), $|++ )[0] );
    $fields{defaultenv} = 1 if $fields{is56x};
    $^O =~ /VMS/i and $fields{is_vms} = 1;

    unless ( defined $fields{testmake} ) {
        $fields{testmake} = 'make';
        $fields{is_win32} and $fields{testmake} = $fields{w32make};
        $fields{is_vms}   and $fields{testmake} = $fields{vmsmake};
    }
    my $self = bless { %fields }, $class;

    return $self;
}

=head2 $smoker->verbose

Get verbosity.

=cut

sub verbose { $_[0]->{v} }

=head2 $smoker->mark_in()

Write the current timestamp with 'Start' marker to the logfile.

=cut

sub mark_in {
    my $self = shift;
    $self->log( sprintf "Started smoke at %d\n", time() );
}

=head2 $smoker->mark_out()

Write the current timestamp with 'Stopped' marker to the logfile.

=cut

sub mark_out {
    my $self = shift;
    $self->log( sprintf "Stopped smoke at %d\n", time() );
}

=head2 Test::Smoke::Smoker->config( $key[, $value] )

C<config()> is an interface to the package lexical C<%CONFIG>,
which holds all the default values for the C<new()> arguments.

With the special key B<all_defaults> this returns a reference
to a hash holding all the default values.

=cut

sub config {
    my $dummy = shift;

    my $key = lc shift;

    if ( $key eq 'all_defaults' ) {
        my %default = map {
            my( $pass_key ) = $_ =~ /^df_(.+)/;
            ( $pass_key => $CONFIG{ $_ } );
        } grep /^df_/ => keys %CONFIG;
        return \%default;
    }

    return undef unless exists $CONFIG{ "df_$key" };

    $CONFIG{ "df_$key" } = shift if @_;

    return $CONFIG{ "df_$key" };
}

=head2 $smoker->tty( $message )

Prints a message to the default filehandle.

=cut

sub tty {
    my $self = shift;
    my $message = join "", @_;
    $self->log_warn($message);
}

=head2 $smoker->log( $message )

Prints a message to the logfile, filehandle.

=cut

sub log {
    my $self = shift;
    my $message = join "", @_;
    print { $self->{logfh} } $message;
}

=head2 $smoker->ttylog( $message )

Prints a message to both the default and the logfile filehandles.

=cut

sub ttylog {
    my $self = shift;
    $self->log( @_ );
    $self->tty( @_ );
}

=head2 $smoker->smoke( $config[, $policy] )

C<smoke()> takes a B<Test::Smoke::BuildCFG::Config> object and runs all
the basic steps as (private) object methods.

=cut

sub smoke {
    my( $self, $config, $policy ) = @_;

    $self->{is_vms} and $self->_vms_rooted_logical;

    $self->make_distclean;

    $self->{v} > 1 and $self->extra_manicheck;

    $self->handle_policy( $policy, $config->policy );

    my $c_result = $self->Configure( $config );
    # Log the compiler info now, the last config could fail
    { # can we config.sh without Configure success?
        my %cinfo = get_smoked_Config( $self->{ddir} => qw(
            cc ccversion gccversion
        ));
        my $version = $cinfo{gccversion} || $cinfo{ccversion};
        $self->log( "\nCompiler info: $cinfo{cc} version $version\n" )
            if $cinfo{cc};
    }

    $c_result or do {
        $self->ttylog( "Unable to configure perl in this configuration\n" );
        return 0;
    };

    my %sconf = get_smoked_Config( $self->{ddir} => 'ldlibpthname' );
    exists $sconf{ldlibpthname} or $sconf{ldlibpthname} = "";
    $sconf{ldlibpthname} and
        local $ENV{ $sconf{ldlibpthname} } = $ENV{ $sconf{ldlibpthname} } || '',
        substr( $ENV{ $sconf{ldlibpthname} }, 0, 0) =
            "$self->{ddir}$Config{path_sep}";

    my $build_stat = $self->make_( $config );

    $build_stat == BUILD_MINIPERL and do {
        $self->ttylog( "Unable to make anything but miniperl",
                       " in this configuration\n" );
        return $self->make_minitest;
    };

    $build_stat == BUILD_NOTHING and do {
        $self->ttylog( "Unable to make perl in this configuration\n" );
        return 0;
    };

    $self->make_test_prep or do {
        $self->ttylog( "Unable to test perl in this configuration\n" );
        return 0;
    };

    $self->make_test( $config );

#    $self->{is_vms} and $self->_unset_rooted_logical;
    return 1;
}

=head2 $smoker->make_distclean( )

C<make_distclean()> runs C<< make -i distclean 2>/dev/null >>

=cut

sub make_distclean {
    my $self = shift;

    $self->tty( "make distclean ..." );
    if ( $self->{fdir} && -d $self->{fdir} ) {
        require Test::Smoke::Syncer;
        my %options = (
            hdir => $self->{fdir},
            ddir => cwd(),
            v    => 0,
        );
        my $distclean = Test::Smoke::Syncer->new( hardlink => %options );
        $distclean->clean_from_directory( $self->{fdir}, 'mktest.out' );
    } else {
        my $target = $self->{is_vms} ? 'realclean' : '-i distclean';
        $self->_make( "$target 2>/dev/null" );
    }
}

=head2 $smoker->extra_manicheck( )

C<extra_manicheck()> will only work for C<< $self->{v} > 1 >> and does
an extra integrity check comparing F<MANIFEST> and the
source-tree. Output is send to the tty.

=cut

sub extra_manicheck {
    my $self = shift;
    $self->{v} > 1 or return;

    require Test::Smoke::SourceTree;
    Test::Smoke::SourceTree->import( qw( :mani_const ) );
    my $tree = Test::Smoke::SourceTree->new( $self->{ddir} );
    my $mani_check = $tree->check_MANIFEST(qw( mktest.out mktest.rpt ));
    foreach my $file ( sort keys %$mani_check ) {
        if ( $mani_check->{ $file } == ST_MISSING() ) {
            $self->tty( "manicheck: missing '$file' (not in source-tree)\n" );
        } elsif ( $mani_check->{ $file } == ST_UNDECLARED() ) {
            $self->tty( "manicheck: extra '$file' (not in MANIFEST)\n" );
        }
    }
}

=head2 $smoker->handle_policy( $policy, @substs );

C<handle_policy()> will try to apply the substition rules and then
write the file F<Policy.sh>.

=cut

sub handle_policy {
    my $self = shift;
    my( $policy, @substs ) = @_;

    return unless UNIVERSAL::isa( $policy, 'Test::Smoke::Policy' );

    $self->tty( "\nCopy Policy.sh ..." );
    $policy->reset_rules;
    if ( @substs ) {
        $policy->set_rules( $_ ) foreach @substs;
    }
    $policy->write;
}

=head2 $smoker->Configure( $config )

C<Configure()> sorts out the MSWin32 mess and calls F<./Configure>

returns true if a makefile was created

=cut

sub Configure {
    my $self = shift;
    my( $config, $policy ) = @_;

    $self->tty( "\nConfigure ..." );
    my $makefile = '';
    if ( $self->{is_win32} ) {
        my @w32args = @{ $self->{w32args} };
        @w32args = @w32args[ 4 .. $#w32args ];
        my $w32_cfg = "$config" =~ /-DCCTYPE=/
            ? "$config" : "$config -DCCTYPE=$self->{w32cc}";

        $makefile = $self->_run( "./Configure $w32_cfg",
                                 \&Test::Smoke::Util::Configure_win32,
                                 $self->{w32make}, @w32args  );
    } elsif ( $self->{is_vms} ) {
        my $vms_cfg = $config->vms;
        $self->_run( qq/\@configure -"des" $vms_cfg/ );
        $makefile = 'DESCRIP.MMS';
    } else {
        $self->_run( "./Configure -des $config" );
        $makefile = 'Makefile';
    }
    return -f $makefile;
}

=head2 $smoker->make_( )

C<make_()> will run make.

returns true if a perl executable is found

=cut

sub make_ {
    my $self = shift;
    my $config = shift;

    $self->tty( "\nmake ..." );
    my $make_args = "";
    $self->{is_vms} && $config->has_arg( '-Dusevmsdebug' ) and
        $make_args = qq[/macro=("__DEBUG__=1")];

    $self->{is_win32} && $config->has_arg( '-Uuseshrplib' ) and
        $make_args = "static";

    my $make_output = $self->_make( $make_args );

    if ( $self->{is_win32} ) { # Win32 creates config.sh during make
        my %cinfo = get_smoked_Config( $self->{ddir} => qw(
            cc ccversion gccversion
        ));
        my $version = $cinfo{gccversion} || $cinfo{ccversion};
        $self->log( "\nCompiler info: $cinfo{cc} version $version\n" )
            if $cinfo{cc};

        $self->{w32cc} =~ /MSVC|BORLAND|GCC/ and $self->tty( "\n$make_output\n" );
    }

    my $exe_ext  = $Config{_exe} || $Config{exe_ext};
    my $miniperl = "miniperl$exe_ext";
    my $perl     = "perl$exe_ext";
    $perl = "ndbg$perl"
        if $self->{is_vms} && $config->has_arg( '-Dusevmsdebug' );
    $perl = "perl-static$exe_ext"
        if $self->{is_win32} && $config->has_arg( '-Uuseshrplib' );

    $self->{_miniperl_bin} = $miniperl;
    $self->{_perl_bin}     = $perl;

    -x $miniperl or return BUILD_NOTHING;
    return -x $perl
        ? $self->{_run_exit} ? BUILD_MINIPERL : BUILD_PERL
        : BUILD_MINIPERL;
}

=head2 make_test_prep( )

Run C<< I<make test-prep> >> and check if F<t/perl> exists.

=cut

sub make_test_prep {
    my $self = shift;
    $self->{harnessonly} and return 1; # no test-prep target

    my $perl = catfile( "t", $self->{_perl_bin} );

    $self->{run} and unlink $perl;
    $self->_make( "test-prep" );

    return $self->{is_win32} ? -f $perl : -l $perl;
}

=head2 $smoker->make_test( )

=cut

sub make_test {
    my $self = shift;

    $self->set_skip_tests;

    my( $config ) = @_;
    my $config_args = "$config";

    $self->tty( "\n Tests start here:\n" );

    # No use testing different io layers without PerlIO
    # just output 'stdio' for mkovz.pl
    my @layers = ( ($config_args =~ /-Uuseperlio\b/) || $self->{defaultenv} )
        ? qw( stdio )
        : $self->{perlio_only}
            ? qw( perlio )
            : qw( stdio perlio );

    my @locales;
    if ( !($config_args =~ /-Uuseperlio\b/ || $self->{defaultenv}) &&
         $self->{locale} ) {
        @locales = split ' ', $self->{locale};
        push @layers, ( 'locale' ) x @locales;
    }

    delete $ENV{PERL_UNICODE};
    foreach my $perlio ( @layers ) {
        my $had_LC_ALL = exists $ENV{LC_ALL};
        local( $ENV{PERLIO}, $ENV{LC_ALL} ) =
             ( "", defined $ENV{LC_ALL} ? $ENV{LC_ALL} : "" );
        my $perlio_logmsg = $perlio;
        if ( $perlio ne 'locale' ) {
            $ENV{PERLIO} = $perlio;
            $self->{is_win32} and $ENV{PERLIO} .= " :crlf";
            $ENV{LC_ALL} = 'C' if $self->{force_c_locale};
            $ENV{LC_ALL} or delete $ENV{LC_ALL};
            # make default 'make test' runs possible
            delete $ENV{PERLIO} if $self->{defaultenv};
        } else {
            my $this_locale = pop(@locales);
            $ENV{LC_ALL} = $this_locale;
            $perlio_logmsg .= ":$this_locale";
        }
        $self->ttylog( "TSTENV = $perlio_logmsg\t" );

        unless ( $self->{run} ) {
            $self->ttylog( "bailing out (--norun)...\n" );
            next;
        }

        if  ( $self->{harnessonly} ) {
            $self->log_debug("[make test] Test::Harness ONLY");

            $self->{harness3opts} and
                local $ENV{HARNESS_OPTIONS} = $self->{harness3opts};

            $self->make_test_harness( $config );

        } else {
            my $test_target = $self->{is_vms}
                ? 'test' : $self->{is56x} ? 'test-notty' : '_test';

            # MSWin32 builds from its own directory
            if ( $self->{is_win32} ) {
#                $config->has_arg( '-Uuseshrplib' )
#                    and $test_target = 'static-test';
#                $self->_run_harness_target( $test_target );
                $self->make_test_harness( $config );
            } else {
                $self->_run_TEST_target( $test_target, 1 );
            }
            $self->tty( "\n" );
        }
        !$had_LC_ALL && exists $ENV{LC_ALL} and delete $ENV{LC_ALL};
    }

    $self->unset_skip_tests;

    return 1;
}

=head2 $self->extend_with_harness( @nok )

=cut

sub extend_with_harness {
    my $self = shift;
    my %inconsistent = $self->_transform_testnames( @_ );
    my @harness = sort keys %inconsistent;
    my $harness_re1 = HARNESS_RE1();
    my $harness_re2 = HARNESS_RE2();
    if ( @harness ) {

        # @20051016 By request of Nicholas Clark
        local $ENV{PERL_DESTRUCT_LEVEL} = $self->{harness_destruct};
        local $ENV{PERL_SKIP_TTY_TEST} = 1;

        # I'm not happy with this PERLSHR approach for VMS
        local $ENV{PERLSHR} = $ENV{PERLSHR} || "";
        $self->{is_vms} and
             $ENV{PERLSHR} = catfile( $self->{ddir},
                                      'PERLSHR' . $Config{_exe} );
        my $harness = join " ", @harness;
        $self->tty( "\nExtending failures with harness:\n\t$harness\n" );
        my $changed_dir;
        chdir 't' and $changed_dir = 1;
        my $all_ok = 0;
        my $tst_perl = catfile( curdir(), 'perl' );
        my $verbose = $self->{v} > 1 ? "-v" : "";
        my @run_harness = $self->_run( "$tst_perl harness $verbose $harness" );
        my $harness_out = $self->_parse_harness_output( \%inconsistent, $all_ok,
                                                        @run_harness );

        # safeguard against empty results
        $inconsistent{ $_ } ||= 'FAILED' for keys %inconsistent;
        $harness_out =~ s/^\s*$//;
        if ( $all_ok ) {
            $harness_out .= scalar keys %inconsistent
                ? "Inconsistent test results (between TEST and harness):\n" .
                  join "", map {
                      my $dots = '.' x (40 - length $_ );
                      "    $_${dots}$inconsistent{ $_ }\n";
                  } keys %inconsistent
                : $harness_out ? "" : "All tests successful.";
        } else {
            $harness_out .= scalar keys %inconsistent
                ? "Inconsistent test results (between TEST and harness):\n" .
                  join "", map {
                      my $dots = '.' x (40 - length $_ );
                      "    $_${dots}$inconsistent{ $_ }\n";
                  } keys %inconsistent
                : "";
        }
        $self->ttylog("\n", $harness_out, "\n" );
        $changed_dir and chdir updir();
    }
}

=head2 $smoker->make_test_harness

Use Test::Harness (the test_harness target) to get the failing test
information and do not bother with TEST.

=cut

sub make_test_harness {
    my( $self, $config ) = @_;

    my $target= "test_harness";
    my $debugging = "";

    if ( $self->{is_vms} ) {

        $debugging = $config->has_arg( '-Dusevmsdebug' )
            ? qq[/macro=("__DEBUG__=1")]
            : "";

    } elsif ($self->{is_win32}) {
        $target = $config->has_arg( '-Uuseshrplib' ) ? "static-test" : "test";
    }

    if ( $self->{hasharness3} ) {
        $self->log_debug("[make_test_harness] Test::Harness >= 3");
        $self->_run_harness3_target( $target, $debugging );
    } else {
        $self->log_debug("[make_test_harness] Test::Harness < 3");
        $self->_run_harness_target( $target, $debugging );
    }
}

=head2 $smoker->_run_harness_target( $target, $extra )

The command to run C<make test_harness> differs based on platform, so
the arguments have to be passed into general routine. C<$target>
specifies the makefile-target, C<$makeopt> specifies the extra options
for the make program.

=cut

sub _run_harness_target {
    my( $self, $target, $extra ) = @_;

    my $seenheader = 0;
    my @failed = ( );

    my $harness_re1 = HARNESS_RE1();
    my $harness_re2 = HARNESS_RE2();

    my $tst = $self->_make_fork( $target, $extra );

    my ($line, $last);
    while ( $line = <$tst> ) {
        #$self->log_debug($line);

        # This line with timings only has to be logged to .out.
        $line =~ / \b (?:Files | u) = .+ Tests = [0-9]+ /xi
            and $self->log($line);

        $last and next;
        $line =~ /All tests successful/
            and push( @failed, $line ), $last++, next;

        $line =~ /Failed Test\s+Stat/
            and $seenheader = 1, next;
        $seenheader or next;

        my( $name, $fail ) = $line =~ m/$harness_re1/;
        if ( $name ) {
            my $dots = '.' x (40 - length $name );
            $self->log_debug("[known failed test] $name");
            push @failed, "    $name${dots}FAILED $fail\n";
        } else {
            ( $fail ) = $line =~ m/$harness_re2/;
            next unless $fail;
            push @failed, " " x 51 . "$fail\n";
        }
    }
    my @dump = <$tst>; # Read trailing output from pipe

    close $tst or do {
        my $error = $! || ( $? >> 8);
        require Carp;
        Carp::carp("\nerror while running harness target '$target': $error");
    };

    $self->ttylog( "\n", join( "", @failed ), "\n" );
    $self->tty( "Archived results...\n" );
}

=head2 $smoker->_run_harness3_target( $target, $extra )

The command to run C<make test_harness> differs based on platform, so
the arguments have to be passed into general routine. C<$target>
specifies the makefile-target, C<$makeopt> specifies the extra options
for the make program.

=cut

sub _run_harness3_target {
    my( $self, $target, $extra ) = @_;

    my $harness3_failed = HARNESS3_RE_FAILED();
    my $harness3_todo = HARNESS3_RE_TODO();
    my $harness3_extra = HARNESS3_RE_EXTRA();
    my $seenheader = 0;
    my @failed = ( );

    my $tst = $self->_make_fork( $target, $extra );

    my $line;
    my $file;
    my $found = 0;
    while ( $line = <$tst> ) {
        #$self->log_debug($line);

        # This line with timings only has to be logged to .out.
        $line =~ / \b (?:Files | u) = .+ Tests = [0-9]+ /xi
            and $self->log($line);

        $line =~ /All tests successful/
            and push( @failed, $line ), next;

        $line =~ /Test Summary Report/ and $seenheader = 1, next;
        $seenheader or next;

        my( $tname ) = $line =~ /^\s*(.+(?:\.t)?)\s+\(Wstat/;
        if ( $tname ) {
            if ($file and not $found) {
                $self->log_debug("[weird failed test] $file");
                push @failed, "${file}??????\n";
            }
            my $ntest = $self->_normalize_testname( $tname );
            my $dots = '.' x (60 - length $ntest);
            $file = $ntest . $dots;
            $found = 0;
            next;
        }

        my( $failed ) = $line =~ /$harness3_failed/x;
        if ( $failed ) {
            $self->log_debug("[known failed test] $file");
            push @failed, "${file}FAILED\n";
            push @failed, "    $failed\n";
            $found = 1;
            next;
        }

        my( $todo ) = $line =~ /$harness3_todo/x;
        if ( $todo ) {
            $self->log_debug("[todo test passed] $file");
            push @failed, "${file}PASSED\n";
            push @failed, "    $todo\n";
            $found = 1;
            next;
        }

        my ( $extra ) = $line =~ /$harness3_extra/x;
        if ( $extra) {
            push @failed, "    $extra\n";
            next;
        }

        my( $parse_error ) = $line =~ /^  Parse errors: (.+)/;
        if ( $parse_error ) {
            $self->log_debug("[TAP-error test] $file");
            push @failed, "${file}FAILED\n";
            push @failed, "    $parse_error\n";
            $found = 1;
            next;
        }

        my( $exit_status ) = $line =~ /^  (Non-zero exit status: .+)/;
        if ( $exit_status ) {
            $self->log_debug("[died test] $file");
            push @failed, "${file}FAILED\n";
            push @failed, "    $exit_status\n";
            $found = 1;
            next;
        }
    }
    if ($file and not $found) {
        $self->log_debug("[unknown failure] $file");
        push @failed, "${file}??????\n";
    }

    my @dump = <$tst>; # Read trailing output from pipe

    close $tst or do {
        my $error = $! || ( $? >> 8);
        require Carp;
        Carp::carp("\nerror while running harness target '$target': $error" );
    };

    $self->ttylog( "\n", join( "", @failed ), "\n" );
    $self->tty( "Archived results...\n" );
}

sub _run_TEST_target {
    my( $self, $target, $extend ) = @_;
    !$target and do {
        require Carp;
        Carp::confess("No target in _run_TEST_target");
    };

    my @nok;
    my $tst = $self->_make_fork( $target );
    my $ok;

    while (<$tst>) {
        $self->log_debug($_);
        skip_filter( $_ ) and next;

        # make mkovz.pl's life easier
        s/(.)(TSTENV\s+=\s+\w+)/$1\n$2/;

        if (m/^u=.*tests=/) {
            s/(\d\.\d*) /sprintf "%.2f ", $1/ge;
            $self->log( $_ );
        } else {
            $ok ||= m/^All tests successful/;
            push @nok, $_;
        }
        $self->tty( $_ );
    }
    close $tst or do {
        my $error = $! || ( $? >> 8);
        $self->tty("\nError while reading test-results: $error");
    };

#    $self->log( map { "    $_" } @nok );
    if ( grep m/^All tests successful/, @nok ) {
        $self->log( "All tests successful.\n" );
        $self->tty( "\nOK, archive results ..." );
        $self->{patch} and
            $nok[0] =~ s/\./ for .patch = $self->{patch}./;
    } elsif ( !$extend ) {
        $self->ttylog( map { "    $_" } @nok );
    } else {
        $self->extend_with_harness( @nok );
    }
}

=head2 $self->make_minitest

C<make> was unable to build a I<perl> executable, but managed to build
I<miniperl>, so we do C<< S<make minitest> >>.

=cut

sub make_minitest {
    my $self = shift;

    $self->ttylog( "TSTENV = minitest\t" );

    if ($self->{is_win32}) {
        $self->_run_harness_target( "minitest" );
    } else {
        $self->_run_TEST_target( "minitest", 0 );
    }

    $self->tty( "\n" );
    return 1;
}

=head2 $self->_parse_harness_output( $\%notok, $all_ok, @lines )

Factor out the parsing of the Test::Harness output, as it seems subject
to change.

=cut

sub _parse_harness_output {
    my( $self, $notok, $all_ok, @lines ) = @_;

    grep m/^Test Summary Report/ => @lines
        and return $self->_parse_harness3_output( $notok, $_[2], @lines );

    my $harness_re1 = HARNESS_RE1();
    my $harness_re2 = HARNESS_RE2();

    my $output = join "", map {
        my( $name, $fail ) = m/$harness_re1/;
        if ( $name ) {
            delete $notok->{ $name };
            my $dots = '.' x (40 - length $name );
            "    $name${dots}FAILED $fail\n";
        } else {
            ( $fail ) = m/$harness_re2/;
            " " x 51 . "$fail\n";
        }
    } grep m/$harness_re2/ || m/$harness_re1/ => map {
        /All tests successful/ && $all_ok++;
        $self->log_info( $_ );
        $_;
    } @lines;

    $_[2] = $all_ok;
    return $output;
}

=head2 $self->_parse_harness3_output( $\%notok, $all_ok, @lines )

Fator out the parsing of the Test::Harness 3 output, as it seems subject
to change.

=cut

sub _parse_harness3_output {
    my( $self, $notok, $all_ok, @lines ) = @_;

    my $harness3_failed = HARNESS3_RE_FAILED();
    my $harness3_todo = HARNESS3_RE_TODO();
    my $harness3_extra = HARNESS3_RE_EXTRA();
    my $seenheader = 0;
    my $ntest = "";
    my $file = "";
    my $found = 0;

    my @out = map {
        my $line = $_;

        my( $tname ) = $line =~ /^\s*(.+(:?\.t)?)\s+\(Wstat/;
        my( $failed ) = $line =~ /$harness3_failed/x;
        my( $todo ) = $line =~ /$harness3_todo/x;
        my( $extra ) = $line =~ /$harness3_extra/x;
        my( $parse_error ) = $line =~ /^  Parse errors: (.+)/;
        my( $exit_status ) = $line =~ /^  (Non-zero exit status: .+)/;

        if ( $tname ) {
            my $r;
            if ($file and not $found) {
                $r = "${file}??????\n";
            }

            $ntest = $self->_normalize_testname( $tname );
            my $dots = '.' x (60 - length $ntest);
            $file = "    $ntest${dots}";
            $found = 0;
            $r;
        } elsif ( $failed ) {
            delete $notok->{ $ntest };
            $found = 1;
            ($file . "FAILED\n", "        $failed\n");
        } elsif ( $todo ) {
            $found = 1;
            ($file . "PASSED\n", "        $todo\n");
        } elsif ($extra) {
            "        $extra\n"
        } elsif ( $parse_error ) {
            delete $notok->{ $ntest };
            $found = 1;
            ($file . "FAILED\n", "        $parse_error\n");
        } elsif ( $exit_status ) {
            delete $notok->{ $ntest };
            $found = 1;
            ($file . "FAILED\n", "        $exit_status\n");
        } else {
            undef;
        }
    } grep defined $_ && length $_ => map {
        $seenheader or $seenheader = $_ =~ /Test Summary Report/;
        /All tests successful/ && $all_ok++;
        $self->log_info($_);
        $seenheader ? $_ : '';
    } @lines;
    if ($file and not $found) {
        push @out, "${file}??????\n";
    }
    my $output = join "", grep defined $_ => @out;

    $_[2] = $all_ok;
    return $output;
}

=head2 $self->_transform_testnames( @notok )

C<_transform_testnames()> takes a list of testnames, as found by
C<TEST> (testname without C<.t> suffix followed by dots and a reason)
and returns a hash with the filenames relative to the C<t/> directory
as keys and the reason as value.

=cut

sub _transform_testnames {
    my( $self, @notok ) = @_;
    my %inconsistent;
    for my $nok ( @notok ) {
        $nok =~ m!^((?:\.\.[\\/])?\w+[\\/][-\w/\\]+)\.*(.*)! or next;
        my( $test_name, $status ) = ( $1, $2 );

        my $test_path = $self->_normalize_testname( $test_name );

        $inconsistent{ $test_path } ||= $status;
    }
    return %inconsistent;
}

=head2 $smoker->_normalize_testname( $test )

Normalize a testname...

=cut

sub _normalize_testname {
    my( $self, $test_name ) = @_;

    $test_name =~ s/\s+$//;
    $test_name =~ /\.t$/ or $test_name .= '.t';
    if ( $test_name !~ m|^\Q../| ) {
        $test_name = $test_name =~ /^(?:cpan|dist|ext|lib|t)\b/
            ? catfile( updir(), $test_name )
            : catfile( updir(), 't', $test_name );
    }

    my $test_base = catdir( $self->{ddir}, 'pod' );
    $test_name = rel2abs( $test_name, $test_base );

    my $test_path = abs2rel( $test_name, $test_base );
    $test_path =~ tr!\\!/! if $self->{is_win32};

    # sometimes ../t is optimized away
    $test_path !~ m|^\.\.[\\/]| and $test_path = "../t/$test_path";

    return $test_path;
}

=head2 set_skip_tests( [$unset] )

Read from a MANIFEST like file, set in C<< $self->{skip_tests} >>, and
rename the files in it with the extension F<.tskip>. If C<$unset> is
set, they will be renamed back.

=head2 unset_skip_tests

Calls C<< $self->set_skip_tests( 1 ) >>.

=cut

sub set_skip_tests {
    my( $self, $unset ) = @_;

    $self->{skip_tests} or return;
    local *SKIPTESTS;

    if ( open SKIPTESTS, "< $self->{skip_tests}" ) {
        my $action = $unset ? 'Unskip' : 'Skip';
        $self->log_info("$action tests from '$self->{skip_tests}'");
        my @libext;
        my $raw;
        while ( $raw = <SKIPTESTS> ) {
            $raw =~ m/^\s*#/ and next;
            $raw =~ s/(\S+).*/$1/s;
            if ($raw !~ m/\.t$/ and $raw !~ m/test\.pl$/) {
                next;
            }
            if ( $raw =~ m{^(?:lib|ext|cpan|dist)/} ) {
                push @libext, $raw;
                next;
            }
            my $tsrc = File::Spec->catfile( $self->{ddir}, $raw );
            next if !-f $tsrc;
            my $skip = qq[print "1..0 # SKIP Disabled by Test::Smoke\\n";\nexit 0;\n__END__\n];
            use autodie;

            open my $test_fh_r, "<:raw", $tsrc;
            my $body = do { local $/; <$test_fh_r> };
            close $test_fh_r;

            open my $test_fh_w, ">:raw", $tsrc;
            print $test_fh_w !$unset ? "$skip$body" : do { $body =~ s/^\Q$skip\E//; $body; };
            close $test_fh_w;

            $self->log_info("\t%s: %sok%s\n", $raw, '', "");
        }
        close SKIPTESTS;
        @libext and $self->change_manifest( \@libext, $unset );
    } else {
        require Carp;
        Carp::carp("Cannot open($self->{skip_tests}): $!");
    }
}

sub unset_skip_tests { $_[0]->set_skip_tests( 1 ) }

=head2 $self->change_manifest( \@tests, $unset )

=cut

sub change_manifest {
    my( $self, $tests, $unset ) = @_;

    my $mani_org = catfile $self->{ddir}, 'MANIFEST';
    my $mani_new = catfile $self->{ddir}, 'MANIFEST.ORG';
    if ( $unset ) {
        if ( -f $mani_new ) {
            my $perms = (stat $mani_new)[2] & 07777;
            chmod 0755, $mani_new;
            unlink $mani_org;
            rename $mani_new, $mani_org;
            chmod $perms, $mani_org;
        }
    } else {
        my $perms = (stat $mani_org)[2] & 07777;
        chmod 0755, $mani_org;
        rename $mani_org, $mani_new or do {
            chmod $perms, $mani_org;
            require Carp;
            Carp::carp("No skip of lib or ext tests [rename($mani_new): $!]");
            return;
        };
        local( *MANIO, *MANIN );
        if ( open MANIO, "< $mani_new" ) {
            binmode MANIO;
            if ( open MANIN, "> $mani_org" ) {
                binmode MANIN;
                my $mline;
                while ( $mline = <MANIO> ) {
                    chomp $mline;
                    ( my $fn = $mline ) =~ s/^(\S+).*/$1/;
                    if ( ! grep /\Q$fn\E/ => @$tests ) {
                        print MANIN "$mline\n";
                    } else {
                        $self->log_info("\t$fn");
                    }
                }
                close MANIN;
            }
            close MANIO;
            chmod $perms, $mani_new;
        }
    }
}

=head2 $self->_run( $command[, $sub[, @args]] )

C<_run()> returns C<< qx( $command ) >> unless C<$sub> is specified.
If C<$sub> is defined (and a coderef) C<< $sub->( $command, @args ) >> will
be called.

=cut

sub _run {
    my $self = shift;
    my( $command, $sub, @args ) = @_;

    $self->log_debug("[$command]");
    defined $sub and return &$sub( $command, @args );

    my ( $out, $err, $res ) = capture { system $command };
    $self->tty($out);
    $self->ttylog($err) if $err;
    $self->{_run_exit} = $res >> 8;
    return wantarray ? split /(\r\n|\r|\n)/, $out : $out;
}

=head2 $self->_make( $command )

C<_make()> calls C<< run( "make $command" ) >>, and does some extra
stuff to help MSWin32 (the right maker, the directory).

=cut

sub _make {
    my $self = shift;
    my $cmd = shift;
    $self->{makeopt} and $cmd = "$self->{makeopt} $cmd";
    $cmd =~ m/clean/ and $cmd =~ s/-j[0-9]+\s+//;

    return
        $self->{is_vms}   ? $self->_make_vms($cmd)
      : $self->{is_win32} ? $self->_make_win32($cmd)
      :                     $self->_run("make $cmd");
}

sub _make_win32 {
    my $self = shift;
    my $cmd = shift;

    $cmd =~ s|2\s*>\s*/dev/null\s*$|2>nul|;

    $cmd = "$self->{w32make} -f smoke.mk $cmd";
    chdir "win32" or die "unable to chdir () into 'win32'";
    my @output = $self->_run($cmd);
    chdir ".." or die "unable to chdir() out of 'win32'";
    return wantarray ? @output : join "", @output;
}

sub _make_vms {
    my $self = shift;
    my $cmd = shift;

    my $kill_err;
    # don't capture STDERR
    # @ But why? and what if we do it DOSish? 2>NUL:

    $cmd =~ s|2\s*>\s*/dev/null\s*$|| and $kill_err = 1;

    $cmd = "$self->{vmsmake} $cmd";
    my @output = $self->_run(
        $kill_err ? qq{$^X -e "close STDERR; system '$cmd'"} : $cmd
    );
    return wantarray ? @output : join "", @output;
}

=head2 $smoker->_make_fork( $target, $extra )

C<_make_fork()> opens a read pipe to the make command with C<$target>
and C<$extra> arguments for the make command.

=cut

sub _make_fork {
    my( $self, $target, $extra ) = @_;

    !defined $extra and $extra = "";

    my( $ok, $err, $cmd );
    local *TST;

    # MSWin32 builds from its own directory
    if ( $self->{is_win32} ) {
        chdir "win32" or die "unable to chdir () into 'win32'";
        # Same as in make ()
        $cmd = "$self->{testmake}$extra -f smoke.mk $target |";
        $ok = open TST, $cmd  or $err = $!;
        chdir ".." or die "unable to chdir () out of 'win32'";
    } else {
        local $ENV{PERL} = "./perl";
        $cmd = "$self->{testmake}$extra $target |";
        $ok = open TST, $cmd or $err = $!;
    }
    $ok or do {
        require Carp;
        Carp::carp("Cannot fork '$cmd': $err");
        return 0;
    };
    select ((select (*TST), $| = 1)[0]);
    return *TST;
}

=head2 $smoker->_vms__rooted_logical

This code sets up a rooted logical C<TSP5SRC> and changes the {ddir}
to that root.

=cut

sub _vms_rooted_logical {
    my $self = shift;
    return unless $^O eq 'VMS';

    Test::Smoke::Util::set_vms_rooted_logical( TSP5SRC => $self->{ddir} );
    $self->{vms_ddir} = $self->{ddir};
    $self->{ddir} = 'TSP5SRC:[000000]';

}

1;

=head1 SEE ALSO

L<Test::Smoke>

=head1 COPYRIGHT

(c) 2002-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
