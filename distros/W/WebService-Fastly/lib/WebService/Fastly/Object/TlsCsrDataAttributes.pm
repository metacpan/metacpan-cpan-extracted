=begin comment

Fastly API

Via the Fastly API you can perform any of the operations that are possible within the management console,  including creating services, domains, and backends, configuring rules or uploading your own application code, as well as account operations such as user administration and billing reports. The API is organized into collections of endpoints that allow manipulation of objects related to Fastly services and accounts. For the most accurate and up-to-date API reference content, visit our [Developer Hub](https://www.fastly.com/documentation/reference/api/) 

The version of the API Spec document: 1.0.0
Contact: oss@fastly.com

=end comment

=cut

#
# NOTE: This class is auto generated.
# Do not edit the class manually.
#
package WebService::Fastly::Object::TlsCsrDataAttributes;

require 5.6.0;
use strict;
use warnings;
use utf8;
use JSON::MaybeXS qw(decode_json);
use Data::Dumper;
use Module::Runtime qw(use_module);
use Log::Any qw($log);
use Date::Parse;
use DateTime;


use base ("Class::Accessor", "Class::Data::Inheritable");

#
#
#
# NOTE: This class is auto generated. Do not edit the class manually.
#

=begin comment

Fastly API

Via the Fastly API you can perform any of the operations that are possible within the management console,  including creating services, domains, and backends, configuring rules or uploading your own application code, as well as account operations such as user administration and billing reports. The API is organized into collections of endpoints that allow manipulation of objects related to Fastly services and accounts. For the most accurate and up-to-date API reference content, visit our [Developer Hub](https://www.fastly.com/documentation/reference/api/) 

The version of the API Spec document: 1.0.0
Contact: oss@fastly.com

=end comment

=cut

#
# NOTE: This class is auto generated.
# Do not edit the class manually.
#
__PACKAGE__->mk_classdata('attribute_map' => {});
__PACKAGE__->mk_classdata('openapi_types' => {});
__PACKAGE__->mk_classdata('method_documentation' => {});
__PACKAGE__->mk_classdata('class_documentation' => {});
__PACKAGE__->mk_classdata('openapi_nullable' => {});

# new plain object
sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $self->init(%args);

    return $self;
}

# initialize the object
sub init
{
    my ($self, %args) = @_;

    foreach my $attribute (keys %{$self->attribute_map}) {
        my $args_key = $self->attribute_map->{$attribute};
        $self->$attribute( $args{ $args_key } );
    }
}

# return perl hash
sub to_hash {
    my $self = shift;
    my $_hash = decode_json(JSON()->new->allow_blessed->convert_blessed->encode($self));

    return $_hash;
}

# used by JSON for serialization
sub TO_JSON {
    my $self = shift;
    my $_data = {};
    foreach my $_key (keys %{$self->attribute_map}) {
        $_data->{$self->attribute_map->{$_key}} = $self->{$_key};
    }

    return $_data;
}

# from Perl hashref
sub from_hash {
    my ($self, $hash) = @_;

    # loop through attributes and use openapi_types to deserialize the data
    while ( my ($_key, $_type) = each %{$self->openapi_types} ) {
        my $_json_attribute = $self->attribute_map->{$_key};
        my $_is_nullable = ($self->openapi_nullable->{$_key} || 'false') eq 'true';
        if ($_type =~ /^array\[(.+)\]$/i) { # array
            my $_subclass = $1;
            my @_array = ();
            foreach my $_element (@{$hash->{$_json_attribute}}) {
                push @_array, $self->_deserialize($_subclass, $_element, $_is_nullable);
            }
            $self->{$_key} = \@_array;
        } elsif ($_type =~ /^hash\[string,(.+)\]$/i) { # hash
            my $_subclass = $1;
            my %_hash = ();
            while (my($_key, $_element) = each %{$hash->{$_json_attribute}}) {
                $_hash{$_key} = $self->_deserialize($_subclass, $_element, $_is_nullable);
            }
            $self->{$_key} = \%_hash;
        } elsif (exists $hash->{$_json_attribute}) { #hash(model), primitive, datetime
            $self->{$_key} = $self->_deserialize($_type, $hash->{$_json_attribute}, $_is_nullable);
        } else {
            $log->debugf("Warning: %s (%s) does not exist in input hash\n", $_key, $_json_attribute);
        }
    }

    return $self;
}

# deserialize non-array data
sub _deserialize {
    my ($self, $type, $data, $is_nullable) = @_;
    $log->debugf("deserializing %s with %s",Dumper($data), $type);

    if (!(defined $data) && $is_nullable) {
        return undef;
    }
    if ($type eq 'DateTime') {
        return DateTime->from_epoch(epoch => str2time($data));
    } elsif ( grep( /^$type$/, ('int', 'double', 'string', 'boolean'))) {
        return $data;
    } else { # hash(model)
        my $_instance = eval "WebService::Fastly::Object::$type->new()";
        return $_instance->from_hash($data);
    }
}


__PACKAGE__->class_documentation({description => '',
                                  class => 'TlsCsrDataAttributes',
                                  required => [], # TODO
}                                 );

__PACKAGE__->method_documentation({
    'sans' => {
        datatype => 'ARRAY[string]',
        base_name => 'sans',
        description => 'Subject Alternate Names - An array of one or more fully qualified domain names or public IP addresses to be secured by this certificate. Required.',
        format => '',
        read_only => 'false',
            },
    'common_name' => {
        datatype => 'string',
        base_name => 'common_name',
        description => 'Common Name (CN) - The fully qualified domain name (FQDN) to be secured by this certificate. The common name should be one of the entries in the SANs parameter.',
        format => '',
        read_only => 'false',
            },
    'country' => {
        datatype => 'string',
        base_name => 'country',
        description => 'Country (C) - The two-letter ISO country code where the organization is located.',
        format => '',
        read_only => 'false',
            },
    'state' => {
        datatype => 'string',
        base_name => 'state',
        description => 'State (S) - The state, province, region, or county where the organization is located. This should not be abbreviated.',
        format => '',
        read_only => 'false',
            },
    'city' => {
        datatype => 'string',
        base_name => 'city',
        description => 'Locality (L) - The locality, city, town, or village where the organization is located.',
        format => '',
        read_only => 'false',
            },
    'postal_code' => {
        datatype => 'string',
        base_name => 'postal_code',
        description => 'Postal Code - The postal code where the organization is located.',
        format => '',
        read_only => 'false',
            },
    'street_address' => {
        datatype => 'string',
        base_name => 'street_address',
        description => 'Street Address - The street address where the organization is located.',
        format => '',
        read_only => 'false',
            },
    'organization' => {
        datatype => 'string',
        base_name => 'organization',
        description => 'Organization (O) - The legal name of the organization, including any suffixes. This should not be abbreviated.',
        format => '',
        read_only => 'false',
            },
    'organizational_unit' => {
        datatype => 'string',
        base_name => 'organizational_unit',
        description => 'Organizational Unit (OU) - The internal division of the organization managing the certificate.',
        format => '',
        read_only => 'false',
            },
    'email' => {
        datatype => 'string',
        base_name => 'email',
        description => 'Email Address (EMAIL) - The organizational contact for this.',
        format => 'email',
        read_only => 'false',
            },
    'key_type' => {
        datatype => 'string',
        base_name => 'key_type',
        description => 'CSR Key Type.',
        format => '',
        read_only => 'false',
            },
    'relationships/tls_private_key/id' => {
        datatype => 'string',
        base_name => 'relationships.tls_private_key.id',
        description => 'Optional. An alphanumeric string identifying the private key you&#39;ve uploaded for use with your TLS certificate. If left blank, Fastly will create and manage a key for you.',
        format => '',
        read_only => 'false',
            },
});

__PACKAGE__->openapi_types( {
    'sans' => 'ARRAY[string]',
    'common_name' => 'string',
    'country' => 'string',
    'state' => 'string',
    'city' => 'string',
    'postal_code' => 'string',
    'street_address' => 'string',
    'organization' => 'string',
    'organizational_unit' => 'string',
    'email' => 'string',
    'key_type' => 'string',
    'relationships/tls_private_key/id' => 'string'
} );

__PACKAGE__->attribute_map( {
    'sans' => 'sans',
    'common_name' => 'common_name',
    'country' => 'country',
    'state' => 'state',
    'city' => 'city',
    'postal_code' => 'postal_code',
    'street_address' => 'street_address',
    'organization' => 'organization',
    'organizational_unit' => 'organizational_unit',
    'email' => 'email',
    'key_type' => 'key_type',
    'relationships/tls_private_key/id' => 'relationships.tls_private_key.id'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});

__PACKAGE__->openapi_nullable( {
} );


1;
