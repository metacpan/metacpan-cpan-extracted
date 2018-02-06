#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

# ToDO: modify add_test to take additional optional argument(s) which test for tests which fail correctly and for startup / breakdown evals

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;  # DISABLE buffering (enable autoflush) on STDIN, STDOUT, and STDERR (keeps output in order)
}

# untaint
# NOTE: IPC::System::Simple gives excellent taint explanations and is very useful in debugging IPC::Run3 taint errors
# $ENV{PATH}, $ENV{TMPDIR} or $ENV{TEMP} or $ENV{TMP}, $ENV{PERL5SHELL} :: all required to be un-tainted for IPC::Run3
# URLref: [Piping with Perl (in taint mode)] http://stackoverflow.com/questions/964426/why-doesnt-a-pipe-open-work-under-perls-taint-mode
{
## no critic ( RequireLocalizedPunctuationVars ProhibitCaptureWithoutTest )
$ENV{PATH}   = ($ENV{PATH} =~ /\A(.*)\z/msx, $1);
$ENV{TMPDIR} = ($ENV{TMPDIR} =~ /\A(.*)\z/msx, $1) if $ENV{TMPDIR};
$ENV{TEMP}   = ($ENV{TEMP} =~ /\A(.*)\z/msx, $1) if $ENV{TEMP};
$ENV{TMP}    = ($ENV{TMP} =~ /\A(.*)\z/msx, $1) if $ENV{TMP};
$ENV{PERL5SHELL} = ($ENV{PERL5SHELL} =~ /\A(.*)\z/msx, $1) if $ENV{PERL5SHELL};
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
}

use Test::More;             # included with perl [see Standard Modules in perlmodlib]
use Test::Differences;      # included with perl [see Standard Modules in perlmodlib]

my $haveExtUtilsMakeMaker = eval { require ExtUtils::MakeMaker; 1; };

# if ( !$ENV{HARNESS_ACTIVE} ) {
#     # not executing under Test::Harness
#     use lib qw{ blib/arch };    # only needed for dynamic module loads (eg, compiled XS) [ remove if no XS ]
#     use lib qw{ lib };          # use the 'lib' version (for ease of testing from command line and testing immediacy; so 'blib/arch' version doesn't have to be built/updated 1st)
#     }

my @modules = ( 'File::Spec', 'IPC::Run3', 'Probe::Perl' );
my $haveRequired = 1;
foreach (@modules) { if (!eval "use $_; 1;") { $haveRequired = 0; diag("$_ is not available");} }   ## no critic (ProhibitStringyEval)

plan skip_all => '[ '.join(', ',@modules).' ] required for testing' if !$haveRequired;

my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; }; # (should be AFTER any plan skip_all ...)

sub add_test;
sub test_num;
sub do_tests;

# Tests

## setup
my $perl = Probe::Perl->find_perl_interpreter;
my $script = File::Spec->catfile( 'bin', 'xx.bat' );

# untaint :: find_perl_interpreter RETURNs tainted value
$perl = ( $perl =~ m/\A(.*)\z/msx ) ? $1 : q{};     ## no critic ( ProhibitCaptureWithoutTest )

## accumulate tests

# Subshells - argument generation via subshell execution & subsequent expansion of subshell output
add_test( [ q{$( perl -e "print 0" )} ], ( q{0} ) );
add_test( [ q{$( perl -e "$x = q{abc}; $x =~ s/a|b/X/; print qq{set _x=$x\\n};" )} ], ( q{set _x=Xbc} ) );
#
add_test( [ qq{\$(" "$perl" -e "print 0" ")} ], ( q{0} ) );
# add_test( [ qq{\$(" "$perl" -e "\$x = q{abc}; \$x =~ s/a|b/X/; print qq{set _x=\$x\\n};" ")} ], ( q{set _x=Xbc} ) );
#
add_test( [ q{$( echo 0 )} ], ( q{0} ) );
add_test( [ q{$( "echo 0 & echo 1" )} ], ( q{0 1} ) );
add_test( [ q{$( "echo 0 && echo 1" )} ], ( q{0 1} ) );
add_test( [ q{$( "echo 0 || echo 1" )} ], ( q{0} ) );
#add_test( [ q{$( echo 0 & echo 1 )} ], ( q{0 1} ), { fails => 1 } );       ## FAILS, as expected; the command line is broken in two pieces by the shell @ the "&" before xx gets it; xx only sees "$( echo 0 "
#add_test( [ q{$( perl -e 'print 0' )} ], ( q{0} ), { fails => 1 } );       ## FAILS, as expected; the subshell is executed with normal shell semantics, so perl sees two arguments "'print" and 0'" causing an exception

