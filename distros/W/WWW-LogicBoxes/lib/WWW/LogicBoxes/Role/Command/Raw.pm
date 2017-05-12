package WWW::LogicBoxes::Role::Command::Raw;

use strict;
use warnings;

#use Smart::Comments;
#use Data::Dumper;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::LogicBoxes::Types qw( HashRef Str );

use HTTP::Tiny;
use URI::Escape qw( uri_escape );
use XML::LibXML::Simple qw(XMLin);
use Carp;

requires 'username', 'password', 'api_key', '_base_uri', 'response_type';

our $VERSION = '1.9.0'; # VERSION
# ABSTRACT: Construct Methods For Making Raw LogicBoxes Requests

use Readonly;
Readonly our $API_METHODS => {
    domains => {
        GET => [
            qw(available suggest-names v5/suggest-names validate-transfer search customer-default-ns orderid details details-by-name locks tel/cth-details)
        ],
        POST => [
            qw(register transfer eu/transfer eu/trade uk/transfer renew modify-ns add-cns modify-cns-name modify-cns-ip delete-cns-ip modify-contact modify-privacy-protection modify-auth-code enable-theft-protection disable-theft-protection tel/modify-whois-pref resend-rfa uk/release cancel-transfer delete restore de/recheck-ns dotxxx/assoication-details)
        ],
    },
    contacts => {
        GET  => [qw(details search sponsors dotca/registrantagreement)],
        POST => [qw(add modify default set-details delete coop/add-sponsor)],
    },
    customers => {
        GET =>
          [qw(details details-by-id generate-token authenticate-token search)],
        POST => [qw(signup modify change-password delete)],
    },
    resellers => {
        GET => [
            qw(details generate-token authenticate-token promo-details temp-password search)
        ],
        POST => [qw(signup modify-details)],
    },
    products => {
        GET => [
            qw(availability details plan-details customer-price reseller-price reseller-cost-price)
        ],
        POST => [qw(category-keys-mapping move)],
    },
    webservices => {
        GET => [
            qw(details active-plan-categories mock/products/reseller-price orderid search modify-pricing)
        ],
        POST => [qw(add renew modify enable-ssl enable-maintenance delete)],
    },
    multidomainhosting => {
        GET  => [qw(details orderid search modify-pricing)],
        POST => [qw(add renew modify enable-ssl delete)],
    },
    'multidomainhosting/windows' => {
        GET  => [qw(details orderid search modify-pricing)],
        POST => [qw(add renew modify enable-ssl delete)],
    },
    resellerhosting => {
        GET  => [qw(details orderid search modify-pricing)],
        POST => [
            qw(add renew modify add-dedicated-ip delete-dedicated-ip delete generate-license-key)
        ],
    },
    mail => {
        GET  => [qw(user mailinglists)],
        POST => [qw(activate)],
    },
    'mail/user' => {
        GET  => [qw(authenticate)],
        POST => [
            qw(add add-forward-only-account modify suspend unsuspend change-password reset-password update-autoresponder delete add-admin-forwards delete-admin-forwards add-user-forwards delete-user-forwards)
        ],
    },
    'mail/users' => {
        GET  => [qw(search)],
        POST => [qw(suspend unsuspend delete)],
    },
    'mail/domain' => {
        GET  => [qw(is-owernship-verified catchall dns-records)],
        POST => [
            qw(add-alias delete-alias update-notification-email active-catchall deactivate-catchall)
        ],
    },
    'mail/mailinglist' => {
        GET  => [qw(subscribers)],
        POST => [
            qw(add update add-subscribers delete-subscribers delete add-moderators delete-moderators)
        ],
    },
    dns => {
        GET  => [],
        POST => [qw(activate)],
    },
    'dns/manage' => {
        GET  => [qw(search-records delete-record)],
        POST => [
            qw(add-ipv4-record add-ipv6-record add-cname-record add-mx-record add-ns-record add-txt-record add-srv-record update-ipv4-record update-ipv6-record update-cname-record update-mx-record update-ns-record update-txt-record update-srv-record update-soa-record delete-ipv4-record delete-ipv6-record delete-cname-record delete-mx-record delete-ns-record delete-txt-record delete-srv-record)
        ],
    },
    domainforward => {
        GET  => [qw(details dns-records)],
        POST => [qw(activate manage)],
    },
    digitalcertificate => {
        GET => [qw(check-status details search orderid)],
        POST =>
          [qw(add cancel delete enroll-for-thawtecertificate reissue renew)],
    },
    billing => {
        GET => [
            qw(customer-transactions reseller-transactions customer-greedy-transactions reseller-greedy-transactions customer-balance customer-transactions/search reseller-transactions/search customer-archived-transactions/search customer-balanced-transactions reseller-balance)
        ],
        POST => [
            qw(customer-pay execute-order-without-payment add-customer-fund add-reseller-fund add-customer-debit-note add-reseller-debit-note add-customer-misc-invoice add-reseller-misc-invoice)
        ],
    },
    orders => {
        GET  => [qw()],
        POST => [qw(suspend unsuspend)],
    },
    actions => {
        GET  => [qw(search-current search-archived)],
        POST => [qw()],
    },
    commons => {
        GET  => [qw(legal-agreements)],
        POST => [qw()],
    },
    pg => {
        GET => [
            qw(allowedlist-for-customer list-for-reseller customer-transactions)
        ],
        POST => [qw()],
    },
};

