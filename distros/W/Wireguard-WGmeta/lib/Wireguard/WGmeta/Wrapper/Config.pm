=pod

=head1 NAME

WGmeta::Wrapper::Config - Class for interfacing the wireguard configuration

=head1 SYNOPSIS

 use Wireguard::WGmeta::Wrapper::Config;
 my $wg_meta = Wireguard::WGmeta::Wrapper::Config->new('<path to wireguard configuration>');

=head1 DESCRIPTION

This class provides wrapper-functions around a wireguard configuration parsed by L<Wireguard::WGmeta::Parser::Config> which
allow to edit, add and remove interfaces and peers.

=head1 CONCURRENCY

Please refer to L<Wireguard::WGmeta::Wrapper::ConfigT>

=head1 EXAMPLES

 use Wireguard::WGmeta::Wrapper::Config;
 my $wg-meta = Wireguard::WGmeta::Wrapper::Config->new('<path to wireguard configuration>');

 # set an attribute (non wg-meta attributes forwarded to the original `wg set` command)
 wg_meta->set('wg0', 'WG_0_PEER_A_PUBLIC_KEY', '<attribute_name>', '<attribute_value>');

 # set an alias for a peer
 wg_meta->set('wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'alias', 'some_fancy_alias');

 # disable peer (this comments out the peer in the configuration file
 wg_meta->disable_by_alias('wg0', 'some_fancy_alias');

 # write config (if parameter is set to True, the config is overwritten, if set to False the resulting file is suffixed with '_not_applied'
 wg_meta->commit(1);

=head1 METHODS

=cut

use v5.20.0;
package Wireguard::WGmeta::Wrapper::Config;
use strict;
use warnings;
use experimental 'signatures';
use Wireguard::WGmeta::Wrapper::Bridge;
use Wireguard::WGmeta::Parser::Config;
use Wireguard::WGmeta::ValidAttributes;
use Wireguard::WGmeta::Utils;

our $VERSION = "0.2.1"; # do not change manually, this variable is updated when calling make

use constant FALSE => 0;
use constant TRUE => 1;

=head3 new($wireguard_home [, $wg_meta_prefix = '#+', $wg_meta_disabled_prefix = '#-'])

Creates a new instance of this class.

B<Parameters>

=over 1

=item *

C<$wireguard_home> Path to Wireguard configuration files. Make sure the path ends with a `/`.

=item *

C<[, $wg_meta_prefix]> A custom wg-meta comment prefix, has to begin with either `;` or `#`.
It is recommended to not change this setting, especially in a already deployed installation.

=item *

C<[, $wg_meta_disabled_prefix]> A custom prefix for the commented out (disabled) sections,
has to begin with either `;` or `#` and must not be equal with C<$wg_meta_prefix>! (This is enforced and an exception is thrown if violated)
It is recommended to not change this setting, especially in an already deployed installation.

=back

B<Returns>

An instance of WGmeta::Wrapper::Config

=cut
sub new($class, $wireguard_home, $wg_meta_prefix = '#+', $wg_meta_disabled_prefix = '#-') {

    if ($wg_meta_prefix eq $wg_meta_disabled_prefix) {
        die '`$wg_meta_prefix` and `$wg_meta_disabled_prefix` have to be different';
    }

    my ($parsed_config, $count) = _read_configs_from_folder($wireguard_home, $wg_meta_prefix, $wg_meta_disabled_prefix);
    my $self = {
        'wireguard_home'           => $wireguard_home,
        'wg_meta_prefix'           => $wg_meta_prefix,
        'wg_meta_disabled_prefix'  => $wg_meta_disabled_prefix,
        'n_conf_files'             => $count,
        'parsed_config'            => $parsed_config,
        'reload_listeners'         => {},
        'wg_meta_attrs'            => Wireguard::WGmeta::ValidAttributes::WG_META_DEFAULT,
        'wg_meta_additional_attrs' => Wireguard::WGmeta::ValidAttributes::WG_META_ADDITIONAL,
        'wg_orig_interface_attrs'  => Wireguard::WGmeta::ValidAttributes::WG_ORIG_INTERFACE,
        'wg_orig_peer_attrs'       => Wireguard::WGmeta::ValidAttributes::WG_ORIG_PEER,
        'wg_quick_attrs'           => Wireguard::WGmeta::ValidAttributes::WG_QUICK,
    };
    bless $self, $class;
    return $self;
}

sub _read_configs_from_folder($wireguard_home, $wg_meta_prefix, $wg_meta_disabled_prefix) {
    my $parsed_configs = {};
    my ($all_dot_conf, $count) = get_all_conf_files($wireguard_home);
    for my $possible_config_path (@{$all_dot_conf}) {
        my $contents = read_file($possible_config_path);
        my $interface = $possible_config_path;
        $interface =~ s/^\/|\\|.*\/|.*\\|.conf$//g;
        my $parsed_config = parse_wg_config($contents, $interface, $wg_meta_prefix, $wg_meta_disabled_prefix);
        if (defined $parsed_config) {
            # additional data
            $parsed_config->{config_path} = $possible_config_path;
            $parsed_config->{mtime} = get_mtime($possible_config_path);
            $parsed_configs->{$interface} = $parsed_config;
        }
    }
    return $parsed_configs, $count;
}

=head3 set($interface, $identifier, $attribute, $value [, $allow_non_meta, $forward_function])

Sets a value on a specific interface section. If C<attribute_value> == C<$value> this sub is essentially a No-Op.

B<Parameters>

=over 1

=item *

C<$interface> Valid interface identifier (e.g 'wg0')

=item *

C<$identifier> If the target section is a peer, this is usually the public key of this peer. If target is an interface,
its again the interface name.

=item *

C<$attribute> Attribute name (Case does not not matter)

=item *

C<[$allow_non_meta = FALSE]> If set to TRUE, non wg-meta attributes are not forwarded to C<$forward_function>.

=item *

C<[$forward_function = undef]> A reference to a callback function when C<$allow_non_meta = TRUE>. The following signature
is expected: C<forward_fun($interface, $identifier, $attribute, $value)>

=back

B<Raises>

Exception if either the interface or identifier is invalid.

B<Returns>

None

=cut
sub set($self, $interface, $identifier, $attribute, $value, $allow_non_meta = FALSE, $forward_function = undef) {
    my $attr_type = decide_attr_type($attribute, TRUE);
    unless (defined $value) {
        warn "Undefined value for `$attribute` in interface `$interface` NOT SET";
        return;
    }
    if ($self->is_valid_interface($interface)) {
        if ($self->is_valid_identifier($interface, $identifier)) {

            # skip if same value
            if (exists $self->{parsed_config}{$interface}{$identifier}{$attribute} && $self->{parsed_config}{$interface}{$identifier}{$attribute} eq $value) {
                return;
            }
            if ($attr_type == ATTR_TYPE_IS_WG_META || $attr_type == ATTR_TYPE_IS_WG_META_CUSTOM) {

                unless (attr_value_is_valid($attribute, $value, get_attr_config($attr_type))) {
                    die "Invalid attribute value `$value` for `$attribute`";
                }
                unless (exists $self->{parsed_config}{$interface}{$identifier}{$attribute}) {
                    # the attribute does not (yet) exist in the configuration, lets add it to the list
                    push @{$self->{parsed_config}{$interface}{$identifier}{order}}, $attribute;
                }
                if ($attribute eq 'alias') {
                    $self->_update_alias_map($interface, $identifier, $value);
                }
                $self->{parsed_config}{$interface}{$identifier}{$attribute} = $value;
            }
            else {
                if ($allow_non_meta == TRUE) {
                    if (_fits_wg_section($interface, $identifier, $attr_type)) {
                        unless (attr_value_is_valid($attribute, $value, get_attr_config($attr_type))) {
                            die "Invalid attribute value `$value` for `$attribute`";
                        }
                        unless (exists $self->{parsed_config}{$interface}{$identifier}{$attribute}) {
                            # the attribute does not (yet) exist in the configuration, lets add it to the list
                            push @{$self->{parsed_config}{$interface}{$identifier}{order}}, $attribute;
                        }
                        # the attribute does already exist and therefore we just set it to the new value
                        $self->{parsed_config}{$interface}{$identifier}{$attribute} = $value;
                    }
                    else {
                        die "The supplied attribute `$attribute` is not valid for this section type (this most likely means you've tried to set a peer attribute in the interface section or vice-versa)";
                    }
                }
                else {
                    if (defined($forward_function)) {
                        &{$forward_function}($interface, $identifier, $attribute, $value);
                    }
                    else {
                        die 'No forward function defined';
                    }
                }
            }
            $self->_set_changed($interface);
        }
        else {
            die "Invalid identifier `$identifier` for interface `$interface`";
        }
    }
    else {
        die "Invalid interface name `$interface`";
    }

}

# internal method to check if a non-meta attribute is valid for the target section
sub _fits_wg_section($interface, $identifier, $attr_type) {
    # if we have an interface
    if ($interface eq $identifier) {
        return $attr_type == ATTR_TYPE_IS_WG_ORIG_INTERFACE || $attr_type == ATTR_TYPE_IS_WG_QUICK
    }
    else {
        return $attr_type == ATTR_TYPE_IS_WG_ORIG_PEER;
    }
}

=head3 attr_value_is_valid($attribute, $value, $ref_valid_attrs)

Simply calls the C<validate()> function defined in L<Wireguard::WGmeta::Validator>

B<Parameters>

=over 1

=item

C<$attribute> Attribute name

=item

C<$value> Attribute value

=item

C<$ref_valid_attrs> Reference to the corresponding L<Wireguard::WGmeta::Validator> section.

=back

B<Returns>

True if validation was successful, False if not

=cut
sub attr_value_is_valid($attribute, $value, $ref_valid_attrs) {
    return $ref_valid_attrs->{$attribute}{validator}($value);
}

sub _update_alias_map($self, $interface, $identifier, $alias) {
    unless (exists $self->{parsed_config}{$interface}{alias_map}{$alias}) {
        $self->{parsed_config}{$interface}{alias_map}{$alias} = $identifier;
    }
    else {
        die "Alias `$alias` is already defined on interface `$interface`";
    }
}

=head3 set_by_alias($interface, $alias, $attribute, $value [, $allow_non_meta = FALSE, $forward_function = undef])

Same as L</set($interface, $identifier, $attribute, $value [, $allow_non_meta, $forward_function])> - just with alias support.

B<Raises>

Exception if alias is invalid

=cut
sub set_by_alias($self, $interface, $alias, $attribute, $value, $allow_non_meta = FALSE, $forward_function = undef) {
    my $identifier = $self->translate_alias($interface, $alias);
    $self->set($interface, $identifier, $attribute, $value, $allow_non_meta, $forward_function);
}

=head3 disable($interface, $identifier)

Disables an interface/peer (by prefixing C<$wg_meta_disabled_prefix>) and setting the wg-meta attribute `Disabled` to C<1>.

B<Parameters>

=over 1

=item *

C<$interface> Valid interface name (e.g 'wg0').

=item *

C<$identifier> A valid identifier: If the target section is a peer, this is usually the public key of this peer. If target is an interface,
its again the interface name.

=back

B<Returns>

None

=cut
sub disable($self, $interface, $identifier,) {
    $self->_toggle($interface, $identifier, TRUE);
}

=head3 enable($interface, $identifier)

Inverse method if L</disable($interface, $identifier)>

=cut
sub enable($self, $interface, $identifier) {
    $self->_toggle($interface, $identifier, FALSE);
}

=head3 disable_by_alias($interface, $alias)

Same as L</disable($interface, $identifier)> just with alias support

B<Raises>

Exception if alias is invalid

=cut
sub disable_by_alias($self, $interface, $alias,) {
    $self->_toggle($interface, $self->translate_alias($interface, $alias), FALSE);
}

=head3 disable_by_alias($interface, $alias)

Same as L</enable($interface, $identifier)>ust with alias support

B<Raises>

Exception if alias is invalid

=cut
sub enable_by_alias($self, $interface, $alias,) {
    $self->_toggle($interface, $self->translate_alias($interface, $alias), TRUE);
}

# internal toggle method (DRY)
sub _toggle($self, $interface, $identifier, $enable) {
    if (exists $self->{parsed_config}{$interface}{$identifier}{Disabled}) {
        if ($self->{parsed_config}{$interface}{$identifier}{Disabled} == "$enable") {
            warn "Section `$identifier` in `$interface` is already $enable";
        }
    }
    $self->set($interface, $identifier, 'disabled', $enable);
}

=head3 is_valid_interface($interface)

Checks if an interface name is valid (present in parsed config)

B<Parameters>

=over 1

=item

C<$interface> An interface name

=back

B<Returns>

True if present, undef if not.

=cut
sub is_valid_interface($self, $interface) {
    return (exists $self->{parsed_config}{$interface});
}

=head3 is_valid_identifier($interface, $identifier)

Checks if an identifier is valid for a given interface

B<Parameters>

=over 1

=item

C<$interface> An interface name

=item

C<$identifier> An identifier (no alias!)

=back

B<Returns>

True if present, undef if not.

=cut
sub is_valid_identifier($self, $interface, $identifier) {
    return (exists $self->{parsed_config}{$interface}{$identifier});
}

=head3 translate_alias($interface, $alias)

Translates an alias to a valid identifier.

B<Parameters>

=over 1

=item *

C<$interface> A valid interface name (e.g 'wg0').

=item *

C<$alias> An alias to translate

=back

B<Raises>

Exception if alias is invalid

B<Returns>

A valid identifier.

=cut
sub translate_alias($self, $interface, $alias) {
    if (exists $self->{parsed_config}{$interface}{alias_map}{$alias}) {
        return $self->{parsed_config}{$interface}{alias_map}{$alias};
    }
    else {
        die "Invalid alias `$alias` on interface $interface";
    }
}
=head3 try_translate_alias($interface, $may_alias)

Tries to translate an identifier (which may be an alias).
However, unlike L</translate_alias($interface, $alias)>, no
exception is thrown on failure, instead the C<$may_alias> is returned.

B<Parameters>

=over 1

=item

C<$interface> A valid interface name (is not validated)

=item

C<$may_alias> An identifier which could be a valid alias for this interface

=back

B<Returns>

If the alias is valid for the specified interface, the corresponding identifier is returned, else C<$may_alias>

=cut
sub try_translate_alias($self, $interface, $may_alias) {
    if (exists $self->{parsed_config}{$interface}{alias_map}{$may_alias}) {
        return $self->{parsed_config}{$interface}{alias_map}{$may_alias};
    }
    else {
        return $may_alias;
    }
}

=head3 get_all_conf_files($wireguard_home)

Returns a list of all files in C<$wireguard_home> matching I<r/.*\.conf$/>.

B<Parameters>

=over 1

=item

C<$wireguard_home> Path to a folder where wireguard configuration files are located

=back

B<Returns>

A reference to a list with absolute paths to the config files (possibly empty)

=cut
sub get_all_conf_files($wireguard_home) {
    my @config_files = read_dir($wireguard_home, qr/.*\.conf$/);
    if (@config_files == 0) {
        die "No matching interface configuration(s) in " . $wireguard_home;
    }
    my $count = @config_files;
    return \@config_files, $count;
}

=head3 commit([$is_hot_config = FALSE, $plain = FALSE])

Writes down the parsed config to the wireguard configuration folder

B<Parameters>

=over 1

=item

C<[$is_hot_config = FALSE])> If set to TRUE, the existing configuration is overwritten. Otherwise,
the suffix '_not_applied' is appended to the filename

