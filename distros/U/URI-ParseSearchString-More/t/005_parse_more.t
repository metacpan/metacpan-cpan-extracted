# -*- perl -*-

use strict;
use warnings;

=head1 SYNOPSIS

This test uses the URLS in t/urls.cfg  If you would like to add more test
cases, just add them to t/urls.cfg and re-run this test.  If you find failing
URLs, please create an RT ticket and include the section(s) of urls.cfg which
you have added.

If you would like to run this test with caching enabled, set the environment
variable TEST_UPM_CACHED to some true value.  For example, you can modify this
script:

$ENV{'TEST_UPM_CACHED'} = 1

or, depending on your shell:

export TEST_UPM_CACHED=1

=cut

use Test::Most;
use Test::RequiresInternet;

use URI::ParseSearchString::More;

my $more = URI::ParseSearchString::More->new();

use Config::General;
my $conf = new Config::General(
    -ConfigFile      => "t/urls.cfg",
    -BackslashEscape => 1,
);
my %config = $conf->getall;

if ( exists $ENV{'TEST_UPM_CACHED'}
    && $ENV{'TEST_UPM_CACHED'} )
{
    $more->set_cached( 1 );
    diag( "caching is enabled..." );
}

foreach my $test ( @{ $config{'urls'} } ) {
    next unless $test->{'terms'};

    my $terms = $more->parse_search_string( $test->{'url'} );

    if (   $more->get_mech
        && $more->get_mech->status
        && $more->get_mech->status == 403 )
    {
        diag( "You may be getting blocked by $test->{'url'}" );
        exit( 0 );
    }

    is( $terms, $test->{'terms'}, "got $terms" );
    is( $more->blame(), 'URI::ParseSearchString::More', 'parsed by More' );

}

done_testing();