has api_methods => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { $API_METHODS },
    init_arg => undef,
);

sub BUILD {
    my $self = shift;

    $self->install_methods();

    return;
}

sub install_methods {
    my $self = shift;

    my $ua = HTTP::Tiny->new;
    for my $api_class ( keys %{ $self->api_methods } ) {
        for my $http_method ( keys %{ $self->api_methods->{ $api_class } } ) {
            for my $api_method (@{ $self->api_methods->{ $api_class }{ $http_method } }) {
                my $method_name = $api_class . '__' . $api_method;

                $method_name =~ s|-|_|g;
                $method_name =~ s|/|__|g;

                $self->meta->add_method(
                    $method_name => sub {
                        my $self = shift;
                        my $args = shift;

                        if( !grep { $_ eq $http_method } qw( GET POST ) ) {
                            croak 'Unable to determine if this is a GET or POST request';
                        }

                        my $uri = $self->_make_query_string(
                            api_class  => $api_class,
                            api_method => $api_method,
                            $args ? ( params => $args ) : ( ),
                        );

                        ### Method Name: ( $method_name )
                        ### HTTP Method: ( $http_method )
                        ### URI: ( $uri )

                        my $response = $ua->request( $http_method, $uri );

                        ### Response: ( Dumper( $response ) )

                        if ( $self->response_type eq "xml_simple" ) {
                            return XMLin( $response->{content} );
                        }
                        else {
                            return $response->{content};
                        }
                    }
                );
            }
        }
    }

    return;
}

sub _make_query_string {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        api_class  => { isa => Str },
        api_method => { isa => Str },
        params     => { isa => HashRef, optional => 1 },
    );

    my $api_class = $args{api_class};
    $api_class =~ s/_/-/g;
    $api_class =~ s/__/\//g;

    my $api_method = $args{api_method};
    $api_method =~ s/_/-/g;
    $api_method =~ s/__/\//g;

    my $response_type = ( $self->response_type eq 'xml_simple' ) ? 'xml' : $self->response_type;

    my $query_uri = sprintf('%s/api/%s/%s.%s?auth-userid=%s',
        $self->_base_uri, $api_class, $api_method, $response_type, uri_escape( $self->username ) );

    if( $self->has_password ) {
      $query_uri .= "&auth-password=" . uri_escape( $self->password )
    }
    elsif($self->has_api_key) {
      $query_uri .= "&api-key=" . uri_escape( $self->apikey )
    }
    else {
        croak 'Unable to construct query string without a password or api_key';
    }

    if( $args{params} ) {
        $query_uri .= $self->_construct_get_args( $args{params} );
    }

    return $query_uri;
}

sub _construct_get_args {
    my $self = shift;
    my ( $params ) = pos_validated_list( \@_, { isa => HashRef } );

    my $get_args;
    for my $param_name ( keys %{ $params } ) {
        if( ref $params->{ $param_name } eq 'ARRAY' ) {
            for my $param_value (@{ $params->{ $param_name } }) {
                $get_args .= sprintf('&%s=%s', uri_escape( $param_name ), uri_escape( $param_value ) );
            }
        }
        else {
            $get_args .= sprintf('&%s=%s', uri_escape( $param_name ), uri_escape( $params->{ $param_name } ) );
        }
    }

    return $get_args;
}

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Role::Command::Raw - Low Level Access to LogicBoxes API

