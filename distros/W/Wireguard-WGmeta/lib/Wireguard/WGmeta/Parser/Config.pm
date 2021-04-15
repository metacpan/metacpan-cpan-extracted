=pod

=head1 NAME

WGmeta::Parser::Config - Parser for wireguard configuration files.

=head1 SYNOPSIS

 use Wireguard::WGmeta::Parser::Config;

 my $content = `cat '<path_to_wireguard_conf_file')`;
 my $hash_parsed_configs = parse_wg_config($content, '<interface_name>', '#+', '#-');

 # and similarly to transform the parsed config into a wireguard compatible format again
 my $interface_config = create_wg_config($hash_parsed_configs->{<interface_name>}, '#+', '#-')

=head1 DESCRIPTION

Parser for wireguard configuration files supporting optional wg-meta attributes.

=head1 METHODS

=cut
use v5.20.0;

package Wireguard::WGmeta::Parser::Config;
use strict;
use warnings FATAL => 'all';

use experimental 'signatures';

use Wireguard::WGmeta::ValidAttributes;
use Wireguard::WGmeta::Utils;

use base 'Exporter';
our @EXPORT = qw(parse_wg_config create_wg_config);

our $VERSION = "0.2.3"; # do not change manually, this variable is updated when calling make

use constant FALSE => 0;
use constant TRUE => 1;

# constants for states of the config parser
use constant IS_EMPTY => -1;
use constant IS_COMMENT => 0;
use constant IS_SECTION => 2;
use constant IS_NORMAL => 3;

=head3 parse_wg_config($config_file_content, $interface_name, $wg_meta_prefix, $disabled_prefix [, $use_checksum])

Parses the contents of C<$config_file_content> and returns a hash with the following structure:

    {
        'interface_name' => {
            'section_order' => <list_of_available_section_identifiers>,
            'alias_map'     => <mapping_alias_to_identifier>,
            'checksum'      => <calculated_checksum_of_this_interface_config>,
            'n_peers'       => <number_of_peers_for_this_interface>,
            'interface_name' => <interface_name>,
            'a_identifier'    => {
                'type'  => <'Interface' or 'Peer'>,
                'order' => <list_of_attributes_in_their_original_order>,
                'attr0' => <value_of_attr0>,
                'attrN' => <value_of_attrN>
            },
            'an_other_identifier => {
                [...]
            }
        }
    }

B<Remarks>

=over 1

=item *

All attributes listed in L<Wireguard::WGmeta::ValidAttributes> are referenced by their key. This means, if you want for
example access I<PublicKey> the key would be I<public-key>. Any attribute not present in L<Wireguard::WGmeta::ValidAttributes>
is stored (and written back) as they appear in Config.

=item *
This method can be used as stand-alone together with the corresponding L</create_wg_config($ref_interface_config, $wg_meta_prefix, $disabled_prefix [, $plain = FALSE])>.

=item *

If the section is of type 'Peer' the identifier equals to its public-key, otherwise its the interface name again.

=item *

wg-meta attributes are always prefixed with C<$wg_meta_prefix>.

=item *

If a section is marked as "disabled", this is represented in the attribute I<$wg_meta_prefix. 'Disabled' >.
However, does only exist if this section has been enabled/disabled once.

=item *

To check whether a file is actually a Wireguard interface config, the parser first checks the presence of the string
I<[Interface]>. If not present, the file is skipped (without warning!). And in this case the parser returns undefined!

=back

B<Parameters>

=over 1

=item *

C<$config_file_content> String containing the contents of a Wireguard configuration file.

=item *

C<$interface_name> Interface name

=item *

C<$wg_meta_prefix> wg-meta prefix. Must start with '#' or ';'

=item *

C<$disabled_prefix> disabled prefix. Must start with '#' or ';'

=item *

C<[$use_checksum = TRUE]> If set to False, checksum is not checked


=back

B<Raises>

