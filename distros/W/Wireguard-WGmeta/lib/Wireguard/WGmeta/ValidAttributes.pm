=head1 NAME

WGmeta::ValidAttributes - Supported attribute configurations

=head1 DESCRIPTION

In this module all supported attributes are configured (and as well their possible validation function). Attributes configured
here affect how the parser stores them and which attributes are supported by the
L<Wireguard::WGmeta::Wrapper::Config/set($interface, $identifier, $attribute, $value [, $allow_non_meta, $forward_function])>.

=head1 SYNOPSIS

Add your own attributes to L</WG_META_ADDITIONAL>

=cut

package Wireguard::WGmeta::ValidAttributes;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use Wireguard::WGmeta::Validator;

=head1 ATTRIBUTE TYPES

=cut

=head3 ATTR_TYPE_IS_WG_META

(Default) - wg-meta attributes

=cut
use constant ATTR_TYPE_IS_WG_META => 10;
=head3 ATTR_TYPE_IS_WG_META_CUSTOM

Your custom wg-meta attributes

=cut
use constant ATTR_TYPE_IS_WG_META_CUSTOM => 11;
=head3 ATTR_TYPE_IS_WG_QUICK

wg-quick attribute

=cut
use constant ATTR_TYPE_IS_WG_QUICK => 12;
=head3 ATTR_TYPE_IS_WG_ORIG_INTERFACE

Original Wireguard attribute, valid for C<[Interface]> sections.

=cut
use constant ATTR_TYPE_IS_WG_ORIG_INTERFACE => 13;
=head3 ATTR_TYPE_IS_WG_ORIG_PEER

Original Wireguard attribute, valid for C<[Peer]> sections.

=cut
use constant ATTR_TYPE_IS_WG_ORIG_PEER => 14;
=head3 ATTR_TYPE_IS_UNKNOWN

Any unknown attribute types

=cut
use constant ATTR_TYPE_IS_UNKNOWN => 15;

use constant TRUE => 1;
use constant FALSE => 0;

use base 'Exporter';
our @EXPORT = qw(
    ATTR_TYPE_IS_WG_META
    ATTR_TYPE_IS_WG_META_CUSTOM
    ATTR_TYPE_IS_WG_QUICK
    ATTR_TYPE_IS_WG_ORIG_INTERFACE
    ATTR_TYPE_IS_WG_ORIG_PEER
    ATTR_TYPE_IS_UNKNOWN
    get_attr_config
    decide_attr_type
    register_custom_attribute
);

=head1 ATTRIBUTE SETS

General remark: If you want to add your own attributes add them to L</WG_META_ADDITIONAL> - all other config sets
should only be modified on (possible) future changes in attribute configurations in Wireguard or wg-quick!

=head3 WG_META_DEFAULT

wg-meta default attributes. Do not make changes here, they are expected to be present!

=cut
use constant WG_META_DEFAULT => {
    'name'        => {
        'in_config_name' => 'Name',
        'validator'      => \&accept_any
    },
    'alias'       => {
        'in_config_name' => 'Alias',
        'validator'      => \&accept_any
    },
    'description' => {
        'in_config_name' => 'Description',
        'validator'      => \&accept_any
    },
    'disabled'    => {
        'in_config_name' => 'Disabled',
        'validator'      => \&accept_any
    },
    'fqdn'        => {
        'in_config_name' => 'FQDN',
        'validator'      => \&accept_any
    }
};

=head3 WG_META_ADDITIONAL

Use L</register_custom_attribute($ref_attr_config)> to register your own attributes

=cut
use constant WG_META_ADDITIONAL => {};

=head3 WG_QUICK

wg-quick attribute set

