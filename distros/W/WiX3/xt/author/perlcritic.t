#!perl

# Test that modules pass perlcritic and perltidy.

use strict;
use Test::More;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
    'Perl::Tidy',
	'Perl::Critic',
	'PPIx::Regexp',
	'Email::Address',
	'Perl::Critic::Utils::Constants',
	'Perl::Critic::More',
	'Test::Perl::Critic',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "require $MODULE"; # Has to be require because we pass options to import.
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

if ( 1.116 > eval { $Perl::Critic::VERSION } ) {
	BAIL_OUT( 'Perl::Critic needs updated to 1.116' );
}

if ( 20101217 > eval { $Perl::Tidy::VERSION } ) {
	BAIL_OUT( "Perl::Tidy needs updated to 20101217" );
}

diag('Takes a few minutes...');

use File::Spec::Functions qw(catfile);
Perl::Critic::Utils::Constants->import(':profile_strictness');
my $dummy = $Perl::Critic::Utils::Constants::PROFILE_STRICTNESS_QUIET;

local $ENV{PERLTIDY} = catfile( 'xt', 'settings', 'perltidy.txt' );

my $rcfile = catfile( 'xt', 'settings', 'perlcritic.txt' );
Test::Perl::Critic->import( 
	-profile            => $rcfile, 
	-severity           => 1, 
	-profile-strictness => $Perl::Critic::Utils::Constants::PROFILE_STRICTNESS_QUIET
);

all_critic_ok();

