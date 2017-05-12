#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Customer qw( create_customer );
use Test::WWW::LogicBoxes::Contact qw( create_contact );
use Test::WWW::LogicBoxes::Domain qw( create_domain );

use Readonly;
Readonly my @CONTACT_TYPES => qw( registrant_contact_id admin_contact_id technical_contact_id billing_contact_id );

my $logic_boxes = create_api();
my $customer    = create_customer();
my @contacts;
for my $contact_number ( 1 .. 4 ) {
    push @contacts, create_contact( customer_id => $customer->id );
}

subtest 'Update Contacts on a Domain That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->update_domain_contacts(
            id                    => 999999999,
            registrant_contact_id => $contacts[0]->id,
            admin_contact_id      => $contacts[1]->id,
            technical_contact_id  => $contacts[2]->id,
            billing_contact_id    => $contacts[3]->id,
        );
    } qr/No such domain exists/, 'Throws attempting to update contacts on a domain that does not exist';
};

subtest 'Update Contacts - New Contact Does Not Exist' => sub {
    my $domain = create_domain(
        customer_id           => $customer->id,
        registrant_contact_id => $contacts[0]->id,
        admin_contact_id      => $contacts[1]->id,
        technical_contact_id  => $contacts[2]->id,
        billing_contact_id    => $contacts[3]->id,
    );

    for my $contact_type ( @CONTACT_TYPES ) {
        subtest $contact_type => sub {
            throws_ok {
                $logic_boxes->update_domain_contacts(
                    id            => $domain->id,
                    $contact_type => 999999999,
                );
            } qr/Invalid $contact_type specified/, 'Throws with invalid contact id';
        };
    }
};

subtest 'Update Contacts - No Changes' => sub {
    my $domain = create_domain(
        customer_id           => $customer->id,
        registrant_contact_id => $contacts[0]->id,
        admin_contact_id      => $contacts[1]->id,
        technical_contact_id  => $contacts[2]->id,
        billing_contact_id    => $contacts[3]->id,
    );

    lives_ok {
        $logic_boxes->update_domain_contacts(
            id                    => $domain->id,
            registrant_contact_id => $contacts[0]->id,
            admin_contact_id      => $contacts[1]->id,
            technical_contact_id  => $contacts[2]->id,
            billing_contact_id    => $contacts[3]->id,
        );
    } 'Lives through updating domain contacts';

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
    ok( !$retrieved_domain->has_irtp_detail, 'Correctly lacks irtp_detail' );

    for my $contact_type ( @CONTACT_TYPES ) {
        cmp_ok( $retrieved_domain->$contact_type, '==', $domain->$contact_type, "Correct $contact_type");
    }
};

subtest 'Update Contacts - Change Registrant Contact' => sub {
    for my $irtp_lock ( 0, 1 ) {
        subtest sprintf('Transfer Lock Status After Change : %s', ( $irtp_lock ? 'Lock' : 'Do Not Lock' ) ) => sub {
            my $domain = create_domain(
                customer_id           => $customer->id,
                registrant_contact_id => $contacts[0]->id,
                admin_contact_id      => $contacts[1]->id,
                technical_contact_id  => $contacts[2]->id,
                billing_contact_id    => $contacts[3]->id,
            );

            my $new_contact = create_contact( customer_id => $customer->id );

            lives_ok {
                $logic_boxes->update_domain_contacts(
                    id                    => $domain->id,
                    is_transfer_locked    => $irtp_lock,
                    registrant_contact_id => $new_contact->id,
                );
            } 'Lives through updating domain contacts';

            my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
            ok( $retrieved_domain->has_irtp_detail, 'Correctly has irtp_detail' );

            for my $contact_type ( @CONTACT_TYPES ) {
                cmp_ok( $retrieved_domain->$contact_type, '==', $domain->$contact_type, "Correctly unchanged $contact_type" );
            }

            subtest 'Inspect IRTP Detail' => sub {
                my $irtp_detail = $retrieved_domain->irtp_detail;
                cmp_ok( $irtp_detail->is_transfer_locked,   '==', $irtp_lock, 'Correct is_transfer_locked' );
                cmp_ok( $irtp_detail->expiration_date->ymd, 'eq', DateTime->now->add( days => 2 )->ymd, 'Correct expiration_date' );
                cmp_ok( $irtp_detail->gaining_foa_status,   'eq', 'PENDING', 'Correct gaining_foa_status' );
                cmp_ok( $irtp_detail->losing_foa_status,    'eq', 'PENDING', 'Correct losing_foa_status' );
                cmp_ok( $irtp_detail->status,               'eq', 'PENDING', 'Correct status' );
                cmp_ok( $irtp_detail->proposed_registrant_contact_id, '==',
                    $new_contact->id, 'Correct proposed_registrant_contact_id' );
                ok( !$irtp_detail->has_message, 'Correctly lacks message' );
            };
        };
    }
};

