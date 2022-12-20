=pod

=head1 NAME

WGmeta::Parser::Middleware - Middleware between the parser and wrapper class(es)

=head1 SYNOPSIS

 use Wireguard::WGmeta::Parser::Middleware;
 use Wireguard::WGmeta::Util;

 # Parse a wireguard configuration file
 my $config_contents = read_file('/path/to/config.conf', 'interface_name');
 my $parsed_config = parse_wg_config2($config_contents);

 # And convert it to string representation again
 my $new_config_content = create_wg_config2($parsed_config);

=head1 DESCRIPTION

Acts as a middleware between L<Wireguard::WGmeta::Wrapper::Config> and L<Wireguard::WGmeta::Parser::Conf>. Most importantly it
implements the I<entry_handler()> and I<section_handler()> callbacks of L<Wireguard::WGmeta::Parser::Conf>.

=head1 METHODS

=cut
package Wireguard::WGmeta::Parser::Middleware;
use strict;
use warnings FATAL => 'all';
use experimental qw(signatures);

use Wireguard::WGmeta::Parser::Conf qw(INTERNAL_KEY_PREFIX parse_raw_wg_config);
use Wireguard::WGmeta::ValidAttributes;
use Wireguard::WGmeta::Utils;

use base 'Exporter';
our @EXPORT = qw(parse_wg_config2 create_wg_config2);

our $VERSION = "0.3.3";

=head3 parse_wg_config2($config_file_content, $interface_name [, $wg_meta_prefix, $disabled_prefix, $use_checksum])

Using the I<entry_handler()> and I<section_handler()>, this method enriches the parsed config by several artefacts:
I<peer_count>, I<alias_maps>, and I<checksum>. Considering this minimal config example:

    #+root_attr1 = value1

    [Interface]
    ListenPort = 12345

    [Peer]
    #+Alias = some_alias
    PublicKey = peer_1

We end up with the following structure:

    {
        'root_attr1' => value1,
        INT_PREFIX.'root_order' => [
            'root_attr1'
        ],
        INT_PREFIX.'section_order' => [
            'interface_1',
            'peer_1'
        ],
        INT_PREFIX.'n_peers' => 1,
        INT_PREFIX.'observer_wg_meta_attrs => {
            'alias' => 1
        },
        INT_PREFIX.'alias_map => {
            'some_alias' => 'peer_1'
        },
        'interface_name => 'interface_name',
        'interface_1 => {
            'listen-port' => 12345,
            INT_PREFIX.'type' => 'Interface',
            INT_PREFIX.'order' => [
                'listen-port',
            ]
        },
        'peer_1' => {
            'alias' => 'some_alias',
            INT_PREFIX.'type => 'Peer',
            INT_PREFIX.'order => [
                'alias',
            ]
        }
    }

B<Remarks>

=over 1

=item *

All attributes listed in L<Wireguard::WGmeta::ValidAttributes> are referenced by their key. This means, if you want for
example access I<PublicKey> the key would be I<public-key>. Any attribute not present in L<Wireguard::WGmeta::ValidAttributes>
is stored (and written back) as they appear in Config.

=item *

This method can be used as stand-alone in conjunction with the L<>

=item *

If the section is of type 'Peer' the identifier equals to its public-key, otherwise its the interface name again.

=item *

wg-meta attributes are always prefixed with C<$wg_meta_prefix>.


=back

B<Parameters>

=over 1

=item *

C<$config_file_content> String containing the contents of a Wireguard configuration file.

=item *

C<$interface_name> Interface name

=item *

C<[$wg_meta_prefix = '#+']> wg-meta prefix. Must start with '#' or ';'

=item *

C<[$disabled_prefix = '#-']> disabled prefix. Must start with '#' or ';'

=item *

C<[$use_checksum = TRUE]> If set to False, checksum is not checked


=back

B<Raises>

An exceptions if:

=over 1

=item *

If the parser ends up in an invalid state (e.g a section without information). Or An alias is defined twice.

=back

A warning:

=over 1

=item *

On a checksum mismatch

=back

B<Returns>

A reference to a hash with the structure described above. Or if the configuration file is not a Wireguard configuration: undef.

