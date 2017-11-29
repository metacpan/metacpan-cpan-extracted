#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 4;

use Validator::Lazy;

describe 'Internal roles' => sub {

    it 'Test' => sub {
        my $v = Validator::Lazy->new();

        ok( ! $v->check( Test => 0 ), 'test is error' );

        my $warnings = [
            { code => 'TEST_WARNING',        field => 'Test', data => { 'x_warn'     => 'warn data'       } },
            { code => 'CHECK_TEST_WRN_CODE', field => 'Test', data => { 'x_chk_warn' => 'warn check data' } },
            { code => 'AFTER_TEST_WRN_CODE', field => 'Test', data => {                                   } },
        ];
        my $errors = [
            { code => 'TEST_ERROR',          field => 'Test', data => { 'x_err'     => 'err data'       } },
            { code => 'CHECK_TEST_ERR_CODE', field => 'Test', data => { 'x_chk_err' => 'err check data' } },
            { code => 'AFTER_TEST_ERR_CODE', field => 'Test', data => {                                 } },
        ];

        is_deeply( $v->errors,   $errors,   'errors ok'   );
        is_deeply( $v->warnings, $warnings, 'warnings ok' );

        is( [ $v->check( Test => 0 ) ]->[1]->{Test}, 555, 'value corrected' );
    };
};

runtests unless caller;
