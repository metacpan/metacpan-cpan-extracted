#!perl -w   -- -*- tab-width: 4; mode: perl -*- ## no critic ( CodeLayout::RequireTidyCode Modules::RequireVersionVar )

## no critic ( ControlStructures::ProhibitPostfixControls NamingConventions::Capitalization )

use strict;
use warnings;

use English qw( -no_match_vars ); # enable long-form built-in variable names; '-no_match_vars' avoids regex performance penalty for perl versions <= 5.16

{; ## no critic ( ProhibitOneArgSelect ProhibitPunctuationVars RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;  # DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless ($ENV{TEST_AUTHOR} or $ENV{AUTHOR_TESTING}) or ($ENV{TEST_RELEASE} or $ENV{RELEASE_TESTING}) or $ENV{TEST_ALL} or $ENV{CI};

my $haveTestPerlCritic = eval { require Test::Perl::Critic; 1; };

plan skip_all => 'Test::Perl::Critic required to criticize code' if !$haveTestPerlCritic;

##-- config
my %config;
# $config{-exclude} = [ qw( CodeLayout::RequireTidyCode CodeLayout::ProhibitHardTabs CodeLayout::ProhibitParensWithBuiltins Documentation::RequirePodAtEnd RegularExpressions::RequireExtendedFormatting RegularExpressions::RequireLineBoundaryMatching Miscellanea::RequireRcsKeywords ControlStructures::ProhibitPostfixControls Subroutines::RequireArgUnpacking Variables::RequireLocalizedPunctuationVars ) ];
$config{-severity} = 1;     # [ 5 = gentle, 4 = stern, 3 = harsh, 2 = cruel, 1 = brutal ]
# $config{-top}      = 10;    # limit number of criricisms to top <N> criticisms
$config{-verbose}  = '[%l:%c]: (%p; Severity: %s) %m. %e. ';
##

Test::Perl::Critic->import( %config );

# all_critic_ok( ... ); # runs in parallel (which is incompatible with Devel::Cover coverage or perl < v5.8.9)

my @targets = ( (-e 'blib' ? 'blib' : 'lib') );
my @files = Perl::Critic::Utils::all_perl_files( @targets );

my $perl_version_current = version->parse( sprintf '%vd', $PERL_VERSION ); # sprintf is used for compatibility back to perl < v5.10
my $perl_version_min = version->parse( '5.8.9' );

my $have_incompatible_version = $perl_version_current < $perl_version_min;

my $active_coverage = eval { $Devel::Cover::VERSION } ? 1 : 0;

# diag( "criticizing ".scalar @files." file(s)" );
if ( $have_incompatible_version || $active_coverage ) {
        plan tests => scalar @files;
        for my $file (@files) { critic_ok( $file ); };
    } else {
        all_critic_ok( @files );
    }
