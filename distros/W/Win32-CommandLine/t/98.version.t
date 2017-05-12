#!perl -w  -- -*- tab-width: 4; mode: perl -*-

# check for CPAN/PAUSE parsable VERSIONs ( URLref: http://cpan.org/modules/04pause.html )

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;  # DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};
plan skip_all => 'TAINT mode not supported (Module::Build is eval tainted)' if in_taint_mode();

use Module::Build;

my $mb = Module::Build->current();

my @files = @{$mb->notes('versioned_filenames_aref')};

#_or_
### untaint
##my $versioned_file_globs = untaint( $ENV{_BUILD_versioned_file_globs} );
##my @files = ( map { glob $_ } split(/;/, $versioned_file_globs) );

untaint( @files );

my $haveExtUtilsMakeMaker = eval { require ExtUtils::MakeMaker; 1; };

#my @all_files = all_perl_files( '.' );
#my @files = @all_files;
#
#my @skip_re = ( '(^/)inc/.*' );
#for (@all_files)
#   {
#
#   }

#print @files;

#print cwd();

plan skip_all => 'ExtUtils::MakeMaker required to check code versioning' if !$haveExtUtilsMakeMaker;

plan tests => scalar( @files * 3 + 1 );

ok( (scalar(@files) > 0), "Found ".scalar(@files)." files to check");
##isnt( MM_parse_version($_), 'undef', "'$_' has ExtUtils::MakeMaker parsable version") for @files;
##ok( (version_non_alpha_form(MM_parse_version($_)) =~ /[0-9]+\.[0-9_]+\.[0-9_]+/), "'$_' has at least M.m.r version") for @files;
##ok( (MM_parse_version($_) =~ /^([0-9]+\.)?[0-9]+\.[0-9_]+[_.][0-9_]+$/), "'$_' has version with correct canonical form [M.m.r[.b] and correct '_' position for alphas]") for @files;
for (@files) {
    my $v = MM_parse_version($_);
    isnt( $v, 'undef', "'$_' (v$v) has ExtUtils::MakeMaker parsable version");
    ok( (version_non_alpha_form($v) =~ /^[0-9]+\.[0-9]+$/), qq{'$_' has version ("}.version_non_alpha_form($v).qq{") in correct canonical form (M.m[_alpha])});
    ok( ($v =~ /^[0-9]+\.[0-9]+(_[0-9]+)?$/), "'$_' has version with correct '_' position for alphas (if alpha)");
    }

#-----------------------------------------------------------------------------

use Carp;

sub MM_parse_version {
    ## MM_parse_version( $ ): returns $
    # detainted version of MM->parse_version
    # Bypass taint failure in MM->parse_version when called directly with active taint-mode
    # NOTE: MM->parse_version() has EVAL taint failure ("Insecure dependency in eval while running with -T switch at c:/strawberry/perl/lib/ExtUtils/MM_Unix.pm line 2663, <$fh> line 43.")
    # ToDO: ask about this on PerlMonks; this seems kludgy
    my ($file) = shift;

    use ExtUtils::MakeMaker;
    use Probe::Perl;

    my $perl = Probe::Perl->find_perl_interpreter;

    untaint( $perl );
    $file =~ s:\\\\:\\:g;
    $file =~ s:\\:\/:g;
    untaint( $file );

    my $v = `$perl -MExtUtils::MakeMaker -e "print MM->parse_version(q{$file})"`;   ## no critic ( ProhibitBacktickOperators ) ## ToDO: revisit/remove

    return $v;
    }

sub version_non_alpha_form
{ ## version_non_alpha_form( $ ): returns $|@ ['shortcut' function]
    # version_non_alpha_form( $version )
    #
    # transform $version into non-alpha form
    #
    # NOTE: not able to currently determine the difference between a function call with a zero arg list {"f(());"} and a function call with no arguments {"f();"} => so, by the Principle of Least Surprise, f() in void context is disallowed instead of being an alias of "f($_)" so that f(@array) doesn't silently perform f($_) when @array has zero elements
    # ** use "f($_)" instead of "f()" when needed

    my $me = (caller(0))[3];    ## no critic ( ProhibitMagicNumbers )   ## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
    if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; } ## no critic ( RequireInterpolationOfMetachars ) #
    if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

    my $v_ref;
    $v_ref = \@_;
    $v_ref = [ @_ ] if defined wantarray; ## no critic (ProhibitPostfixControls) #  # break aliasing if non-void return context

    for my $v ( @{$v_ref} ) {
        if (defined($v)) {
            if (_is_const($v)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
            $v =~ s/_//g;  # numify # remove all interior '_'
            }
        }

    return wantarray ? @{$v_ref} : "@{$v_ref}";
}

use File::Spec;

## from Perl::Critic::Utils

