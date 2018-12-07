package Test::WWW::eNom::Domain;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;
use MooseX::Params::Validate;
use String::Random qw( random_string );

use WWW::eNom::Types qw( Bool Contact DomainName DomainNames PositiveInt Str );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Service qw( mock_purchase_services );
use Test::WWW::eNom::Contact qw( create_contact mock_get_contacts $DEFAULT_CONTACT $RAW_PROTECTED_CONTACT );

use WWW::eNom::Domain;
use WWW::eNom::DomainRequest::Registration;

use List::Util qw( first );
use DateTime;
use Mozilla::PublicSuffix qw( public_suffix );

use Readonly;
Readonly our $UNREGISTERED_DOMAIN => WWW::eNom::Domain->new(
    id                  => 42,
    name                => 'NOT-REGISTERED-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.com',
    status              => 'Paid',
    verification_status => 'Pending Suspension',
    is_auto_renew       => 0,
    is_locked           => 1,
    is_private          => 0,
    created_date        => DateTime->now,
    expiration_date     => DateTime->now->add( years => 1 ),
    ns                  => [ 'ns1.enom.com', 'ns2.enom.com' ],
    registrant_contact  => $DEFAULT_CONTACT,
    admin_contact       => $DEFAULT_CONTACT,
    technical_contact   => $DEFAULT_CONTACT,
    billing_contact     => $DEFAULT_CONTACT,
);

Readonly our $NOT_MY_DOMAIN => WWW::eNom::Domain->new(
    id                  => 42,
    name                => 'enom.com',
    status              => 'Paid',
    verification_status => 'Pending Suspension',
    is_auto_renew       => 0,
    is_locked           => 1,
    is_private          => 0,
    created_date        => DateTime->now,
    expiration_date     => DateTime->now->add( years => 1 ),
    ns                  => [ 'ns1.enom.com', 'ns2.enom.com' ],
    registrant_contact  => $DEFAULT_CONTACT,
    admin_contact       => $DEFAULT_CONTACT,
    technical_contact   => $DEFAULT_CONTACT,
    billing_contact     => $DEFAULT_CONTACT,
);

use Exporter 'import';
our @EXPORT_OK = qw(
    create_domain
    retrieve_domain_with_cron_delay
    mock_domain_registration
    mock_domain_retrieval
    mock_update_nameserver

    mock_purchase
    mock_get_domain_info
    mock_get_dns
    mock_get_reg_lock
    mock_get_whois_contact
    mock_get_renew
    mock_set_renew
    $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN
);

sub create_domain {
    my ( %args ) = validated_hash(
        \@_,
        name                => { isa => DomainName,         optional => 1 },
        ns                  => { isa => DomainNames,        optional => 1 },
        is_locked           => { isa => Bool,               optional => 1 },
        is_private          => { isa => Bool,               optional => 1 },
        is_auto_renew       => { isa => Bool,               optional => 1 },
        years               => { isa => PositiveInt,        optional => 1 },
        registrant_contact  => { isa => Contact,            optional => 1 },
        admin_contact       => { isa => Contact,            optional => 1 },
        technical_contact   => { isa => Contact,            optional => 1 },
        billing_contact     => { isa => Contact,            optional => 1 },
    );

    $args{name}               //= 'test-' . random_string('nnccnnccnnccnnccnnccnncc') . '.com';
    $args{ns}                 //= [ 'ns1.enom.com', 'ns2.enom.com' ];
    $args{is_locked}          //= 1;
    $args{years}              //= 1;
    $args{registrant_contact} //= create_contact( first_name => 'Before', last_name => 'Change' );
    $args{admin_contact}      //= create_contact();
    $args{technical_contact}  //= create_contact();
    $args{billing_contact}    //= create_contact();

    my $api = create_api();

    my $domain;
    subtest 'Create Domain' => sub {
        my $request;
        lives_ok {
            $request = WWW::eNom::DomainRequest::Registration->new( %args );
        } 'Lives through creating request object';

        my $mocked_api = mock_domain_registration( request => $request );

        lives_ok {
            $domain = $api->register_domain( request => $request );
        } 'Lives through domain registration';

        $mocked_api->unmock_all();

        note( 'Domain ID: ' . $domain->id );
        note( 'Domain Name: ' . $domain->name );
    };

    return $domain;

}

sub retrieve_domain_with_cron_delay {
    my ( $api, $domain_name ) = pos_validated_list( \@_, { isa => 'WWW::eNom' }, { isa => DomainName } );

    if( $ENV{USE_MOCK} ) {
        return $api->get_domain_by_name( $domain_name );
    }

    note('Waiting for eNom to Process Contact Change...');
    sleep 10;

    for my $seconds_waited ( 1 .. 60 ) {
        if( DateTime->now->second > 5 && DateTime->now->second < 10 ) {
            return $api->get_domain_by_name( $domain_name );
        }
        else {
            if( $seconds_waited % 5 == 0 ) {
                note("Waited $seconds_waited seconds - " . DateTime->now->datetime );
            }

            sleep 1;
        }
    }
}

