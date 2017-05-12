#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;
use Test::MockModule;
use MooseX::Params::Validate;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Domain qw( create_domain );
use Test::WWW::LogicBoxes::Customer qw( create_customer );
use Test::WWW::LogicBoxes::Contact qw( create_contact );

use WWW::LogicBoxes::Types qw( DomainTransfer );

use WWW::LogicBoxes::Domain;
use WWW::LogicBoxes::DomainTransfer;
use WWW::LogicBoxes::DomainRequest::Transfer;

use DateTime;

my $logic_boxes        = create_api();
my $customer           = create_customer();
my $registrant_contact = create_contact( customer_id => $customer->id );
my $admin_contact      = create_contact( customer_id => $customer->id );
my $technical_contact  = create_contact( customer_id => $customer->id );
my $billing_contact    = create_contact( customer_id => $customer->id );

# LogicBoxes will accept domain transfers even if it's locked or too new

subtest 'Transfer Unregistered Domain' => sub {
    my $request;
    lives_ok {
        $request = WWW::LogicBoxes::DomainRequest::Transfer->new(
            name                  => 'test-' . random_string('ccnnccnnccnnccnnccnn') . '.com',
            customer_id           => $customer->id,
            ns                    => [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ],
            registrant_contact_id => $registrant_contact->id,
            admin_contact_id      => $admin_contact->id,
            technical_contact_id  => $technical_contact->id,
            billing_contact_id    => $billing_contact->id,
            is_private            => 0,
        );
    } 'Lives through creating request object';

    throws_ok {
        $logic_boxes->transfer_domain( request => $request );
    } qr/It is available for registration as new domain/, 'Throws on transfering unregistered domain';
};

subtest 'Transfer Transferable Domain - Without EPP Key - Without Privacy' => sub {
    my $request;
    lives_ok {
        $request = WWW::LogicBoxes::DomainRequest::Transfer->new(
            name                  => 'test-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.com',
            customer_id           => $customer->id,
            ns                    => [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ],
            registrant_contact_id => $registrant_contact->id,
            admin_contact_id      => $admin_contact->id,
            technical_contact_id  => $technical_contact->id,
            billing_contact_id    => $billing_contact->id,
            is_private            => 0,
        );
    } 'Lives through creating request object';

    my $mocked_logic_boxes = _mock_valid_domain_transfer( $request );

    my $domain;
    lives_ok {
        $domain = $logic_boxes->transfer_domain( request => $request );
    } 'Lives through domain transfer';

    subtest 'Inspect Created Domain Transfer' => sub {
        if( isa_ok( $domain, 'WWW::LogicBoxes::DomainTransfer' ) ) {
            note( 'Domain ID: ' . $domain->id );

            cmp_ok( $domain->name, 'eq', $request->name, 'Correct name' );
            cmp_ok( $domain->customer_id, '==', $customer->id, 'Correct customer_id' );
            cmp_bag( $domain->ns, $request->ns, 'Correct name servers' );

            cmp_ok( $domain->registrant_contact_id, '==', $request->registrant_contact_id, 'Correct registrant_contact_id' );
            cmp_ok( $domain->admin_contact_id,      '==', $request->admin_contact_id, 'Correct admin_contact_id' );
            cmp_ok( $domain->technical_contact_id,  '==', $request->technical_contact_id, 'Correct technical_contact_id' );
            cmp_ok( $domain->billing_contact_id,    '==', $request->billing_contact_id, 'Correct billing_contact_id' );

            cmp_ok( $domain->transfer_status, 'eq', 'Transfer waiting for Admin Contact Approval', 'Correct transfer_status' );
            ok( !$domain->has_epp_key, 'Domain lacks EPP Key' );
        }
    };
};

subtest 'Transfer Transferable Domain - With EPP Key - With Privacy' => sub {
    my $request;
    lives_ok {
        $request = WWW::LogicBoxes::DomainRequest::Transfer->new(
            name                  => 'checkingmyemail.com',
            customer_id           => $customer->id,
            ns                    => [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ],
            registrant_contact_id => $registrant_contact->id,
            admin_contact_id      => $admin_contact->id,
            technical_contact_id  => $technical_contact->id,
            billing_contact_id    => $billing_contact->id,
            is_private            => 1,
            epp_key               => 'Test EPP Key',
        );
    } 'Lives through creating request object';

    my $mocked_logic_boxes = _mock_valid_domain_transfer( $request );

    my $domain;
    lives_ok {
        $domain = $logic_boxes->transfer_domain( request => $request );
    } 'Lives through domain transfer';

    subtest 'Inspect Created Domain Transfer' => sub {
        if( isa_ok( $domain, 'WWW::LogicBoxes::DomainTransfer' ) ) {
            note( 'Domain ID: ' . $domain->id );

            cmp_ok( $domain->name, 'eq', $request->name, 'Correct name' );
            cmp_ok( $domain->customer_id, '==', $customer->id, 'Correct customer_id' );
            cmp_bag( $domain->ns, $request->ns, 'Correct name servers' );

            cmp_ok( $domain->registrant_contact_id, '==', $request->registrant_contact_id, 'Correct registrant_contact_id' );
            cmp_ok( $domain->admin_contact_id,      '==', $request->admin_contact_id, 'Correct admin_contact_id' );
            cmp_ok( $domain->technical_contact_id,  '==', $request->technical_contact_id, 'Correct technical_contact_id' );
            cmp_ok( $domain->billing_contact_id,    '==', $request->billing_contact_id, 'Correct billing_contact_id' );

            cmp_ok( $domain->transfer_status, 'eq', 'Transfer waiting for Admin Contact Approval', 'Correct transfer_status' );
            cmp_ok( $domain->epp_key, 'eq', $request->epp_key, 'Correct EPP Key' );
        }
    };
};

