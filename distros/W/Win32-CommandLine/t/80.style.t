#!perl -w  -- -*- tab-width: 4; mode: perl -*- ## no critic ( CodeLayout::RequireTidyCode Modules::RequireVersionVar )

# t/01.style.t - test for style rule breaks

# ToDO: Modify untaint() to allow UNDEF argument(s) [needs to be changed across all tests]

## no critic ( ControlStructures::ProhibitPostfixControls NamingConventions::Capitalization Subroutines::RequireArgUnpacking )
## no critic ( ProhibitStringyEval )

use strict;
use warnings;
use English qw( -no_match_vars ); # enable long-form built-in variable names; '-no_match_vars' avoids regex performance penalty for perl versions <= 5.16

{; ## no critic ( ProhibitOneArgSelect ProhibitPunctuationVars RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;  # DISABLE buffering (enable autoflush) on STDIN, STDOUT, and STDERR (keeps output in order)
}

use Test::More;     # included with perl v5.6.2+

use version qw//;
my @required_modules = ( );  # @required_modules = ( '<MODULE> [<MIN_VERSION> [<MAX_VERSION>]]', ... )
my $have_required = 1;
foreach (@required_modules) { my ($module, $min_v, $max_v) = /\S+/gmsx;
    my $v = eval "require $module; $module->VERSION();";
    if ( !$v || ($min_v && ($v < version->new($min_v))) || ($max_v && ($v > version->new($max_v))) ) {
        $have_required = 0; my $out = $module . ($min_v?' [v'.$min_v.($max_v?" - $max_v":q/+/).q/]/:q//);
        diag("$out is not available");
        }
    }

plan skip_all => '[ '.join(', ',@required_modules).' ] required for testing' if not $have_required;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless ($ENV{TEST_AUTHOR} or $ENV{AUTHOR_TESTING}) or ($ENV{TEST_RELEASE} or $ENV{RELEASE_TESTING}) or $ENV{TEST_ALL} or $ENV{CI};
plan skip_all => 'TAINT mode not supported (Module::Build is eval tainted)' if in_taint_mode();

use Module::Build;

my $mb;

my $have_MB_current = eval { $mb = Module::Build->current(); 1; };
plan skip_all => 'Module::Build->current() is not available' if not $have_MB_current;

plan skip_all => 'No repository file list found' if not defined $mb->notes('repo_files');
plan skip_all => 'Empty repository file list found' if not @{$mb->notes('repo_files')};

my %files;
foreach ( @{$mb->notes('repo_files')} ) { $files{$_}++; };
if (defined $mb->notes('repo_files_binary')) { foreach ( @{$mb->notes('repo_files_binary')} ) { delete $files{$_}; }; };
foreach ( keys %files ) { delete $files{$_} if -d; };
my @files = sort keys %files;

plan tests => 1 + (scalar( @files ) * 5);

ok( (scalar(@files) > 0), 'Found '.scalar(@files).' repository files to check');