=item

C<[$plain = FALSE])> If set to TRUE, no header is generated

=back

B<Raises>

Exception if: Folder or file is not writeable

B<Returns>


None

=cut
sub commit($self, $is_hot_config = FALSE, $plain = FALSE) {
    for my $interface (keys %{$self->{parsed_config}}) {
        if ($self->_has_changed($interface)) {
            my $new_config = create_wg_config($self->{parsed_config}{$interface}, $self->{wg_meta_prefix}, $self->{wg_meta_disabled_prefix}, $plain);
            my $fh;
            if ($is_hot_config == TRUE) {
                open $fh, '>', $self->{wireguard_home} . $interface . '.conf' or die $!;
            }
            else {
                open $fh, '>', $self->{wireguard_home} . $interface . '.conf_not_applied' or die $!;
            }
            # write down to file
            print $fh $new_config;
            $self->_reset_changed($interface);
            close $fh;
        }
    }
}


=head3 get_interface_list()

Return a list of all interfaces.

B<Returns>

A list of all valid interface names. If no interfaces are available, an empty list is returned

=cut
sub get_interface_list($self) {
    return sort keys %{$self->{parsed_config}};
}

=head3 get_interface_section($interface, $identifier)

Returns a hash representing a section of a given interface

B<Parameters>