subtest 'Update Contacts - Change Non Registrant Contact' => sub {
    for my $contact_type (qw( admin_contact_id technical_contact_id billing_contact_id )) {
        subtest $contact_type => sub {
            my $domain = create_domain(
                customer_id           => $customer->id,
                registrant_contact_id => $contacts[0]->id,
                admin_contact_id      => $contacts[1]->id,
                technical_contact_id  => $contacts[2]->id,
                billing_contact_id    => $contacts[3]->id,
            );

            my $new_contact = create_contact( customer_id => $customer->id );

            lives_ok {
                $logic_boxes->update_domain_contacts(
                    id            => $domain->id,
                    $contact_type => $new_contact->id,
                );
            } 'Lives through updating domain contacts';

            my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
            ok( !$retrieved_domain->has_irtp_detail, 'Correctly lacks irtp_detail' );

            for my $updated_contact_type ( @CONTACT_TYPES ) {
                if( $updated_contact_type eq $contact_type ) {
                    cmp_ok( $retrieved_domain->$updated_contact_type, '==', $new_contact->id,
                        "Correctly updated $updated_contact_type");
                }
                else {
                    cmp_ok( $retrieved_domain->$updated_contact_type, '==', $domain->$updated_contact_type,
                        "Correct unchanged $updated_contact_type");
                }
            }
        };
    }
};

subtest 'Update Contacts - Change All Contacts' => sub {
    my $domain = create_domain(
        customer_id           => $customer->id,
        registrant_contact_id => $contacts[0]->id,
        admin_contact_id      => $contacts[1]->id,
        technical_contact_id  => $contacts[2]->id,
        billing_contact_id    => $contacts[3]->id,
    );

    my @updated_contacts;
    for my $contact_number ( 1 .. 4 ) {
        push @updated_contacts, create_contact( customer_id => $customer->id );
    }

    lives_ok {
        $logic_boxes->update_domain_contacts(
            id                    => $domain->id,
            registrant_contact_id => $updated_contacts[0]->id,
            admin_contact_id      => $updated_contacts[1]->id,
            technical_contact_id  => $updated_contacts[2]->id,
            billing_contact_id    => $updated_contacts[3]->id,
        );
    } 'Lives through updating domain contacts';

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

    subtest 'Inspect IRTP' => sub {
        ok( $retrieved_domain->has_irtp_detail, 'Correctly has irtp_detail' );
        cmp_ok( $retrieved_domain->irtp_detail->is_transfer_locked, '==', 1, 'Correct is_transfer_locked' );
        cmp_ok( $retrieved_domain->irtp_detail->proposed_registrant_contact_id, '==', $updated_contacts[0]->id,
            'Correct proposed_registrant_contact_id' );
    };

    subtest 'Inspect Other Contacts' => sub {
        for my $contact_type ( @CONTACT_TYPES ) {
            cmp_ok( $retrieved_domain->$contact_type, '==', $domain->$contact_type, "Correctly unchanged $contact_type" );
        }
    };
};

