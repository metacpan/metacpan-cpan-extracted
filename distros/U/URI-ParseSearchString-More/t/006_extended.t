# -*- perl -*-

use strict;
use warnings;

=head1 SYNOPSIS

To run these tests, set the environment variable TEST_UPM_EXTENDED to some
true value.

These tests will not be run by default.  The tricky part about this module is
that it relies on certain web services to be available, and that's not always
going to be the case.  So, certain URLs which may or may not constistently be
available will be tested here.

This test uses the URLS in t/extended_urls.cfg  If you would like to add more test
cases, just add them to t/extended_urls.cfg and re-run this test.  If you find failing
URLs, please create an RT ticket and include the section(s) of urls.cfg which
you have added.

If you would like to run these tests, set the environment
variable TEST_UPM_EXTENDED to some true value.  For example, you can modify this
script:

$ENV{'TEST_UPM_EXTENDED'} = 1

or, depending on your shell:

export TEST_UPM_EXTENDED=1

If you would like to run this test with caching enabled, set the environment
variable TEST_UPM_CACHED to some true value.  For example, you can modify this
script:

$ENV{'TEST_UPM_CACHED'} = 1

or, depending on your shell:

export TEST_UPM_CACHED=1


=cut

use Test::Most;

use URI::ParseSearchString::More;

my $more = URI::ParseSearchString::More->new();

use Config::General;
my $conf = new Config::General(
    -ConfigFile      => "t/extended_urls.cfg",
    -BackslashEscape => 1,
);
my %config = $conf->getall;

if ( exists $ENV{'TEST_UPM_CACHED'}
    && $ENV{'TEST_UPM_CACHED'} )
{
    $more->set_cached( 1 );
    diag( "caching is enabled..." );
}

my $skip = 1;
if ( exists $ENV{'TEST_UPM_EXTENDED'}
    && $ENV{'TEST_UPM_EXTENDED'} )
{
    $skip = 0;
    diag( "extended testing is enabled..." );
}

my $tests = scalar @{ $config{'urls'} };

SKIP: {

    skip "See inline docs for info on how to enable these tests", $tests
        if $skip;

    foreach my $test ( @{ $config{'urls'} } ) {
        next unless $test->{'terms'};

        my $terms = $more->parse_search_string( $test->{'url'} );

        cmp_ok( $terms, 'eq', $test->{'terms'}, "got $terms" );
        cmp_ok(
            $more->blame(), 'eq',
            'URI::ParseSearchString::More',
            "parsed by More"
        );

    }

}

done_testing();
