=head1 NAME

WGmeta::ValidAttributes - Supported attribute configurations

=head1 DESCRIPTION

In this module all supported attribute names are defined. Currently this only affects
L<Wireguard::WGmeta::Wrapper::Config/set($interface, $identifier, $attribute, $value [, $allow_non_meta, $forward_function])>

=head1 SYNOPSIS

Add your own attributes to L</WG_META_ADDITIONAL>

=head1 ATTRIBUTE SETS

=cut

package Wireguard::WGmeta::ValidAttributes;
use strict;
use warnings FATAL => 'all';

use Wireguard::WGmeta::Validator;

# Attribute configurations (do not change, add your own under WG_META_ADDITIONAL)
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
    }
};

=head2 WG_META_ADDITIONAL

Define your custom attributes here in the following format (the wg meta prefix can be omitted here):

    'attribute-name-in-lower-case-and-separated-by-dashes' => {
        'in_config_name' => 'Pretty name as it appear in config',
        'validator'      => <function-reference to validator function>
    },
    'other-attributes' => {
        'in_config_name' => 'Other name'
        'validator'      => <function-reference to validator function>,
    }

Validator functions can be defined in L<Wireguard::WGmeta::Validator>

=cut
use constant WG_META_ADDITIONAL => {};

# wg-quick attributes
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

# attribute names which are valid for the [Interface] sections
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

# attribute name which are valid for the [Peer] sections
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

1;