=head1 SYNOPSIS

    use WWW::LogicBoxes;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $response = $logic_boxes->domains__suggest_names({
        'keyword'       => 'car',
        'tlds'          => ['com', 'net', 'org'],
        'no-of-results' => 10,
        'hypehn-allowed'=> 'false',
        'add-related'   => 'true',
    });

=head1 REQUIRES

=over 4

=item username

=item password

=item api_key

=item _base_uri

=item response_Type

=back

=head1 DESCRIPTION

This role composes a series of methods into the consuming class (L<WWW::LogicBoxes>) that directly expose methods of the L<LogicBoxes|http://www.logicboxes.com> API.  It is the lowest level of access to the LogicBoxes API and is intended only for the most advanced usages that are not covered by other commands.

B<NOTE> You almost never want to make this low level of a call.  You really should be looking at the L<commands|WWW::LogicBoxes/COMMANDS> to find the specific method to accomplish your goals.

=head1 METHODS

Methods are constructed by abstracting out the need to specify the HTTP method (POST or GET) and automagically building the request URI according to the documentation provided by L<LogicBoxes|http://www.logicboxes.com> (see the Logic Boxes API user guide at L<http://manage.logicboxes.com/kb/answer/744> for additional information).

=head2 Method Naming

To fully understand the method names it's best to take a specific example (in this case the suggestion of domain names).

=head3 Suggest Domains (and many others)

    my $response = $logic_boxes->domains__suggest_names({
        'keyword'       => 'car',
        'tlds'          => ['com', 'net', 'org'],
        'no-of-results' => 10,
        'hypehn-allowed'=> 'false',
        'add-related'   => 'true',
    });

L<LogicBoxes|http://www.logicboxes.com>' API states that this method is part of their HTTP API, specifically the Domain Category and more specifically the Suggest Names method.  The sample URI for this request would then be:

https://test.httpapi.com/api/domains/suggest-names.json?auth-userid=0&auth-password=password&keyword=domain&tlds=com&tlds=net&no-of-results=0&hyphen-allowed=true&add-related=true

The method name is built using the URI that the request is expected at in a logical way.  Since this method is a member of the Domains Category and is specifically Suggest Names we end up:

    $logic_boxes->domains__suggest_names

Where everything before the first "__" is the category and everything following it is the specific method (with - replaced with _ and / replaced with __).

=head2 Arguments Passed to Methods

The specific arguments each method requires is not enforced by this module, rather it is left to the developer to reference the L<LogicBoxes API|http://manage.logicboxes.com/kb/answer/744> and to pass the correct arguments to each method as a hash.  Again, this is a module of last resort, you should really be using the exposed Commands if at all posible.

There are two I<odd> cases that you should be aware of with respect to the way arguments must be passed.

=head3 Repeated Elements

For methods such as domains__check that accept the same I<key> multiple times:

https://test.httpapi.com/api/domains/available.json?auth-userid=0&auth-password=password&domain-name=domain1&domain-name=domain2&tlds=com&tlds=net

This module accepts a hash where the key is the name of the argument (such as domain-name) and the value is an array of values you wish to pass:

    $logic_boxes->domains__available({
        'domain-name' => ["google", "cnn"],
        'tlds'        => ["com","net"]
    });

This is interpreted for you automagically into the repeating elements when the API's URI is built.

=head3 Array of Numbered Elements

For methods such as contacts__set_details that accept the same key multiple times except an incrementing digit is appended:

https://test.httpapi.com/api/contacts/set-details.json?auth-userid=0&auth-password=password&contact-id=0&attr-name1=sponsor1&attr-value1=0&product-key=dotcoop

This module still accepts a hash and leaves it to the developer to handle the appending of the incrementing digit to the keys of the hash:

    $logic_boxes->contacts__set_details({
        'contact-id'    => 1337,
        'attr-name1'    => 'sponsor',
        'attr-value1'   => '0',
        'attr-name2'    => 'CPR',
        'attr-value2'   => 'COO',
        'product-key'   => 'dotcoop'
    });

In this way you are able to overcome the need for unique keys and still pass the needed values onto LogicBoxes' API.

=cut