=cut
use constant WG_QUICK => {
    'address'     => {
        'in_config_name' => 'Address',
        'validator'      => \&accept_any
    },
    'dns'         => {
        'in_config_name' => 'DNS',
        'validator'      => \&accept_any
    },
    'mtu'         => {
        'in_config_name' => 'MTU',
        'validator'      => \&accept_any
    },
    'table'       => {
        'in_config_name' => 'Table',
        'validator'      => \&accept_any
    },
    'pre-up'      => {
        'in_config_name' => 'PreUp',
        'validator'      => \&accept_any
    },
    'post-up'     => {
        'in_config_name' => 'PostUP',
        'validator'      => \&accept_any
    },
    'pre-down'    => {
        'in_config_name' => 'PreDown',
        'validator'      => \&accept_any
    },
    'post-down'   => {
        'in_config_name' => 'PostDown',
        'validator'      => \&accept_any
    },
    'save-config' => {
        'in_config_name' => 'SaveConfig',
        'validator'      => \&accept_any
    }
};

=head3 WG_ORIG_INTERFACE

Attributes valid for Wireguard I<[Interface>] sections

=cut
use constant WG_ORIG_INTERFACE => {
    'listen-port' => {
        'in_config_name' => 'ListenPort',
        'validator'      => \&is_number
    },
    'fwmark'      => {
        'in_config_name' => 'Fwmark',
        'validator'      => \&accept_any
    },
    'private-key' => {
        'in_config_name' => 'PrivateKey',
        'validator'      => \&accept_any
    }
};

=head3 WG_ORIG_PEER

Attributes valid for Wireguard I<[Peer>] sections

=cut
use constant WG_ORIG_PEER => {
    'public-key'           => {
        'in_config_name' => 'PublicKey',
        'validator'      => \&accept_any
    },
    'preshared-key'        => {
        'in_config_name' => 'PresharedKey',
        'validator'      => \&accept_any
    },
    'endpoint'             => {
        'in_config_name' => 'Endpoint',
        'validator'      => \&accept_any
    },
    'persistent-keepalive' => {
        'in_config_name' => 'PresistentKeepAlive',
        'validator'      => \&accept_any
    },
    'allowed-ips'          => {
        'in_config_name' => 'AllowedIPs',
        'validator'      => \&accept_any
    },
};

# internal method to create mappings
sub _create_inverse_mapping() {
    my $inv_map = {};
    map {$inv_map->{$_} = ATTR_TYPE_IS_WG_ORIG_PEER;} (keys %{+WG_ORIG_PEER});
    map {$inv_map->{$_} = ATTR_TYPE_IS_WG_ORIG_INTERFACE;} (keys %{+WG_ORIG_INTERFACE});
    map {$inv_map->{$_} = ATTR_TYPE_IS_WG_META;} (keys %{+WG_META_DEFAULT});
    map {$inv_map->{$_} = ATTR_TYPE_IS_WG_META_CUSTOM;} (keys %{+WG_META_ADDITIONAL});
    map {$inv_map->{$_} = ATTR_TYPE_IS_WG_QUICK;} (keys %{+WG_QUICK});
    return $inv_map;
}
sub _create_inconfig_name_mapping() {
    my $names2key = {};
    map {$names2key->{WG_ORIG_PEER->{$_}{in_config_name}} = $_;} (keys %{+WG_ORIG_PEER});
    map {$names2key->{WG_ORIG_INTERFACE->{$_}{in_config_name}} = $_;} (keys %{+WG_ORIG_INTERFACE});
    map {$names2key->{WG_META_DEFAULT->{$_}{in_config_name}} = $_;} (keys %{+WG_META_DEFAULT});
    map {$names2key->{WG_META_ADDITIONAL->{$_}{in_config_name}} = $_;} (keys %{+WG_META_ADDITIONAL});
    map {$names2key->{WG_QUICK->{$_}{in_config_name}} = $_;} (keys %{+WG_QUICK});
    return $names2key;
}

=head3 INVERSE_ATTR_TYPE_MAPPING

[Generated] Static mapping from I<attr_key>attr_key to I<attr_type>.

