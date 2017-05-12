#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Email EPP Key On Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->email_epp_key_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Email EPP Key On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->email_epp_key_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Email EPP Key On Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    lives_ok {
        $api->email_epp_key_by_name( $domain->name );
    } 'Lives through emailing epp key';
};

done_testing;