=over 1

=item *

C<$interface> Valid interface name

=item *

C<$identifier> Valid section identifier

=back

B<Returns>

A hash containing the requested section. If the requested section/interface is not present, an empty hash is returned.

=cut
sub get_interface_section($self, $interface, $identifier) {
    if (exists $self->{parsed_config}{$interface}{$identifier}) {
        my %r = %{$self->{parsed_config}{$interface}{$identifier}};
        return %r;
    }
    else {
        return ();
    }
}

=head3 get_section_list($interface)

Returns a list of valid sections of an interface (ordered as in the original config file).

B<Parameters>

=over 1

=item *

C<$interface> A valid interface name

=back

B<Returns>

A list of all sections of an interface. If interface is not present, an empty list is returned.

=cut
sub get_section_list($self, $interface) {
    if (exists $self->{parsed_config}{$interface}) {
        return @{$self->{parsed_config}{$interface}{section_order}};
    }
    else {
        return ();
    }
}

=head3 get_interface_fqdn($interface)

Returns the FQDN for an interface (if available)

B<Parameters>

=over 1

=item

C<$interface> A valid interface name

=back

B<Returns>

Value of C<fqdn> attribute or empty string if unavailable.

=cut
sub get_interface_fqdn($self, $interface) {
    if ($self->is_valid_interface($interface) && exists $self->{parsed_config}{$interface}{fqdn}) {
        return $self->{parsed_config}{$interface}{fqdn};
    }
    else {
        return '';
    }
}

