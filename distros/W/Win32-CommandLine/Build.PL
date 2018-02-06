#!perl -w   -- ## emacs -*- tab-width: 4; mode: cperl; indent-tabs-mode: nil; basic-offset: 2 -*- ## (jedit) :tabsize=4:mode=perl: ## (notepad++) vim:ts=4:sw=2:et:sta:sts=2 ## no critic ( CodeLayout::RequireTidyCode Modules::ProhibitExcessMainComplexity )
#$Id: Build.PL,v 0.4.1.340 ( r112:594c42f8f73c [mercurial] ) 2013/12/26 05:30:45 rivy $

## no critic ( CodeLayout::ProhibitParensWithBuiltins RequireExtendedFormatting RequireLineBoundaryMatching RequireCarping )

## ToDO: expand upon assert_os to allow or disallow OS subtypes (Win9x, XP, ME, etc)

## TODO?: remove the '_' from the version for output dist files (>> will this cause a problem for PPM or CPAN with some sort of version mismatch between filename and META.yml
## TODO?: .. or just remove VERSION code generating the alpha '_' within the version? does it matter? does the '_' interfere with version comparisons on CPAN?
## ...... these don't seem to be a problem

# ToDO: open a defect ticket about error leakage for checking compiler presence in ExtUtils::CBuilder :: should be done in CBuilder with STDERR redirect
# ToDO: open a defect ticket about error leakage for checking gpg presence in Module::Signature :: should be done in Module::Signature with STDERR redirect
##      # EG: #>perl -e "use File::Spec; $n = File::Spec->devnull(); if (qx{gpg --version 2>$n} =~ /GnuPG.*?(\S+)\s*$/m) { $h = $1 } else { $h = qq{NULL}; }; print $h"

## TODO: add an 'upload' action to use cpan_upload... to upload the basic distribution to CPAN
## : depends(testall) without errors

## ToDO: redirect STDERR to STDOUT for skipcheck (currently all output goes to STDERR)

## TODO: flesh out stub documentation for additional custom actions

## TODO: add/check compatibility for use of module PPM when installed (for non-ActiveState perl distributions)

## TODO: bring up to date with most recent META.yml spec and include all fields in DEFAULTS

# URLrefs:
# [META.yml Specification] http://module-build.sourceforge.net/META-spec-current.html
# [Module::Install] http://search.cpan.org/~ADAMK/Module-Install (see README info)

use strict;
use warnings;
use utf8;       # script source code is utf8 compatible/encoded
# use 5.008008;   # minimum perl version ## v5.8.8 ~ required for decent basic Unicode support
use 5.006001;   # v5.6.1: earliest tested version ## v5.5: for AUTHOR and ABSTRACT in Makefile.PL; v5.6: for 'our', three-argument open, indirect filehandles, extended versions for 'use' [URLref: http://www.dagolden.com/index.php/369/version-numbers-should-be-boring @@ https://archive.is/7PZQL @@ http://www.webcitation.org/66Z1eHR17]

use English qw( -no_match_vars ); # enable long-form built-in variable names; '-no_match_vars' avoids regex performance penalty for perl versions <= 5.16

# use lib qw/ inc /;

# use open IN => ":crlf :encoding(utf8)", OUT => ":raw :utf8";
# use open ':std';

# VERSION: major.minor.release[.build]]  { minor is ODD => alpha/beta/experimental; minor is EVEN => stable/release }
# generate VERSION from $Version: 0.1.0.198571514 $ SCS tag
# $defaultVERSION   :: used to make the VERSION code resilient vs missing keyword expansion
# $generate_alphas  :: 0 => generate normal versions; true/non-0 => generate alpha version strings for ODD numbered minor versions
# [NOTE: perl 'Extended Version' (multi-dot) format is prefered and created from any single dotted (major.minor) or non-dotted (major) versions; see 'perldoc version']
use version qw(); our $VERSION; { my $defaultVERSION = '0.4'; my $generate_alphas = 0; $VERSION = ( $defaultVERSION, qw( $Version: 0.4.1.340 $ ))[-2]; if ($VERSION =~ /^\d+([\._]\d+)?$/msx) {$VERSION .= '.0'; if (!defined($1)) {$VERSION .= '.0'}}; if ($generate_alphas) { $VERSION =~ /(\d+)[\._](\d+)[\._](\d+)(?:[\._])?(.*)/msx; $VERSION = $1.'.'.$2.((!$4&&($2%2))?'_':'.').$3.($4?((($2%2)?'_':'.').$4):q{}); $VERSION = version->new( $VERSION ); }; } ## no critic ( ProhibitCallsToUnexportedSubs ProhibitCaptureWithoutTest ProhibitNoisyQuotes ProhibitMixedCaseVars ProhibitMagicNumbers Capitalization RequireConstantVersion ProhibitEscapedMEtaCharacters )

use FindBin; () = eval {FindBin::again()}; # FindBin paranoia ## swallow errors for older FindBin without `FindBin::again()`

##- config
my %config;

## config options which are NOT configurable in config file ... ToDO: change to alternate name or use prefix 'ro_...' and logic on readin to avoid overwrites
# config must (may?) be done via a local config file [REQUIRED ... ToDO: make OPTIONAL?]     ## allows Build.PL to be maintained seperately and used without changes between modules
$config{'rc_filename'} = 'Build.PL.config'; ##  # configuration file name (in .NET style)
$config{'self_path'} = File::Spec->canonpath( $PROGRAM_NAME );
$config{'self_parent_path'} = File::Spec->canonpath( $FindBin::RealBin );
$config{'dist_path'} = $config{'self_parent_path'};

# Module::Build DEFAULTS [ ** DO NOT CHANGE, use the Build.PL.config to set the values ]
# * required
$config{'dist_name'} = undef;
$config{'dist_abstract'} = undef;
$config{'dist_author'} = undef;
$config{'license'} = undef;
# * optional
$config{'module_name'} = undef;                     # "primary" module (for construction of README, .packlist, etc); will be calculated/constructed if not defined
$config{'dist_version'} = undef;                    # will be constructed if not defined
#
$config{'exports_aref'} = undef;                    # expected symbol table exports (no obvious default; single ARRAY ref for 'default' module, or HASH of ARRAYs to specify multiple modules)
$config{'recommends_href'} = {};                    # distribution recommendations (no obvious default)
$config{'requires_href'} = {};                      # distribution requirements (no obvious default)
# ... additional meta info (default to Meta::Spec v2 format; see <https://metacpan.org/pod/CPAN::Meta::Spec>)
$config{'meta_add_href'} = {'meta-spec'=>{version=>'2'}};   # key/value pairs to "add" to META files (no obvious default except default to meta-spec v2); note: completely overwrites META ARRAY or HASH values
$config{'meta_merge_href'} = {'meta-spec'=>{version=>'2'}}; # key/value pairs to "merge" into META files (no obvious default except default to meta-spec v2); note: merges values into META ARRAY or HASH values
#
$config{'dynamic_config'} = 0;                      # Build.PL must be executed in order to determine prereqs (metadata only is not enough) [ref: <https://metacpan.org/pod/CPAN::Meta::Spec#dynamic_config>]
#
$config{'configure_requires_href'} = {              # basic distribution requirements for configuration (ie, requirements needed to run `perl Build.PL`); URLref: https://www.socialtext.net/perl5/configure_requires [@2011.04.15.2129@ http://www.webcitation.org/5xydysS2l ]
    'perl' => '5.6.1',
    'Module::Build' => '0',
    'version' => '0.77',                                    ## version v0.77+ needed for v5.10+ extended version support & declare->()
    # Build.PL
    'Cwd' => '0',
    'Config' => '0',
    'File::Basename' => '0',
    'File::Find' => '0',
    'File::Spec' => '0', 'File::Spec::Functions' => '0',
    'FindBin' => '0',
    # subclass code
    'ExtUtils::Manifest' => '1.54',                         ## ExtUtils::Manifest v1.54+ only needed for clients with MANIFEST file names containing internal whitespace; added here for convenience
    'File::Basename' => '0',
    'File::Glob' => '0',
    'File::Spec' => '0', 'File::Spec::Functions' => '0',
    'File::Path' => '0',
    'File::Which' => '0',
    'IO::File' => '0',
    'Text::Template' => '1.44',                             ## Text::Template v1.44+ required for minimally complete Text::Template API
    'URI' => 0,
    # * TAP::Harness hack/manipulation
    'TAP::Harness' => '0', 'TAP::Formatter::Console' => '0', 'TAP::Formatter::Color' => '0',
    };
$config{'build_requires_href'} = {                  # distribution requirements to build / install (eg, `build` and `build install`)
    %{$config{'configure_requires_href'}},
    };
$config{'test_requires_href'} = {                   # distribution requirements to test (eg, `build test`)
    %{$config{'build_requires_href'}},
    # module requirements for the usual basic tests
    'Carp' => '0',
    'CPAN::Meta' => '0',
    'ExtUtils::Manifest' => '1.54',                         ## ExtUtils::Manifest v1.54+ only needed for clients with MANIFEST file names containing internal whitespace; added here for convenience
    'File::Spec' => '0', 'File::Spec::Functions' => '0',
    'Module::Build' => '0',
    'Probe::Perl' => '0',
    'Test::CPAN::Meta' => '0',
    'Test::CPAN::Meta::JSON' => '0',
    'Test::Differences' => '0', 'Test::More' => '0',        ## Test::More + Test::Differences
    'version' => '0.77',                                    ## version v0.77+ needed for v5.10+ extended version support & declare->()
    };
$config{'sign'} = 'true';                           # always sign the distribution, if possible (note: this is only used when the distribution is built/tested (or when testing the author signature ($ENV{TEST_ALL} or $ENV{TEST_SIGNATURE} are set)))
$config{'create_readme'} = 'true';                  # create README from module pod
$config{'create_metafile_pl'} = 'small';            # pass all Makefile.PL functionality to Build.PL, but requires Module::Build (ERROR if Module::Build is missing; so, use 'configure_requires=>Module::Build') [see PerlDOC: module::build::compat]
$config{'recursive_test_files'} = undef;            # scan the ./t directory recursively for *.t perl files to execute during testing (no obvious default)
$config{'no_index_href'} = { directory => [ 'inc', 't', 'xt' ] };   # private files/directories/packages/namespaces; will not be indexed and listed on CPAN
$config{'script_files_aref'} = [];                  # alternate script/executable file locations
$config{'pm_files_href'} = {};                      # alternate PM file locations [to help with MakeMaker transitions]
$config{'pod_files_href'} = {};                     # alternate POD file locations [to help with MakeMaker transitions]
$config{'xs_files_href'} = {};                      # alternate XS file locations [to help with MakeMaker transitions]
$config{'PL_files_href'} = {};                      # perl files to execute during processing (usually to generated .PL files from templates {see Module::Build::API docmentation under "PL_files"})
$config{'PL_folders_aref'} = [ 'PL{,.#no-dist}' ];  # globs matching folders used to hold templating PL files; after config file processing, entries are added into the PL_files href for each matching PL file within the template folder(s) (target file location within the distribution is set automatically, reflected from the corresponding PL file location within the PL folder to the main distribution directory)
$config{'c_source'} = undef;                        # c source files to compile
$config{'config_href'} = {};                        # modify Config.pm values for the build
# clean == all files which should not be distributed and are not comitted to repo
# realclean == all build constructed files that are not committed to repo
# veryclean == ALL build constructed files
# ToDO: use repo functions to automatically construct the defaults; add a built_files hash
$config{'add_to_cleanup_aref'} = [ 'MANIFEST.bak', 'Makefile', 'Makefile.old', 'pm_to_blib', 'MYMETA.json', 'MYMETA.yml', 'SIGNATURE' ];    # globs matching extra files to clean up during "build clean"
$config{'add_to_realcleanup_aref'} = [ 'MANIFEST' ];    # globs matching extra files to clean up during "build realclean" (note: MANIFEST is always automatically generated from MANIFEST.SKIP)
$config{'add_to_verycleanup_aref'} = [ 'META.json', 'META.yml' ];    # globs matching extra files to clean up during "build veryclean"
$config{'assert_os_aref'} = [];                     # limit build to specific OS types (default = [] => any OS) [NOTE: entries are used as REGEXs for comparison VS $^O]
#
$config{'add_to_versioned_aref'} = [ 'bin/*' ]; # globs matching extra files which should have the distribution version number upon a successful build (these are added to the list of all files containing "provides" modules)
#
$config{'repo_commit_id_length_medium'} = 12;       # length of 'medium' commit ID ('excellent' chance of uniqueness vs other commits within the repo; conflict chance ~(# repo commits):100,000,000,000,000)
$config{'repo_commit_id_length_short'} = 6;         # length of 'short' commit ID ('good' chance of uniqueness vs other commits within the repo; conflict chance ~(# repo commits):10,000,000)
$config{'repo_commit_id_length_tiny'} = 4;          # length of 'tiny' commit ID ('likely' chance of uniqueness vs other commits within the repo; conflict chance ~(# repo commits):50,000)
#
$config{'custom_code_href'} = {};                   # custom code overrides from config
# $config{'custom_ENV_href'} = {};                    # custom environment overrides (set before each dispatch) for state transfer to subordinate executables [default $ENV{_BUILD_dist_name} == $config{'dist_name'} [SET after Build.PL.config is read, unless set within config]]
#
$config{'dist_cpan'} = undef;                       # CPAN web front-end (URL; no obvious default)
$config{'dist_cpan_id'} = undef;                    # CPAN ID (URL; no obvious default)
$config{'dist_issues'} = undef;                     # issue tracker web front-end (URL; no obvious default)
$config{'dist_metacpan'} = undef;                   # MetaCPAN web front-end (URL; no obvious default)
$config{'dist_metacpan_id'} = undef;                # MetaCPAN ID (URL; no obvious default)
$config{'dist_repo'} = undef;                       # public repository (URL; no obvious default)
$config{'dist_repo_host'} = undef;                  # hostname of public repository (URL; no obvious default)
$config{'dist_repo_id'} = undef;                    # public repository ID (URL; no obvious default)
$config{'dist_repo_path'} = undef;                  # path of public repository (URL; no obvious default)
$config{'dist_repo_web'} = undef;                   # public repository web front-end (URL; no obvious default)
$config{'dist_repo_web_host'} = undef;              # hostname of public repository web front-end (URL; no obvious default)
$config{'dist_repo_web_path'} = undef;              # path of public repository web front-end (URL; no obvious default)

##

use Cwd qw//;
use Config;
use File::Basename qw/ dirname /;
use File::Find qw//;
use File::Spec;
use File::Spec::Functions qw/ rel2abs /;
use Module::Build;
use URI;

# Build.PL must be located in the main directory of the distribution (all described paths are relative to the main distribution directory)
# Build.PL expects to be executed with CWD == the Build.PL containing directory == the main directory of the distribution
# ToDO: relax this? allowing Build.PL to be re-located as long as 'dist_path' is recalculated in rc file?
if ( File::Spec->canonpath( $FindBin::RealBin ) ne File::Spec->canonpath( Cwd::getcwd ) ) { die 'Must execute Build.PL from the base directory' }

# # $config{} helper variables
# $config{'lib_path'} = undef;                        # auto-generated from $config{'dist_name'} during .config file parsing (should NOT be set in .config, since it is regenerated after each successful $config{'dist_name'} parse in the .config parsing section)
# $config{'module_path'} = undef;                     # auto-generated from $config{'dist_name'} during .config file parsing (should NOT be set in .config, since it is regenerated after each successful $config{'dist_name'} parse in the .config parsing section)

