#!perl
#
#   Test WWW::Shorten::ShadyURL
#
#   $Id: 20-WWW-Shorten-ShadyURL.t 141 2010-05-18 03:41:20Z infidel $
#

use Test::More tests => 7;

###
### VARS
###

my $testurl = 'http://www.youtube.com/watch?v=2pfwY2TNehw'; # Pale Blue Dot
my( $shorturl, $longurl, $FAILCOUNT );
my $TRUE = 1;

###
### TESTS
###

# Test: Can we use the module?  Will pull in WWW::Shorten automagically.
BEGIN {
	use_ok( 'WWW::Shorten::ShadyURL' );
}

# -------------------------------------------------
# Knowingly abusing a TO-DO block for online tests.
# -------------------------------------------------
TODO: {
    local $TODO = "Online tests may fail intermittently.";

    # Test: shortening
    ok( $shorturl = makeashorterlink( $testurl ),
        'ONLINE: makeashorterlink() works' )
      or $FAILCOUNT++;

    # Test: resolving
    ok( $longurl = makealongerlink( $shorturl ),
        'ONLINE: makealongerlink() works' )
      or $FAILCOUNT++;

    # Test: two are equal
    is( $longurl, $testurl, 'ONLINE: short and resolved URL equivalence' )
      or $FAILCOUNT++;

    undef $shorturl;
    undef $longurl;

    # Test: shortening w/ &shorten=on
    ok( $shorturl = makeashorterlink( $testurl, $TRUE ),
        'ONLINE: makeashorterlink() works w/ shortener' )
      or $FAILCOUNT++;

    # Test: resolving above
    ok( $longurl = makealongerlink( $shorturl ),
        'ONLINE: makealongerlink() still works' )
      or $FAILCOUNT++;

    # Test: two are still equal
    is( $longurl, $testurl, 'ONLINE: shorter and resolved URL equivalence' )
      or $FAILCOUNT++;

} # end TO-DO section

if( $FAILCOUNT )
{
    diag( "\n\nNOTE: $FAILCOUNT of the ONLINE tests have failed. This is " .
          "likely not a problem with\n" .
          "the module, but rather an intermittent issue with the shortener " .
          "service.\n\n" );
}

# XXX: These are moot because we use prototypes.
# ----------------------
# Expected failure modes
# ----------------------
#eval {
#    $junk = makeashorterlink();
#};
#like( $@, qr/No URL passed to makeashorterlink/, 'Expected failure: short()' );
#
#eval {
#    $junk = makealongerlink();
#};
#like( $@, qr/^No URL passed to makealongerlink/, 'Expected failure: long()' );


__END__
