#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Contact qw( create_contact );
use Test::WWW::eNom::Domain qw(
    create_domain retrieve_domain_with_cron_delay
    $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN
);

subtest 'Update Contacts for Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->update_contacts_for_domain_name(
            domain_name        => $UNREGISTERED_DOMAIN->name,
            registrant_contact => create_contact(),
            admin_contact      => create_contact(),
            technical_contact  => create_contact(),
            billing_contact    => create_contact(),
        );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Update Contacts for Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->update_contacts_for_domain_name(
            domain_name        => $NOT_MY_DOMAIN->name,
            registrant_contact => create_contact(),
            admin_contact      => create_contact(),
            technical_contact  => create_contact(),
            billing_contact    => create_contact(),
        );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Update Contacts - No Changes' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    lives_ok {
        $api->update_contacts_for_domain_name(
            domain_name        => $domain->name,
            registrant_contact => $domain->registrant_contact,
            admin_contact      => $domain->admin_contact,
            technical_contact  => $domain->technical_contact,
            billing_contact    => $domain->billing_contact,
        );
    } 'Lives through updating contact';

    my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );

    subtest 'Inspect Unchanged Contacts' => sub {
        for my $unchanged_contact_type (qw( registrant_contact admin_contact technical_contact billing_contact )) {
            is_deeply( $retrieved_domain->$unchanged_contact_type, $domain->$unchanged_contact_type,
                "Correct unchanged $unchanged_contact_type ");
        }
    };
};

subtest 'Update Contacts - Change Registrant Contact - With Transfer Lock' => sub {
    subtest 'Domain Transfer Lock After Update' => sub {
        my $api    = create_api();
        my $domain = create_domain();

        my $updated_contact = create_contact({
            first_name        => 'New First Name',
            last_name         => 'New Last Name',
            organization_name => 'Some Other Organization',
            job_title         => 'Bug Squisher',
            phone_number      => '18005550000',
        });

        lives_ok {
            $api->update_contacts_for_domain_name(
                domain_name        => $domain->name,
                is_transfer_locked => 1,
                registrant_contact => $updated_contact,
            );
        } 'Lives through updating contact';

        my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );

        subtest 'Inspect IRTP Detail' => sub {
            if( isa_ok( $retrieved_domain->irtp_detail, 'WWW::eNom::IRTPDetail' ) ) {
                my $irtp_detail = $retrieved_domain->irtp_detail;
                cmp_ok( $irtp_detail->is_transfer_locked, '==', 1, 'Correct is_transfer_locked' );
            }
        };

        subtest 'Inspect Changed Contact' => sub {
            is_deeply( $retrieved_domain->registrant_contact, $updated_contact, 'Correctly updated registrant contact' );
        };

        subtest 'Inspect Unchanged Contacts' => sub {
            for my $unchanged_contact_type (qw( admin_contact technical_contact billing_contact ) ) {
                is_deeply( $retrieved_domain->$unchanged_contact_type, $domain->$unchanged_contact_type,
                    "Correct unchanged $unchanged_contact_type ");
            }
        };
    };

    subtest 'Opt Out of Transfer Lock' => sub {
        my $api    = create_api();
        my $domain = create_domain();

        my $updated_contact = create_contact({
            first_name        => 'New First Name',
            last_name         => 'New Last Name',
            organization_name => 'Some Other Organization',
            job_title         => 'Bug Squisher',
            phone_number      => '18005550000',
        });

        lives_ok {
            $api->update_contacts_for_domain_name(
                domain_name        => $domain->name,
                is_transfer_locked => 0,
                registrant_contact => $updated_contact,
            );
        } 'Lives through updating contact';

        my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );

        ok( !$retrieved_domain->has_irtp_detail, 'Correctly lacks irtp_detail' );

        subtest 'Inspect Changed Contact' => sub {
            is_deeply( $retrieved_domain->registrant_contact, $updated_contact, 'Correctly updated registrant contact' );
        };

        subtest 'Inspect Unchanged Contacts' => sub {
            for my $unchanged_contact_type (qw( admin_contact technical_contact billing_contact ) ) {
                is_deeply( $retrieved_domain->$unchanged_contact_type, $domain->$unchanged_contact_type,
                    "Correct unchanged $unchanged_contact_type ");
            }
        };
    };
};

