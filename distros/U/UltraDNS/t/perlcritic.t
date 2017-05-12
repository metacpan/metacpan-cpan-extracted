#!perl

use Test::More;

plan( skip_all => "Developer only test")
    unless -d ".svn";

if (!eval { require Test::Perl::Critic }) {
    plan( skip_all => "Test::Perl::Critic required for testing PBP compliance");
}

Test::Perl::Critic->import(
    -severity => 4,
    # force use of local perlcriticrc to avoid picking up the users own
    # (which may be more strict and so make the test fail)
    -profile => File::Spec->catfile( 't', 'perlcriticrc' ),
);

all_critic_ok();
