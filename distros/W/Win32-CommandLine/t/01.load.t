#!perl -w  -- -*- tab-width: 4; mode: perl -*- ## no critic ( CodeLayout::RequireTidyCode Modules::RequireVersionVar )

# t/01.load.t - check module loading

# ToDO: Modify untaint() to allow UNDEF argument(s) [needs to be changed across all tests]

## no critic ( ControlStructures::ProhibitPostfixControls NamingConventions::Capitalization Subroutines::RequireArgUnpacking )
## no critic ( ProhibitStringyEval )

use strict;
use warnings;

{; ## no critic ( ProhibitOneArgSelect ProhibitPunctuationVars RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;  # DISABLE buffering (enable autoflush) on STDIN, STDOUT, and STDERR (keeps output in order)
}

use Test::More;     # included with perl v5.6.2+

diag("$^O, perl v$], $^X"); ## no critic ( ProhibitPunctuationVars )

use version qw//;
my @required_modules = ( 'CPAN::Meta' );  # @required_modules = ( '<MODULE> [<MIN_VERSION> [<MAX_VERSION>]]', ... )
my $have_required = 1;
foreach (@required_modules) { my ($module, $min_v, $max_v) = /\S+/gmsx;
    my $v = eval "require $module; $module->VERSION();";
    if ( !$v || ($min_v && ($v < version->new($min_v))) || ($max_v && ($v > version->new($max_v))) ) {
        $have_required = 0; my $out = $module . ($min_v?' [v'.$min_v.($max_v?" - $max_v":q/+/).q/]/:q//);
        diag("$out is not available");
        }
    }

plan skip_all => '[ '.join(', ',@required_modules).' ] required for testing' if not $have_required;

my $metafile = q//;
    $metafile = 'META.json'   if (($metafile eq q//) && (-f 'META.json'));
    $metafile = 'META.yaml'   if (($metafile eq q//) && (-f 'META.yaml'));
    $metafile = 'META.yml'    if (($metafile eq q//) && (-f 'META.yml'));
    # $metafile = 'MYMETA.json' if (($metafile eq q//) && (-f 'MYMETA.json'));
    # $metafile = 'MYMETA.yaml' if (($metafile eq q//) && (-f 'MYMETA.yaml'));
    # $metafile = 'MYMETA.yml'  if (($metafile eq q//) && (-f 'MYMETA.yml'));
my $have_metafile = ($metafile ne q//);
my $have_metafile_content = $have_metafile && (-s $metafile);
my $meta_href = $have_metafile_content ? CPAN::Meta->load_file( $metafile ) : undef;
my $packages_href = (defined $meta_href) ? $meta_href->{provides} : undef;

if ( !$have_metafile ) { plan tests => 1; fail("No metafile found"); exit 0; }

plan skip_all => "No packages found in '$metafile'" if not defined $packages_href or ( scalar( keys %{$packages_href} ) < 1 );

plan tests => scalar( keys %{$packages_href} ) * 2;

foreach my $module_name ( sort keys %{$packages_href} ) {
    my $message = "Missing $module_name";
    if (not defined $module_name) {
        diag $message;
        skip $message, 1;
        }

    # loadable?
    require_ok( $module_name );

    # loaded expected version?
    # note: some perl/version combos leave alpha markers in version->numify() results (eg, [from smoke testers] 5.16.3.1/0.9902 and 5.16.0.1/0.9904)
    my $module_version = $module_name->VERSION();
    my $provides_version = ${$packages_href}{$module_name}{version};
    my (  $module_version_n, $provides_version_n );
    # * remove any alpha markers and numify versions for comparison
    $module_version_n = version->parse( do { my $v = $module_version; $v =~ s/_//gmsx; $v } )->numify;
    $provides_version_n = version->parse( do { my $v = $provides_version; $v =~ s/_//gmsx; $v } )->numify;
    is( $module_version_n, $provides_version_n, q/loaded version matches metafile 'provides' information/ );

    diag( qq{$module_name $provides_version, \$$module_name->VERSION()=$module_version} );
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