=cut
sub parse_wg_config2($config_file_content, $interface_name, $wg_meta_prefix = '#+', $disabled_prefix = '#-', $use_checksum = 1) {

    return undef unless ($config_file_content =~ /\[Interface\]/);

    my %alias_map;
    my %observed_wg_meta_attrs;
    my $peer_count = 0;
    my $alias_to_consume;
    my $old_checksum;

    my $entry_handler = sub($raw_key, $raw_value, $is_wg_meta) {
        my $final_key = $raw_key;
        my $final_value = $raw_value;


        # Convert known Keys to attr-name style
        $final_key = NAME_2_KEYS_MAPPING->{$raw_key} if exists NAME_2_KEYS_MAPPING->{$raw_key};

        $observed_wg_meta_attrs{$final_key} = 1 if $is_wg_meta;
        # register alias to consume (if any)
        $alias_to_consume = $raw_value if $raw_key eq 'Alias';

        if ($raw_key eq 'Checksum') {
            $old_checksum = $raw_value;
            # discard old checksum
            return undef, undef, 1;
        }

        return $final_key, $final_value, 0;
    };

    my $new_section_handler = sub($identifier, $section_type, $is_active) {
        $peer_count++ if $section_type eq 'Peer';

        # Consume alias (if any)
        if (defined $alias_to_consume) {
            die "Alias `$alias_to_consume` is already defined on $interface_name" if exists $alias_map{$alias_to_consume};
            $alias_map{$alias_to_consume} = $identifier;
            $alias_to_consume = undef;
        }

        return ($section_type eq 'Interface') ? $interface_name : $identifier;

    };

    my $parsed_config = parse_raw_wg_config($config_file_content, $entry_handler, $new_section_handler, 0, $wg_meta_prefix, $disabled_prefix);
    $parsed_config->{INTERNAL_KEY_PREFIX . 'alias_map'} = \%alias_map;
    $parsed_config->{INTERNAL_KEY_PREFIX . 'n_peers'} = $peer_count;
    $parsed_config->{INTERNAL_KEY_PREFIX . 'interface_name'} = $interface_name;
    $parsed_config->{INTERNAL_KEY_PREFIX . 'observed_wg_meta_attrs'} = \%observed_wg_meta_attrs;

    if ($use_checksum == 1 && defined $old_checksum) {
        my $new_checksum = compute_md5_checksum(create_wg_config2($parsed_config, $wg_meta_prefix, $disabled_prefix, 1));
        warn("Checksum mismatch `$interface_name` has been altered in the meantime") if not $new_checksum eq $old_checksum;
    }

    return $parsed_config;
}

=head3 create_wg_config2($ref_interface_config [, $wg_meta_prefix, $disabled_prefix, $no_checksum])

Turns a reference of interface-config hash (just a single interface!) back into a wireguard config.

B<Parameters>

=over 1

=item *

C<$ref_interface_config> Reference to hash containing B<one> interface config.

=item *

C<[$wg_meta_prefix = '#+']> Has to start with a '#' or ';' character and is ideally the
same as in L</parse_wg_config2($config_file_content, $interface_name [, $wg_meta_prefix, $disabled_prefix, $use_checksum])>

=item *

C<[$wg_meta_prefix = '#-']> Same restrictions as parameter C<$wg_meta_prefix>

=item *

C<[$no_checksum = FALSE]> If set to true, no header checksum is calculated and added to the output

=back

B<Returns>

A string, ready to be written down as a config file.

=cut
sub create_wg_config2($ref_interface_config, $wg_meta_prefix = '#+', $disabled_prefix = '#-', $no_checksum = 0) {
    my $new_config = "";

    for my $identifier (@{$ref_interface_config->{INTERNAL_KEY_PREFIX . 'section_order'}}) {
        if (not ref($ref_interface_config->{$identifier}) eq 'HASH') {
            # We are in root section
            $new_config .= _write_line($identifier, $ref_interface_config->{$identifier}, '', $wg_meta_prefix);
        }
        else {
            # First lets check if the following section is active
            my $is_disabled = (exists $ref_interface_config->{$identifier}{'disabled'}
                and $ref_interface_config->{$identifier}{'disabled'} == 1) ? $disabled_prefix : '';

            # Add [Interface] or [Peer]
            $new_config .= "\n$is_disabled" . "[$ref_interface_config->{$identifier}{INTERNAL_KEY_PREFIX . 'type'}]\n";

            # Add config lines
            for my $attr_name (@{$ref_interface_config->{$identifier}{INTERNAL_KEY_PREFIX . 'order'}}) {

                my $is_wg_meta = (exists $ref_interface_config->{INTERNAL_KEY_PREFIX .'observed_wg_meta_attrs'}{$attr_name}) ? $wg_meta_prefix : '';
                $new_config .= _write_line($attr_name, $ref_interface_config->{$identifier}{$attr_name}, $is_disabled, $is_wg_meta);
            }
        }
    }
    if ($no_checksum == 0) {
        return "#+Checksum = " . compute_md5_checksum($new_config) . "\n" . $new_config;
    }
    return $new_config;
}

# internal method to create on config line
sub _write_line($attr_name, $attr_value, $is_disabled, $is_wg_meta) {
    my $cfg_line = '';
    # if we have a comment
    if (substr($attr_name, 0, 7) eq 'comment') {
        $cfg_line .= $attr_value . "\n";
    }
    else {
        my $inconfig_name = exists KNOWN_ATTRIBUTES->{$attr_name} ? KNOWN_ATTRIBUTES->{$attr_name}{in_config_name} : $attr_name;
        $cfg_line .= "$is_disabled$is_wg_meta$inconfig_name = $attr_value\n";
    }
    return $cfg_line;
}


1;