An exceptions if:

=over 1

=item *

If the parser ends up in an invalid state (e.g a section without information).

=back

A warning:

=over 1

=item *

On a checksum mismatch

=back

B<Returns>

A reference to a hash with the structure described above. Or if the configuration file is not a Wireguard configuration: undef.

=cut
sub parse_wg_config($config_file_content, $interface_name, $wg_meta_prefix, $disabled_prefix, $use_checksum = TRUE) {
    my $regex_friendly_meta_prefix = quotemeta $wg_meta_prefix;

    my $parsed_wg_config = {};

    return undef unless ($config_file_content =~ /\[Interface\]/);

    my %alias_map;
    my $current_state = -1;
    my $peer_count = 0;

    # state variables
    my $STATE_INIT_DONE = FALSE;
    my $STATE_READ_SECTION = FALSE;
    my $STATE_READ_ID = FALSE;
    my $STATE_EMPTY_SECTION = TRUE;
    my $STATE_READ_ALIAS = FALSE;

    # data of current section
    my $section_type;
    my $is_disabled = FALSE;
    my $comment_counter = 0;
    my $identifier;
    my $alias;
    my $section_data = {};
    my $checksum = '';
    my @section_data_order;
    my @section_order;

    for my $line (split "\n", $config_file_content) {
        $current_state = _decide_state($line, $wg_meta_prefix, $disabled_prefix);

        # remove disabled prefix if any
        $line =~ s/^$disabled_prefix//g;

        if ($current_state == IS_EMPTY) {
            # empty line
        }
        elsif ($current_state == IS_SECTION) {
            # strip-off [] and whitespaces
            $line =~ s/^\[|\]\s*$//g;
            if (_is_valid_section($line)) {
                if ($STATE_EMPTY_SECTION == TRUE && $STATE_INIT_DONE == TRUE) {
                    die 'Found empty section, aborting';
                }
                else {
                    $STATE_READ_SECTION = TRUE;

                    if ($STATE_INIT_DONE == TRUE) {
                        # we are at the end of a section and therefore we can store the data

                        # first check if we read an private or public-key
                        if ($STATE_READ_ID == FALSE) {
                            die 'Section without identifying information found (Private -or PublicKey field)'
                        }
                        else {
                            $STATE_READ_ID = FALSE;
                            $STATE_EMPTY_SECTION = TRUE;
                            $parsed_wg_config->{$identifier} = $section_data;
                            $parsed_wg_config->{$identifier}{type} = $section_type;

                            # update peer count if we have type [Peer]
                            $peer_count++ if ($section_type eq 'Peer');

                            # we have to use a copy of the array here - otherwise the reference stays the same in all sections.
                            $parsed_wg_config->{$identifier}{order} = [ @section_data_order ];
                            push @section_order, $identifier;

                            # reset vars
                            $section_data = {};
                            $is_disabled = FALSE;
                            @section_data_order = ();
                            $section_type = $line;
                            if ($STATE_READ_ALIAS == TRUE) {
                                $alias_map{$alias} = $identifier;
                                $STATE_READ_ALIAS = FALSE;
                            }
                        }
                    }
                    $section_type = $line;
                    $STATE_INIT_DONE = TRUE;
                }
            }
            else {
                die "Invalid section found: $line";
            }
        }
        # skip comments before sections -> we replace these with our header anyways...
        elsif ($current_state == IS_COMMENT) {
            unless ($STATE_INIT_DONE == FALSE) {
                my $comment_id = "comment_" . $comment_counter++;
                push @section_data_order, $comment_id;

                $line =~ s/^\s+|\s+$//g;
                $section_data->{$comment_id} = $line;
            }
        }
        elsif ($current_state == ATTR_TYPE_IS_WG_META) {
            # a special wg-meta attribute
            if ($STATE_INIT_DONE == FALSE) {
                # this is already a wg-meta config and therefore we expect a checksum
                (undef, $checksum) = split_and_trim($line, "=");
            }
            else {
                if ($STATE_READ_SECTION == TRUE) {
                    $STATE_EMPTY_SECTION = FALSE;
                    my ($attr_name, $attr_value) = split_and_trim($line, "=");

                    # remove wg-meta prefix
                    $attr_name =~ s/^$regex_friendly_meta_prefix//g;
                    $attr_name = _attr_to_internal_name($attr_name);
                    if ($attr_name eq 'alias') {
                        if (exists $alias_map{$attr_value}) {
                            die "Alias '$attr_value' already exists, aborting";
                        }
                        $STATE_READ_ALIAS = TRUE;
                        $alias = $attr_value;
                    }
                    push @section_data_order, $attr_name;
                    $section_data->{$attr_name} = $attr_value;
                }
                else {
                    die 'Attribute without a section encountered, aborting';
                }
            }
        }
        else {
            # normal attribute
            if ($STATE_READ_SECTION == TRUE) {
                $STATE_EMPTY_SECTION = FALSE;
                my ($attr_name, $attr_value) = split_and_trim($line, '=');
                $attr_name = _attr_to_internal_name($attr_name);
                if (_is_identifying($attr_name)) {
                    $STATE_READ_ID = TRUE;
                    if ($section_type eq 'Interface') {
                        $identifier = $interface_name;
                    }
                    else {
                        $identifier = $attr_value;
                    }

                }
                push @section_data_order, $attr_name;
                $section_data->{$attr_name} = $attr_value;
            }
            else {
                die 'Attribute without a section encountered, aborting';
            }
        }
    }
    # store last section
    if ($STATE_READ_ID == FALSE) {
        die "Section without identifying information found (Private -or PublicKey field) in config file `$interface_name`";
    }
    else {
        $peer_count++ if ($section_type eq 'Peer');
        $parsed_wg_config->{$identifier} = $section_data;
        $parsed_wg_config->{$identifier}{type} = $section_type;
        $parsed_wg_config->{checksum} = $checksum;
        $parsed_wg_config->{section_order} = \@section_order;
        $parsed_wg_config->{alias_map} = \%alias_map;
        $parsed_wg_config->{n_peers} = $peer_count;
        $parsed_wg_config->{interface_name} = $interface_name;

        $parsed_wg_config->{$identifier}{order} = \@section_data_order;
        push @section_order, $identifier;
        if ($STATE_READ_ALIAS == TRUE) {
            $alias_map{$alias} = $identifier;
        }
    }
    # checksum
    unless ($use_checksum == FALSE) {
        my $current_hash = compute_md5_checksum(create_wg_config($parsed_wg_config, $wg_meta_prefix, $disabled_prefix, TRUE));
        if ($checksum ne '' && "$current_hash" ne $checksum) {
            warn "Config `$interface_name.conf` has been changed by an other program or user. This is just a warning.";
        }
    }

    return $parsed_wg_config;
}

