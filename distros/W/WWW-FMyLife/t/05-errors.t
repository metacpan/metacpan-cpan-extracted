#!perl

# testing possible errors

use strict;
use warnings;
use WWW::FMyLife;

use Test::More tests => 12;
use Test::Deep;

SKIP: {
    skip 'Error tests have been disabled for now' => 12;

    eval 'use Net::Ping';
    $@ && skip 'Net::Ping required for this test' => 12;

    my $p = Net::Ping->new('syn', 2);

    if ( ( ! $p->ping('google.com') ) && ( ! $p->ping('yahoo.com') ) ) {
        $p->close;
        skip q{Both Google and Yahoo down? most likely you're offline} => 12;
    }

    $p->close;
    my $fml = WWW::FMyLife->new();

    diag('Removing API URL');
    my $api_url = $fml->api_url;
    $fml->api_url('http://127.0.0.1:7656/free/the/animals');

    my $my_error =
        qr/500 Can't connect to 127\.0\.0\.1\:7656/;

    ok( ! $fml->last,       'Failing on incorrect API URL' );
    ok(   $fml->error,      'Error flag is up'             );
    ok( ! $fml->fml_errors, 'No FML error flag'            );

    like( $fml->module_error, $my_error, 'General module error' );

    diag('Returning API, removing key');
    $fml->api_url($api_url);
    $fml->key('');
    ok( ! $fml->last, 'Making last fail' );

    cmp_deeply(
        $fml->fml_errors,
        [ 'Invalid API key' ],
        'FML errors: API key missing',
    );

    ok( ! $fml->module_error, 'No module error'  );
    ok(   $fml->error,        'Error flag is up' );

    diag('Setting back key');
    $fml->key('readonly');

    ok(   $fml->last,         'last() has no errors' );
    ok( ! $fml->error,        'No error flag'        );
    ok( ! $fml->module_error, 'No module errors'     );
    ok( ! $fml->fml_errors,   'No FML errors'        );
}