sub get_wg_meta_prefix($self) {
    return $self->{wg_meta_prefix};
}

sub get_disabled_prefix($self) {
    return $self->{wg_meta_disabled_prefix};
}

=head3 add_interface($interface_name, $ip_address, $listen_port, $private_key)

Adds a (minimally configured) interface. If more attributes are needed, please set them using the C<set()> method.

B<Caveat:> No validation is performed on the values!

B<Parameters>

=over 1

=item *

C<$interface_name> A new interface name, must be unique.

=item *

C<$ip_address> A string describing the ip net(s) (e.g '10.0.0.0/24, fdc9:281f:04d7:9ee9::2/64')

=item *

C<$listen_port> The listen port for this interface.

=item *

C<$private_key> A private key for this interface

=back

B<Raises>

An exception if the interface name already exists.

B<Returns>

None

=cut
sub add_interface($self, $interface_name, $ip_address, $listen_port, $private_key) {
    if ($self->is_valid_interface($interface_name)) {
        die "Interface `$interface_name` already exists";
    }
    my %interface = (
        'Address'    => $ip_address,
        'ListenPort' => $listen_port,
        'PrivateKey' => $private_key,
        'type'       => 'Interface',
        'order'      => [ 'Address', 'ListenPort', 'PrivateKey' ]
    );
    $self->{parsed_config}{$interface_name}{$interface_name} = \%interface;
    $self->{parsed_config}{$interface_name}{alias_map} = {};
    $self->{parsed_config}{$interface_name}{section_order} = [ $interface_name ];
    $self->{parsed_config}{$interface_name}{checksum} = 'none';
    $self->{parsed_config}{$interface_name}{mtime} = 0.0;
    $self->{parsed_config}{$interface_name}{config_path} = $self->{wireguard_home} . $interface_name . '.conf';
    $self->{parsed_config}{$interface_name}{has_changed} = 1;

}

