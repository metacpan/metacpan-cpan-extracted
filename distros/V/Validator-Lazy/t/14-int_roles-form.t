#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 18;

use Validator::Lazy;

describe 'Internal roles' => sub {

    it 'Form' => sub {
        my $v = Validator::Lazy->new();

        ok( $v->check( Form => { Phone => '+380978763456', Email => 'test@godaddy.com' } ) );
        is_deeply( $v->errors, [ ] );

        ok( ! $v->check( Form => { Phone => 'zzzz', Email => 'test@godaddy.com' } ) );
        is_deeply( $v->errors, [ { code => 'PHONE_BAD_FORMAT', field => 'Phone', data => {} } ] );

        ok( ! $v->check( Form => { Phone => 'zzzz', Email => 'yyyy' } ) );

        is_deeply( $v->errors, [
            { code => 'EMAIL_ERROR',      field => 'Email', data => { error_code => 'rfc822' } },
            { code => 'PHONE_BAD_FORMAT', field => 'Phone', data => {} },
        ] );
    };

    it 'Form' => sub {
        my $v = Validator::Lazy->new(
            {
                ph => [ 'Phone', 'Required' ],
                em => 'Email',
                cc => [ 'CountryCode', 'Required' ],
                ff => [ { Form => [ 'ph', 'em', 'cc' ] } ],
            }
        );

        ok( ! $v->check( ff => { } ) );
        is_deeply( $v->errors, [
            { code => 'REQUIRED_ERROR', field => 'cc', data => { } },
            { code => 'REQUIRED_ERROR', field => 'ph', data => { } },
        ] );

        ok( ! $v->check( ff => { em => 'zzz' } ) );

        is_deeply( $v->errors, [
            { code => 'REQUIRED_ERROR', field => 'cc', data => { } },
            { code => 'EMAIL_ERROR',    field => 'em', data => { error_code => 'rfc822' } },
            { code => 'REQUIRED_ERROR', field => 'ph', data => { } },
        ] );

        ok( ! $v->check( ff => { em => 'info@godaddy.com', cc => 'zz' } ) );
        is_deeply( $v->errors, [
            { code => 'COUNTRYCODE_ERROR', field => 'cc', data => { } },
            { code => 'REQUIRED_ERROR', field => 'ph', data => { } },
        ] );

        ok( ! $v->check( ff => { em => 'info@godaddy.com', cc => 'US' } ) );
        is_deeply( $v->errors, [
            { code => 'REQUIRED_ERROR', field => 'ph', data => { } },
        ] );

        ok( $v->check( ff => { em => 'info@godaddy.com', cc => 'US', ph => '+380509874967' } ) );
        is_deeply( $v->errors, [ ] );
    };

    it 'FormFieldDepend' => sub {
        my $v = Validator::Lazy->new(
            {
                ph => [ 'Phone', 'Required' ],
                em => 'Email',
                cc => [ 'CountryCode', 'Required' ],
                ff => [ { Form => [ 'ph', 'em', 'cc' ] }, 'Validator::Lazy::TestRole::FieldDep' ],
            }
        );

        my $data = {
            ph => '+380509874967',
            em => 'info@domain.com',
            cc => 'US',
        };

        ok( ! $v->check( ff => $data ) );

        is_deeply( $v->errors, [
            {
                'code' => 'VALIDATOR_LAZY_TESTROLE_FIELDDEP_ERROR',
                'data' => {},
                'field' => 'ff'
            }
        ] );

    };
};

runtests unless caller;