subtest 'Update Contacts - Change Non Registrant Contact' => sub {
    for my $contact_type (qw( admin_contact technical_contact billing_contact )) {
        my $api    = create_api();
        my $domain = create_domain();

        my $updated_contact = create_contact({
            first_name        => 'New First Name',
            last_name         => 'New Last Name',
            organization_name => 'Some Other Organization',
            job_title         => 'Bug Squisher',
            phone_number      => '18005550000',
        });

        lives_ok {
            $api->update_contacts_for_domain_name(
                domain_name   => $domain->name,
                $contact_type => $updated_contact,
            );
        } 'Lives through updating contact';

        my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );

        ok( !$retrieved_domain->has_irtp_detail, 'Correctly lacks rtp_detail' );

        subtest 'Inspect Changed Contact' => sub {
            is_deeply( $retrieved_domain->$contact_type, $updated_contact, "Correctly updated $contact_type" );
        };

        subtest 'Inspect Unchanged Contacts' => sub {
            for my $unchanged_contact_type ( qw( admin_contact technical_contact billing_contact ) ) {
                ( $unchanged_contact_type eq $contact_type ) and next;

                is_deeply( $retrieved_domain->$unchanged_contact_type, $domain->$unchanged_contact_type,
                    "Correct unchanged $unchanged_contact_type ");
            }
        };

    };
};

subtest 'Update Contacts - Change All Contacts' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $updated_contacts = {
        registrant_contact => create_contact({
            organization_name => 'London Univeristy',
            job_title         => 'Bug Squisher',
            phone_number      => '18005550000',
        }),
        admin_contact      => create_contact({
            phone_number      => '18005550001',
            fax_number        => '18005551212',
        }),
        technical_contact  => create_contact({
            phone_number      => '18005550002',
        }),
        billing_contact    => create_contact({
            phone_number      => '18005550003',
        }),
    };

    lives_ok {
        $api->update_contacts_for_domain_name(
            domain_name        => $domain->name,
            is_transfer_locked => 1,
            %{ $updated_contacts },
        );
    } 'Lives through updating contacts';

    my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );

    subtest 'Inspect IRTP Detail' => sub {
        if( isa_ok( $retrieved_domain->irtp_detail, 'WWW::eNom::IRTPDetail' ) ) {
            my $irtp_detail = $retrieved_domain->irtp_detail;
            cmp_ok( $irtp_detail->is_transfer_locked, '==', 1, 'Correct is_transfer_locked' );
        }
    };

    subtest 'Inspect Contacts' => sub {
        for my $contact_type ( keys %{ $updated_contacts } ) {
            is_deeply( $retrieved_domain->$contact_type, $updated_contacts->{$contact_type}, "Correct $contact_type" );
        }
    };
};

subtest 'Changing Contacts After Changing The Registrant' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    subtest 'First Change Of Registrant' => sub {
        my $updated_contact = create_contact({
            first_name        => 'First First Name',
            last_name         => 'First Last Name',
            organization_name => 'First Other Organization',
            job_title         => 'First Bug Squisher',
            phone_number      => '18005551111',
        });

        lives_ok {
            $api->update_contacts_for_domain_name(
                domain_name        => $domain->name,
                is_transfer_locked => 1,
                registrant_contact => $updated_contact,
            );
        } 'Lives through updating contact';

        my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );
        is_deeply( $retrieved_domain->registrant_contact, $updated_contact, 'Correct registrant contact' );
    };

    subtest 'Another Change of Registrant - Overwrites Previous Request' => sub {
        my $updated_contact = create_contact({
            first_name        => 'Second First Name',
            last_name         => 'Second Last Name',
            organization_name => 'Second Other Organization',
            job_title         => 'Second Bug Squisher',
            phone_number      => '18005552222',
        });

        lives_ok {
            $api->update_contacts_for_domain_name(
                domain_name        => $domain->name,
                is_transfer_locked => 1,
                registrant_contact => $updated_contact,
            );
        } 'Lives through updating contact';

        my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );
        is_deeply( $retrieved_domain->registrant_contact, $updated_contact, 'Correct registrant contact' );
    };

    subtest 'Attempt Another Change of Contacts' => sub {
        my $updated_contact = create_contact({
            first_name        => 'Tech First Name',
            last_name         => 'Tech Last Name',
            organization_name => 'Tech Other Organization',
            job_title         => 'Tech Bug Squisher',
            phone_number      => '18005553333',
        });

        lives_ok {
            $api->update_contacts_for_domain_name(
                domain_name        => $domain->name,
                is_transfer_locked => 1,
                technical_contact  => $updated_contact,
            );
        } 'Lives through updating contact';

        my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );
        is_deeply( $retrieved_domain->technical_contact, $updated_contact, 'Correct technical contact' );
    };
};