=head3 add_peer($interface, $name, $ip_address, $public_key [, $alias, $preshared_key])

Adds a peer to an exiting interface.

B<Parameters>

=over 1

=item *

C<$interface> A valid interface.

=item *

C<$name> A name for this peer (wg-meta).

=item *

C<$ip_address> A string describing the ip-address(es) of this this peer.

=item *

C<$public_key> Public-key for this interface. This becomes the identifier of this peer.

=item *

C<[$preshared_key]> Optional argument defining the psk.

=item *

C<[$alias]> Optional argument defining an alias for this peer (wg-meta)

=back

B<Raises>

An exception if either the interface is invalid, the alias is already assigned or the public-key is
already present on an other peer.

B<Returns>

A tuple consisting of the iface private-key and listen port

=cut
sub add_peer($self, $interface, $name, $ip_address, $public_key, $alias = undef, $preshared_key = undef) {
    # generate new key pair if not defined
    if ($self->is_valid_interface($interface)) {
        if ($self->is_valid_identifier($interface, $public_key)) {
            die "An interface with this public-key already exists on `$interface`";
        }
        # generate peer config
        my %peer = ();
        $self->{parsed_config}{$interface}{$public_key} = \%peer;
        $self->set($interface, $public_key, 'name', $name);
        $self->set($interface, $public_key, 'public-key', $public_key, 1);
        $self->set($interface, $public_key, 'allowed-ips', $ip_address, 1);
        if (defined $alias) {
            $self->set($interface, $public_key, 'alias', $alias);
        }
        if (defined $preshared_key) {
            $self->set($interface, $public_key, 'preshared-key', $preshared_key);
        }

        # set type to to Peer
        $self->{parsed_config}{$interface}{$public_key}{type} = 'Peer';
        # add section to global section list
        push @{$self->{parsed_config}{$interface}{section_order}}, $public_key;
        return $self->{parsed_config}{$interface}{$interface}{'private-key'}, $self->{parsed_config}{$interface}{$interface}{'listen-port'};
    }
    else {
        die "Invalid interface `$interface`";
    }
}

