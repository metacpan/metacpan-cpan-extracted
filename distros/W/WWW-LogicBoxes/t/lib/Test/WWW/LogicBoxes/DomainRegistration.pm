package Test::WWW::LogicBoxes::DomainRegistration;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;
use String::Random qw( random_string );

use Test::WWW::LogicBoxes qw( create_api );

use WWW::LogicBoxes::Types qw( DomainRegistration );

use WWW::LogicBoxes::DomainRequest::Registration;

use Exporter 'import';
our @EXPORT_OK = qw( test_domain_registration );

sub test_domain_registration {
    my ( $request ) = pos_validated_list( \@_, { isa => DomainRegistration } );

    my $domain;
    lives_ok {
        $domain = create_api()->register_domain( request => $request );
    } 'Lives through domain registration';

    subtest 'Inspect Created Domain' => sub {
        if( isa_ok( $domain, 'WWW::LogicBoxes::Domain' ) ) {
            note( 'Domain ID   : ' . $domain->id );
            note( 'Domain Name : ' . $domain->name );

            cmp_ok( $domain->name,                'eq', $request->name, 'Correct name' );
            cmp_ok( $domain->customer_id,         '==', $request->customer_id, 'Correct customer_id' );
            cmp_ok( $domain->status,              'eq', 'Active', 'Correct status' );

            ok( ( grep { $_ eq $domain->verification_status } qw( Pending Verified ) ), 'Correct verification_status' );

            ok( $domain->is_locked, 'Correct is_locked' );
            cmp_ok( !!$domain->is_private, '==', !!$request->is_private, 'Correct is_private' );

            my $now = DateTime->now( time_zone => 'UTC' );
            cmp_ok( $domain->created_date->ymd,    'eq', $now->ymd, 'Correct created_date' );
            cmp_ok( $domain->expiration_date->ymd, 'eq', $now->clone->add( years => 1 )->ymd, 'Correct expiration_date' );

            is_deeply( $domain->ns, $request->ns, 'Correct ns' );

            cmp_ok( $domain->registrant_contact_id, '==', $request->registrant_contact_id, 'Correct registrant_contact_id' );
            cmp_ok( $domain->admin_contact_id,      '==', $request->admin_contact_id,      'Correct admin_contact_id' );
            cmp_ok( $domain->technical_contact_id,  '==', $request->technical_contact_id,  'Correct technical_contact_id' );

            if( $request->has_billing_contact_id ) {
                cmp_ok( $domain->billing_contact_id, '==', $request->billing_contact_id, 'Correct billing_contact_id' );
            }
            else {
                ok( !$domain->has_billing_contact_id, 'Correct lacks billing_contact_id' );
            }
        }
    };

    return $domain;
}

1;