=cut
use constant INVERSE_ATTR_TYPE_MAPPING => _create_inverse_mapping;

=head3 NAME_2_KEYS_MAPPING

[Generated] Static mapping from I<in_config_name> to I<attr_key>.

=cut
use constant NAME_2_KEYS_MAPPING => _create_inconfig_name_mapping;

=head1 METHODS

=head2 get_attr_config($attr_type)

Returns an attribute config set from L</ATTRIBUTE SETS> given a valid attr type.
Ideally obtained through L</decide_attr_type($attr_name [, $allow_unknown = FALSE])>.

B<Parameters>

=over 1

=item

C<$attr_type> A valid attribute type.

=back

B<Raises>

Exception is type is invalid (not known).

B<Returns>

If the type is valid, the corresponding attribute config map.

=cut
sub get_attr_config($attr_type) {
    for ($attr_type) {
        $_ == ATTR_TYPE_IS_WG_ORIG_PEER && do {
            return WG_ORIG_PEER;
        };
        $_ == ATTR_TYPE_IS_WG_ORIG_INTERFACE && do {
            return WG_ORIG_INTERFACE;
        };
        $_ == ATTR_TYPE_IS_WG_META && do {
            return WG_META_DEFAULT;
        };
        $_ == ATTR_TYPE_IS_WG_META_CUSTOM && do {
            return WG_META_ADDITIONAL;
        };
        $_ == ATTR_TYPE_IS_WG_QUICK && do {
            return WG_QUICK;
        };
    }
    die "Invalid attribute type `$attr_type`";
}

=head2 decide_attr_type($attr_name [, $allow_unknown = FALSE])

Returns the attribute type given an I<attr_key>.

B<Parameters>

=over 1

=item

C<$attr_name> An attribute key as defined in one L</ATTRIBUTE SETS>.

=item

C<[$allow_unknown = FALSE]> If set to true, unknown attributes result in the type L</ATTR_TYPE_IS_UNKNOWN>.

=back

B<Raises>

An Exception, if the attribute is unknown (and C<$allow_unknown = FALSE>).

B<Returns>

An attribute type from L</ATTRIBUTE TYPES>

=cut
sub decide_attr_type($attr_name, $allow_unknown = FALSE) {
    if (exists INVERSE_ATTR_TYPE_MAPPING->{$attr_name}) {
        return INVERSE_ATTR_TYPE_MAPPING->{$attr_name};
    }
    else {
        if ($allow_unknown == TRUE) {
            return ATTR_TYPE_IS_UNKNOWN;
        }
        else {
            die "Attribute `$attr_name` is not known";
        }
    }
}

=head3 register_custom_attribute($ref_attr_config)

Register your custom attribute names.

B<Parameters>

=over 1

=item

C<$ref_attr_config> A reference to your attribute description. Expected to be in the following format:

    {
        'in_config_name' => 'in_config_attr_name',
        'validator'      => 'Function reference to a validator function'
    },

For the validator function you can either create your own or use one defined in L<Wireguard::WGmeta::Validator>

=back

B<Raises>

Exception if C<$ref_attr_config> is malformed

B<Returns>

1 on success, undef if the attribute is already defined

=cut
sub register_custom_attribute($attr_key, $ref_attr_config) {
    unless (decide_attr_type($attr_key, TRUE) != ATTR_TYPE_IS_UNKNOWN) {
        if (exists $ref_attr_config->{in_config_name} && exists $ref_attr_config->{validator}) {
            WG_META_ADDITIONAL->{$attr_key} = $ref_attr_config;
            # update mappings
            INVERSE_ATTR_TYPE_MAPPING->{$attr_key} = ATTR_TYPE_IS_WG_META_CUSTOM;
            NAME_2_KEYS_MAPPING->{$ref_attr_config->{in_config_name}} = $attr_key;
        }
        else {
            die "Malformed attribute config";
        }
    }
    else {
        return undef;
    }
    return 1;
}

1;