# internal method to decide that current state using a line of input
sub _decide_state($line, $comment_prefix, $disabled_prefix) {
    #remove leading white space
    $line =~ s/^\s+//;
    for ($line) {
        $_ eq '' && return IS_EMPTY;
        (substr $_, 0, 1) eq '[' && return IS_SECTION;
        /^\Q${comment_prefix}/ && return ATTR_TYPE_IS_WG_META;
        /^\Q${disabled_prefix}/ && do {
            $line =~ s/^$disabled_prefix//g;
            # lets do a little bit of recursion here ;)
            return _decide_state($line, $comment_prefix, $disabled_prefix);
        };
        (substr $_, 0, 1) eq '#' && return IS_COMMENT;
        return IS_NORMAL;
    }
}

# internal method to whether a section has a valid type
sub _is_valid_section($section) {
    return {
        Peer      => 1,
        Interface => 1
    }->{$section};
}

# internal method to check if an attribute fulfills identifying properties
sub _is_identifying($attr_name) {
    return {
        'private-key' => 1,
        'public-key'  => 1
    }->{$attr_name};
}

sub _attr_to_internal_name($attr_name) {
    if (exists Wireguard::WGmeta::ValidAttributes::NAME_2_KEYS_MAPPING->{$attr_name}) {
        return Wireguard::WGmeta::ValidAttributes::NAME_2_KEYS_MAPPING->{$attr_name};
    }
    else {
        return $attr_name;
    }
}

