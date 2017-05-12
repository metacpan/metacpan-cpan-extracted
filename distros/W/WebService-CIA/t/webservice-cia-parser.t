use strict;
use Test::More tests => 9;
use Module::Build;

#1
BEGIN {	use_ok('WebService::CIA::Parser'); }

#2
my $parser = WebService::CIA::Parser->new();
ok( defined $parser, 'new() returns something' );

#3
ok( $parser->isa('WebService::CIA::Parser'), 'new() returns a WebService::CIA::Parser object' );

my $data = $parser->parse('zz', q(
                        <td width="20%" valign="top" class="FieldLabel">
                                <div align="right">Test:</div>
                        </td>
                        <td valign="top" bgcolor="#FFFFFF" width="80%">
                                Wombat
                        </td>
));

#4
ok( exists $data->{Test} &&
    $data->{Test} eq 'Wombat', 'parse() - sets field data correctly' );

#5
ok( exists $data->{URL} &&
    $data->{URL} eq $WebService::CIA::base_url . 'geos/zz.html', 'parse() - sets URL data correctly' );

SKIP: {

    skip 'Skipping internet-based tests - set TEST_INTERNET to run these tests', 4 if ! $ENV{ TEST_INTERNET };

    require LWP::UserAgent;
    require Crypt::SSLeay;

    my $ua = LWP::UserAgent->new();
    my $data = $parser->parse( 'uk', '' );

    for ( "URL - Flag", "URL - Map", "URL", "URL - Print" ) {
        my $resp = $ua->get( $data->{ $_ } );
        is( $resp->code, 200, "$_ OK" );
    }

}
