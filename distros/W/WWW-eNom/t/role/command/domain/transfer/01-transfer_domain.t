#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;
use MooseX::Params::Validate;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );
use Test::WWW::eNom::Contact qw( create_contact );

use WWW::eNom::Contact;
use WWW::eNom::DomainRequest::Transfer;

subtest 'Transfer Unregistered Domain' => sub {
    my $api = create_api();

    my $request;
    lives_ok {
        $request = WWW::eNom::DomainRequest::Transfer->new(
            name               => $UNREGISTERED_DOMAIN->name,
            epp_key            => '12345',
            registrant_contact => create_contact(),
            admin_contact      => create_contact(),
            technical_contact  => create_contact(),
            billing_contact    => create_contact(),
        );
    } 'Lives through creating request object';

    my $domain_transfer;
    lives_ok {
        $domain_transfer = $api->transfer_domain( request => $request );
    } 'Lives through transfering domain';

    inspect_preliminary_transfer_detail(
        request         => $request,
        domain_transfer => $domain_transfer,
    );

    my $mocked_submit = mock_submit(
        request   => $request,
        order_id  => $domain_transfer->order_id,
        status_id => 20,
        status    => 'Canceled - Domain is currently not registered and cannot be transferred',
    );

    subtest 'Inspect Pending Transfer Detail' => sub {
        my $updated_domain_transfer = $api->get_transfer_by_order_id( $domain_transfer->order_id );

        cmp_ok( $updated_domain_transfer->status_id, '==', 20, 'Correct status_id' );
        cmp_ok( $updated_domain_transfer->status, 'eq',
            'Canceled - Domain is currently not registered and cannot be transferred', 'Correct status' );
    };
};

subtest 'Transfer Domain - Bad EPP Key' => sub {
    my $api = create_api();

    my $request;
    lives_ok {
        $request = WWW::eNom::DomainRequest::Transfer->new(
            name               => 'godaddy.com',
            epp_key            => '12345',
            registrant_contact => create_contact(),
            admin_contact      => create_contact(),
            technical_contact  => create_contact(),
            billing_contact    => create_contact(),
        );
    } 'Lives through creating request object';

    my $domain_transfer;
    lives_ok {
        $domain_transfer = $api->transfer_domain( request => $request );
    } 'Lives through transfering domain';

    inspect_preliminary_transfer_detail(
        request         => $request,
        domain_transfer => $domain_transfer,
    );

    my $mocked_submit = mock_submit(
        request   => $request,
        order_id  => $domain_transfer->order_id,
        status_id => 32,
        status    => 'Canceled - Invalid EPP/authorization key - Please contact current registrar to obtain correct key',
    );

    subtest 'Inspect Pending Transfer Detail' => sub {
        my $updated_domain_transfer = $api->get_transfer_by_order_id( $domain_transfer->order_id );

        cmp_ok( $updated_domain_transfer->status_id, '==', 32, 'Correct status_id' );
        cmp_ok( $updated_domain_transfer->status, 'eq',
            'Canceled - Invalid EPP/authorization key - Please contact current registrar to obtain correct key',
            'Correct status' );
    };
};

subtest 'Transfer Domain - New Contacts - No Privacy, Locking, Auto Renew' => sub {
    my $api = create_api();

    my $request;
    lives_ok {
        $request = WWW::eNom::DomainRequest::Transfer->new(
            name                  => $NOT_MY_DOMAIN->name,
            epp_key               => '12345',
            is_private            => 0,
            is_locked             => 0,
            is_auto_renew         => 0,
            use_existing_contacts => 0,
            registrant_contact    => create_contact(),
            admin_contact         => create_contact(),
            technical_contact     => create_contact(),
            billing_contact       => create_contact(),
        );
    } 'Lives through creating request object';

    my $domain_transfer;
    lives_ok {
        $domain_transfer = $api->transfer_domain( request => $request );
    } 'Lives through transfering domain';

    inspect_preliminary_transfer_detail(
        request         => $request,
        domain_transfer => $domain_transfer,
    );

    my $mocked_submit = mock_submit(
        request   => $request,
        order_id  => $domain_transfer->order_id,
        status_id => 9,
        status    => 'Awaiting auto verification of transfer request',
    );

    subtest 'Inspect Pending Transfer Detail' => sub {
        my $updated_domain_transfer = $api->get_transfer_by_order_id( $domain_transfer->order_id );

        cmp_ok( $updated_domain_transfer->status_id, '==', 9, 'Correct status_id' );
        cmp_ok( $updated_domain_transfer->status, 'eq',
            'Awaiting auto verification of transfer request',
            'Correct status' );

        for my $contact_type (qw( registrant admin technical billing )) {
            my $attribute = sprintf('%s_contact', $contact_type );
            my $predicate = sprintf('has_%s_contact', $contact_type );

            ok( $updated_domain_transfer->$predicate, "Correctly has $contact_type contact" );
            is_deeply( $updated_domain_transfer->$attribute, $request->$attribute, "Correct $contact_type contact" );
        }
    };
};