#Readonly::Array my @skip_dir => qw( CVS RCS .svn _darcs {arch} .bzr _build blib );
#Readonly::Hash my %skip_dir => hashify( @skip_dir );
my @skip_dir = qw( CVS RCS .svn _darcs {arch} .bzr _build blib );
my %skip_dir = hashify( @skip_dir );

sub hashify {  ## no critic (ArgUnpacking)
    return map { $_ => 1 } @_;
}

sub all_perl_files
{#

    # Recursively searches a list of directories and returns the paths
    # to files that seem to be Perl source code.  This subroutine was
    # poached from Test::Perl::Critic.

    my @queue      = @_;
    my @code_files = ();

    while (@queue) {
        my $file = shift @queue;
        if ( -d $file ) {
            opendir my ($dh), $file or next;
            my @newfiles = sort readdir $dh;
            closedir $dh;

            @newfiles = File::Spec->no_upwards(@newfiles);
            @newfiles = grep { !$skip_dir{$_} } @newfiles;
            push @queue, map { File::Spec->catfile($file, $_) } @newfiles;
        }

        if ( (-f $file) && ! _is_backup($file) && _is_perl($file) ) {
            push @code_files, $file;
        }
    }
    return @code_files;
}

#-----------------------------------------------------------------------------
# Decide if it's some sort of backup file

sub _is_backup {
    my ($file) = @_;
    return 1 if $file =~ m{ [.] swp \z}xms;
    return 1 if $file =~ m{ [.] bak \z}xms;
    return 1 if $file =~ m{  ~ \z}xms;
    return 1 if $file =~ m{ \A [#] .+ [#] \z}xms;
    return;
}

#-----------------------------------------------------------------------------
# Returns true if the argument ends with a perl-ish file
# extension, or if it has a shebang-line containing 'perl' This
# subroutine was also poached from Test::Perl::Critic

##use Perl::Critic::Exception::Fatal::Generic qw{ throw_generic };

sub _is_perl {
    my ($file) = @_;

    #Check filename extensions
    return 1 if $file =~ m{ [.] PL    \z}xms;
    return 1 if $file =~ m{ [.] p[lm] \z}xms;
    return 1 if $file =~ m{ [.] t     \z}xms;

    #Check for shebang
    open my $fh, '<', $file or return;
    my $first = <$fh>;
    #close $fh or throw_generic "unable to close $file: $!";
    close $fh or die "unable to close $file: $!";   ## no critic (RequireCarping)

    return 1 if defined $first && ( $first =~ m{ \A [#]!.*perl }xms );
    return;
}

#-----------------------------------------------------------------------------

sub shebang_line {
    my $doc = shift;
    my $first_element = $doc->first_element();
    return if not $first_element;
    return if not $first_element->isa('PPI::Token::Comment');
    my $location = $first_element->location();
    return if !$location;
    # The shebang must be the first two characters in the file, according to
    # http://en.wikipedia.org/wiki/Shebang_(Unix)
    return if $location->[0] != 1; # line number
    return if $location->[1] != 1; # column number
    my $shebang = $first_element->content;
    return if $shebang !~ m{ \A [#]! }xms;
    return $shebang;
}

#-----------------------------------------------------------------------------

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

sub is_tainted {
    ## no critic ( ProhibitStringyEval RequireCheckingReturnValueOfEval ) # ToDO: remove/revisit
    # URLref: [perlsec - Laundering and Detecting Tainted Data] http://perldoc.perl.org/perlsec.html#Laundering-and-Detecting-Tainted-Data
    return ! eval { eval(q{#} . substr(join(q{}, @_), 0, 0)); 1 };
    }

sub in_taint_mode {
    ## no critic ( RequireBriefOpen RequireInitializationForLocalVars ProhibitStringyEval RequireCheckingReturnValueOfEval ProhibitBarewordFileHandles ProhibitTwoArgOpen ) # ToDO: remove/revisit
    # modified from Taint source @ URLref: http://cpansearch.perl.org/src/PHOENIX/Taint-0.09/Taint.pm
    my $taint = q{};

    if (not is_tainted( $taint )) {
        $taint = substr("$0$^X", 0, 0);
        }

    if (not is_tainted( $taint )) {
        $taint = substr(join("", @ARGV, %ENV), 0, 0);
        }

    if (not is_tainted( $taint )) {
        local(*FILE);
        my $data = q{};
        for (qw(/dev/null nul / . ..), values %INC, $0, $^X) {
            # Why so many? Maybe a file was just deleted or moved;
            # you never know! :-)  At this point, taint checks
            # are probably off anyway, but this is the ironclad
            # way to get tainted data if it's possible.
            # (Yes, even reading from /dev/null works!)
            #
            last if open FILE, $_
            and defined sysread FILE, $data, 1
            }
        close( FILE );
        $taint = substr($data, 0, 0);
        }

    return is_tainted( $taint );
    }
