#!perl
############ STANDARD Perl::Critic TEST - DO NOT EDIT ##################
use strict;
use File::Spec::Functions;
use FindBin;
use Test::More;
unless ($ENV{PERL_CRITIC_TESTS} || $ENV{PERL_AUTHOR} || $ENV{THIS_IS_MARKF_YOU_BETCHA}) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic tests not enabled (set PERL_CRITIC_TESTS or PERL_AUTHOR env var)"
    );
}
unless (require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for complaining compliance"
    );
}
Test::Perl::Critic->import( -profile => catfile( $FindBin::Bin, "anyperlperlcriticrc" ) );
Test::Perl::Critic::all_critic_ok();