subtest 'Transfer Domain - Use Existing Contacts - With Privacy, Locking, Auto Renew' => sub {
    my $api = create_api();

    my $request;
    lives_ok {
        $request = WWW::eNom::DomainRequest::Transfer->new(
            name                  => $NOT_MY_DOMAIN->name,
            epp_key               => '12345',
            is_private            => 1,
            is_locked             => 1,
            is_auto_renew         => 1,
            use_existing_contacts => 1,
        );
    } 'Lives through creating request object';

    my $domain_transfer;
    lives_ok {
        $domain_transfer = $api->transfer_domain( request => $request );
    } 'Lives through transfering domain';

    inspect_preliminary_transfer_detail(
        request         => $request,
        domain_transfer => $domain_transfer,
    );

    my $mocked_submit = mock_submit(
        request   => $request,
        order_id  => $domain_transfer->order_id,
        status_id => 9,
        status    => 'Awaiting auto verification of transfer request',
    );

    subtest 'Inspect Pending Transfer Detail' => sub {
        my $updated_domain_transfer = $api->get_transfer_by_order_id( $domain_transfer->order_id );

        cmp_ok( $updated_domain_transfer->status_id, '==', 9, 'Correct status_id' );
        cmp_ok( $updated_domain_transfer->status, 'eq',
            'Awaiting auto verification of transfer request',
            'Correct status' );

        for my $contact_type (qw( registrant admin technical billing )) {
            my $predicate = sprintf('has_%s_contact', $contact_type );
            ok( !$domain_transfer->$predicate, "Correctly lacks $contact_type contact" );
        }
    };
};

# I considered adding test coverage for these additional cases but because
# we are mocking everything anyway there is no difference between these and
# other errors.  Because of this, I'm leaving these unimplemented.
#subtest 'Transfer Domain - Domain is Locked'
#subtest 'Transfer Domain - Too New to Transfer'
#subtest 'Transfer Domain From Another eNom Account'

done_testing;

sub inspect_preliminary_transfer_detail {
    my ( %args ) = validated_hash(
        \@_,
        request         => { isa => 'WWW::eNom::DomainRequest::Transfer' },
        domain_transfer => { isa => 'WWW::eNom::DomainTransfer'          },
    );

    subtest 'Inspect Preliminary Transfer Detail' => sub {
        if( isa_ok( $args{domain_transfer}, 'WWW::eNom::DomainTransfer' ) ) {
            like( $args{domain_transfer}->order_id, qr/^\d+$/, 'order_id looks numeric' );
            cmp_ok( $args{domain_transfer}->name,                  'eq', lc $args{request}->name, 'Correct name' );
            cmp_ok( $args{domain_transfer}->is_locked,             '==', $args{request}->is_locked, 'Correct is_locked' );
            cmp_ok( $args{domain_transfer}->is_auto_renew,         '==', $args{request}->is_auto_renew, 'Correct is_auto_renew' );
            cmp_ok( $args{domain_transfer}->use_existing_contacts, '==',
                $args{request}->use_existing_contacts, 'Correct use_existing_contacts' );
            cmp_ok( $args{domain_transfer}->status_id,             '==', 9, 'Correct status_id' );
            cmp_ok( $args{domain_transfer}->status, 'eq', 'Awaiting auto verification of transfer request', 'Correct status' );

            for my $contact_type (qw( registrant admin technical billing )) {
                my $predicate = sprintf('has_%s_contact', $contact_type );
                ok( !$args{domain_transfer}->$predicate, "Correctly lacks $contact_type contact" );
            }
        }
    };

    return;
}

sub mock_submit {
    my ( %args ) = validated_hash(
        \@_,
        request   => { isa => 'WWW::eNom::DomainRequest::Transfer' },
        order_id  => { isa => 'Int' },
        status_id => { isa => 'Int' },
        status    => { isa => 'Str' },
    );

    my $mock = Test::MockModule->new('WWW::eNom');
    $mock->mock('submit', sub {
        note('Mocked WWW::eNom->submit');

        my $contacts;
        if( $args{request}->use_existing_contacts ) {
            $contacts = {
                'Registrant' => 'None',
                'Tech'       => 'None',
                'Admin'      => 'None',
                'AuxBilling' => 'None',
            };
        }
        else {
            $contacts = {
                'Registrant' => $args{request}->registrant_contact->construct_creation_request(),
                'Tech'       => $args{request}->technical_contact->construct_creation_request(),
                'Admin'      => $args{request}->admin_contact->construct_creation_request(),
                'AuxBilling' => $args{request}->billing_contact->construct_creation_request(),
            };
        }

        return {
            ErrCount            => 0,
            transferorderdetail => {
                'transferorderdetailid' => $args{order_id},
                'sld'         => $args{request}->sld,
                'tld'         => $args{request}->tld,
                'statusid'    => $args{status_id},
                'statusdesc'  => $args{status},
                'lock'        => ( $args{request}->is_locked             ? 'True' : 'False' ),
                'renew'       => ( $args{request}->is_auto_renew         ? 'True' : 'False' ),
                'usecontacts' => ( $args{request}->use_existing_contacts ? '1' : '0' ),
                'contacts'    => $contacts,
            },
        }
    });

    return $mock;
}