sub mock_domain_registration {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api => { isa => 'Test::MockModule', optional => 1 },
        request    => { isa => 'WWW::eNom::DomainRequest::Registration' }
    );

    my $mocked_api = $args{mocked_api} // Test::MockModule->new('WWW::eNom');

    mock_purchase(
        mocked_api => $mocked_api,
        purchase   => $args{request}
    );

    mock_purchase_services( mocked_api => $mocked_api );

    mock_domain_retrieval(
        mocked_api         => $mocked_api,
        name               => $args{request}->name,
        is_private         => $args{request}->is_private,
        is_locked          => $args{request}->is_locked,
        is_auto_renew      => $args{request}->is_auto_renew,
        nameservers        => $args{request}->ns,
        registrant_contact => $args{request}->registrant_contact,
        admin_contact      => $args{request}->admin_contact,
        technical_contact  => $args{request}->technical_contact,
        billing_contact    => $args{request}->billing_contact,
    );

    return $mocked_api;
}

sub mock_domain_retrieval {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api              => { isa => 'Test::MockModule',  optional => 1 },
        name                    => { isa => 'Str' },
        expiration_date         => { isa => 'DateTime',           optional => 1 },
        is_private              => { isa => 'Bool',               default  => 0 },
        is_locked               => { isa => 'Bool',               default  => 1 },
        is_auto_renew           => { isa => 'Bool',               default  => 0 },
        nameservers             => { isa => 'ArrayRef',           optional => 1 },
        is_pending_verification => { isa => 'Bool',               default  => 0 },
        registrant_contact      => { isa => 'WWW::eNom::Contact', optional => 1 },
        admin_contact           => { isa => 'WWW::eNom::Contact', optional => 1 },
        technical_contact       => { isa => 'WWW::eNom::Contact', optional => 1 },
        billing_contact         => { isa => 'WWW::eNom::Contact', optional => 1 },
    );

    my $mocked_api = $args{mocked_api} // Test::MockModule->new('WWW::eNom');

    mock_get_domain_info(
        mocked_api      => $mocked_api,
        domain_name     => $args{name},
        expiration_date => defined $args{expiration_date}
            ? ( $args{expiration_date} )
            : ( DateTime->now( time_zone => 'UTC' )->add( years => 1 ) ),
        is_private      => $args{is_private},
        is_pending_verification => $args{is_pending_verification},
    );

    mock_get_dns(
        mocked_api  => $mocked_api,
        defined $args{nameservers} ? ( nameservers => $args{nameservers} ) : ( ),
    );

    mock_get_reg_lock(
        mocked_api => $mocked_api,
        is_locked  => $args{is_locked},
    );

    mock_get_renew(
        mocked_api    => $mocked_api,
        is_auto_renew => $args{is_auto_renew},
    );

    mock_get_contacts(
        mocked_api              => $mocked_api,
        is_pending_verification => $args{is_pending_verification},
        $args{registrant_contact} ? ( registrant_contact      => $args{registrant_contact} ) : ( ),
        $args{admin_contact}      ? ( admin_contact           => $args{admin_contact}      ) : ( ),
        $args{technical_contact}  ? ( technical_contact       => $args{technical_contact}  ) : ( ),
        $args{billing_contact}    ? ( billing_contact         => $args{billing_contact}    ) : ( ),
    );

    mock_get_whois_contact(
        mocked_api   => $mocked_api,
        created_date => DateTime->now,
    );

    return $mocked_api;
}

sub mock_update_nameserver {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api          => { isa => 'Test::MockModule', optional => 1 },
        domain              => { isa => 'WWW::eNom::Domain' },
        nameservers         => { isa => 'ArrayRef' },
    );

    my $mocked_api = $args{mocked_api} // Test::MockModule->new('WWW::eNom');

    mock_response(
        mocked_api => $mocked_api,
        method     => 'ModifyNS',
        response   => {
            ErrCount => 0,
        }
    );

    mock_response(
        mocked_api => $mocked_api,
        method     => 'RegisterNameServer',
        response   => {
            ErrCount => 0
        }
    );

    $mocked_api->mock( 'CheckNSStatus', sub {
        my $self   = shift;
        my $params = shift;

        note('Mocked WWW::eNom->CheckNSStatus');

        my $private_nameserver = first {
               $_->isa('WWW::eNom::PrivateNameServer')
            && $_->name eq $params->{CheckNSName}
        } @{ $args{nameservers} };

        if( $private_nameserver ) {
            return {
                ErrCount => 0,
                CheckNsStatus => {
                    name      => $private_nameserver->name,
                    ipaddress => $private_nameserver->ip,
                }
            };
        }
        else {
            return {
                ErrCount => 1,
                errors   => [ 'Domain cannot be found.' ],
            };
        }
    });

    mock_response(
        mocked_api => $mocked_api,
        method     => 'DeleteNameServer',
        response   => {
            ErrCount => 0
        }
    );

    mock_domain_retrieval(
        mocked_api    => $mocked_api,
        name          => $args{domain}->name,
        is_private    => $args{domain}->is_private,
        is_locked     => $args{domain}->is_locked,,
        is_auto_renew => $args{domain}->is_auto_renew,
        nameservers   => [ map {
            $_->isa('WWW::eNom::PrivateNameServer') ? $_->name : $_
        } @{ $args{nameservers} } ],
        registrant_contact => $args{domain}->registrant_contact,
        admin_contact      => $args{domain}->admin_contact,
        technical_contact  => $args{domain}->technical_contact,
        billing_contact    => $args{domain}->billing_contact,
    );

    return $mocked_api;
}

