package Test::WWW::LogicBoxes::Domain;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;
use String::Random qw( random_string );

use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Customer qw( create_customer );
use Test::WWW::LogicBoxes::Contact qw( create_contact );

use WWW::LogicBoxes::Types qw( Bool DomainName DomainNames Int );

use WWW::LogicBoxes::Domain;
use WWW::LogicBoxes::DomainRequest::Registration;

use DateTime;

use Exporter 'import';
our @EXPORT_OK = qw( create_domain );

sub create_domain {
    my ( %args ) = validated_hash(
        \@_,
        name        => { isa => DomainName,  optional => 1 },
        years       => { isa => Int,         optional => 1 },
        customer_id => { isa => Int,         optional => 1 },
        ns          => { isa => DomainNames, optional => 1 },
        is_private  => { isa => Bool,        optional => 1 },
        registrant_contact_id => { isa => Int, optional => 1 },
        admin_contact_id      => { isa => Int, optional => 1 },
        technical_contact_id  => { isa => Int, optional => 1 },
        billing_contact_id    => { isa => Int, optional => 1 },
    );

    $args{name}        //= 'test-' . random_string('nnccnnccnnccnnccnnccnncc') . '.com';
    $args{years}       //= 1;
    $args{customer_id} //= create_customer()->id;
    $args{ns}          //= [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ];
    $args{registrant_contact_id} //= create_contact( customer_id => $args{customer_id} )->id;
    $args{admin_contact_id}      //= create_contact( customer_id => $args{customer_id} )->id;
    $args{technical_contact_id}  //= create_contact( customer_id => $args{customer_id} )->id;
    $args{billing_contact_id}    //= create_contact( customer_id => $args{customer_id} )->id;

    my $api = create_api();

    my $domain;
    subtest 'Create Domain' => sub {
        my $request;
        lives_ok {
            $request = WWW::LogicBoxes::DomainRequest::Registration->new( %args );
        } 'Lives through creating request object';

        lives_ok {
            $domain = $api->register_domain( request => $request );
        } 'Lives through domain registration';

        note( 'Domain ID: ' . $domain->id );
        note( 'Domain Name: ' . $domain->name );
    };

    return $domain;
};

1;
