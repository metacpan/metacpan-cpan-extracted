#!/usr/bin/env perl

use Modern::Perl '2015';
use lib('lib');

use WG::API;

use Test::More;

BEGIN {
    use_ok('WG::API::Error') || say "WG::API::Error loaded";
}

my $error;
my %error_params = (
    field   => 'search',
    message => 'SEARCH_NOT_SPECIFIED',
    code    => 402,
    value   => 'null',
);

can_ok( 'WG::API::Error', qw/field message code value/ );

eval { $error = WG::API::Error->new() };
ok( !$error && $@, 'create error object without params' );

eval { $error = WG::API::Error->new(%error_params) };
ok( $error && !$@, 'create error object with valid params' );
isa_ok( $error, 'WG::API::Error' );

ok( $error->field eq $error_params{'field'},     'error->field checked' );
ok( $error->message eq $error_params{'message'}, 'error->message checked' );
ok( $error->code eq $error_params{'code'},       'error->code checked' );
ok( $error->value eq $error_params{'value'},     'error->value checked' );
ok( !ref $error->raw,                            'error->raw checked' );

done_testing();