subtest 'Changing the Registrant Twice - Second Time Fails' => sub {
    my $domain = create_domain(
        customer_id           => $customer->id,
        registrant_contact_id => $contacts[0]->id,
        admin_contact_id      => $contacts[1]->id,
        technical_contact_id  => $contacts[2]->id,
        billing_contact_id    => $contacts[3]->id,
    );

    my $first_new_registrant_contact  = create_contact( customer_id => $customer->id );
    my $second_new_registrant_contact = create_contact( customer_id => $customer->id );

    lives_ok {
        $logic_boxes->update_domain_contacts(
            id                    => $domain->id,
            registrant_contact_id => $first_new_registrant_contact->id,
        );
    } 'Lives through updating domain contacts';

    throws_ok {
        $logic_boxes->update_domain_contacts(
            id                    => $domain->id,
            registrant_contact_id => $second_new_registrant_contact->id,
        );
    } qr/There is already a pending action on this domain/,
        'Throws trying to update an already in progress registrant contact change';
};

subtest 'Changing the Registrant Then Changing Another Contact' => sub {
    my $domain = create_domain(
        customer_id           => $customer->id,
        registrant_contact_id => $contacts[0]->id,
        admin_contact_id      => $contacts[1]->id,
        technical_contact_id  => $contacts[2]->id,
        billing_contact_id    => $contacts[3]->id,
    );

    my $new_registrant_contact = create_contact( customer_id => $customer->id );
    my $new_admin_contact      = create_contact( customer_id => $customer->id );

    lives_ok {
        $logic_boxes->update_domain_contacts(
            id                    => $domain->id,
            registrant_contact_id => $new_registrant_contact->id,
        );
    } 'Lives through updating registrant domain contact';

    throws_ok {
        $logic_boxes->update_domain_contacts(
            id               => $domain->id,
            admin_contact_id => $new_admin_contact->id,
        );
    } qr/There is already a pending action on this domain/,
        'Throws trying to update an already in progress registrant contact change';
};

subtest 'Changing Something Other Then Registrant Then Changing the Registrant' => sub {
    my $domain = create_domain(
        customer_id           => $customer->id,
        registrant_contact_id => $contacts[0]->id,
        admin_contact_id      => $contacts[1]->id,
        technical_contact_id  => $contacts[2]->id,
        billing_contact_id    => $contacts[3]->id,
    );

    my $new_admin_contact      = create_contact( customer_id => $customer->id );
    my $new_registrant_contact = create_contact( customer_id => $customer->id );

    lives_ok {
        $logic_boxes->update_domain_contacts(
            id               => $domain->id,
            admin_contact_id => $new_admin_contact->id,
        );
    } 'Lives through updating admin domain contact';

    lives_ok {
        $logic_boxes->update_domain_contacts(
            id                    => $domain->id,
            registrant_contact_id => $new_registrant_contact->id,
        );
    } 'Lives through updating registrant domain contact';

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

    subtest 'Inspect IRTP' => sub {
        ok( $retrieved_domain->has_irtp_detail, 'Correctly has irtp_detail' );
        cmp_ok( $retrieved_domain->irtp_detail->is_transfer_locked, '==', 1, 'Correct is_transfer_locked' );
        cmp_ok( $retrieved_domain->irtp_detail->proposed_registrant_contact_id, '==', $new_registrant_contact->id,
            'Correct proposed_registrant_contact_id' );
    };

    subtest 'Inspect Contacts' => sub {
        cmp_ok( $retrieved_domain->registrant_contact_id, '==', $domain->registrant_contact_id, 'Correct registrant_contact_id' );
        cmp_ok( $retrieved_domain->admin_contact_id,      '==', $new_admin_contact->id, 'Correct admin_contact_id' );
        cmp_ok( $retrieved_domain->technical_contact_id,  '==', $domain->technical_contact_id, 'Correct technical_contact_id' );
        cmp_ok( $retrieved_domain->billing_contact_id,    '==', $domain->billing_contact_id, 'Correct billing_contact_id' );
    };
};

done_testing;
