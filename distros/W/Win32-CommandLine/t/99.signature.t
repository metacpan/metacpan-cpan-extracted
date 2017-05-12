#!perl -w  -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;		# included with perl v5.6.2+

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

my $haveSIGNATURE = (-f 'SIGNATURE');
my $haveNonEmptySIGNATURE = (-s 'SIGNATURE');
my $haveModuleSignature = eval { require Module::Signature; 1 };
my $haveSHA = 0;
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA; 1 }; }
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA1; 1 }; }
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA::PurePerl; 1 }; }
my $haveKeyserverConnectable = eval { require Socket; Socket::inet_aton('pgp.mit.edu') };

my $message = q{};

unless ($message || $haveModuleSignature) { $message = 'Module::Signature required to check distribution SIGNATURE'; }
unless ($message || $haveSHA) { $message = 'Missing any supported SHA modules (Digest::SHA, Digest::SHA1, or Digest::SHA::PurePerl)'; }
unless ($message || $haveKeyserverConnectable) { $message = 'Unable to connect to keyserver (pgp.mit.edu)'; }

#plan skip_all => $message if $message;

unless ($message || $haveSIGNATURE) { $message = 'Missing SIGNATURE file'; }
unless ($message || $haveNonEmptySIGNATURE) { $message = 'Empty SIGNATURE file'; }

# plan skip_all => $message if $message;

plan skip_all => 'TAINT mode not supported (Module::Build is eval tainted)' if in_taint_mode();

plan tests => 2;

# pull module information and subroutines via Module::Build->current()
use Module::Build;
my $mb = Module::Build->current();
$mb->my_maniskip_init();
{## no critic ( ProhibitNoWarnings )
{no warnings qw( once redefine );
my $codeRef = $mb->can('my_maniskip');      # ref: http://www.perlmonks.org/?node_id=62737 @@ https://archive.is/pJtfr
*ExtUtils::Manifest::maniskip = $codeRef;
}}

local $ENV{TEST_SIGNATURE} = (defined $ENV{TEST_SIGNATURE} && $ENV{TEST_SIGNATURE}) || 1;   # Module::Signature only considers MANIFEST.SKIP when $ENV{TEST_SIGNATURE} is set (bug?)

# BUGFIX: ExtUtils::Manifest::manifind is File::Find::find() tainted; REPLACE with fixed version
# URLref: [Find::File and taint mode] http://www.varioustopics.com/perl/219724-find-file-and-taint-mode.html
{## no critic ( ProhibitNoWarnings )
{no warnings qw( once redefine );
my $codeRef = \&my_manifind;
*ExtUtils::Manifest::manifind = $codeRef;
}}

is($message, q{}, $message);
is(Module::Signature::verify(), Module::Signature::SIGNATURE_OK(), 'Verify SIGNATURE over distribution');


#### SUBs ---------------------------------------------------------------------------------------##


{## no critic ( ProhibitNoWarnings ProhibitPackageVars )
{no warnings qw( once );  	# avoid multiple "used only once" warnings for ExtUtils::Manifest::manifind() code PATCH
# ExtUtils::Manifest::manifind() has File::Find taint errors
# PATCH over with BUGFIX my_manifind()
# MODIFIED from ExtUtils::Manifest::manifind() v1.58
require File::Find;
require ExtUtils::Manifest;
sub my_manifind {
    my $p = shift || {};
    my $found = {};
    my $wanted = sub {
		my $name = ExtUtils::Manifest::clean_up_filename($File::Find::name);
		warn "Debug: diskfile $name\n" if $ExtUtils::Manifest::Debug;			## no critic ( ProhibitPackageVars )
		return if -d $_;

        if( $ExtUtils::Manifest::Is_VMS_lc ) {  	## no critic ( ProhibitPackageVars )
            $name =~ s#(.*)\.$#\L$1#msx;
            $name = uc($name) if $name =~ /^MANIFEST(\.SKIP)?$/imsx;
        }
		$found->{$name} = q{};
	    };

    # We have to use "$File::Find::dir/$_" in preprocess, because
    # $File::Find::name is unavailable.
    # Also, it's okay to use / here, because MANIFEST files use Unix-style
    # paths.

    # PATCH: add 'no_chdir' to File::Find::find() call [ avoids chdir taint ]
    File::Find::find({wanted => $wanted, no_chdir => 1}, $ExtUtils::Manifest::Is_MacOS ? q{:} : q{.});  	## no critic ( ProhibitPackageVars )

    return $found;
	}
}}


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
