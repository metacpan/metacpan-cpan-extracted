#!perl

eval "use Test::Perl::Critic";

if ($@) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}
else {
    Test::Perl::Critic->import(
        -verbose  => 8,
        -severity => 5,
## This check fails to differentiate between parameters and class variables
## This is not changing a class variable :/
##  $config->param( 'lang', delete( $args->{lang} ) ) if ( $args->{lang} );
        -exclude => ['ProhibitAccessOfPrivateData']
    );
}

Test::Perl::Critic::all_critic_ok();