=head3 remove_peer($interface, $identifier)

Removes a peer (identified by it's public key or alias) from an interface.

B<Parameters>

=over 1

=item

C<$interface> A valid interface name

=item

C<$identifier> A valid identifier (or an alias)

=back

B<Raises>

Exception if interface or identifier is invalid

B<Returns>

None

=cut
sub remove_peer($self, $interface, $identifier) {
    if ($self->is_valid_interface($interface)) {
        $identifier = $self->try_translate_alias($interface, $identifier);
        if ($self->is_valid_identifier($interface, $identifier)) {

            # delete section
            delete $self->{parsed_config}{$interface}{$identifier};

            # delete from section list
            $self->{parsed_config}{$interface}{section_order} = [ grep {$_ ne $identifier} @{$self->{parsed_config}{$interface}{section_order}} ];

            # decrease peer count
            $self->{parsed_config}{$interface}{n_peers}--;

            # delete alias (if exists)
            while (my ($alias, $a_identifier) = each %{$self->{parsed_config}{$interface}{alias_map}}) {
                if ($a_identifier eq $identifier) {
                    delete $self->{parsed_config}{$interface}{alias_map}{$alias};
                }
            }
            $self->_set_changed($interface);
        }
        else {
            die "Invalid identifier `$identifier` for `$interface`";
        }
    }
    else {
        die "Invalid interface `$interface`";
    }
}

=head3 remove_interface($interface [, $keep_file = FALSE])

Removes an interface. This command deletes the config file immediately. I.e no rollback possible!

B<Parameters>

=over 1

=item

C<$interface> A valid interface name

=back

B<Raises>

Exception if interface or identifier is invalid

B<Returns>

None

=cut
sub remove_interface($self, $interface) {
    if ($self->is_valid_interface($interface)) {
        # delete interface
        delete $self->{parsed_config}{$interface};
        unlink "$self->{wireguard_home}$interface.conf" or warn "Could not delete `$self->{wireguard_home}$interface.conf` do you have the needed permissions?";
        $self->{n_conf_files}--;
    }
}

=head3 get_peer_count([$interface = undef])

Returns the number of peers.

B<Caveat:> Does return the count represented  in the current (parsed) configuration state.

B<Parameters>

=over 1

=item

C<[$interface = undef]> If defined, only return counts for this specific interface

=back

B<Returns>

Number of peers

=cut
sub get_peer_count($self, $interface = undef) {
    if (defined $interface && $self->is_valid_interface($interface)) {
        return $self->{parsed_config}{$interface}{n_peers};
    }
    else {
        my $count = 0;
        for ($self->get_interface_list()) {
            $count += $self->{parsed_config}{$_}{n_peers};
        }
        return $count;
    }
}

=head3 reload_from_disk($interface [, $new = FALSE])

Method to reload an interface configuration from disk. Also useful to add an newly (externally) created
interface on-the-fly.

B<Parameters>

=over 1

=item *

C<$interface> A valid interface name

=item *

C<[$new = FALSE]> If set to True, the parser looks at C<$wireguard_home> for this new interface config.

=back

B<Raises>

Exception: If the interface is invalid (or the config file is not found)

B<Returns>

None, or undef if C<$new == True> and the interface in fact not a wg config.

=cut
sub reload_from_disk($self, $interface, $new = FALSE) {
    my $config_path;
    if ($new == FALSE) {
        if ($self->is_valid_interface($interface)) {
            $config_path = $self->{wireguard_home} . $interface . '.conf';
            my $contents = read_file($self->{parsed_config}{$interface}{config_path});
            $self->{parsed_config}{$interface} = parse_wg_config($contents, $interface, $self->{wg_meta_prefix}, $self->{wg_meta_disabled_prefix}, FALSE);
            $self->{parsed_config}{$interface}{config_path} = $config_path;
            $self->{parsed_config}{$interface}{mtime} = get_mtime($config_path);
            $self->_call_reload_listeners($interface);
        }
        else {
            die "Invalid interface $interface - if this is a new interface, set `\$new` to True";
        }

    }
    else {
        $config_path = $self->{wireguard_home} . $interface . '.conf';
        if (-e $config_path) {
            my $contents = read_file($config_path);
            my $maybe_new_config = parse_wg_config($contents, $interface, $self->{wg_meta_prefix}, $self->{wg_meta_disabled_prefix}, FALSE);
            if (defined $maybe_new_config) {
                $self->{n_conf_files}++;
                $self->{parsed_config}{$interface} = $maybe_new_config;
                $self->{parsed_config}{$interface}{config_path} = $config_path;
                $self->{parsed_config}{$interface}{mtime} = get_mtime($config_path);
                $self->_call_reload_listeners($interface);
            }
            else {
                return undef;
            }
        }
        else {
            die "The interface $interface was not found in $self->{wireguard_home}";
        }

    }

}

# internal method to add to hash if value is defined
sub _add_to_hash_if_defined($ref_hash, $key, $value) {
    if (defined($value)) {
        $ref_hash->{$key} = $value;
    }
    return $ref_hash;
}

# internal method to create a configuration file (this method exists primarily for testing purposes)
sub _create_config($self, $interface, $plain = FALSE) {
    return create_wg_config(
        $self->{parsed_config}{$interface},
        $self->{wg_meta_prefix},
        $self->{disabled_prefix},
        $plain = $plain)
}

sub _has_changed($self, $interface) {
    return exists $self->{parsed_config}{$interface}{has_changed};
}

sub _set_changed($self, $interface) {
    $self->{parsed_config}{$interface}{has_changed} = 1;
}

sub _reset_changed($self, $interface) {
    delete $self->{parsed_config}{$interface}{has_changed} if (exists $self->{parsed_config}{$interface}{has_changed});
}

=head3 register_on_reload_listener($ref_handler, $handler_id [, $ref_listener_args = []])

Register your callback handlers for the C<reload_from_disk()> event here. Your handler is called
B<after> the reload happened, is blocking and exceptions are caught in an C<eval{};> environment.

B<Parameters>

=over 1

=item

C<$ref_handler> Reference to a handler function. The followin signature is expected:

    sub my_handler_function($interface, $ref_list_args){
        ...
    }

=item

C<$handler_id> An identifier for you handler function. Must be unique!

=item

C<[$ref_listener_args = []]> A reference to an argument list for your handler function

=back

B<Returns>

None, exception if C<$handler_id> is already present.

=cut
sub register_on_reload_listener($self, $ref_handler, $handler_id, $ref_listener_args = []) {
    unless ($self->{reload_listeners}{$handler_id}) {
        my $listener_data = {
            'handler' => $ref_handler,
            'args'    => $ref_listener_args
        };
        $self->{reload_listeners}{$handler_id} = $listener_data;
    }
    else {
        die "Handler id $handler_id already present";
    }

}

=head3 remove_on_reload_listener($handler_id)

Removes a reload callback handler by it's C<$handler_id>.

B<Parameters>

=over 1

=item

C<$handler_id> A valid handler id

=back

B<Returns>

1 on success, undef on failure.

=cut
sub remove_on_reload_listener($self, $handler_id) {
    if (exists $self->{reload_listeners}{$handler_id}) {
        delete $self->{reload_listeners}{$handler_id};
        return 1;
    }
    else {
        return undef;
    }
}

sub _call_reload_listeners($self, $interface) {
    for my $listener_id (keys %{$self->{reload_listeners}}) {
        eval {
            &{$self->{reload_listeners}{$listener_id}{handler}}($interface, $self->{reload_listeners}{$listener_id}{args});
        };
        if ($@) {
            warn "Call to reload_listener $listener_id failed: $@";
        }
    }
}


1;