subtest 'Changing Something Other Then Registrant Then Changing the Registrant' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $updated_technical_contact = create_contact({
        first_name        => 'Tech First Name',
        last_name         => 'Tech Last Name',
        organization_name => 'Tech Other Organization',
        job_title         => 'Tech Bug Squisher',
        phone_number      => '18005551111',
    });

    my $updated_registrant_contact = create_contact({
        first_name        => 'Registrant First Name',
        last_name         => 'Registrant Last Name',
        organization_name => 'Registrant Other Organization',
        job_title         => 'Registrant Bug Squisher',
        phone_number      => '18005552222',
    });

    subtest 'Change Non Registrant Contact' => sub {
        lives_ok {
            $api->update_contacts_for_domain_name(
                domain_name       => $domain->name,
                technical_contact => $updated_technical_contact,
            );
        } 'Lives through updating contact';

        my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );
        ok( !$retrieved_domain->has_irtp_detail, 'Correctly lacks irtp_detail' );
        is_deeply( $retrieved_domain->technical_contact, $updated_technical_contact, 'Correct registrant contact' );
    };

    subtest 'Change Registrant Contact' => sub {
        lives_ok {
            $api->update_contacts_for_domain_name(
                domain_name        => $domain->name,
                is_transfer_locked => 1,
                registrant_contact => $updated_registrant_contact,
            );
        } 'Lives through updating contact';

        my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );

        subtest 'Inspect IRTP Detail' => sub {
            if( isa_ok( $retrieved_domain->irtp_detail, 'WWW::eNom::IRTPDetail' ) ) {
                my $irtp_detail = $retrieved_domain->irtp_detail;
                cmp_ok( $irtp_detail->is_transfer_locked, '==', 1, 'Correct is_transfer_locked' );
            }
        };

        subtest 'Inspect Changed Contact' => sub {
            is_deeply( $retrieved_domain->registrant_contact, $updated_registrant_contact, 'Correctly updated registrant contact' );
        };

        subtest 'Inspect Unchanged Contacts' => sub {
            is_deeply( $retrieved_domain->technical_contact,
                $updated_technical_contact, 'Correct technical_contact' );
            is_deeply( $retrieved_domain->admin_contact,
                $domain->admin_contact, 'Correct admin_contact' );
            is_deeply( $retrieved_domain->billing_contact,
                $domain->billing_contact, 'Correct billing_contact' );
        };
    };
};

subtest 'Update Two Contacts at Once' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $updated_contacts = {
        registrant_contact => create_contact({
            organization_name => 'London Univeristy',
            job_title         => 'Bug Squisher',
            phone_number      => '18005550000',
        }),
        admin_contact      => create_contact({
            phone_number      => '18005550001',
            fax_number        => '18005551212',
        }),
    };

    lives_ok {
        $api->update_contacts_for_domain_name(
            domain_name        => $domain->name,
            is_transfer_locked => 1,
            %{ $updated_contacts },
        );
    } 'Lives through updating contacts';

    my $retrieved_domain = retrieve_domain_with_cron_delay( $domain->name );

    subtest 'Inspect IRTP Detail' => sub {
        if( isa_ok( $retrieved_domain->irtp_detail, 'WWW::eNom::IRTPDetail' ) ) {
            my $irtp_detail = $retrieved_domain->irtp_detail;
            cmp_ok( $irtp_detail->is_transfer_locked, '==', 1, 'Correct is_transfer_locked' );
        }
    };

    subtest 'Inspect Changed Contacts' => sub {
        for my $contact_type (qw( registrant_contact admin_contact )) {
            is_deeply( $retrieved_domain->$contact_type, $updated_contacts->{$contact_type}, "Correct $contact_type" );
        }
    };

    subtest 'Inspect Unchanged Contacts' => sub {
        for my $contact_type (qw( technical_contact billing_contact)) {
            is_deeply( $retrieved_domain->$contact_type, $domain->$contact_type, "Correct $contact_type" );
        }
    };
};

done_testing;