sub mock_purchase {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api => { isa => 'Test::MockModule', optional => 1 },
        purchase   => { isa => 'WWW::eNom::DomainRequest::Registration' },
    );

    return mock_response(
        defined $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'Purchase',
        response => {
            OrderID      => '42',
            IsLockable   => 'True',
            ErrCount     => '0',
            errors       => undef,
            RRPCode      => '200',
            RRPText      => 'Command completed successfully - 42',
            OrderStatus  => 'Success',
            TotalCharged => '8.95',
            DomainInfo   => {
                RegistryExpDate    => DateTime->now->add( years => $args{purchase}->years )->strftime('%F %T') . '.000',
                RegistryCreateDate => DateTime->now->strftime('%F %T') . '.000',
            },
            RegistrantPartyID => {},
            Contacts          => {
                Registrant => $RAW_PROTECTED_CONTACT,
                Tech       => $RAW_PROTECTED_CONTACT,
                Admin      => $RAW_PROTECTED_CONTACT,
                Billing    => $RAW_PROTECTED_CONTACT,
            },
        }
    );
}

sub mock_get_domain_info {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api      => { isa => 'Test::MockModule', optional => 1 },
        domain_name     => { isa => 'Str' },
        expiration_date => { isa => 'DateTime' },
        is_private      => { isa => 'Bool' },
        is_pending_verification => { isa => 'Bool', default => 0 },
    );

    my $sld = public_suffix( $args{domain_name} );
    my $tld = substr( $args{domain_name}, 0, length( $args{domain_name} ) - ( length( $sld ) + 1 ) );

    return mock_response(
        defined $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'GetDomainInfo',
        response => {
            'ErrCount'      => '0',
            'errors'        => undef,
            'GetDomainInfo' => {
                'domainname' => {
                    'domainnameid' => '42',
                    'sld'          => $sld,
                    'tld'          => $tld,
                    'content'      => $args{domain_name},
                },
                'status' => {
                    'registrationstatus' => 'Registered',
                    'expiration'         => $args{expiration_date}->strftime( '%m/%d/%Y %r' ),
                },
                'services' => {
                    'entry' => {
                        'raasettings'  => {},
                        'irtpsettings' => {
                            'irtpsetting' => {
                                'optout'              => 'False',
                                'transferlock'        => ( $args{is_pending_verification} ? 'True' : 'False' ),
                                'icanncompliant'      => 'True',
                                'transferlockexpdate' => {},
                            },
                        },
                        'wpps' => {
                            'service' => {
                                'changable' => '1',
                                'content'   => $args{is_private} ? '1120' : '1123',
                            }
                        },
                    }
                },
            },
        },
    );
}

sub mock_get_dns {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api  => { isa => 'Test::MockModule', optional => 1 },
        nameservers => { isa => 'ArrayRef', optional => 1 },
    );

    my $nameservers = $args{nameservers} // [
        'ns1.enom.com',
        'ns2.enom.com'
    ];

    return mock_response(
        defined $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'GetDNS',
        response => {
            'ErrCount' => '0',
            'errors'   => undef,
            'dns'      => $nameservers,
        },
    );
}

sub mock_get_reg_lock {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api => { isa => 'Test::MockModule', optional => 1 },
        is_locked  => { isa => 'Bool', default => 1 },
    );

    return mock_response(
        defined $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'GetRegLock',
        response => {
            'ErrCount' => '0',
            'errors'   => undef,
            'reg-lock' => $args{is_locked} ? '1' : '0',
        },
    );
}

sub mock_get_whois_contact {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api   => { isa => 'Test::MockModule', optional => 1 },
        created_date => { isa => 'DateTime', optional => 1 },
    );

    my $created_date = $args{created_date} // DateTime->now;

    return mock_response(
        defined $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'GetWhoisContact',
        response => {
            'ErrCount'         => '0',
            'errors'           => undef,
            'GetWhoisContacts' => {
                'rrp-info' => {
                        'created-date' =>  $created_date->datetime . '.00Z',
                },
            }
        }
    );
}

sub mock_get_renew {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api    => { isa => 'Test::MockModule', optional => 1 },
        is_auto_renew => { isa => 'Bool', default => 1 },
    );

    return mock_response(
        defined $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'GetRenew',
        response => {
            'ErrCount' => '0',
            'errors'   => undef,
            'auto-renew' => $args{is_auto_renew} ? '1' : '0',
        },
    );
}

sub mock_set_renew {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api => { isa => 'Test::MockModule', optional => 1 },
    );

    return mock_response(
        defined $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'SetRenew',
        response => {
            'ErrCount' => '0',
            'errors'   => undef,
        },
    );
}

1;