# pull in needed custom builder code
my %code = rivy_builder_code_subs();
() = eval $code{q/#/};                ## no critic ( ProhibitStringyEval )  ## init / prereq
() = eval $code{q/@/.'version'};      ## no critic ( ProhibitStringyEval )  ## version loading / manipulation
# () = eval $code{q/@/.'repo'};         ## no critic ( ProhibitStringyEval )  ## repo code

# $config{VERSION}
# * generated from any existing VERSION file in the main directory
$config{'VERSION_filename'} = 'VERSION';
%config = ( %config, version_from_vfile( rel2abs($config{'VERSION_filename'}, $config{'dist_path'}) ) );
if ( defined $config{'VERSION'} ) { my $v = $config{'VERSION'}; $v =~ s/^v//imsx; $config{'dist_version'} = $v; }

# include configuration options, if the file exists
# config file format:
# <var_name1> => <value>...
# ...
# <var_nameN> => <value>...
#
# where each "<var_name> => <value>" follows perl hash entry definition semantics (including embedded comments)
# ToDO: <value> can be multiline, terminated by EOF or next '<var_nameM> => ...' line
my $config_filename = rel2abs($config{'rc_filename'}, $config{'dist_path'});
#print "config => ".$config_filename;
if ( -e $config_filename )
{
    my $comment_chars = q{#};
    my $fh = undef;
    open( $fh, '<', $config_filename ) or die qq{Can't open "$config_filename": $OS_ERROR\n};
    my $line = 0;
    while ( my $s = <$fh> )
    {
        $line++;
        #eval $s;
        my ( $key, $value );
        if ( $s =~ m/^\s*$/msx )                            { next; }    # skip any blank line
        if ( $s =~ m/^\s*(?:[$comment_chars]|\/\/).*$/msx ) { next; }    # skip any line starting with '#', ';', q{'}, or '//' as a comment line
        if ( $s =~ m/^\s*(.*?)\s*=>\s*(.*)$/msx )
        { ## quoted values are allowed with perl quoting semantics
            $key   = $1;
            $value = $2;
            if ( $key =~ m/^user_/msx || exists $config{$key} )
            { ## eval $value into $config{}
                my $ev = q/$/.'config'."{$key} = $value";
                my $e = 0; my $w = 0;
                $SIG{'__WARN__'} = sub { if (!$w) {chomp($w = $_[0]);} };
                $e = !eval "$ev; 1"; ## no critic ( ProhibitStringyEval )
                # print STDERR "w = $w\n";
                $SIG{'__WARN__'} = 'DEFAULT';   ## NOTE: 'IGNORE' is not supported by $SIG{'__WARN__'} [URLrefs: [perlvar - %SIG] http://perldoc.perl.org/perlvar.html#%SIG , [Perl's Warn and Die Signals] http://www.perlmonks.org/?node_id=51097 , http://www.perlmonks.org/?node_id=673637 ]
                if ($w || $e) {warn qq{build: warning, malformed configuration entry: "$config_filename", line $line\n};}
                if ($key eq 'dist_name' && (not defined $config{'module_name'})) {
                    # guess module_name
                    $config{'module_name'} = $config{'dist_name'}; $config{'module_name'} =~ s/-/::/gmsx;
                    }
                # if ($key eq 'dist_name') {
                # # if ($key eq 'module_name') {
                #     # $config{'lib_path'} = 'lib/' . join( q{/}, split( /::/xms, ( $config{'module_name'} =~ m/(.*)::.*?$/xms ? $1 : q{} ) ) );   # relative path to the module's lib location (using standard Module::Builder rules)
                #     # $config{'module_path'} = $config{lib_path} . q{/} . (split(q{::},$config{module_name}))[-1] . '.pm';                        # relative path to the usual location of a module's package file (using 'lib_path')
                #     # early construction of dist_version_from from dist_name, if not already defined
                #     if ( ! $config{dist_version_from} ) { $config{dist_version_from} = 'lib/' . join( q{/}, split(/-/msx, $config{'dist_name'}) ) . '.pm'; }
                #     }
                if ($key eq 'dist_repo') {
                    my $url = URI->new( $config{'dist_repo'} );
                    $config{'dist_repo_host'} = $url->authority if not defined $config{'dist_repo_host'};
                    $config{'dist_repo_path'} = $url->path if not defined $config{'dist_repo_path'};
                    }
                if ($key eq 'dist_repo_web') {
                    my $url = URI->new( $config{'dist_repo_web'} );
                    $config{'dist_repo_web_host'} = $url->authority if not defined $config{'dist_repo_web_host'};
                    $config{'dist_repo_web_path'} = $url->path if not defined $config{'dist_repo_web_path'};
                    }
                if ($key eq 'VERSION_filename') {
                    # determine VERSION from file, if present
                    %config = ( %config, version_from_vfile( rel2abs($config{'VERSION_filename'}, $config{'dist_path'}) ) );
                    if ( defined $config{'VERSION'} ) { my $v = $config{'VERSION'}; $v =~ s/^v//i; $config{'dist_version'} = $v; }
                    }
            }
            else { die qq{Unknown configuration key '$key' @ ("$config_filename", line $line)\n}; }
        }
        else { die qq{Malformed configuration line @ ($config_filename, line $line)\n}; }
    }
    close $fh or die qq{Can't close "$config_filename" after reading: $OS_ERROR\n};
}

# print STDERR '$config{VERSION} = '.($config{VERSION} ? $config{VERSION} : q{})."\n";
# print STDERR '$config{VERSION} = '.($config{VERSION} ? $config{VERSION} : q{})."\n";

# SETUP PL_files from PL_folders, if needed
if ( @{$config{'PL_folders_aref'}} > 0 )
    {
    my $OS_no_case = File::Spec->case_tolerant();

    my @PL_globs = @{$config{'PL_folders_aref'}};
    my @PL_folders = map { glob } @PL_globs;

    my %files;
    foreach my $folder ( @PL_folders ) {
        if ( -e $folder ) {
            my $match_re = ($OS_no_case ? '(?i)' : q{}) . '[.](?i:pl)$';
            my $subst_re = ($OS_no_case ? '(?i)' : q{}) . "^$folder\/(.*)[.](?i:pl)\$";
            File::Find::find( sub { my $f_s = $File::Find::name; my $f_d = $f_s; /$match_re/ && ( $f_d =~ s/$subst_re/$1/ ) && ( $files{$f_s} = $f_d ) }, $folder );
            }
        }
    $config{'PL_files_href'} = { %{$config{'PL_files_href'}}, %files };
    ##my @files = %files;
    ##print "PL files in PL_folders = [ @files ]\n";
    }

# SETUP PL_target_files
my %PL_target_files;
while (my (undef, $to) = each %{$config{'PL_files_href'}}) {
    $PL_target_files{$to} = 1;
    }
$config{'PL_target_files_href'} = { %PL_target_files };

# SETUP versioned_files
# if ( @{$config{'add_to_versioned_aref'}} <= 0 ) { $config{'add_to_versioned_aref'} = [ $config{module_path}, qw( bin/* ) ] };
##if ( @{$config{'versioned_file_globs_exclude_aref'}} <= 0 ) { $config{'versioned_file_globs_exclude_aref'} = [ qw( bin/*.pl.pl ) ] };
## ToDO: add PL_file targets ... or take from META / provides {module => file / version}
# if ( @{$config{'add_to_versioned_aref'}} <= 0 ) { $config{'add_to_versioned_aref'} = [ $config{module_path}, values %{$config{'PL_files_href'}} ] };
# if ( @{$config{'add_to_versioned_aref'}} <= 0 ) { $config{'add_to_versioned_aref'} = [ $config{dist_version_from}, qw( bin/* ) ] };
$config{'add_to_versioned_aref'} = [ @{$config{'add_to_versioned_aref'}}, ( grep { defined && /[.](?:bat|cmd|pl|pm)$/imsx } keys %{$config{'PL_target_files_href'}} ) ];

#use Data::Dumper;
#print Dumper( %config );
#print Dumper( $config{'dist_name'} );
#print Dumper( $config{'os_req'} );

##
##

# UPDATE files for 'clean'
# * if using MSVC compiler ('cl'), add Visual C debug files ('vc[1-9][0-9]*.pdb') to cleanup
if (lc($Config{'cc'}) eq 'cl') { $config{'add_to_cleanup_aref'} = [ 'vc[1-9][0-9]*.pdb', @{$config{'add_to_cleanup_aref'}} ]; }

# UPDATE files for 'realclean'
# * automatically add Makefile.PL to cleanup if $config{'create_metafile_pl'} == ANY
if ($config{'create_metafile_pl'}) { $config{'add_to_realcleanup_aref'} = [ 'Makefile.PL', @{$config{'add_to_realcleanup_aref'}} ]; }
# * automatically add README to cleanup if $config{'create_readme'} == 'true'
if ($config{'create_readme'}) { $config{'add_to_realcleanup_aref'} = [ 'README', @{$config{'add_to_realcleanup_aref'}} ]; }

# UPDATE files for 'veryclean'
# * automatically add PL_target_files
$config{'add_to_verycleanup_aref'} = [ sort keys %{$config{'PL_target_files_href'}}, @{$config{'add_to_verycleanup_aref'}} ];

##

if ( ! $config{'dist_name'} && ! $config{'module_name'} ) { die 'Either $config{dist_name} or $config{module_name} must be defined' . "\n"; } ## no critic ( RequireCarping RequireInterpolation )

if ( ! $config{'dist_abstract'} ) { die '$config{dist_abstract} must be defined' . "\n"; } ## no critic ( RequireCarping RequireInterpolation )
if ( ! $config{'dist_author'} )   { die '$config{dist_author} must be defined' . "\n"; } ## no critic ( RequireCarping RequireInterpolation )
if ( ! $config{'license'} )       { die '$config{license} must be defined' . "\n"; } ## no critic ( RequireCarping RequireInterpolation )

if ( defined $config{'VERSION'} ) { my $v = $config{'VERSION'}; $v =~ s/^v//imsx; $config{'dist_version'} = $v; }

#assert( $config{'lib_path'} ) # should be defined if $config{'dist_name'} has been parsed (as asserted above)

# if ( !$config{'custom_ENV_href'}->{'_BUILD_dist_name'} ) { $config{'custom_ENV_href'}->{'_BUILD_dist_name'} = $config{'dist_name'}; }
##if ( !$config{'custom_ENV_href'}->{'_BUILD_versioned_file_globs'} ) { $config{'custom_ENV_href'}->{'_BUILD_versioned_file_globs'} = join(q{;}, ( $config{module_path}, qw( bin/*.pl bin/*.bat ) )); }   ## versioned files default to main file and all files in the bin directory
## ToDO: # CHANGE: '_BUILD_versioned_file_globs' => [ map {recursive_glob} qw{lib/*.pm bin/*.bat bin/*.pl} ]

#use lib 'inc';
#require Devel::AssertOS; import Devel::AssertOS ( @{$config{'assert_os_aref'}} );
# [DONE: WORKS fine] TODO: check with CPAN testers whether the current failure output string is close enough to the 'standard' "OS unsupported\n" string so that test failures are NA for unsupported OS's
if (defined($config{'assert_os_aref'}) && @{$config{'assert_os_aref'}}) { my $found = 0; for my $os (@{$config{'assert_os_aref'}}) { $found = 1 if $^O =~ /$os/; }; if (!$found) { die "OS unsupported : $config{dist_name} is designed to be used for ( @{$config{assert_os_aref}} ) systems only - installation aborted\n";}; }; ## no critic (Variables::ProhibitPunctuationVars ErrorHandling::RequireCarping)

my $class = Module::Build->subclass( class => 'RIVY::Builder', code => rivy_builder_code() );
my %optional_args = ();     # Module::Build::new() optional args (only included if they are non-empty; otherwise, if included as empty list(s)/hash(es) in new(), Module::Build carps that the specified [and needed] files are missing)
if ( keys %{$config{'meta_add_href'}} )             { %optional_args = ( %optional_args, meta_add =>  { %{$config{'meta_add_href'}} }); }
if ( keys %{$config{'meta_merge_href'}} )           { %optional_args = ( %optional_args, meta_merge =>  { %{$config{'meta_merge_href'}} }); }
if ( keys %{$config{'configure_requires_href'}} )   { %optional_args = ( %optional_args, configure_requires =>  { %{$config{'configure_requires_href'}} }); }
if ( keys %{$config{'test_requires_href'}} )        { %optional_args = ( %optional_args, test_requires =>  { %{$config{'test_requires_href'}} }); }
if ( keys %{$config{'no_index_href'}} )             { %optional_args = ( %optional_args, no_index =>  { %{$config{'no_index_href'}} }); }
if ( @{$config{'script_files_aref'}} )              { %optional_args = ( %optional_args, script_files => [ @{$config{'script_files_aref'}} ]); }
if ( keys %{$config{'pm_files_href'}} )             { %optional_args = ( %optional_args, pm_files =>  { %{$config{'pm_files_href'}} }); }
if ( keys %{$config{'pod_files_href'}} )            { %optional_args = ( %optional_args, pod_files => { %{$config{'pod_files_href'}} }); }
if ( keys %{$config{'xs_files_href'}} )             { %optional_args = ( %optional_args, xs_files =>  { %{$config{'xs_files_href'}} }); }
my $build = $class->new(
    get_options => { color => { type => '=s' } }, ## option to output in color ## OPTION color => 0/never/no/off; 1/on/yes; always # parsed in dispatch()

    module_name          => $config{'module_name'},

    dist_name            => $config{'dist_name'},
    dist_version_from    => $config{'dist_version_from'},

    dist_abstract        => $config{'dist_abstract'},
    dist_author          => $config{'dist_author'},
    license              => $config{'license'},

    dist_version         => $config{'dist_version'},

    requires             => { %{$config{'requires_href'}} },
    recommends           => { %{$config{'recommends_href'}} },

    dynamic_config       => $config{'dynamic_config'},

    build_requires       => { %{$config{'build_requires_href'}} },

    sign                 => $config{'sign'},
    recursive_test_files => $config{'recursive_test_files'},
    create_readme        => $config{'create_readme'},
    create_metafile_pl   => $config{'create_metafile_pl'},

    %optional_args,      ## meta_add, meta_merge, configure_requires, test_requires, no_index, script_files, pm_files, pod_files, xs_files

    config               => { %{$config{'config_href'}} },

    PL_files             => { %{$config{'PL_files_href'}} },

    add_to_cleanup       => [ @{$config{'add_to_cleanup_aref'}}, ( map { join( q{-}, split(/::/xms) ) . q{-*} } $config{'dist_name'} ), ( map { join( q{-}, split(/::/xms) ) . '.ppd' } $config{'dist_name'} ) ],

    add_to_realcleanup   => [ @{$config{'add_to_realcleanup_aref'}} ],

    add_to_verycleanup  => [ @{$config{'add_to_verycleanup_aref'}} ],
);

# push $config{*} info into $build->notes
foreach ( keys %config ) {
    $build->notes("config/$_" => $config{$_});
    # print STDERR "$_ ... $config{$_}\n" ;
    ##print "$_ => ".$build->notes("config/$_")."\n";
    }

$build->create_build_script;

####

sub version_from_vfile { ## ( $:file ) => %:version_info
    # determine VERSION from file, if present

    # VERSION: Major.minor[_alpha] { if no alpha: minor is ODD => alpha (aka, developer, beta, or experimental), minor is EVEN => stable or release }
    # * NOTE: "boring" versions are preferred (ref: http://www.dagolden.com/index.php/369/version-numbers-should-be-boring @@ https://archive.is/7PZQL @@ http://www.webcitation.org/66Z1eHR17])

    my $VERSION_filename = shift;
    my %RETval = ();
    $RETval{'VERSION'} = undef;
    if ( -e $VERSION_filename ) {
        my $fh;
        open( $fh, '<', $VERSION_filename ) or die qq{Can't open "$VERSION_filename": $OS_ERROR\n}; ## no critic ( RequireCarping )
        my $file_contents;
        {# slurp entire file
            local $/ = undef;
            $file_contents = <$fh>;
        }
        close $fh or die qq{Can't close "$VERSION_filename" after reading: $OS_ERROR\n}; ## no critic ( RequireCarping )
        $file_contents = q// if not defined $file_contents;

        # remove and save any leading whitespace and/or trailing non-version text (comments, etc)
        if ( $file_contents =~ /^([\s\n]*)((?:\d|[._])+)((?:.|\s)*?)$/msx ) {
            $RETval{'VERSION_prefix'} = $1;
            $RETval{'VERSION'} = $2;
            $RETval{'VERSION_suffix'} = $3;
            $RETval{'VERSION'} =~ s/(.*?)[._]*$/$1/;  # remove any trailing '.|_'
            # print qq{Found version ('$RETval{VERSION}') in "$VERSION_filename"\n};
            }
        else
            {
            $RETval{'VERSION'} = '0.001';
            warn qq{build: warning, using default version ('$RETval{VERSION}'); no version found in "$VERSION_filename"\n};
            }

        ( $RETval{'VERSION_M'}, $RETval{'VERSION_m'}, $RETval{'VERSION_a'} ) = ( $RETval{'VERSION'} =~ /\d+/msxg );
        $RETval{'VERSION'} = version_f( $RETval{'VERSION_M'}, $RETval{'VERSION_m'}, $RETval{'VERSION_a'} );
        # print "\\$VERSION = '$RETval{VERSION}'\n";
    }

    ##print STDERR '\\$RETval{VERSION} = '.($RETval{VERSION} ? $RETval{VERSION} : q{})."\n";
    return %RETval;
}

####

sub _is_const { return !eval { ($_[0]) = $_[0]; 1; }; }
sub _encodeQQ
{
    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = [ @_ ] if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

    for my $arg ( @{$arg_ref} ) {
        if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
        $arg =~ s/([^[:word:].,;:])/'\x{'.sprintf("%x", ord($1)).'}'/esg;
    }
    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
}
sub _encodeQ
{
    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = [ @_ ] if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

    for my $arg ( @{$arg_ref} ) {
        if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
        $arg =~ s/([\\{}])/\\$1/sg;
    }
    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
}

####

sub rivy_builder_code
{
    my $code = q{};
    my %code = rivy_builder_code_subs();
    for (keys %{$config{custom_code_href}}) { $code{$_} = $config{custom_code_href}->{$_}; }
    for (sort keys %code) { $code .= $code{$_}; }
    return $code;
}
sub rivy_builder_code_subs
{; ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars ValuesAndExpressions::ProhibitImplicitNewlines)
my %code;
$code{q/#/} = q{
    use strict;
    use warnings;
    use English qw( -no_match_vars ); ## enable long-form built-in variable names; '-no_match_vars' avoids regex performance penalty for perl versions <= 5.16
    # use open IN => ":crlf :encoding(UTF-8)", OUT => ":raw :utf8";
    # use open ':std';

    use File::Basename;
    use File::Glob qw//;
    use File::Spec qw//;
    use File::Spec;
    use File::Spec::Functions;
    use File::Path;
    use File::Which;
    use IO::File;
    use Text::Template;
    use URI;

    # print STDERR "\#(use section): HERE\\n";
};
$code{'@qprinf'} = q{
    {
    my @encoding;
    my @printf_encoding;
    for (my $n = 0; $n <= 0xff; $n++) {
        $encoding[$n] = sprintf "\\%02x", $n;
        $printf_encoding[$n] = $encoding[$n];
        }
    for (my $n = 0; $n <= 0x7f; $n++) {
        my $c = chr($n);
        next if $c =~ /[%"'\\*\\?\\[\\]\\{\\}[:^graph:]]/;  # escape character, quotes, printf format specifier, special glob characters
        $printf_encoding[$n] = $c;
        }
    sub qprintf ## ( @:strings ) => @:printf encoded strings
        {
        my @in = @_;
        # encode input as equivalent printf compatible strings (also, portable)
        my $IFS = $ENV{IFS};
        if ( not defined $IFS || $IFS eq q// ) { $IFS = " \n\t" }
        ## replace IFS characters in @printf_encoding with encoded equivalents
        foreach ( split q//, $IFS ) { $printf_encoding[ord($_)] = $encoding[ord($_)] }
        ## foreach @_ { replace each character with its equivalent encoding }
        foreach ( @in ) { $_ =~ s/(.)/$printf_encoding[ord($_)]/egmsx }
        return @in;
        }
    }
};
$code{'@version'} = q{
    # ref: http://www.dagolden.com/index.php/369/version-numbers-should-be-boring @@ https://archive.is/7PZQL @@ http://www.webcitation.org/66Z1eHR17]
    # NOTE: VERSION == Major.minor[_alpha] { if no alpha: minor is ODD => alpha (aka, developer, beta, or experimental), minor is EVEN => stable or release }

    sub version_f { ## ( $:major, $:minor, $:alpha ) => $:formatted version string ("boring" style)
        my ( $major, $minor, $alpha ) = @_;
        $major = '1' if not defined $major;
        $minor = '0' if not defined $minor || $minor eq q//;
        $alpha = q// if not defined $alpha;
        if (( $minor % 2 ) && ($alpha eq q//) ) { $alpha = 1; }
        my $v;
        $v  = sprintf( '%d', $major );
        $v .= sprintf( q/./.((($major == 0) && ($alpha eq q//)) ? '%d' : '%03d'), $minor );
        $v .= sprintf( q/_/.(($alpha == 1) ? '%d' : '%03d'), $alpha ) if $alpha ne q//;
        return $v;
        }
};
$code{'repo'} = q{
    sub repo_property_update ## ( )
    {
        my $self = shift;

        # print STDERR "repo_property_update()\\n";

        use File::Spec::Functions qw( rel2abs );
        use File::Basename qw( dirname );

        my $filename;

        my $null = File::Spec->devnull();

        my $repo_commands_ref = undef;

        if ( not $repo_commands_ref ) {
            # prefer GIT
            # : GIT
            $filename = rel2abs('.git', $self->base_dir);
            if ( -d $filename )
                {
                # if ( system("git --version 1>$null 2>&1") == 0 ) { return 'git' };
                if ( system("git --no-pager log -1 --pretty=oneline 1>$null 2>&1") == 0 ) { $repo_commands_ref = _repo_commands('git'); };
                }
            }

        if ( not $repo_commands_ref ) {
            # : Mercurial
            $filename = rel2abs('.hg', $self->base_dir);
            if ( -d $filename )
                {
                if ( system("hg --version 2>&1 1>$null") == 0 ) { $repo_commands_ref =_repo_commands('hg'); };
                }
            }

        if ( $repo_commands_ref ) {
            foreach ( keys %{$repo_commands_ref} ) {
                # print STDERR "\\$repo_commands_ref->{$_}()=".scalar($repo_commands_ref->{$_}())."\n";
                $self->notes( "repo_$_" => scalar( $repo_commands_ref->{$_}() ) );
            }
        }

        return;
    }
    sub _repo_commands # ( [ $:repo_type ] ) => $REPO_FUNCTION_REF
    {
        my $repo_type = shift;  # [ 'git', 'hg' ]

        my $repo_function_ref;
        my $function_name;

        # URLref: [Mercurial for GIT users] http://mercurial.selenic.com/wiki/GitConcepts @@ http://archive.is/pnLtQ @@ http://webcitation.org/6MAMUgtwV

        # branch
        $function_name = 'branch';
        $repo_function_ref->{git}{$function_name} = sub {
            my @lines = qx{git rev-parse --abbrev-ref HEAD};
            my $RETval = $lines[0];
            chomp( $RETval );
            return $RETval;
            };
        $repo_function_ref->{hg}{$function_name} = sub {
            my @lines = qx{hg branch};
            my $RETval = $lines[0];
            chomp( $RETval );
            return $RETval;
            };

        # commit_author
        $function_name = 'commit_author';
        $repo_function_ref->{git}{$function_name} = sub {
            my @lines = qx{git show --pretty="%aN <%aE>"};
            my $RETval = $lines[0];
            chomp( $RETval );
            return $RETval;
            };
        $repo_function_ref->{hg}{$function_name} = sub {
            my @lines = qx{hg log -r . --template '{author}'};
            my $RETval = $lines[0];
            chomp( $RETval );
            return $RETval;
            };

        # commit_number
        $function_name = 'commit_number';
        $repo_function_ref->{git}{$function_name} = sub {
            my @lines = qx{git rev-list HEAD};
            return scalar(@lines);
            };
        $repo_function_ref->{hg}{$function_name} = sub {
            my @lines = qx{hg log -r . --template '{rev}'};
            my $RETval = $lines[0];
            chomp( $RETval );
            return $RETval;
            };

        # commit_id
        $function_name = 'commit_id';
        $repo_function_ref->{git}{$function_name} = sub {
            # URLref: [How to retrieve the hash for the current commit in Git?] http://stackoverflow.com/a/949391/43774
            my @lines = qx{git rev-parse HEAD};
            my $RETval = $lines[0];
            chomp( $RETval );
            return $RETval;
            };
        $repo_function_ref->{hg}{$function_name} = sub {
            my @lines = qx{hg log -r . --template '{node}'};
            my $RETval = $lines[0];
            chomp( $RETval );
            return $RETval;
            };

        # # commit_id_of_size
        # $function_name = 'commit_id_of_size';
        # $repo_function_ref->{git}{$function_name} = sub {
        #     # URLref: [How to retrieve the hash for the current commit in Git?] http://stackoverflow.com/a/949391/43774
        #     my $size = shift;
        #     my @lines = qx{git rev-parse --short=$size HEAD};
        #     my $RETval = $lines[0];
        #     chomp( $RETval );
        #     return $RETval;
        #     };
        # $repo_function_ref->{hg}{$function_name} = sub {
        #     my $size = shift;
        #     my @lines = qx{hg log -r . --template '{node}'};
        #     my $RETval = $lines[0];
        #     chomp( $RETval );
        #     return substr ( $RETval, 0, $size );
        #     };

        # commit_describe
        $function_name = 'commit_describe';
        $repo_function_ref->{git}{$function_name} = sub {
            my @lines = qx{git describe --tags --always};
            my $RETval = $lines[0];
            chomp( $RETval );
            return $RETval;
            };
        $repo_function_ref->{hg}{$function_name} = sub {
            my @lines = qx{hg log -r . --template '{latesttag}-{latesttagdistance}-{node|short}\n'};
            my $RETval = $lines[0];
            chomp( $RETval );
            return $RETval;
            };

        # contributors
        $function_name = 'contributors';
        $repo_function_ref->{git}{$function_name} = sub {
            my @lines = ();
            @lines = qx{git log --format="%aN <%aE>"};
            return wantarray ? @lines : \\@lines;
            };
        $repo_function_ref->{hg}{$function_name} = sub {
            my @lines = qx{hg log --template "{author}\\n"};
            return wantarray ? @lines : \\@lines;
            };

        # is_dirty
        $function_name = 'is_dirty';
        $repo_function_ref->{git}{$function_name} = sub {
            # URLref: http://stackoverflow.com/questions/2657935/checking-for-a-dirty-index-or-untracked-files-with-git
            my @lines = qx{git diff --shortstat};
            return scalar(@lines) != 0;
            };
        $repo_function_ref->{hg}{$function_name} = sub {
            my @lines = qx{hg status -mard};
            return scalar(@lines) != 0;
            };

        # type
        $function_name = 'type';
        $repo_function_ref->{git}{$function_name} = sub {
            return 'git';
            };
        $repo_function_ref->{hg}{$function_name} = sub {
            return 'hg';
            };

        if ( $repo_type )
            {
            return $repo_function_ref->{$repo_type};
            }
        return $repo_function_ref;
    }
};
####
$code{'#pod'} = q{
=head1 OPTIONS (CUSTOM)

Additional custom options.

=over 4

=item --color=0|no|never|off|1|on|yes|always

Force TAP::Harness color output via manipulation of TAP::Formatter (and the use of Win32::Console::ANSI for MSWin32). When color
is enabled (and Win32::Console::ANSI for MSWin32 systems) is installed, colored output is displayed reliably to the shell.
For MSWin32 systems, both CMD and TCC shells display colored output. Additionally, although the TAP::Formatter will
usually not pipe colored output, when 'always' is used, output color is enabled and piped correctly.
output as well. Normally, the TAP::Formatter will not pipe colored output.

--color=0|no|never|off  disable color output
--color=1|on|yes                enable color output (piped output is not colored)
--color=always              enable color output (including piped output)

=back

=head1 ACTIONS (CUSTOM)

Additional custom actions.

=over 4

=item distall

Build all distributions.

=item distppm

Build the PPM distribution.

=item distpar

Build the PAR distribution.

=item PL_files

Build all files from PL templating scripts.

=item sign

Sign the current module content in the base directory (for local testing).

=item show_vfiles

Print all versioned files within module.

=item show_versions

Print all versioned files within module with their $VERSION.

=item show_PL_targets

Print all PL script target files within module.

=item smoke

Build and "smoke test" the distribution (an alias of smoke_build).

=item smoke_build

Build and "smoke test" the distribution, using Build.PL for the target distribution build.

=item smoke_make

Build and "smoke test" the distribution, using Makefile.PL and make for the target distribution build.

=item taint_test

[version 0.01]

Run regression tests (via test) with taint-mode ON. See C<test> for more information and argument specification(s).

=item taint_testall

[version 0.01]

Run all regression tests (via testall) with taint-mode ON. See C<testall> for more information and argument specification(s).

=item TRIALaction

Execute a trial action (for testing purposes).

=back

=cut
};
# $code{'@new'} = q{
#     sub new{
#         #my $self = shift()->_construct(@_);
#         #
#         #$self->{invoked_action} = $self->{action} ||= 'Build_PL';
#         #$self->cull_args(@ARGV);
#         #
#         #die "Too early to specify a build action '$self->{action}'.  Do 'perl Build.PL' instead.\n"
#         #if $self->{action} && $self->{action} ne 'Build_PL';
#         #
#         #$self->check_manifest;
#         #$self->check_prereq;
#         #$self->check_autofeatures;
#         #
#         #$self->dist_name;
#         #$self->dist_version;
#         #
#         #$self->_set_install_paths;
#         #$self->_find_nested_builds;
#         #
#         #return $self;
#         my $self = shift;
#         my ($args, $action) = $self->read_args(@ARGV);
#
#         if ($action) {
# ##            $self->do_system($self->{properties}{perl}.' Build.PL');  ## causes intermittent errors as $self is not well-formed yet
#             system "$^X $0";
#             if ( -f 'Build' ) {
#                 print "Executing: perl Build @ARGV\n";
#                 #exit( $self->run_perl_script('Build', [], @ARGV) );
#                 #exit( do 'Build' );
#                 exit( $self->do_system("$^X Build @ARGV") );
#                 }
#             else {
#                 die "Too early to specify a build action '$action'.  Do 'perl Build.PL' instead.\n";
#                 }
#             }
#
#         return $self->SUPER::new( @_ );
#         }
# };
$code{'ACTION_PL_files'} = q{
    #[ADD] PL_files - create all templated PL files
    sub ACTION_PL_files {
        my $self = shift;

        if ( $self->PL_files )
            {
            ##my @entries = %{$self->PL_files};
            ##print "entries = [ @entries ]\n";
            $self->process_PL_files;
            #_or_?#$self->depends_on('code');
            };
      }
    sub process_PL_files {
        my ($self) = @_;
        my $files = $self->find_PL_files;

        foreach my $file (sort keys %$files) {
        my $to = $files->{$file};
        unless ($self->FILES_up_to_date( $to, [ $file, 'Build', 'Build.PL', 'Build.PL.config' ], { ignore_case => 1 } )) {
            $self->run_perl_script($file, [], [@$to]) or die "$file failed";
            # $self->add_to_cleanup(@$to);
            }
        }
    }
    sub create_note_versioned_filenames {
        my $self = shift;

        $self->depends_on('PL_files');

        my @globs;
        my @files;
        my @files_to_exclude;

        @globs = @{$self->notes('config/add_to_versioned_aref')};
        @files = map { glob $_ } @globs;
        ##
        ####@globs = @{$self->notes('config/versioned_file_globs_exclude_aref')};
        ####@files_to_exclude = map { File::Glob::bsd_glob($_,File::Glob::GLOB_NOCASE()) } @globs;
        ####
        ##### URLref: [How can I delete items from an array in another array in perl?] http://stackoverflow.com/a/6714829
        ####my %elements;
        ####@elements{ @files_to_exclude } = ();
        ####my @final_files = grep ! exists $elements{$_}, @files;
        ##
        ####$self->notes('config/add_to_versioned_aref' => [ @final_files ]);

        $self->notes('config/versioned_filenames_aref' => [ @files ]);

        #print "s->n(vfa) = @{$self->notes('config/versioned_files_aref')}\n";
      }
};
$code{'get_template_vars'} = q{
    sub get_template_vars {
        # get_template_vars( [$output_filename] ) ): %vars
        my $self = shift;
        my $output_filename = shift;
        my %vars = ();

        my %notes = $self->notes;

        # add notes() to template vars
        for ( keys %notes ) {
            # next unless /^config[/](.*)$/;
            next unless /^config\\/(.*)$/;
            # next if not defined $notes{$_};
            $vars{$1} = do { my $t = $notes{$_}; ref $t ? \\$t : $t; };  # counteract auto-dereference
            }

        # add repo properties (if they exist) to template vars
        for ( keys %notes ) {
            next unless /^repo_(.*)$/;
            $vars{'repo_'.$1} = $notes{$_};
            }

        # create numeric VERSION
        {
        my $v = $vars{VERSION};
        $v =~ s/_//gmsx; # remove any alpha markers
        $vars{VERSION_numeric} = version->parse( $v )->numify;
        }

        if (defined $output_filename) {
            # define file specific variables
            $vars{ME_filename} = $output_filename;
            $vars{ME_filename} =~ s|\\\\|/|gmsx;      # to *nix style
            $vars{ME_source_filename} = undef;

            my $sourcefile_map_href = $self->find_PL_files;
            if ( $sourcefile_map_href ) {
                my $filename = $vars{ME_filename};
                my %file_map = %{$sourcefile_map_href};
                foreach my $src_file ( keys %file_map ) {
                    if ( grep { $filename eq $_ } map { s:\\\\:/:gmsx; $_ } @{$file_map{$src_file}} ) {
                        $vars{ME_source_filename} = $src_file;
                        $vars{ME_source_filename} =~ s:\\\\:/:gmsx;
                        last;
                        }
                    }
                }

            if ( $vars{ME_filename} =~ m{^lib/(.*)[.](?i:pm)$}msx ) {
                # eg, `Module::Name 0.945_1 ("lib/Module/Name.pm" from "PL.#no-dist/lib/Module/Name.pm.PL")`
                $vars{ME_ID} = qq{$vars{module_name} $vars{VERSION} ("$vars{ME_filename}"}.($vars{ME_source_filename} ? qq{ from "$vars{ME_source_filename}"} : q//).")";
                } else {
                # eg, `"lib/Module/Name.pod" 0.945_1 ("lib/Module/Name.pod" from "PL.#no-dist/lib/Module/Name.pod.PL")`
                $vars{ME_ID} = qq{"$vars{ME_filename}" $vars{VERSION}}.($vars{ME_source_filename} ? qq{ (from "$vars{ME_source_filename}")} : q//);
                }
            }

        # for ( sort keys %vars ) {
        #     my $val = $vars{$_};
        #     if (not defined $val) { $val = 'undef'; }
        #     elsif ( not ref $val ) { $val = qq{'$val'}; }
        #     print STDERR "\$vars{$_}=$val\n";
        # }

        return %vars;
        }
};
$code{'expand_template'} = q{
    sub expand_template {
        # expand_template( $output_filename, \@template ) ): %vars
        my $self = shift;
        my $output_filename = shift;
        my $template_aref = shift;

        # my $delim_start = '#{{';
        # my $delim_stop  = '}}#';
        my $delim_start = q/":{{/;
        my $delim_stop  = q/}}:"/;

        my %vars = $self->get_template_vars( $output_filename );

        use English qw( -no_match_vars ); ## enable long-form built-in variable names; '-no_match_vars' avoids regex performance penalty for perl versions <= 5.16

        $self->log_info("Building $output_filename (from $0) ... ");

        my $template = Text::Template->new(TYPE => 'ARRAY', SOURCE => $template_aref, DELIMITERS => [ $delim_start, $delim_stop ]) or die $Text::Template::ERROR;

        my $text = $template->fill_in( PACKAGE => 'TEMPLATE', HASH => \%vars );

        $text =~ s/\r*\n/\r\n/gmsx if $output_filename =~ /[.](bat|cmd)$/imsx;   # 'MSWin32' BAT/CMD files must have CRLF end-of-lines

        my ($vol, $dir, undef) = File::Spec->splitpath( $output_filename );
        my $output_dir = $vol.$dir;
        if (not -e $output_dir) { File::Path::mkpath( $output_dir ); }

        my $mode = ((stat $output_filename)[2] || 0777) & 07777;
        $mode |= 0222; # "a+w" permissions
        chmod $mode, $output_filename;   # enable write access; allows overwrite for files which may be previously marked read-only

        my $fh;
        open( $fh, "> :raw :utf8", $output_filename ) or die "cannot write to '$output_filename': $OS_ERROR";
        print $fh $text;
        close( $fh );

        $mode &= ~0222; # "a-w" permissions
        chmod $mode, $output_filename;   # mark the output file as read-only as a reminder that the file is build-generated

        $self->log_info("ok\n");
        }
};
$code{'ACTION_build'} = q{
    sub ACTION_build {
        my $self = shift;

        my @RETval = $self->SUPER::ACTION_build( @_ );
        $self->depends_on('meta');

        $self->create_note_versioned_filenames;

        return wantarray ? @RETval : $RETval[0];
      }
};
$code{'ACTION_meta'} = q{
    sub ACTION_meta {
        my $self = shift;

        # my @RETval = $self->SUPER::ACTION_meta( @_ );

        $self->depends_on('build');
        $self->do_create_metafile if (not $self->FILES_up_to_date([ 'META.json', 'META.yml' ], [ 'Build', 'Build.PL', 'Build.PL.config', 'LICENSE', $self->dist_version_from, sort keys %{$self->notes('config/PL_target_files_href')} ], { ignore_case => 1 }));   ## worry about _main_docfile(), ASSERT?

        # return wantarray ? @RETval : $RETval[0];
      }
};
$code{'get_metadata'} = q{
    sub get_metadata {
        my $self = shift;

        # BUGFIX: if no_index is defined, Module::Build erroneously skips including "provides" in the meta-data
        # ToDO?: will this correctly skip 'no_index' areas of the distribution?
        my $pkgs = eval { $self->find_dist_packages };
        if (%$pkgs) { $self->meta_add->{provides} = $pkgs; };

        # my $metadata_href = $self->SUPER::get_metadata( @_ );
        # return $metadata_href;

        return $self->SUPER::get_metadata( @_ );
      }
};
$code{'known_actions'} = q{
    sub known_actions{
          my ($self) = @_;

          my %actions;
          no strict 'refs';

          foreach my $class ($self->super_classes) {
            foreach ( keys %{ $class . '::' } ) {
              $actions{$1}++ if /^ACTION_(\\w+)/;
            }
          }

          delete $actions{'manifest_skip'};

          return wantarray ? sort keys %actions : \\%actions;
        }
};
$code{'dispatch'} = q{
    sub dispatch \{
        #my $self = shift;
        #local $self->{_completed_actions} = {};
        #
        #if (@_) {
        #   my ($action, %p) = @_;
        #   my $args = $p{args} ? delete($p{args}) : {};
        #
        #   local $self->{invoked_action} = $action;
        #   local $self->{args} = {%{$self->{args}}, %$args};
        #   local $self->{properties} = {%{$self->{properties}}, %p};
        #   return $self->_call_action($action);
        #   }
        #
        #die "No build action specified" unless $self->{action};
        #local $self->{invoked_action} = $self->{action};
        #$self->_call_action($self->{action});
        my $self = shift;
};
# ## ToDO: change to use $self->notes(...)
# foreach (keys %{$config{'custom_ENV_href'}}) { $code{'dispatch'} .= qq{\t\t}.'$ENV{'.$_.'} = q{'._encodeQ($config{'custom_ENV_href'}->{$_}).'};'.qq{\n}; }
$code{'dispatch'} .= q{

        my $haveWin32ConsoleANSI = eval q{use Win32::Console::ANSI; 1};

        # OPTION color => 0/never/no/off; 1/on/yes; always
        $self->{properties}{use_color} = $self->{properties}{use_color} || 0; # 0/never/no/off
        if  ( defined($self->{args}{color}) ) {
            my $option = lc( $self->{args}{color} );
            $self->{properties}{use_color} = 1 if ( $option eq q{} || $option eq q{1} || $option eq q{on} || $option eq q{yes} );
            $self->{properties}{use_color} = 'always' if $option eq q{always};
            if ( not $self->{properties}{use_color} && not ( $option eq q{0} || $option eq q{never} || $option eq q{no} || $option eq q{off})) {
                die "Malformed --color option (use --color=0|never|no|off|1|on|yes|always)\n";
                };
            ## only warn if explicitly setting use_color=1 via the command line
            if ( $^O =~ /\AMSWin/i && $self->{properties}{use_color} && not $haveWin32ConsoleANSI ) {
                warn qq{Win32::Console::ANSI is recommended for reliable color output (but is not installed; to install, use "cpan Win32::Console::ANSI")\n};
                };
            }

        if ( $self->{properties}{use_color} ) {
            $self->{properties}{tap_harness_args}{color} = 1;
            }
        if ( $self->{properties}{use_color} eq 'always' ) {
            # force TAP to use console no matter if redirected or not (this avoids the loss of color output for TAP::Formatter::File output)
            $self->{properties}{tap_harness_args}{formatter_class} = 'TAP::Formatter::Console';
            }

        # HACK: convince TAP::Formatter::Color to use Term::ANSIColor if we can load Win32::Console::ANSI by masquerading as "linux" OS
        # * this solves multiple color output problems for TAP testing output (works with CMD and TCC shells as well)
        # NOTE: this might be moved into test, testall, etc. (but it's single source here)
        # ToDO: move to test_setup_color() and add to test(), testall(), retest(), disttest(), taint_test(), taint_testall(), testcover(), testdb(), testpod(), testpodcoverage() ## is there a common origin?
        if ( $self->{properties}{use_color} ) {
            if ($haveWin32ConsoleANSI)
                {
                # if Win32::Console::ANSI is installed/exists => force TAP::Formatter::Color to ignore MSWin32 and use Term::ANSIColor (via masquerade as "linux" OS)
                local $^O="linux";
                require TAP::Formatter::Color;
                }
            }

## **       $self->{properties}{tap_harness_args}{switches} .= ($self->{properties}{tap_harness_args}{switches} ? q{ }:q{}) . '-T';     # add '-T' taint mode option to harness args

##  tap_harness_args => {
        # tap_harness_args => ... passed as an argument to Module::Build implies "use_tap_harness  => 1"
        # if TAP::Formatter::Color is changed to use TERM::ANSIColor with windows, the below allows color propogation to redirected streams
##      color => 1,
##      formatter_class => 'TAP::Formatter::Console',
        # "prove -b -l --color --formatter TAP::Formatter::Console t\01.load.t | less" also allows color output to be redirected to less or a file
        # USE "prove -b -l --color --formatter TAP::Formatter::Console t\01.load.t | cat" for usual output, although this relies on TAP::Formatter::Color to send ANSI sequences to reliably set color (otherwise it _may_ output color for CMD, not TCC)
        # color output using the normal TAP::Formatter::Color method uses Win32::Console; seems to only to set colors for primary CMD shells and only subshells which have soley CMD parents up to the primary shell (any TCC within the chain stops color output)
##      },

        # update repo properties
        $self->repo_property_update();

        return $self->SUPER::dispatch( @_ );
    \}
};
$code{'create_build_script'} = q{
    sub create_build_script{
        # build META.{json,yml} early, with Build.PL
        my $self = shift;

        my @RETval;

        # $self->do_create_metafile if (not $self->FILES_up_to_date([ 'META.json', 'META.yml' ], [ 'Build', 'Build.PL', 'Build.PL.config', 'LICENSE', $self->dist_version_from ], { ignore_case => 1 }));   ## worry about _main_docfile(), ASSERT?
        @RETval = $self->SUPER::create_build_script( @_ );
        $self->FILES_to_NIX( 'Build' );
        return wantarray ? @RETval : $RETval[0];
        }
};
$code{'find_dist_packages'} = q{
    sub find_dist_packages{
        # rebuild MANIFEST early :: fixes missing MANIFEST warnings for modern versions of Module::Build which include the new MYMETA.yml paradigm
        # * MYMETA.yml is dynamically created very early in the process
        #   the initializing create_build_script() calls create_mymeta almost immediately, and MANIFEST is needed to correctly create MYMETA.yml
        #   the call stack is: create_build_script -> create_mymeta -> get_metadata -> prepare_metadata -> find_dist_packages
        my $self = shift;

        #$self->ACTION_manifest( qq{quiet} );
        {
            local $self->{properties}{quiet} = 1;
            require ExtUtils::Manifest;     # needed to modify $ExtUtils::Manifest::Verbose and $ExtUtils::Manifest::Quiet prior to manifest building
            local ($ExtUtils::Manifest::Verbose, $ExtUtils::Manifest::Quiet) = (0,1);
            $self->ACTION_manifest;         # [use direct execution of ACTION; depends_on() will cache and execute each ACTION only once per script execution]
        }

        return $self->SUPER::find_dist_packages( @_ );
        }
};
$code{'have_c_compiler'} = q{
    sub have_c_compiler {
        my ($self) = @_;

#       # swallow any annoying error output from ExtUtils::CBuilder have_compiler() [URLref: http://www.perlmonks.org/?node_id=629771]
#       my $err;
#       open STDERR_o, '>&STDERR';
#       close STDERR;
#       open STDERR, '>', \$err;
#
#       my $RETval = $self->SUPER::have_c_compiler(@_);
#
#       # restore STDERR
#       open STDERR, '>&STDERR_o';
#       close STDERR_o;
#
#       return $RETval;

        my @RETval;

        # swallow any annoying error output from ExtUtils::CBuilder have_compiler()
        # URLrefs: [Capture::Tiny] http://search.cpan.org/~DAGOLDEN/Capture-Tiny , [Close + Re-opening STDOUT] http://www.perlmonks.org/?node_id=617136 @@ http://www.webcitation.org/66O9EXPAz
        # URLrefs: [How can I capture STDERR from an external command] http://www.perlmonks.org/?node=How%20can%20I%20capture%20STDERR%20from%20an%20external%20command%3F @@ http://www.webcitation.org/66O9ViBoB
        # alternate method (without Capture::Tiny) [URLref: http://www.perlmonks.org/?node_id=629771 @@ http://www.webcitation.org/66O97acch]
        #BEGIN { eval { require Capture::Tiny; 1 }; }   # Capture::Tiny requires loading via BEGIN for 'syntactic sugar' [see URLref: http://perlmonks.com/?node=Seekers%20of%20Perl%20Wisdom ]
        my $haveCaptureTiny = eval { require Capture::Tiny; 1; };
        my $o = q{};
        if ($haveCaptureTiny) {
            ($o, undef) = Capture::Tiny::capture( sub { @RETval = $self->SUPER::have_c_compiler(@_) } );
            }
        else {
            @RETval = $self->SUPER::have_c_compiler(@_);
            }
        print $o if $o;

        return wantarray ? @RETval : $RETval[0];
    }
};
$code{'up_to_date'} = q{
    sub up_to_date {
        # skip up_to_date() check for 'clean' and 'realclean' tasks (removes annoying warning when cleaning up the directory, maybe just for realclean since it removes the Build.PL dependent script)
        my $self = shift;

        # may be just blow this off... shouldn't happen except when monkeying with Build.PL in the module directory instead of, as should be done, in the upstream build script repo
        # PENDING: also may need to look for magicnum checks later in script execution to block warnings for clean/realclean
        # ARGV hasn't been parsed when this is used in the initial Build.BAT to check for modified Build.PL
        # (? check argv ... seems like a REAL HACK )
        # use File::Basename;
        # if ('Build.PL', basename($0)) and ARGV[n] == realclean
        #print "s->a = $self->{action}\n";
        #print "s->ia = $self->{invoked_action}\n";
        #
        #return 1 if ((lc($self->{action}) eq 'clean') or (lc($self->{action}) eq 'realclean'));

        return $self->SUPER::up_to_date( @_ );
    }
};
$code{'ACTION_TRIALaction'} = q{
    #[ADD] NEW action = TRIALaction - a trial action for testing purposes
    sub ACTION_TRIALaction {
        my ($self) = @_;

        print "self->dist_name = `$self->dist_name`\n";
        print "self->dist_name = `$self->dist_version`\n";
        for (sort keys %{$self}) { print "self->{$_} = `$self->{$_}`\n"; }
        for (sort keys %{$self->{args}}) {
            print "self->{args}{$_} = `$self->{args}{$_}`\n";
            };
        print "$self->{properties}{tap_harness_args}{formatter_class} = `$self->{properties}{tap_harness_args}{formatter_class}`\n";
        for (sort keys %{$self->{properties}}) {
            print "self->{properties}{$_} = ". (defined($self->{properties}{$_}) ? (q{`}.$self->{properties}{$_}.q{`}): 'undef' ) . qq{\n};
            };
        my $n;
        my $dist_name = $self->dist_name;
        my $dist_version = $self->dist_version;
        $n = q{'}.$self->dist_name.q{'};
        print "n = $n\n";
        $n =~ s/$dist_name/SUB-Dist-Name/g;
        print "n = $n\n";
        #print "ENVIRONMENT:\n";
        #for (sort keys %ENV) { print "$_ = $ENV{$_}\n"; }
      }
};
$code{'harness_switches'} = q{
    sub harness_switches {
        my $self = shift;
        my @res = $self->SUPER::harness_switches;
        push @res, '-T' if $self->notes('taintcheck');
        return @res;
    }
};
$code{'ACTION_taint_test'} = q{
    #[ADD] NEW action = taint_test - run regression tests (via test) with taint-mode ON
    sub ACTION_taint_test {
        my $self = shift;

        $self->notes('taintcheck' => 1);

        $self->ACTION_test( @_ );
      }
};
$code{'ACTION_taint_testall'} = q{
    #[ADD] NEW action = taint_test - run all regression tests (via testall) with taint-mode ON
    sub ACTION_taint_testall {
        my $self = shift;

        $self->notes('taintcheck' => 1);

        $self->ACTION_testall( @_ );
      }
};
$code{'ACTION_sign@_sign_dir'} = q{
    sub _MY_module_signature_has_gpg {
        my $null = File::Spec->devnull();
        if (qx{gpg --version 2>$null} =~ /GnuPG.*?(\S+)\s*$/m) {
            return $1
            }
        else { return; }
        }
    sub _sign_dir {
        my ($self, $dir) = @_;

        unless (eval { require Module::Signature; 1 }) {
            $self->log_warn("Missing Module::Signature; unable to sign the distribution\n");
            return;
            }

        ## override Module::Signature (based on VERSION) to quiet _has_gpg()
        ## : add $Module::Signature::VERSION gating when appropriate (upstream fixed)
        ## : [2013-12-29] as of v0.69, $Module::Signature has an improved gpg detection routine _which_gpg() which has no error output and detects gpg2, etc
        if ( $Module::Signature::VERSION < 0.69 ) {
            print "MY_has_gpg\n";
            my $codeRef = \&_MY_module_signature_has_gpg;
            {no warnings 'redefine';
            *Module::Signature::_has_gpg = $codeRef;
            }
        }

        ## ToDO: based on _has_gpg(); (if Windows?, maybe all platforms), initiate gpg with something in the base directory to start gpg-agent, so that gpg-agent doesn't hold an open file handle on this or a sub-directory
        ## ToDO: open a defect report about gpg-agent holding an open file handle

        # URLrefs:
        # http://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html#GPG-Configuration-Options @@ http://www.webcitation.org/66OEXPIRA
        # http://www.gnupg.org/documentation/manuals/gnupg/GPG-Input-and-Output.html#GPG-Input-and-Output @@ http://www.webcitation.org/66OEYz0So
        #
        # doesn't work ... gpg opens another gpg-agent when signing using Module::Signature
        # from the open handles after the below command, it looks like gpg-agent opens a handle on the CWD when first initiated
        # --batch stops all terminal output
        ##my $gpg = Module::Signature::_which_gpg();
        ##my $gpg_output = qx{cd $ENV{SystemRoot} & gpg --batch --output nul --clearsign $ENV{SystemDrive}\\nul 2> nul}; ## gpg-agent will hold an open handle on %SystemDrive% which is essentially un-deletable (so it's as same as possible)
        ##{
        ##local *D;
        ##open D, "| $gpg --output nul --clearsign" or die "Could not call gpg: $!";
        ##print D "TEST";
        ##close D;
        ##}

        # Add SIGNATURE to the MANIFEST
        {
        my $manifest = File::Spec->catfile($dir, 'MANIFEST');
        die "Signing a distribution requires a MANIFEST file\n" unless -e $manifest;
        #$self->_add_to_manifest($manifest, "SIGNATURE    Added here by Module::Build");
        #[CHANGED] == removed comment to prevent altering MANIFEST, when possible (to preserve correct signatures as long as possible)
        $self->_add_to_manifest($manifest, 'SIGNATURE');    # NO comment, just the filename; comments can alter the MANIFEST when/if it is auto-regenerated
        $self->_sort_manifest($manifest);   # keep MANIFEST sorted (to preserve correct signatures as much as possible)
        }

        ## CHECK: remove this add add dependencies in actions before calling this ... it's cleaner; (ACTION_sign, ACTION_dist_sign (depends on distdir [unless already created]), ACTION_distdir (already depends on distmeta); so, should be correct
        ###[ADD] create the distmeta prior to signature
        ##$self->ACTION_distmeta;

        # use local GnuPG gpg.conf, if available, for GnuPG signing (provides local repository override of default signature) [would be nice if Module::Signature took a signer argument]
        # * use $ENV{_BUILD_gpg_conf_path}, if specified; or default to search .gpg in the main directory
        # * optional, and no warnings if .gpg/gpg.conf missing (the builder should look for correct signature on builds)
        use File::Spec::Functions qw( rel2abs );
        use File::Basename qw( dirname );

        #print "_BUILD_gpg_conf_path = $ENV{_BUILD_gpg_conf_path}\n";
        my $gpg_conf_path = q{};
##        my $base_dir = dirname(rel2abs($0));
        my $base_dir = $self->base_dir;
        if ($ENV{_BUILD_gpg_conf_path}) {
            $gpg_conf_path = rel2abs($ENV{_BUILD_gpg_conf_path}, $base_dir);
            }
        else {
            $gpg_conf_path = rel2abs('.gpg', $base_dir);
            }
        #print "gpg_conf_path = '$gpg_conf_path'\n";
        if ( -e $gpg_conf_path and -e "$gpg_conf_path/gpg.conf" )
            {
            #print qq{'$gpg_conf_path' and '$gpg_conf_path/gpg.conf' EXIST\n};
            $ENV{GnuPGHome} = $gpg_conf_path;
            }

        # Would be nice if Module::Signature took a directory argument.
        $self->_do_in_dir($dir, sub {local $Module::Signature::Quiet = 1; Module::Signature::sign( overwrite => 1 )});
    }
};
$code{'ACTION_sign'} = q{
    #[ADD] NEW action = sign - sign current module content
    sub ACTION_sign {
        my ($self) = @_;
        # from: ACTION_distsign
        #{
        #local $self->{properties}{sign} = 0;  # We'll sign it ourselves
        #$self->depends_on('distdir') unless -d $self->dist_dir;
        #}
        #$self->_sign_dir($self->dist_dir);
        $self->depends_on('distmeta');

        $self->_sign_dir($self->base_dir);
        $self->FILES_to_NIX( 'SIGNATURE' );
    }
};
$code{'ACTION_dist'} = q{
    #[ADD] dist - make ACTION_dist dependant on distmeta
    sub ACTION_dist {
        my $self = shift;

        $self->depends_on('distmeta');

        $self->SUPER::ACTION_dist( @_ );
      }
};
$code{'ACTION_distdir'} = q{
    #[ADD] distdir - make ACTION_distdir dependant on sign (as a HACK to avoid gpg-agent open file handle on distdir)
    sub ACTION_distdir {
        my $self = shift;

##        $self->depends_on('PL_files');

        if ( $self->sign ) {
            # HACK: avoid gpg-agent leaving an open handle on a directory scheduled for cleanup :: this causes sign events & leaves gpg-agent with a handle open to the main directory (not as bad because we don't clean it up)
            # would be better to fix this in _sign_dir or in Module::Signature itself, if possible ([2013-12-29] still not possible); best repair would be a corrected gpg-agent
            if ($^O =~ /\AMSWin/i) {
                if (not File::Glob::bsd_glob('SIGNATURE',File::Glob::GLOB_NOCASE())) { $self->depends_on('sign'); }
                }
            }

        $self->SUPER::ACTION_distdir( @_ );
      }
};
$code{'ACTION_distsign'} = q{
    #[ADD] distsign - make ACTION_distsign dependant on sign (as a HACK to avoid gpg-agent open file handle on distdir)
    sub ACTION_distsign {
        my $self = shift;

        # HACK: avoid gpg-agent leaving an open handle on a directory scheduled for cleanup :: this causes sign events & leaves gpg-agent with a handle open to the main directory (not as bad because we don't clean it up)
        # would be better to fix this in _sign_dir or in Module::Signature itself, if possible ([2013-12-29] still not possible); best repair would be a corrected gpg-agent
        if ($^O =~ /\AMSWin/i) {
            if (not File::Glob::bsd_glob('SIGNATURE',File::Glob::GLOB_NOCASE())) { $self->depends_on('sign'); }
            }

        $self->SUPER::ACTION_distsign( @_ );
      }
};
$code{'ACTION_distcheck'} = q{
    #[ADD] action = distcheck - custom distcheck ACTION to create MANIFEST (if needed; especially after a "distclean")
    sub ACTION_distcheck {
        my $self = shift;

        # needed prior to ACTION_distcheck to make sure there is a MANIFEST o/w distcheck gripes
        #$self->ACTION_manifest( qq{quiet} );
        {
            local $self->{properties}{quiet} = 1;
            require ExtUtils::Manifest;     # needed to modify $ExtUtils::Manifest::Verbose and $ExtUtils::Manifest::Quiet prior to manifest building
            local ($ExtUtils::Manifest::Verbose, $ExtUtils::Manifest::Quiet) = (0,1);
            $self->ACTION_manifest;         # [use direct execution of ACTION; depends_on() will cache and execute each ACTION only once per script execution]
        }

        $self->SUPER::ACTION_distcheck( @_ );
      }
};
$code{'ACTION_distall'} = q{
    #[ADD] NEW action = distall - makes all distributions
    sub ACTION_distall {
        my ($self) = @_;

        $self->depends_on('distmeta');

        $self->depends_on('pardist');
        $self->depends_on('ppmdist');
        $self->depends_on('dist');
      }
};
$code{'ACTION_distppm'} = q{
    #[ADD] NEW action = distppm - makes ppm distribution (ALIAS to ppmdist)
    sub ACTION_distppm {
        shift->depends_on('ppmdist');
      }
};
$code{'ACTION_distpar'} = q{
    #[ADD] NEW action = distpar - makes par distribution (ALIAS to pardist)
    sub ACTION_distpar {
        shift->depends_on('pardist');
      }
};
$code{'ACTION_disttest'} = q{
    #[ADD] SUB action = disttest - run tests on distribution (_without_ resetting the distribution directory 1st)
    sub ACTION_disttest {
        # FROM Module::Build::ACTION_disttest()
        my ($self) = @_;
        $self->depends_on('distdir') unless -d $self->dist_dir;     # modification: don't reset the dist_dir

        $self->_do_in_dir
        ( $self->dist_dir,
          sub {
            # XXX could be different names for scripts
            $self->run_perl_script('Build.PL') # XXX Should this be run w/ --nouse-rcfile
              or die "Error executing 'Build.PL' in dist directory: $!";
            $self->run_perl_script('Build')
              or die "Error executing 'Build' in dist directory: $!";
            $self->run_perl_script('Build', [], ['test'])
              or die "Error executing 'Build test' in dist directory";
          });
        }
};
$code{'ACTION_disttestall'} = q{
    #[ADD] NEW action = disttestall - run all tests on distribution (_without_ resetting the distribution directory 1st)
    sub ACTION_disttestall {
        # FROM Module::Build::ACTION_disttest()
        my ($self) = @_;
        $self->depends_on('distdir') unless -d $self->dist_dir;     # modification: don't reset the dist_dir

        $self->_do_in_dir
        ( $self->dist_dir,
          sub {
            # XXX could be different names for scripts
            $self->run_perl_script('Build.PL') # XXX Should this be run w/ --nouse-rcfile
              or die "Error executing 'Build.PL' in dist directory: $!";
            $self->run_perl_script('Build')
              or die "Error executing 'Build' in dist directory: $!";
            $self->run_perl_script('Build', [], ['testall'])
              or die "Error executing 'Build test' in dist directory";
          });
        }
};
$code{'ACTION_smoke'} = q{
    #[ADD] NEW actions = smoke, smoke_build, smoke_make - smoke test distribution
    # FROM Module::Build::ACTION_disttest()

    # usual smoke testing procedure:
    # * $ENV{AUTOMATED_TESTING}=1
    # * <build distribution>
    # * cd $BUILD_DIRECTORY
    # * perl Makefile.PL
    # * make
    # * make test

    sub ACTION_smoke {
        my $self = shift;

        # default to using build
        $self->ACTION_smoke_build( @_ );
        }
    sub ACTION_smoke_build {
        my ($self) = @_;

        $self->depends_on('distdir');   # * resets the dist_dir

        $ENV{AUTOMATED_TESTING} = 1;
        $self->_do_in_dir
        ( $self->dist_dir,
          sub {

            $self->run_perl_script('Build.PL') # XXX Should this be run w/ --nouse-rcfile
              or die "Error executing 'Build.PL' in dist directory: $!";
            $self->run_perl_script('Build')
              or die "Error executing 'Build' in dist directory: $!";
            $self->run_perl_script('Build', [], ['test'])
              or die "Error executing 'Build test' in dist directory";
          });
        }
    sub ACTION_smoke_make {
        my ($self) = @_;

        $self->depends_on('distdir');   # * resets the dist_dir

        $ENV{AUTOMATED_TESTING} = 1;
        $self->_do_in_dir
        ( $self->dist_dir,
          sub {

            $self->run_perl_script('Makefile.PL') # XXX Should this be run w/ --nouse-rcfile
              or die "Error executing 'Makefile.PL' in dist directory: $!";
            $self->do_system('make')
              or die "Error executing 'make' in dist directory: $!";
            $self->do_system('make test')
              or die "Error executing 'make test' in dist directory";
          });
        }
};
$code{'ACTION_upload_cpan'} = q{
    #[ADD] NEW action = upload_cpan - use CPAN::Uploader to upload finished / test-complete distributions to CPAN
    sub ACTION_upload_cpan {
        my ($self) = @_;

        $self->depends_on('dist');
        $self->log_info("Distribution built successfully.\n");
        $self->depends_on('disttestall');
        $self->log_info("Testing of distribution completed successfully.\n");

        if ( $self->notes('repo_is_dirty') ) { die "Repository has uncommited changes; bailing out before upload." }

        my $devnull = File::Spec->devnull();
        my $haveCPANUpload = ( qx{cpan-upload --help 2>$devnull} =~ /\scpan-upload\s/m );
        if (not $haveCPANUpload) {
            die q{Unable to upload distribution ('cpan-upload' script required; install CPAN::Uploader)}."\n";
            }
        my $havePAUSEcredentials = -e $ENV{HOME}.'/.pause';
        if (not $havePAUSEcredentials) {
            die q{Unable to upload distribution ('.pause' credentials file expected in the $ENV{HOME} directory; see documentation for CPAN::Uploader)}."\n";
            }
        my $dist_dir = $self->dist_dir;
        ## ToDO: refactor to either quote $dist_dir.tar.gz correctly for system() or use CPAN::Uploader directly (it is vaguely possible that we could have errors because of inadequate argument quoting)
        system( qq{cpan-upload $dist_dir.tar.gz} );
      }
};
$code{'ACTION_cpan_upload'} = q{
    #[ADD] NEW action = cpan_upload - (ALIAS of upload_cpan)
    sub ACTION_cpan_upload {
        shift->ACTION_upload_cpan();
      }
};
$code{'ACTION_show_vfiles'} = q{
    #[ADD] NEW action = show_vfiles - print all versioned files within module
    sub ACTION_show_vfiles {
        my ($self) = @_;

        $self->create_note_versioned_filenames();

        my @files = @{$self->notes('config/versioned_filenames_aref')};

        print join(qq{\n}, @files);

        return @files;
      }
};
$code{'ACTION_show_versions'} = q{
    #[ADD] NEW action = show_versions - print all versioned files within module (with their corresponding $VERSION)
    sub ACTION_show_versions {
        my ($self) = @_;

        my $haveExtUtilsMakeMaker = eval { require ExtUtils::MakeMaker; 1; };

        if (not $haveExtUtilsMakeMaker) { die "Unable to parse versions with ExtUils::MakeMaker (install ExtUils::MakeMaker)\n" };

        $self->create_note_versioned_filenames();

        my @files = @{$self->notes('config/versioned_filenames_aref')};

        my %versions;
        map { $versions{$_} = MM->parse_version($_) } @files;
        # print join(qq{\n}, map { $_.q{ }.$versions{$_} } @files );  # keep @files order (primary versioned file [aka $config{module}] is first)
        print join(qq{\n}, map { $_.q/ /.$versions{$_} } sort keys %versions );

        return %versions;
      }
};
$code{'ACTION_show_PL_targets'} = q{
    #[ADD] NEW action = show_PL_targets - show all PL script target files within the module
    sub ACTION_show_PL_targets {
        my ($self) = @_;

        my $file_map_href = $self->find_PL_files;

        return () if not $file_map_href;

        my %file_map = %{$file_map_href};

        my @files;

        foreach my $src_file ( keys %file_map ) {
            push @files, @{$file_map{$src_file}};
            }

        print join(qq{\n}, @files);

        return @files;
      }
};
$code{'ACTION_show_PL'} = q{
    #[ADD] NEW action = show_PL - show all PL script target files within the module
    sub ACTION_show_PL {
        my ($self) = @_;

        my $file_map_href = $self->find_PL_files;

        return () if not $file_map_href;

        my %file_map = %{$file_map_href};

        foreach my $from ( keys %file_map ) {
            print qq{[ @{$file_map{$from}} ]}, qq{ (from $from)}, "\n";
            }

        return %file_map;
      }
};
$code{'ACTION_show_XS'} = q{
    #[ADD] NEW action = show_XS - print all XS files within module
    sub ACTION_show_XS {
        my ($self) = @_;

        my $file_map_href = $self->find_xs_files;

        return () if not $file_map_href;

        my %file_map = %{$file_map_href};

        foreach my $from ( keys %file_map ) {
            print qq{$file_map{$from}}, ($from ne $file_map{$from}) ? qq{ (from $from)} : q//, "\n";
            }

        return %file_map;
      }
};
$code{'ACTION_realclean'} = q{
    sub ACTION_realclean {
        ## BUG in Module::Build v0.30 : Win32 is case-insensitive => so comparisons should be case insensitive => '$basename eq $self->build_script' should be 'lc($basename) eq lc($self->build_script)'
        ## and 'Vodoo' is misspelled
        #my ($self) = @_;
        #
        #$self->SUPER::ACTION_realclean();
        #
        #my $basename = basename($0);
        #$basename =~ s/(?:\.bat)?$//i;
        #
        #if ( $basename eq $self->build_script ) {
        #   if ( $self->build_bat ) {
        #       my $full_progname = $0;
        #       $full_progname =~ s/(?:\.bat)?$/.bat/i;
        #
        #       # Vodoo required to have a batch file delete itself without error;
        #       # Syntax differs between 9x & NT: the later requires a null arg (???)
        #       require Win32;
        #       my $null_arg = (Win32::IsWinNT()) ? '""' : '';
        #       my $cmd = qq(start $null_arg /min "\%comspec\%" /c del "$full_progname");
        #
        #       my $fh = IO::File->new(">> $basename.bat")
        #       or die "Can't create $basename.bat: $!";
        #       print $fh $cmd;
        #       close $fh ;
        #   } else {
        #       $self->delete_filetree($self->build_script . '.bat');
        #   }
        #   }
        my ($self) = @_;

        #print @{$self->{properties}{add_to_realcleanup}}."\n";
        #print 'realcleanup_aref = {'.join(':', @{$self->{properties}{add_to_realcleanup}})."}\n";
        $self->add_to_cleanup(@{$self->{properties}{add_to_realcleanup}});

        my @cleanup_files = $self->cleanup();
        $self->log_debug("realclean: cleanup = [ @cleanup_files ]\n");

        $self->SUPER::ACTION_realclean();

        my $OS_no_case = File::Spec->case_tolerant();

        my $basename = basename($0);
        $basename =~ s/(?:\.bat)?$//i;  # only .bat on Win32 (case-tolerant)

        if ( ($basename eq $self->build_script) || ($OS_no_case && (lc($basename) eq lc($self->build_script))) ) {
            if ( $self->build_bat ) {
                my $full_progname = $0;
                $full_progname =~ s/(?:\.bat)?$/.bat/i;
                $full_progname = File::Spec::Functions::rel2abs($full_progname);

                # Coding voodoo required to have a batch file delete itself without error;
                # Syntax differs between 9x & NT: the later requires an extra arg (Window Title)
                ## TODO: discuss race condition that occurs here: if other process completes 1st (which should almost never occur) the deletion will still be successful just a possible error message might occur = "The batch file cannot be found." & user may notice that the .bat file is still existant for a couple of seconds until the other process starts/inits/completes the deletion
                ## use /d to avoid AutoRUN as well (we only need a basic shell, no addons)
                require Win32;
                my $null_arg = (Win32::IsWinNT()) ? q{""} : q{};
                my $cmd = qq(start $null_arg /min "%comspec%" /d /c del "$full_progname");

                my $fh = IO::File->new(">> $basename.bat")
                or die "Can't create $basename.bat: $!";
                print $fh qq{\n}.$cmd.qq{\n};                       ## TODO: calling SUPER::ACTION_realclean() caused a bug repeating the command twice on the same line causing it to fail for PowerShell => add a new line first
                close $fh ;
                }
            else {
                $self->delete_filetree($self->build_script . '.bat');
                }
            }
        }
};
$code{'ACTION_veryclean'} = q{
    sub ACTION_veryclean {
        ## clean out ALL build generated files
        my ($self) = @_;
        $self->add_to_cleanup(@{$self->{properties}{add_to_verycleanup}});
        $self->ACTION_realclean();
        }
};
$code{'ACTION_ppmdist@ppm_name'} = q{
    # change PPM name to trailing '-PPM' (instead of the default leading 'PPM-')
    sub ppm_name{
        my $self = shift;
        return $self->dist_dir . '-PPM';
        }
};
$code{'ACTION_ppmdist@htmlify_pods'} = q{
    # correct HTML generation for ActivePerl installations
    sub htmlify_pods{
        my $self = shift;
        my $type = shift;

        if (!(eval { require ActivePerl; })) { return $self->SUPER::htmlify_pods( $type ); }

        # this is an ActivePerl installation

        #print "ActivePerl: PRESENT\n";

        # [code modified from Module::Build::Base.pm]
        #print "type = $type\n";
        #my $htmldir = shift || File::Spec->catdir($self->blib, "${type}html");
        my $htmldir = shift || File::Spec->catdir($self->blib, "html/site/lib");

        require Module::Build::PodParser;
        require Pod::Html;

        $self->add_to_cleanup('pod2htm*');

        my $pods = $self->_find_pods( $self->{properties}{"${type}doc_dirs"}, exclude => [ qr/\.(?:bat|com|html)$/ ] );
        return unless %$pods;  # nothing to do

        my $up_to_date = 1;
        foreach my $pod ( keys %$pods ) {

          my ($name, $path) = File::Basename::fileparse($pods->{$pod}, qr{\.(?:pm|plx?|pod)$});
          my @dirs = File::Spec->splitdir( File::Spec->canonpath( $path ) );
          pop( @dirs ) if $dirs[-1] eq File::Spec->curdir;

          my $fulldir = File::Spec->catfile($htmldir, undef, @dirs);
          my $outfile = File::Spec->catfile($fulldir, "${name}.html");
          my $infile  = File::Spec->abs2rel($pod);

          #print "infile = $infile\n";
          #print "outfile = $outfile\n";

          next if $self->up_to_date($infile, $outfile);

          $up_to_date = 0;
          last;
          }

        if (!$up_to_date) {
            my $installdirs = $self->installdirs;
            #print "installdirs = $installdirs\n";
            require ActivePerl::DocTools;
            $self->log_info("HTMLifying PODs\n");
            $self->log_verbose("ActivePerl::DocTools::UpdateHTML_blib( installdirs => \"$installdirs\" )\n");
            ActivePerl::DocTools::UpdateHTML_blib( installdirs => "$installdirs" );
            }
        }
};
$code{'ACTION_ppmdist'} = q{
    # correct PPM generation for ActivePerl installations (modified from Module::Build::Base.pm v0.2808)
    sub ACTION_ppmdist {
        my ($self) = @_;

        if (!(eval { require ActivePerl; })) { return $self->SUPER::ACTION_ppmdist; }

        # this is an ActivePerl installation
        #print "my PPMDIST\n";

        $self->depends_on( 'build' );

        my $ppm = $self->ppm_name;
        $self->delete_filetree( $ppm );
        $self->log_info( "Creating $ppm\n" );
        $self->add_to_cleanup( $ppm, "$ppm.tar.gz" );

        my %types = ( # translate types/dirs to those expected by ppm
            lib     => 'lib',
            arch    => 'arch',
            bin     => 'bin',
            script  => 'script',
            bindoc  => 'man1',
            libdoc  => 'man3',
            binhtml => undef,
            libhtml => undef,
            html => 'html',
        );

      foreach my $type ( $self->install_types, 'html') {
        next if exists( $types{$type} ) && !defined( $types{$type} );

        my $dir = File::Spec->catdir( $self->blib, $type );
        next unless -e $dir;

        my $files = $self->rscan_dir( $dir );
        foreach my $file ( @$files ) {
          next unless -f $file;
          my $rel_file =
            File::Spec->abs2rel( File::Spec->rel2abs( $file ),
                                 File::Spec->rel2abs( $dir  ) );
          my $to_file  =
            File::Spec->catdir( $ppm, 'blib',
                                exists( $types{$type} ) ? $types{$type} : $type,
                                $rel_file );
          $self->copy_if_modified( from => $file, to => $to_file );
        }
      }

      foreach my $type ( qw(bin lib) ) {
        local $self->{properties}{html_css} = 'Active.css';
        $self->htmlify_pods( $type, File::Spec->catdir($ppm, 'blib', 'html') );
      }

      # create a tarball;
      # the directory tar'ed must be blib so we need to do a chdir first
      my $start_wd = $self->cwd;
      chdir( $ppm ) or die "Can't chdir to $ppm";
      $self->make_tarball( 'blib', File::Spec->catfile( $start_wd, $ppm ) );
      chdir( $start_wd ) or die "Can't chdir to $start_wd";

      $self->depends_on( 'ppd' );

      $self->delete_filetree( $ppm );
      }
};
$code{'ACTION_install'} = q{
    sub ACTION_install {
        my ($self) = @_;

        ###[ADD] update all distmeta info when installing
        ##$self->depends_on('distmeta');    ## NOT NEEDED and causes a MANIFEST rebuild which can cause SIGNATURE issues on tests after installs ## may be fixed with sorted MANIFEST

        if (!(eval { require ActivePerl; }) || !_has_ppm()) { return $self->SUPER::ACTION_install; }

        ## this is an ActivePerl installation (and ppm is available)

        if (!_has_ppm() || ($^O eq 'cygwin')) { return $self->SUPER::ACTION_install; }      # cygwin PPM doesn't work correctly

        # PPM is available for install (should work for ActivePerl and Strawberry/Vanilla perl)

        # build ppd and ppm
        $self->depends_on('build');
        $self->depends_on('ppd');
        $self->depends_on('ppmdist');

        my $ppd_name = join('-', split(/::/, $self->dist_name)).'.ppd';

        $self->log_info("Installing via ppm (using $ppd_name)\n");
        # TODO: move this note to the appropriate place :: ?Win32-CommandLine... :: note: installation failures involving inability to rename may be either permission problems or, more likely, trying to rename a file which is in use (locking it with a file handle)
        my $output = `ppm install $ppd_name`;
        print $output;
      }
};
$code{'ACTION_install@_has_ppm'} = q{
    sub _has_ppm {
        return File::Which::which('ppm');
      }
};
$code{'ACTION_fakeinstall'} = q{
    sub ACTION_fakeinstall {
        my ($self) = @_;

        if (!(eval { require ActivePerl; }) || !_has_ppm()) { return $self->SUPER::ACTION_fakeinstall; }

        # this is an ActivePerl installation (and ppm is available)

        # build ppd and ppm
        $self->depends_on('build');
        $self->depends_on('ppd');
        $self->depends_on('ppmdist');

        my $ppd_name = join('-', split(/::/, $self->dist_name)).'.ppd';

        $self->log_info("Installing via ppm (using $ppd_name)\n");
        #`ppm install $ppd_name`;
      }
};
$code{'@FILES_up_to_date'} = q{
    sub FILES_up_to_date {
        # FILES_up_to_date( \%:SELF, $|\@:DEPENDENT_FILE(s), $|\@:ANTECEDENT(s) [, \%:OPTIONAL_ARGS] ): returns $:TRUE/FALSE
        #print "_ = [ @_ ]\n";

        my ($self) = shift;
        my %opt = (
            ignore_case => 'auto',  # = [undef/0]/true/'auto'       ## 0/undef/false = match case always; 'auto' = match case dependent on File::Spec->case_tolerant(), o/w true = ignore case for matches
            );

        my $me = (caller(0))[3];    ## no critic ( ProhibitMagicNumbers )   ## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
        my $opt_ref;
        $opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));  ## no critic (ProhibitPostfixControls)  ## pop last argument only if it's a HASH reference (assumed to be options for our function)
        if ($opt_ref) { for (keys %{$opt_ref}) { if (exists $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' for function ".$me; return; } } }

        #custom_code_href => { 'ACTION_test' => q[sub ACTION_test{ my ($self) = @_; $self->depends_on('build'); if ($ENV{TEST_AUTHOR} or $ENV{TEST_ALL}) { if (!File::Glob::bsd_glob('Makefile.PL',File::Glob::GLOB_NOCASE()) or !File::Glob::bsd_glob('README',File::Glob::GLOB_NOCASE()) or !File::Glob::bsd_glob('META.yml',File::Glob::GLOB_NOCASE())) {$self->depends_on('distmeta')}; if (!File::Glob::bsd_glob('SIGNATURE',File::Glob::GLOB_NOCASE())) {$self->depends_on('sign')};}; return $self->SUPER::ACTION_test;}] }

        my $GLOB_FLAGS = 0;
        if ($opt{ignore_case} eq 'auto') { $GLOB_FLAGS |= ( File::Spec->case_tolerant()? 0 : File::Glob::GLOB_NOCASE() ); }
        else { $GLOB_FLAGS |= ( $opt{ignore_case} ? File::Glob::GLOB_NOCASE() : 0 ); }        # any value resets GLOB_FLAG defaults to 0 => implies nullglob = true

        #my @dependent_files = map { File::Glob::bsd_glob( $_, $GLOB_FLAGS ) } ( ref $_[0] ? @{shift @_} : shift );
        #my @antecedents = map { if ($_) { File::Glob::bsd_glob( $_, $GLOB_FLAGS ) } } ( ref $_[0] ? @{shift @_} : shift );

        #if (not @dependent_files) { return 0; }     # no dependency files found

        my @dependent_files;
        my @files = ( ref $_[0] ? @{shift @_} : shift );    # dependent_files
        for my $file ( @files )
            {
            next if not defined $file;
            my @globs = File::Glob::bsd_glob( $file, $GLOB_FLAGS );
            if (not @globs) { return 0; }   # ALL dependent file entries must return at least one file or return NOT FILES_up_to_date
            push @dependent_files, @globs;
            }
        my @antecedents = map { File::Glob::bsd_glob( $_, $GLOB_FLAGS ) } grep { defined } ( ref $_[0] ? @{(shift)} : shift );      #??: design?: should missing antecedents cause a NOT FILES_up_to_date return?

        my $oldest = @dependent_files ? -M $dependent_files[0] : 0;
        my $youngest = @antecedents ? -M $antecedents[0]: 0;
        for ( @dependent_files ) { if (-M $_ > $oldest) { $oldest = -M $_; } }
        for ( @antecedents ) { if (-M $_ < $youngest) { $youngest = -M $_; } }

        # print 'dep['.scalar(@dependent_files)."] = [ @dependent_files ]\n";
        # print 'ant['.scalar(@antecedents)."] = [ @antecedents ]\n";
        # print "oldest = ".24*60*60*$oldest."\n";
        # print "youngest = ".24*60*60*$youngest."\n";
        # print "youngest >= oldest = ".($youngest >= $oldest)."\n";

        return ( $youngest >= $oldest );
        }
};
$code{'@FILES_to_NIX'} = q{
    sub FILES_to_NIX {
        # FILES_to_NIX( \%:SELF, @:FILE(s) ) => returns undef
        #print "_ = [ @_ ]\n";

        my ($self) = shift;
        my %opt = (
            # ignore_case => 'auto',  # = [undef/0]/true/'auto'       ## 0/undef/false = match case always; 'auto' = match case dependent on File::Spec->case_tolerant(), o/w true = ignore case for matches
            );

        my $me = (caller(0))[3];    ## no critic ( ProhibitMagicNumbers )   ## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
        my $opt_ref;
        $opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));  ## no critic (ProhibitPostfixControls)  ## pop last argument only if it's a HASH reference (assumed to be options for our function)
        if ($opt_ref) { for (keys %{$opt_ref}) { if (exists $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' for function ".$me; return; } } }

        #custom_code_href => { 'ACTION_test' => q[sub ACTION_test{ my ($self) = @_; $self->depends_on('build'); if ($ENV{TEST_AUTHOR} or $ENV{TEST_ALL}) { if (!File::Glob::bsd_glob('Makefile.PL',File::Glob::GLOB_NOCASE()) or !File::Glob::bsd_glob('README',File::Glob::GLOB_NOCASE()) or !File::Glob::bsd_glob('META.yml',File::Glob::GLOB_NOCASE())) {$self->depends_on('distmeta')}; if (!File::Glob::bsd_glob('SIGNATURE',File::Glob::GLOB_NOCASE())) {$self->depends_on('sign')};}; return $self->SUPER::ACTION_test;}] }

        # my $GLOB_FLAGS = 0;
        # if ($opt{ignore_case} eq 'auto') { $GLOB_FLAGS |= ( File::Spec->case_tolerant()? 0 : File::Glob::GLOB_NOCASE() ); }
        # else { $GLOB_FLAGS |= ( $opt{ignore_case} ? File::Glob::GLOB_NOCASE() : 0 ); }        # any value resets GLOB_FLAG defaults to 0 => implies nullglob = true

        my $GLOB_FLAGS = File::Glob::GLOB_NOCASE();

        my @globs = @_;
        my @files = map { File::Glob::bsd_glob( $_, $GLOB_FLAGS ) } @globs;

        foreach my $file (@files) {
            # print "FILES_to_NIX: file = $file\n";
            next if ! -e $file;
            next if -d $file;
            my $fh;
            open( $fh, '< :raw :encoding(UTF-8)', $file ) or die qq{Can't open "$file": $OS_ERROR\n}; ## no critic ( RequireCarping )
            my $file_contents;
            {# slurp entire file
                local $/ = undef;
                $file_contents = <$fh>;
            }
            close $fh or die qq{Can't close "$file" after reading: $OS_ERROR\n}; ## no critic ( RequireCarping )
            $file_contents = q// if not defined $file_contents;
            $file_contents =~ s/\r?[\r\n]/\n/gmsx;
            open( $fh, '> :raw :utf8', $file ) or die qq{Can't open "$file": $OS_ERROR\n}; ## no critic ( RequireCarping )
            print $fh $file_contents;
            close $fh or die qq{Can't close "$file" after rewriting: $OS_ERROR\n}; ## no critic ( RequireCarping )
            }
        return;
        }
};
$code{'do_create'} = q{
    sub create_mymeta {
        # create_mymeta( \%:SELF ) => undef
        my $self = shift;
        $self->SUPER::create_mymeta;
        $self->FILES_to_NIX('MYMETA.json', 'MYMETA.yml');
        return;
        }
    sub do_create_makefile_pl {
        # create_makefile_pl( \%:SELF ) => undef
        my $self = shift;
        $self->SUPER::do_create_makefile_pl;
        print "#1\n";
        $self->FILES_to_NIX('Makefile.PL');
        return;
        }
    sub do_create_readme {
        # do_create_readme( \%:SELF ) => undef
        my $self = shift;
        $self->SUPER::do_create_readme;
        $self->FILES_to_NIX('README');
        return;
        }
    sub do_create_license {
        # do_create_license( \%:SELF ) => undef
        my $self = shift;
        $self->SUPER::do_create_license;
        $self->FILES_to_NIX('LICENSE');
        return;
        }
    sub do_create_metafile {
        # do_create_metafile( \%:SELF ) => undef
        my $self = shift;
        $self->SUPER::do_create_metafile;
        $self->FILES_to_NIX('META.json', 'META.yml');
        return;
        }
};
$code{'ACTION_distmeta'} = q{
    sub ACTION_distmeta {
        my ($self) = @_;

        #[ADD] create meta info; but, to stabilize build for SIGNATURE, only recreate if needed (eg, antecedent file(s) are newer)
        # completely replaces $self->SUPER::ACTION_distmeta (to avoid unneeded file rebuilds)

        $self->depends_on('PL_files');

        #[ADD] update the MANIFEST when building 'distmeta'
        # needed prior to ACTION_distmeta to make sure there is a MANIFEST o/w META.yml creation has errors
        #$self->ACTION_manifest( qq{quiet} );
        {
            local $self->{properties}{quiet} = 1;
            require ExtUtils::Manifest;     # needed to modify $ExtUtils::Manifest::Verbose and $ExtUtils::Manifest::Quiet prior to manifest building
            local ($ExtUtils::Manifest::Verbose, $ExtUtils::Manifest::Quiet) = (0,1);
            $self->ACTION_manifest;         # [use direct execution of ACTION; depends_on() will cache and execute each ACTION only once per script execution]
        }

        # NOTE: FILES_up_to_date( $|\@ dependent_file(s), $|\@ antecedent(s) [, \%] ) {...}

        # do { $self->do_create_makefile_pl; FILES_to_NIX('Makefile.PL'); } if ($self->do_create_makefile_pl and not $self->FILES_up_to_date('Makefile.PL', [ 'Build', 'Build.PL', 'Build.PL.config', $self->_main_docfile ], { ignore_case => 1 }));  ## worry about _main_docfile(), ASSERT?
        # do { $self->do_create_readme; FILES_to_NIX('README'); } if ($self->create_readme and not $self->FILES_up_to_date('README', $self->dist_version_from, { ignore_case => 1 }));    ## worry about _main_docfile(), ASSERT?
        # do { $self->do_create_license; FILES_to_NIX('LICENSE'); } if ($self->create_license and not $self->FILES_up_to_date('LICENSE', [ 'Build', 'Build.PL', 'Build.PL.config', $self->_main_docfile ], { ignore_case => 1 }));  ## worry about _main_docfile(), ASSERT?
        # do { $self->do_create_metafile; FILES_to_NIX('META.json', 'META.yml'); } if (not $self->FILES_up_to_date([ 'META.json', 'META.yml' ], [ 'Build', 'Build.PL', 'Build.PL.config', 'LICENSE', $self->dist_version_from ], { ignore_case => 1 }));   ## worry about _main_docfile(), ASSERT?
        $self->create_makefile_pl if ($self->create_makefile_pl and not $self->FILES_up_to_date('Makefile.PL', [ 'Build', 'Build.PL', 'Build.PL.config', $self->_main_docfile ], { ignore_case => 1 }));  ## worry about _main_docfile(), ASSERT?
        $self->do_create_readme if ($self->create_readme and not $self->FILES_up_to_date('README', $self->dist_version_from, { ignore_case => 1 }));    ## worry about _main_docfile(), ASSERT?
        $self->do_create_license if ($self->create_license and not $self->FILES_up_to_date('LICENSE', [ 'Build', 'Build.PL', 'Build.PL.config', $self->_main_docfile ], { ignore_case => 1 }));  ## worry about _main_docfile(), ASSERT?
        $self->do_create_metafile if (not $self->FILES_up_to_date([ 'META.json', 'META.yml' ], [ 'Build', 'Build.PL', 'Build.PL.config', 'LICENSE', $self->dist_version_from ], { ignore_case => 1 }));   ## worry about _main_docfile(), ASSERT?

        # TODO: check file(s) for up-to-date before recreation of files (and DON'T call SUPER)
        ## Makefile.PL [ check create_metafile_pl ... ]
            #sub do_create_metafile_pl {
            #  my $self = shift;
            #  require Module::Build::Compat;
            #  $self->delete_filetree('Makefile.PL');
            #  $self->log_info("Creating Makefile.PL\n");
            #  Module::Build::Compat->create_metafile_pl($self->create_metafile_pl, $self, @_);
            #  $self->_add_to_manifest('MANIFEST', 'Makefile.PL');
            #}

        ## 'README' [ MODULE files... : check do_create_readme and POD::ReadMe to find the correct files ]
            # README created from _main_docfile
            #my $docfile = $self->_main_docfile;
            #sub _main_docfile {
            #  my $self = shift;
            #  if ( my $pm_file = $self->dist_version_from ) {
            #   (my $pod_file = $pm_file) =~ s/.pm$/.pod/;
            #   return (-e $pod_file ? $pod_file : $pm_file);
            #  } else {
            #   return;
            #  }
            #}

        ## License [ check create_license ... ]
            #sub do_create_license {
            #  my $self = shift;
            #  $self->log_info("Creating LICENSE file");
            #
            #  my $l = $self->license
            #   or die "No license specified";
            #
            #  my $key = $self->valid_licenses->{$l}
            #   or die "'$l' isn't a license key we know about";
            #  my $class = "Software::License::$key";
            #
            #  eval "use $class; 1"
            #   or die "Can't load Software::License to create LICENSE file: $@";
            #
            #  $self->delete_filetree('LICENSE');
            #
            #  my $author = join " & ", @{ $self->dist_author };
            #  my $license = $class->new({holder => $author});
            #  my $fh = IO::File->new('> LICENSE')
            #   or die "Can't write LICENSE file: $!";
            #  print $fh $license->fulltext;
            #  close $fh;
            #
            #  $self->_add_to_manifest('MANIFEST', 'LICENSE');
            #}

        ## META.yml [ check create_metafile ... ]
            #sub do_create_metafile {
            #  my $self = shift;
            #  return if $self->{wrote_metadata};
            #
            #  my $p = $self->{properties};
            #  my $metafile = $self->metafile;
            #
            #  unless ($p->{license}) {
            #    $self->log_warn("No license specified, setting license = 'unknown'\n");
            #    $p->{license} = 'unknown';
            #  }
            #  unless (exists $self->valid_licenses->{ $p->{license} }) {
            #    die "Unknown license type '$p->{license}'";
            #  }
            #
            #  # If we're in the distdir, the metafile may exist and be non-writable.
            #  $self->delete_filetree($metafile);
            #  $self->log_info("Creating $metafile\n");
            #
            #  # Since we're building ourself, we have to do some special stuff
            #  # here: the ConfigData module is found in blib/lib.
            #  local @INC = @INC;
            #  if (($self->module_name || '') eq 'Module::Build') {
            #    $self->depends_on('config_data');
            #    push @INC, File::Spec->catdir($self->blib, 'lib');
            #  }
            #
            #  $self->write_metafile;
            #}

        #[ADD] re-update the MANIFEST with any new files [use direct execution of ACTION; depends_on() will cache and execute each ACTION only once per script execution]
        #$self->ACTION_manifest( qq{quiet} );
        {
            local $self->{properties}{quiet} = 1;
            require ExtUtils::Manifest;     # needed to modify $ExtUtils::Manifest::Verbose and $ExtUtils::Manifest::Quiet prior to manifest building
            local ($ExtUtils::Manifest::Verbose, $ExtUtils::Manifest::Quiet) = (0,1);
            $self->ACTION_manifest;         # [use direct execution of ACTION; depends_on() will cache and execute each ACTION only once per script execution]
        }
    }
};
$code{'ACTION_testall'} = q{
    sub ACTION_testall {
        my ($self) = @_;

        $ENV{TEST_ALL} = 1;

        # build dependency (to make sure we're testing the most recent incarnation of the package)
        $self->depends_on('build');

        # NOT strictly necessary to limit distmeta builds to only TEST_AUTHOR or TEST_ALL cases (distmeta rebuilds are now dependency gated)
        # ... but distmeta rebuilds on other platforms can change minor things such as EOL characters, quote characters, or links, any of which invalidates the SIGNATURE; so, avoid distmeta rebuilds especially for installation tests
        # ... so keep the ENV variable gates
        #$self->depends_on('distmeta');
        if ($ENV{TEST_AUTHOR} or $ENV{TEST_ALL}) { $self->depends_on('distmeta') };

        if (($ENV{TEST_SIGNATURE} or $ENV{TEST_ALL}) and $self->{properties}{sign} and not File::Glob::bsd_glob('SIGNATURE',File::Glob::GLOB_NOCASE())) { $self->depends_on('sign') };    # [case insensitive search on all platforms] don't touch SIGNATURE if already present; and don't touch at all unless going to be tested [use build sign to resign the package]

        return $self->SUPER::ACTION_testall;
    }
};
$code{'ACTION_manifest@_POSSIBLE_add_to_manifest'} = q{
    #[ADD] _POSSIBLE_add_to_manifest = add sort after adding to manifest to keep MANIFEST in sorted condition
    sub _POSSIBLE_add_to_manifest {
        my ($self) = @_;

        $self->_add_to_manifest();
        $self->_sort_manifest();
      }
};
$code{'ACTION_manifest@sort_manifest'} = q{
    sub _sort_manifest {
        my ($self, $manifest) = @_;

        my $fh;

        $fh = IO::File->new("< $manifest") or die "Can't read $manifest: $!";
        my @lines = <$fh>;
        $fh->close;

        return unless @lines;

        my @sorted_lines = sort { lc $a cmp lc $b } @lines;

        #print "sorted_lines = ".@sorted_lines."\n";
        #print "lines = ".@lines."\n";
        my $are_equal = (@sorted_lines == @lines);
        for (my $i = 0; $i < @sorted_lines; $i++)
            {
            #print "sl[$i] = $sorted_lines[$i]\n";
            #print " l[$i] = $lines[$i]\n";
            if ($sorted_lines[$i] ne $lines[$i]) { $are_equal = 0; last; }
            }

        return if $are_equal;

        my $mode = (stat $manifest)[2];
        chmod($mode | oct(222), $manifest) or die "Can't make $manifest writable: $!";

        $fh = IO::File->new("> $manifest") or die "Can't write to $manifest: $!";
        print $fh map "$_", @sorted_lines;
        close $fh;
        chmod($mode, $manifest);

        $self->FILES_to_NIX( 'MANIFEST' );

        $self->log_info("Sorted $manifest\n");
    }
};
$code{'ACTION_manifest'} = q{
  {
  my $dist_name = q{};
  my $dist_version = q{};
  my $dist_path = q{};
    ## FROM: ExtUtils::Manifest (v1.54)
    sub my_maniskip {
        # print STDERR "HERE in my_maniskip()\n";
        my @skip ;
        my $mfile = shift || "$ExtUtils::Manifest::MANIFEST.SKIP";
        # print STDERR "my_maniskip(): mfile = $mfile\n";
        ExtUtils::Manifest::_check_mskip_directives($mfile) if -f $mfile;
        local(*M, $_);
        open M, "< $mfile" or open M, "< $ExtUtils::Manifest::DEFAULT_MSKIP" or return sub {0};
        while (<M>){
        chomp;
        s/\r//;
        next if /^#/;
        next if /^\s*$/;
        ## BUGFIX: trailing comments were being interpreted into the regexp ## TODO: ExtUtils::Manifest docs say whitespace may be included in regexp if single quoted o/w whitespace and anything following are discarded as comments (see perldoc ExtUtils::Manifest, MANIFEST section)
        ## NOTE: this repairs the BUG for this Build.PL, however, other tools (such as 'cpansign') use the bugged ExtUtils::Manifest and so won't interpret the MANIFEST.SKIP file in the same manner (basically breaking any line with a trailing comment)
        ##       ** so, best practice is to avoid ANY trailing comments in MANIFEST.SKIP
        #?: s/\s+(#[^']*)?$//;  # remove trailing whitespace and comments (any whitespace followed by '#')
        ##s/\s+(#.*)?$//;   # remove trailing whitespace and comments (any whitespace followed by '#')
        #TODO: leave whitespace/comment characters within single quotes alone (need a balanced single quote regexp here)
        ##  s/^'//;
        ##  s/'$//;
        $_ =~ qr{^\s*(?:(?:'([^\\\\']*(?:\\\\.[^\\\\']*)*)')|([^#\s]\S*))?(?:(?:\s*)|(?:\s+(.*?)\s*))$};
        #my $comment = $3;
        my $filename = $2;
        if ( defined($1) ) { $filename = $1; $filename =~ s/\\\\(['\\\\])/$1/g; }   ## #'
        next if (not defined($filename) or not $filename);
        #print "skip: regexp = '$filename'\n";
        #TODO: check for bad regexps
        #push @skip, ExtUtils::Manifest::_macify($_);
        push @skip, ExtUtils::Manifest::_macify($filename);
        }
        close M;
        # bring $dist_name, $dist_version, $dist_path into current scope
        my @x = ($dist_name, $dist_version, $dist_path);
        #print "dist_path = $dist_path\n";
        #print "dist_name = $dist_name\n";
        #print "dist_version = $dist_version\n";
        #print 'skip['.scalar(@skip)."] = {". join(':', @skip) ."}]\n\n";
        # insert vars into regexps
        for (@skip) {
            s:\$\\{(\w+)\\}:eval '${'.$1.'}':eg;
            # print STDERR "skip: $_\n";
            }

        return sub {0} unless (scalar @skip > 0);

        # extinguish only used once warnings
        my $dummy; $dummy = $ExtUtils::Manifest::Is_VMS; $dummy = $ExtUtils::Manifest::MANIFEST; $dummy = $ExtUtils::Manifest::DEFAULT_MSKIP;

        my $opts = $ExtUtils::Manifest::Is_VMS ? '(?i)' : '';

        # Make sure each entry is isolated in its own parentheses, in case
        # any of them contain alternations
        my $regex = join '|', map "(?:$_)", @skip;

#       return sub {
#           my $f = File::Spec->rel2abs($_[0]);
#           if ($^O eq 'MSWin32') {$f =~ s:\\\\:/:g;};
#           #print "[$_[0]=>$f]\n";
#           return ($f =~ qr{$opts$regex});
#           };
        return sub {
            ## NOT # check each regex against the full filename
            ## ... # this is not noticibly slower than the single regex against the relative/shortened filename
            ## ... my $f = File::Spec->rel2abs($_[0]);
            # check each regex vs relative filename
            my $f = $_[0];
            if ($^O eq 'MSWin32') {$f =~ s:\\\\:/:g;};      # unixify path for Win32
            my $found = 0;
            #print "[$_[0]=>$f]:";
            #print 'skip['.scalar(@skip)."] = {". join(':', @skip) ."}]\n\n";
            for my $re (@skip) { if ($f =~ qr{$opts$re}) { $found = 1; last; } };
            #print "[skip = ".($found ? "true" : "false")."]\n";
            return $found;
            };
      }
    sub my_maniskip_init {
        my ($self) = @_;

        use File::Spec::Functions qw( rel2abs );
        use File::Basename qw( dirname );

        ## ADDED: dist_name and dist_version for use within MANIFEST.SKIP
        $dist_name = quotemeta( $self->dist_name );
        $dist_version = quotemeta( $self->dist_version );
        # $dist_path = dirname(rel2abs($0)); $dist_path =~ s:\\\\:\/:g; $dist_path = quotemeta( $dist_path );
        $dist_path = $self->notes('config/dist_path'); $dist_path =~ s:\\\\:\/:g; $dist_path = quotemeta( $dist_path );
        # print "dist_name = $dist_name\n";
        # print "dist_version = $dist_version\n";
        # print "dist_path = $dist_path\n";
    }
    sub ACTION_manifest {
        my ($self) = @_;
        #my ($self, $quiet) = @_;

        #use Sub::Override;
        require ExtUtils::Manifest; #ExtUtils::Manifest->import();
        my $codeRef = \&my_maniskip;
        #my $override = Sub::Override->new( 'ExtUtils::Manifest::maniskip' => $codeRef );
        #local *ExtUtils::Manifest::_maniskip = \&my_maniskip;
        {no warnings 'redefine';
        *ExtUtils::Manifest::maniskip = $codeRef;
        }

        use File::Spec::Functions qw( rel2abs );
        use File::Basename qw( dirname );

        $self->my_maniskip_init();

        # URLrefs: [Capture::Tiny] http://search.cpan.org/~DAGOLDEN/Capture-Tiny , [Close + Re-opening STDOUT] http://www.perlmonks.org/?node_id=617136
#       my ($OUT, $o, $ERR, $e);
#       if ( $quiet ) {
#           print "REDIRECTING\n";
#           # redirect STDOUT/STDERR and suppress ACTION_manifest output
#           open($OUT,'>&STDOUT');
#           close STDOUT;
#           open STDOUT, '>', \$o or die "Unable to redirect STDOUT: $!";
#           open($ERR,'>&STDERR');
#           close STDERR;
#           open STDERR, '>', \$e or die "Unable to redirect STDERR: $!";
#           }

#       BEGIN { eval { require Capture::Tiny; 1; }; }   # Capture::Tiny requires loading via BEGIN [see URLref: http://perlmonks.com/?node=Seekers%20of%20Perl%20Wisdom ]
#       my $haveCaptureTiny = eval { require Capture::TinyX; 1; };
#       my $o = q{};
#       my $e = q{};
#       if ($haveCaptureTiny) {
#           ($o, $e) = Capture::Tiny::capture { $self->SUPER::ACTION_manifest; };
#           }
#       else {

            $self->SUPER::ACTION_manifest;

#           }
#       print 'o=['.$o."]\n" unless $quiet;
#       print 'e=['.$e."]\n";

#       if ( $quiet ) {
#           # re-open STDOUT/STDERR for normal output
#           open STDOUT, ">&", $OUT or die "can't reopen STDOUT: $!";
#           open STDERR, ">&", $ERR or die "can't reopen STDERR: $!";
#           print "REOPENED\n";
#           }

        # ???: SIGN?
        #my $dist_path = '.';
        #$dist_path = dirname(rel2abs($0));
        #$dist_path =~ s:\\\\:\/:g;
        #$self->_sign_dir($dist_path);

        #my $manifest = File::Spec->catfile($dist_path, $ExtUtils::Manifest::MANIFEST);
        #$self->_sort_manifest( $manifest );
        $self->_sort_manifest( $ExtUtils::Manifest::MANIFEST );
      }
    ##?? add Sub::Override for maniskip here?? for all subs in the new Build
    #require ExtUtils::Manifest;
    #use Sub::Override;
    #my $codeRef = \&my_maniskip;
    #my $override = Sub::Override->new( 'ExtUtils::Manifest::maniskip' => $codeRef );
    #my $override = Sub::Override->new( 'ExtUtils::Manifest::maniskip' => \&my_maniskip );
    #override->restore;
    #*ExtUtils::Manifest::_maniskip = \&my_maniskip;

    # CHECK: ... might be brittle:: Module::Signature overrides it as well ( but only for ExtUtils::Manifest->VERSION < 1.41 ), probably ok
    # ToDO: ... petition ExtUtils::Manifest maintainers for a hook? changing the original code might break some folks MANIFEST.SKIPs
  }
};
$code{'ACTION_ppd@my_varchname'} = q{
    ##BUGBYPASS: [for Module::Build v0.3 and perl v5.10+ $^V version string change] repairs incorrect version interpretation for perl v5.10+ (still works for 5.8 and earlier, as well)
    sub my_varchname {  # Copied from PPMMaker.pm
        my ($self, $config) = @_;
        my $varchname = $config->{archname};
        # Append "-5.8" to architecture name for Perl 5.8 and later
        #if (defined($^V) && ord(substr($^V,1)) >= 8) {
          #$varchname .= sprintf("-%d.%d", ord($^V), ord(substr($^V,1)));
        #}
        ## BUGFIX: send to Module::Build::PPMMaker and PPM
        if (defined($^V)) {
            my @v = split(/\./, sprintf(qq{%vd},$^V));
            if ($v[1] >= 8) {
                $varchname .= '-'.$v[0].'.'.$v[1];
                }
        }
        return $varchname;
      }
};
$code{'ACTION_ppd'} = q{
    # copied from Mobule::Build - Base.pm (v0.3)
    sub ACTION_ppd {
        my ($self) = @_;
        require Module::Build::PPMMaker;
        my $ppd = Module::Build::PPMMaker->new();
        #use Sub::Override;
        my $codeRef = \&my_varchname;
        #my $override = Sub::Override->new( 'Module::Build::PPMMaker::_varchname' => $codeRef );
        {no warnings 'redefine';
        *Module::Build::PPMMaker::_varchname = $codeRef;
        }
        my $file = $ppd->make_ppd(%{$self->{args}}, build => $self);
        $self->add_to_cleanup($file);
      }
};
$code{'ACTION_test'} = q{
    sub ACTION_test {
        my ($self) = @_;

        # build dependency (to make sure we're testing the most recent incarnation of the package)
        $self->depends_on('build');

        # NOT strictly necessary to limit distmeta builds to only TEST_AUTHOR or TEST_ALL cases (distmeta rebuilds are now dependency gated)
        # ... but distmeta rebuilds on other platforms can change minor things such as EOL characters, quote characters, or links, any of which invalidates the SIGNATURE; so, avoid distmeta rebuilds especially for installation tests
        # ... so keep the ENV variable gates
        #$self->depends_on('distmeta');
        if ($ENV{TEST_AUTHOR} or $ENV{TEST_ALL}) { $self->depends_on('distmeta') };

        if (($ENV{TEST_SIGNATURE} or $ENV{TEST_ALL}) and $self->{properties}{sign} and not File::Glob::bsd_glob('SIGNATURE',File::Glob::GLOB_NOCASE())) { $self->depends_on('sign') };    # [case insensitive search on all platforms] don't touch SIGNATURE if already present; and don't touch at all unless going to be tested [use build sign to resign the package]

        return $self->SUPER::ACTION_test;
      }
};
$code{'ACTION_version_set'} = q{
    #[ADD] version_set( v ) - write version to $build->notes('config/VERSION_filename')
    sub ACTION_version_set {
        my $self = shift;

        use English qw( -no_match_vars ); ##    # long Perl built-in variable names ['-no_match_vars' avoids regex performance penalty]

        my $VERSION_filename = $self->notes('config/VERSION_filename');

        my $fh;

        my $v;
        my ($M, $m, $a);

        my $args_aref = $self->args('ARGV');
        ##print "args() = [ @{$args_aref} ]\n";
        if ( scalar(@{$args_aref}) > 0 ) { $v = @{$args_aref}[0]; }

        if ( $v =~ /(\d+)[._](\d+)(?:[\._](\d+))?(?:[\._](\d+))?/ )
            {
            $M = $1;
            $m = $2;
            $a = defined $3 ? $3 : q{};
            }
        else {
            die "Can't parse version string ('$v')\n";  ## no critic ( RequireCarping )
            }
        $v = version_f( $M, $m, $a );

        open( $fh, '>', $VERSION_filename ) or die "Can't write to '$VERSION_filename': $OS_ERROR\n"; ## no critic ( RequireCarping )
        print $fh $self->notes('config/VERSION_prefix').$v.$self->notes('config/VERSION_suffix');
        close $fh or die "Can't close '$VERSION_filename' after writing: $OS_ERROR\n"; ## no critic ( RequireCarping )

        $self->notes('config/VERSION_M' => $M);
        $self->notes('config/VERSION_m' => $m);
        $self->notes('config/VERSION_a' => $a);
        $self->notes('config/VERSION' => $v);

        print "Version set (\$VERSION = '$v')\n";
        }
};
$code{'ACTION_version_set_next'} = q{
    #[ADD] version_set_next - update version in $build->notes('config/VERSION_filename') to next alpha build number
    # NOTE: VERSION == Major.minor[_alpha] { if no alpha: minor is ODD => alpha (aka, developer, beta, or experimental), minor is EVEN => stable or release }
    sub ACTION_version_set_next {
        my $self = shift;

        use English qw( -no_match_vars ); ##    # long Perl built-in variable names ['-no_match_vars' avoids regex performance penalty]

        my $VERSION_filename = $self->notes('config/VERSION_filename');

        my $fh;

        my $v;
        my $M = $self->notes('config/VERSION_M');
        my $m = $self->notes('config/VERSION_m');
        my $a = $self->notes('config/VERSION_a');

        if ($a ne q{}) { $a++ }
        else {
            $m++;
            if (($m % 2) eq 0) { $m++ };
            }

        $v = version_f( $M, $m, $a );

        open( $fh, '>', $VERSION_filename ) or die "Can't write to '$VERSION_filename': $OS_ERROR\n"; ## no critic ( RequireCarping )
        print $fh $self->notes('config/VERSION_prefix').$v.$self->notes('config/VERSION_suffix');
        close $fh or die "Can't close '$VERSION_filename' after writing: $OS_ERROR\n"; ## no critic ( RequireCarping )

        $self->notes('config/VERSION_M' => $M);
        $self->notes('config/VERSION_m' => $m);
        $self->notes('config/VERSION_a' => $a);
        $self->notes('config/VERSION' => $v);

        print "Version set (\$VERSION = '$v')\n";
        }
};
$code{'ACTION_version_set_next_release'} = q{
    #[ADD] version_set_next_release - update version in $build->notes('config/VERSION_filename') to next alpha build number
    # NOTE: VERSION == Major.minor[_alpha] { if no alpha: minor is ODD => alpha (aka, developer, beta, or experimental), minor is EVEN => stable or release }
    sub ACTION_version_set_next_release {
        my $self = shift;

        use English qw( -no_match_vars ); ##    # long Perl built-in variable names ['-no_match_vars' avoids regex performance penalty]

        my $VERSION_filename = $self->notes('config/VERSION_filename');

        my $fh;

        my $v;
        my $M = $self->notes('config/VERSION_M');
        my $m = $self->notes('config/VERSION_m');
        my $a = $self->notes('config/VERSION_a');

        $a = q{};
        $m++;
        if (($m % 2) ne 0) { $m++ };

        $v = version_f( $M, $m, $a );

        open( $fh, '>', $VERSION_filename ) or die "Can't write to '$VERSION_filename': $OS_ERROR\n"; ## no critic ( RequireCarping )
        print $fh $self->notes('config/VERSION_prefix').$v.$self->notes('config/VERSION_suffix');
        close $fh or die "Can't close '$VERSION_filename' after writing: $OS_ERROR\n"; ## no critic ( RequireCarping )

        $self->notes('config/VERSION_M' => $M);
        $self->notes('config/VERSION_m' => $m);
        $self->notes('config/VERSION_a' => $a);
        $self->notes('config/VERSION' => $v);

        print "Version set (\$VERSION = '$v')\n";
        }
};
return %code;
}


## FROM: Module::Build::Base
#sub ACTION_manifest {
#  my ($self) = @_;
#
#  my $maniskip = 'MANIFEST.SKIP';
#  unless ( -e 'MANIFEST' || -e $maniskip ) {
#    $self->log_warn("File '$maniskip' does not exist: Creating a default '$maniskip'\n");
#    $self->_write_default_maniskip($maniskip);
#  }
#
#  require ExtUtils::Manifest;  # ExtUtils::Manifest is not warnings clean.
#  local ($^W, $ExtUtils::Manifest::Quiet) = (0,1);
#  use Sub::Override;
#  my $override = Sub::Override->new( 'ExtUtils::Manifest::maniskip' => &my_maniskip );
#  ExtUtils::Manifest::mkmanifest('ExtUtils::Manifest::maniskip');
#  override->restore;
#}

# FROM: Module::Build::Base
#sub ACTION_manifest {
#  my ($self) = @_;
#
#  my $maniskip = 'MANIFEST.SKIP';
#  unless ( -e 'MANIFEST' || -e $maniskip ) {
#    $self->log_warn("File '$maniskip' does not exist: Creating a default '$maniskip'\n");
#    $self->_write_default_maniskip($maniskip);
#  }
#
#  require ExtUtils::Manifest;  # ExtUtils::Manifest is not warnings clean.
#  local ($^W, $ExtUtils::Manifest::Quiet) = (0,1);
#  ExtUtils::Manifest::mkmanifest();
#}


# FROM: Module::Build::Base
#sub ACTION_manifest {
#  my ($self) = @_;
#
#  my $maniskip = 'MANIFEST.SKIP';
#  unless ( -e 'MANIFEST' || -e $maniskip ) {
#    $self->log_warn("File '$maniskip' does not exist: Creating a default '$maniskip'\n");
#    $self->_write_default_maniskip($maniskip);
#  }
#
#  require ExtUtils::Manifest;  # ExtUtils::Manifest is not warnings clean.
#  local ($^W, $ExtUtils::Manifest::Quiet) = (0,1);
#  ExtUtils::Manifest::mkmanifest();
#}

# FROM: ExtUtils::Manifest
## returns an anonymous sub that decides if an argument matches
#sub maniskip {
#    my @skip ;
#    my $mfile = shift || "$MANIFEST.SKIP";
#    _check_mskip_directives($mfile) if -f $mfile;
#    local(*M, $_);
#    open M, "< $mfile" or open M, "< $DEFAULT_MSKIP" or return sub {0};
#    while (<M>){
#   chomp;
#   s/\r//;
#   next if /^#/;
#   next if /^\s*$/;
#        s/^'//;
#        s/'$//;
#   push @skip, _macify($_);
#    }
#    close M;
#    return sub {0} unless (scalar @skip > 0);
#
#    my $opts = $Is_VMS ? '(?i)' : '';
#
#    # Make sure each entry is isolated in its own parentheses, in case
#    # any of them contain alternations
#    my $regex = join '|', map "(?:$_)", @skip;
#
#    return sub { $_[0] =~ qr{$opts$regex} };
#}
