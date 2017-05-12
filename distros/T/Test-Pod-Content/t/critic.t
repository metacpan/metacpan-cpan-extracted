use strict;
use warnings;

use Test::More;

if ( not $ENV{RELEASE_TESTING} ) {
	my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
	plan( skip_all => $msg );
	exit 0;
}

eval {
    require Test::Perl::Critic;
    Test::Perl::Critic::import('Test::Perl::Critic',
        -profile => 't/perlcriticrc', -serverity => 1
    );
};
if ($@) {
    Test::More::plan( 
       skip_all => 'Test::Critic required for testing criticism'
    );
}
if (-d 't/') {
    all_critic_ok();
}
else {
    # chdir .. is stupid, but the profile has to be given 
    # as argument to import and is loaded in all_critic_ok...
    chdir '..';
    all_critic_ok('lib');
}