foreach my $file ( @files ) {
    # diag( qq{file: "$_"} );
    my $file_contents;
    if ( not -f $file ) { my $msg = 'Missing file: "'.$file.'"'; diag($msg); }
    else  {
        my $fh;
        open( $fh, '< :raw :encoding(UTF-8)', $file ) or die qq{Can't open "$file": $OS_ERROR\n};
        {# slurp entire file
            local $/ = undef;
            $file_contents = <$fh>;
        }
        close $fh or die qq{Can't close "$file" after reading: $OS_ERROR\n}; ## no critic ( RequireCarping )
        }
    $file_contents = q// if not defined $file_contents;

    my $message;

    #:: 1. Test for required line endings
    $message = qq{"$file" has required line endings (LF whenever possible, CRLF for .BAT/.CMD)};
    my $has_MAC_EOL = ( $file_contents =~ m/\r([^\n]|\z)/msx ) ? 1 : 0;     # CR EOL
    my $has_DOS_EOL = ( $file_contents =~ m/\r\n/msx ) ? 1 : 0;             # CRLF EOL
    # my $has_NIX_EOL = ( $file_contents =~ m/[^\r]\n/msx ) ? 1 : 0;          # LF EOL
    # my $size = -s $file;
    my $is_bat = ( $file =~ m/[.](bat|cmd)$/imsx ) ? 1 : 0;
    my $EOL_ok = not ( $has_MAC_EOL || ($has_DOS_EOL && (not $is_bat)) || ((not $has_DOS_EOL) && $is_bat) );
    # diag(qq{"$file", has_CR=$has_CR_EOL, has_CRLF=$has_CRLF_EOL, has_LF=$has_LF_EOL, size=$size, is_bat=$is_bat, ok=$ok});
    is( $EOL_ok, 1, $message );

    #:: simplify further testing by normalizing to LF EOLs
    $file_contents =~ s/\r\n|\r/\n/gmsx;

    #:: 2. Test for prohibited TABs within leading whitespace
    #:: 3? ? test that makefiles have ONLY leading tabs?
    $message = qq{"$file" has no prohibited TABs within leading whitespace};
    if ( $file =~ /^[Mm]akefile([.].*)?$/msx ) {
        # * exclude makefiles (which require leading TABs)
        pass($message);
       } else {
        is( ( $file_contents =~ m/^\s*\t/msx ) ? 1 : 0, 0, $message );
        }

    #:: 4. Test for files with lines having trailing whitespace
    $message = qq{"$file" has no lines with trailing whitespace};
    # ref: https://stackoverflow.com/questions/3469080/match-whitespace-but-not-newlines[`@`](http://archive.is/qulXQ)
    my $have_trailing_whitespace = ( $file_contents =~ m/[^\S\n]\n/msx ) ? 1 : 0;
    is( $have_trailing_whitespace, 0, $message );
    if ( $have_trailing_whitespace ) {
        # diag(qq{"$file" has trailing whitespace\n} );
        my @lines = split /\n/, $file_contents;
        # diag(qq{"$file" has }.scalar(@lines).qq{ lines trailing whitespace\n} );
        for ( my $i = 0; $i < scalar(@lines); $i++ ) {
            # diag( "\$i = $i\n" );
            if ( $lines[$i] =~ m/[^\S\n]$/msx ) { diag( qq{"$file":}.($i+1).qq{ has trailing whitespace\n} ); };
            }
        }

    #:: 5. Test for files with BOM
    $message = qq{"$file" has no initial BOM};
    is( ( $file_contents =~ m/\A[\xEF][\xBB][\xBF]/msx ) ? 1 : 0, 0, $message );

    #:: 6. Test for files (containing content) without trailing newline
    $message = qq{"$file" has trailing newline};
    is( ((not -s $file) || ( $file_contents =~ m/[\r\n]\z/msx )) ? 1 : 0, 1, $message );

    }

#### SUBs ---------------------------------------------------------------------------------------##

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
        if (defined $arg) {
            if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
            $arg = ( $arg =~ m/\A(.*)\z/msx ) ? $1 : undef;
            }
        }

    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
    }

sub is_tainted {
    ## no critic ( ProhibitStringyEval RequireCheckingReturnValueOfEval ProhibitParensWithBuiltins ) # ToDO: remove/revisit
    # URLref: [perlsec - Laundering and Detecting Tainted Data] http://perldoc.perl.org/perlsec.html#Laundering-and-Detecting-Tainted-Data
    return ! eval { eval(q{#} . substr(join(q{}, @_), 0, 0) ); 1 };
    }

sub in_taint_mode {
    ## no critic ( RequireBriefOpen RequireInitializationForLocalVars ProhibitStringyEval RequireCheckingReturnValueOfEval ProhibitBarewordFileHandles ProhibitTwoArgOpen ProhibitParensWithBuiltins ProhibitPunctuationVars ) # ToDO: remove/revisit
    # modified from Taint source @ URLref: http://cpansearch.perl.org/src/PHOENIX/Taint-0.09/Taint.pm
    my $taint = q{};

    if (not is_tainted( $taint )) {
        $taint = substr("$0$^X", 0, 0);
        }

    if (not is_tainted( $taint )) {
        $taint = substr(join(q//, @ARGV, %ENV), 0, 0);
        }

    if (not is_tainted( $taint )) {
        local(*FILE); ## no critic ( ProhibitLocalVars )
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
        () = close( FILE );
        $taint = substr($data, 0, 0);
        }

    return is_tainted( $taint );
    }