## do tests

#plan tests => test_num() + ($Test::NoWarnings::VERSION ? 1 : 0);
plan tests => 1 + test_num() + ($haveTestNoWarnings ? 1 : 0);

ok( -r $script, "script readable" );

#my (@args, @exp, @got, $got_stdout, $got_stderr);
#$ENV{'~TEST'} = "/test";
#@args = ( q{~TEST} );
## check multiple expansion (for NORMAL characters)
#@exp = ( q{\\test} );
#eval { IPC::Run3::run3( "$perl $script $script -e @args", \undef, \$got_stdout, \$got_stderr ); chomp($got_stdout); chomp($got_stderr); if ($got_stdout ne q{}) { push @got, $got_stdout }; if ($got_stderr ne q{}) {push @got, $got_stderr}; 1; } or ( @got = ( $@ =~ /^(.*)\s+at.*$/ ) ); eq_or_diff \@got, \@exp, '[line:'.__LINE__."] testing: `@args`";

# TODO: check multiple expansion (for NON-PRINTABLE characters) -- SHOULD FAIL

do_tests(); # test
##
my @tests;
sub add_test { push @tests, [ (caller(0))[2], @_ ]; return; }       ## NOTE: caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
sub test_num { return scalar(@tests); }
## no critic (Subroutines::ProtectPrivateSubs)
sub do_tests { foreach my $t (@tests) { my $line = shift @{$t}; my @args = @{shift @{$t}}; my @exp = @{$t}; my @got; my ($got_stdout, $got_stderr); eval { IPC::Run3::run3( qq{"$perl" "$script" -e @args}, \undef, \$got_stdout, \$got_stderr ); chomp($got_stdout); chomp($got_stderr); if ($got_stdout ne q{}) { push @got, $got_stdout }; if ($got_stderr ne q{}) {push @got, $got_stderr}; 1; } or ( @got = ( $@ =~ /^(.*)\s+at.*$/ ) ); eq_or_diff \@got, \@exp, "[line:$line] testing: `@args`"; } return; }

#### SUBs

sub quotemeta_glob{
    my $s = shift @_;

    my $gc = quotemeta( q{?*[]{}~}.q{\\} );
    $s =~ s/([$gc])/\\$1/g;                 # backslash quote all glob metacharacters (backslashes as well)
    return $s;
}

sub dosify{
    # use Win32::CommandLine::_dosify
    use Win32::CommandLine;
    return Win32::CommandLine::_dosify(@_); ## no critic ( ProtectPrivateSubs )
}

sub _is_const { my $isVariable = eval { ($_[0]) = $_[0]; 1; }; return !$isVariable; }

sub untaint {
    # untaint( $|@ ): returns $|@
    # RETval: variable with taint removed

    # BLINDLY untaint input variables
    # URLref: [Favorite method of untainting] http://www.perlmonks.org/?node_id=516577
    # URLref: [Intro to Perl's Taint Mode] http://www.webreference.com/programming/perl/taint

    use Carp;

    #my $me = (caller(0))[3];
    #if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; }
    #if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = [ @_ ] if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

    for my $arg ( @{$arg_ref} ) {
        if (defined($arg)) {
            if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
            $arg = ( $arg =~ m/\A(.*)\z/msx ) ? $1 : undef;
            }
        }

    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
    }