# internal method to check if a section is disabled
sub _is_disabled($ref_parsed_config_section) {
    if (exists $ref_parsed_config_section->{disabled}) {
        return $ref_parsed_config_section->{disabled} == TRUE;
    }
    return FALSE;
}

=head3 create_wg_config($ref_interface_config, $wg_meta_prefix, $disabled_prefix [, $plain = FALSE])

Turns a reference of interface-config hash (just a single interface!) back into a wireguard config.

B<Parameters>

=over 1

=item *

C<$ref_interface_config> Reference to hash containing B<one> interface config.

=item *

C<$wg_meta_prefix> Has to start with a '#' or ';' character and is ideally the
same as in L</parse_wg_config($config_file_content, $interface_name, $wg_meta_prefix, $disabled_prefix [, $use_checksum])>

=item *

C<$wg_meta_prefix> Same restrictions as parameter C<$wg_meta_prefix>

=item *

C<[, $plain = FALSE]> If set to true, no header is added (useful for checksum calculation)

=back

B<Returns>

A string, ready to be written down as a config file.

=cut
sub create_wg_config($ref_interface_config, $wg_meta_prefix, $disabled_prefix, $plain = FALSE) {
    my $new_config = "";

    for my $identifier (@{$ref_interface_config->{section_order}}) {
        if (_is_disabled($ref_interface_config->{$identifier})) {
            $new_config .= $disabled_prefix;
        }
        # write down [section_type]
        $new_config .= "[$ref_interface_config->{$identifier}{type}]\n";
        for my $attr_name (@{$ref_interface_config->{$identifier}{order}}) {
            if (_is_disabled($ref_interface_config->{$identifier})) {
                $new_config .= $disabled_prefix;
            }
            if (substr($attr_name, 0, 7) eq 'comment') {
                $new_config .= $ref_interface_config->{$identifier}{$attr_name} . "\n";
            }
            else {
                my $attr_type = decide_attr_type($attr_name, TRUE);
                my $meta_prefix = '';
                if ($attr_type == ATTR_TYPE_IS_WG_META_CUSTOM || $attr_type == ATTR_TYPE_IS_WG_META) {
                    $meta_prefix = $wg_meta_prefix;
                }
                unless ($attr_type == ATTR_TYPE_IS_UNKNOWN) {
                    $new_config .= $meta_prefix . get_attr_config($attr_type)->{$attr_name}{in_config_name}
                        . " = " . $ref_interface_config->{$identifier}{$attr_name} . "\n";
                }
                else {
                    $new_config .= "$attr_name = $ref_interface_config->{$identifier}{$attr_name}\n";
                }

            }
        }
        $new_config .= "\n";
    }
    if ($plain == FALSE) {
        my $new_hash = compute_md5_checksum($new_config);
        my $config_header = "# This config is generated and maintained by wg-meta.\n"
            . "# It is strongly recommended to edit this config only through a supporting wg-meta\n"
            . "# implementation (e.g the wg-meta cli interface)\n"
            . "#\n"
            . "# Changes to this header are always overwritten, you can add normal comments in [Peer] and [Interface] section though.\n"
            . "#\n"
            . "# Support and issue tracker: https://github.com/sirtoobii/wg-meta\n"
            . "#+Checksum = $new_hash\n\n";

        return $config_header . $new_config;
    }
    else {
        return $new_config;
    }
}

1;