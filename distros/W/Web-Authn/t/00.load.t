#!perl
##----------------------------------------------------------------------------
## WebAuthn - t/00.load.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
};

# To build the list of modules:
# find ./lib -type f -name "*.pm" -print | xargs perl -lE 'my @f=sort(@ARGV); for(@f) { s,./lib/,,; s,\.pm$,,; s,/,::,g; substr( $_, 0, 0, q{use_ok( ''} ); $_ .= q{'' );}; say $_; }'
BEGIN
{
    use_ok( 'Web::Authn' ) or BAIL_OUT( 'Cannot load Web::Authn' );
    use_ok( 'Web::Authn::Attestation' );
    use_ok( 'Web::Authn::CBOR' );
    use_ok( 'Web::Authn::COSE' );
    use_ok( 'Web::Authn::Crypto' );
    use_ok( 'Web::Authn::Exception' );
    use_ok( 'Web::Authn::NullObject' );
    use_ok( 'Web::Authn::Parse' );
}

diag( "Testing Web::Authn $Web::Authn::VERSION, Perl $], $^X" );

done_testing;

__END__