done_testing;

sub _mock_valid_domain_transfer {
    my ( $request ) = pos_validated_list( \@_, { isa => DomainTransfer } );

    my $mocked_logic_boxes = Test::MockModule->new( 'WWW::LogicBoxes' );
    $mocked_logic_boxes->mock( 'submit', sub {
        my $self = shift;
        my $args = shift;

        if( $args->{method} eq 'domains__transfer' ) {
            return {
                'status'           => 'Success',
                'entityid'         => '64937459',
                'eaqid'            => '330470368',
                'actiontype'       => 'AddTransferDomain',
                'actiontypedesc'   => 'Transfer of ' . $request->name . ' from old Registrar along with 1 year Renewal',
                'actionstatus'     => 'RFASent',
                'actionstatusdesc' => 'Transfer waiting for Admin Contact Approval',
                'description'      => $request->name,
            }
        }
        elsif( $args->{method} eq 'domains__details' ) {
            # isprivacyprotected
            # creationtime
            # endtime
            return {
                'orderid'               => '64937459',
                'cns'                   => {},
                'domainname'            => $request->name,
                'customerid'            => $request->customer_id,
                'currentstatus'         => 'InActive',
                'raaVerificationStatus' => 'NA',
                'orderstatus'           => [],
                'domsecret'             => $request->has_epp_key ? $request->epp_key : '',

                'ns1' => $request->ns->[0],
                'ns2' => $request->ns->[1],

                'registrantcontactid' => $request->registrant_contact_id,
                'admincontactid'      => $request->admin_contact_id,
                'techcontactid'       => $request->technical_contact_id,
                'billingcontactid'    => $request->billing_contact_id,

                'actioncompleted'  => '0',
                'actiontype'       => 'AddTransferDomain',
                'actiontypedesc'   => 'Transfer of ' . $request->name . ' from old Registrar along with 1 year Renewal',
                'actionstatus'     => 'RFASent',
                'actionstatusdesc' => 'Transfer waiting for Admin Contact Approval',
            };
        }
    });

    return $mocked_logic_boxes;
}

sub _mock_domain_is_locked {
    my ( $request ) = pos_validated_list( \@_, { isa => DomainTransfer } );

    my $mocked_logic_boxes = Test::MockModule->new( 'WWW::LogicBoxes' );
    $mocked_logic_boxes->mock( 'submit', sub {
        my $self = shift;
        my $args = shift;

        if( $args->{method} eq 'domains__transfer' ) {
            return {
                'description'      => $request->name,
                'status'           => 'AdminApproved',
                'actionstatusdesc' => 'Order Locked In Processing.',
                'actiontypedesc'   => 'Transfer of ' . $request->name . ' from old Registrar along with 1 year Renewal',
                'actionstatus'     => 'AdminApproved',
                'eaqid'            => '326759191',
                'error'            => 'NoError',
                'actiontype'       => 'AddTransferDomain',
                'entityid'         => '64473117'
            };
        }
        elsif( $args->{method} eq 'domains__details' ) {
            return {
                'productcategory'  => 'domorder',
                'productkey'       => 'domcno',
                'classkey'         => 'domcno',
                'entityid'         => '64473202',
                'entitytypeid'     => '3',
                'orderid'          => '64473202',
                'customerid'       => $request->customer_id,
                'currentstatus'    => 'InActive',
                'actionstatus'     => 'AdminApproved',
                'actionstatusdesc' => 'Order Locked In Processing.',
                'actiontype'       => 'AddTransferDomain',
                'actiontypedesc'   => 'Transfer of ' . $request->name . ' from old Registrar along with 1 year Renewal',
                'actioncompleted'  => '0',
                'description'      => $request->name,
                'domainname'       => $request->name,
                'domsecret'        => $request->has_epp_key ? $request->epp_key : '',
                'raaVerificationStatus' => 'NA',

                'registrantcontactid' => $request->registrant_contact_id,
                'admincontactid'      => $request->admin_contact_id,
                'techcontactid'       => $request->technical_contact_id,
                'billingcontactid'    => $request->billing_contact_id,

                'noOfNameServers' => '2',
                'ns1' => $request->ns->[0],
                'ns2' => $request->ns->[1],

                'privacyprotectedallowed' => 'true',

                'orderstatus' => [],

                'isImmediateReseller'    => 'true',
                'orderSuspendedByParent' => 'false',
                'allowdeletion'          => 'true',
                'parentkey'              => '999999999_999999998_465229',
                'bulkwhoisoptout'        => 't',
                'domainstatus'           => [],
                'jumpConditions'         => [{
                    'descLangKey'    => 'null',
                    'captionLangKey' => 'btn.cancel-order',
                    'retryinterval'  => '0',
                    'authRelation'   => 'RELATION_DIRECT_OR_DIRECT_PARENT',
                    'jumpCondition'  => 'Cancel'
                }],
                'classname'        => 'com.logicboxes.foundation.sfnb.order.domorder.DomCno',
                'multilingualflag' => 'f',
                'recurring'        => 'false',
                'moneybackperiod'  => '4',
                'eaqid'            => '326760057',
                'isOrderSuspendedUponExpiry' => 'false'
            };
        }
    });

    return $mocked_logic_boxes;
}
