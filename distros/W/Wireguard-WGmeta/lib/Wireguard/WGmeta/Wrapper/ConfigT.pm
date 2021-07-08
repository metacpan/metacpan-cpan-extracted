=pod

=head1 NAME

WGmeta::Wrapper::ConfigT - Class for interfacing the wireguard configuration supporting concurrent access

=head1 DESCRIPTION

Specialized child class of L<Wireguard::WGmeta::Wrapper::Config> which is capable of handling concurrent access.

=head1 SYNOPSIS

The interface is almost identical with the exception
of L</commit([$is_hot_config = FALSE, $plain = FALSE, $ref_hash_integrity_keys = undef])>

 use Wireguard::WGmeta::Wrapper::ConfigT;
 my $wg_metaT = Wireguard::WGmeta::Wrapper::ConfigT->new('<path to wireguard configuration>');

=head1 CONCURRENCY

To ensure that no inconsistent config files are generated, calls to a C<get_*()> may result in a reload from disk - namely
when the config file on disk is newer than the current (parsed) one. So keep in mind to C<commit()> as soon as possible
(this is obviously only true for environments where such situations are possible to occur)

 # thread/process A
 $wg_metaT->set('wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'alias', 'A');

 # thread/process B
 $wg_metaT->set('wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'alias', 'B');
 $wg_metaT->commit(1);

 # thread/process A (alias 'A' is overwritten by 'B')
 wg_metaT->disable_by_alias('wg0', 'A'); # throws exception `invalid alias`!

For more details about the reloading behaviour please refer to L</may_reload_from_disk([$interface = undef])>.

B<Commit behaviour>

	FUNCTION commit($integrity_hashes)
		FOR $interface IN $known_interfaces
		    IF has_changed($interface) THEN
                lock_exclusive($interface)
                UNLESS my_config_is_latest THEN
                    $on_disk <- read_from_disk($interface)
                $contents <- create_wg_config($interface, $on_disk,$integrity_hashes)
                write($contents)

	FUNCTION create_wg_config($interface, $on_disk, $integrity_hashes);
		$may_conflicting <- search_for_common_data($interface, $on_disk)
		FOR $section IN $may_conflicting
			$sha_internal <- calculate_sha_from_internal()
			$sha_disk <- calculate_sha_from_disk()
			IF $sha_internal NE $sha_disk
				IF $sha_disk EQ $integrity_hashes[$section]
					$section_data <- take_from_internal()
				ELSE
					$section_data <- take_from_disk()
			ELSE
				$section_data <- take_from_disk()
			$config_content .= create_section($section_data)
		$config_content .= create_non_conflicting()
		return $config_content

=head1 EXAMPLES

 use Wireguard::WGmeta::Wrapper::ConfigT;

 # thread A
 my $wg_metaT = Wireguard::WGmeta::Wrapper::ConfigT->new('<path to wireguard configuration>');
 $wg_metaT->set('wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'name', 'set_in_thread_A');
 # Assumption: Our internal version is equal with the on-disk version at this point
 my $integrity_hash = $wg_metaT->calculate_sha_from_internal();

 # thread B
 my $wg_metaT = Wireguard::WGmeta::Wrapper::ConfigT->new('<path to wireguard configuration>');
 $wg_metaT->set('wg0', 'AN_OTHER_PUBLIC_KEY', 'name', 'set_in_thread_B');
 $wg_metaT->commit(1); # works fine (internal & on_disk have same version)

 # thread A (non conflicting changes -> same file, different section)
 $wg_metaT->commit(1); # "Your changes for `WG_0_PEER_A_PUBLIC_KEY` were not applied"
 $wg_metaT->commit(1, 0, {'WG_0_PEER_A_PUBLIC_KEY' => $integrity_hash}); # works fine -> non conflicting changes

 # Reload callbacks
 sub my_reload_callback($interface, $ref_list_args){
    my @args = @{$ref_list_args};
    print "$interface, reloaded and $args[0]!";
 }

 # register our callback handler
 $wg_metaT->register_on_reload_listener(\&my_reload_callback, 'handler_id', [ 'hello from listener' ]);

 # Everytime an interface is reloaded, our handler is called until we uninstall our handler
 $wg_metaT->remove_on_reload_listener('handler_id');

=head1 METHODS

=cut

package Wireguard::WGmeta::Wrapper::ConfigT;
use strict;
use warnings FATAL => 'all';
use Digest::SHA qw(sha1_hex);
use Fcntl qw(:flock);
use File::Basename;
use experimental 'signatures';

use Wireguard::WGmeta::Wrapper::Config;
use Wireguard::WGmeta::Parser::Middleware;
use Wireguard::WGmeta::Parser::Conf qw(INTERNAL_KEY_PREFIX);
use Wireguard::WGmeta::ValidAttributes;
use Wireguard::WGmeta::Utils;

use parent 'Wireguard::WGmeta::Wrapper::Config';

use constant FALSE => 0;
use constant TRUE => 1;
use constant INTEGRITY_HASH_SALT => 'wefnwioefh9032ur3';

our $VERSION = "0.3.1"; # do not change manually, this variable is updated when calling make

=head3 is_valid_interface($interface)

L<Wireguard::WGmeta::Wrapper::Config/is_valid_interface($interface)>

=cut
sub is_valid_interface($self, $interface) {
    $self->_sync_interfaces();
    return $self->SUPER::is_valid_interface($interface);
}


sub is_valid_alias($self, $interface, $alias) {
    $self->may_reload_from_disk($interface);
    return $self->SUPER::is_valid_alias($interface, $alias);
}

=head3 is_valid_identifier($interface, $identifier)

L<Wireguard::WGmeta::Wrapper::Config/is_valid_identifier($interface, $identifier)>

=cut
sub is_valid_identifier($self, $interface, $identifier) {
    $self->may_reload_from_disk($interface);
    return $self->SUPER::is_valid_identifier($interface, $identifier);
}

=head3 try_translate_alias($interface, $may_alias)

L<Wireguard::WGmeta::Wrapper::Config/try_translate_alias($interface, $may_alias)>

=cut
sub try_translate_alias($self, $interface, $may_alias) {
    $self->may_reload_from_disk($interface);
    return $self->SUPER::try_translate_alias($interface, $may_alias);
}

=head3 get_interface_section($interface, $identifier)

L<Wireguard::WGmeta::Wrapper::Config/get_interface_section($interface, $identifier)>

=cut
sub get_interface_section($self, $interface, $identifier) {
    $self->may_reload_from_disk($interface);
    if (exists $self->{parsed_config}{$interface}{$identifier}) {
        my %r = %{$self->{parsed_config}{$interface}{$identifier}};
        return %r;
    }
    else {
        return ();
    }
}

=head3 get_section_list($interface)

L<Wireguard::WGmeta::Wrapper::Config/get_section_list($interface)>

=cut
sub get_section_list($self, $interface) {
    $self->may_reload_from_disk($interface);
    return $self->SUPER::get_section_list($interface);
}

=head3 get_peer_count([$interface])

L<Wireguard::WGmeta::Wrapper::Config/get_peer_count([$interface = undef])>

=cut
sub get_peer_count($self, $interface = undef) {
    $self->may_reload_from_disk($interface);
    return $self->SUPER::get_peer_count($interface);
}

sub _get_all_conf_files($wireguard_home) {
    my @config_files = read_dir($wireguard_home, qr/.*\.conf$/);
    if (@config_files == 0) {
        die "No matching interface configuration(s) in " . $wireguard_home;
    }
    my $count = @config_files;
    return \@config_files, $count;
}

=head3 get_interface_list()

L<Wireguard::WGmeta::Wrapper::Config/get_interface_list()>

=cut
sub get_interface_list($self) {
    $self->_sync_interfaces();
    # $self->may_reload_from_disk();
    return sort keys %{$self->{parsed_config}};
}

=head3 commit([$is_hot_config = FALSE, $plain = FALSE, $ref_hash_integrity_keys = undef])

Writes down the parsed config to the wireguard configuration folder.

B<Parameters>

=over 1

=item

C<[$is_hot_config = FALSE])> If set to TRUE, the existing configuration is overwritten. Otherwise,
the suffix '_not_applied' is appended to the filename

=item

C<[$plain = FALSE])> If set to TRUE, no header is generated

=item

C<[$ref_hash_integrity_keys = undef])> Reference to a hash of integrity keys. Expected structure:

    {
        <identifier1> => 'integrity_hash_of_corresponding_section',
        <identifier2> => 'integrity_hash_of_corresponding_section'
    }

For a more detailed explanation when this information is needed please refer to L</CONCURRENCY>.

=back

B<Raises>

Exception if: Folder or file is not writeable

B<Returns>

None

=cut
sub commit($self, $is_hot_config = FALSE, $plain = FALSE, $ref_hash_integrity_keys = undef) {
    for my $interface_name (keys %{$self->{parsed_config}}) {
        if ($self->_has_changed($interface_name)) {
            my $file_name;
            if ($is_hot_config == TRUE) {
                $file_name = $self->{wireguard_home} . $interface_name . '.conf';
                $self->{parsed_config}->{$interface_name}{is_hot_config} = 1;
            }
            else {
                $file_name = $self->{wireguard_home} . $interface_name . $self->{not_applied_suffix};
                $self->{parsed_config}->{$interface_name}{is_hot_config} = 0;
            }
            my $on_disk_config = undef;
            my $is_new = undef;

            # --- From here we lock the affected configuration file exclusively ----
            my $fh;
            # check if interface exists - if not, we have a new interface
            if (-e $file_name) {

                # in this case open the file for RW
                open $fh, '+<', $file_name or die "Could not open $file_name: $!";
                flock $fh, LOCK_EX;
                my $config_contents = read_file($fh, TRUE);
                $on_disk_config = parse_wg_config2($config_contents, $interface_name, $self->{wg_meta_prefix}, $self->{wg_meta_disabled_prefix});
                seek $fh, 0, 0;
            }
            else {
                open $fh, '>', $file_name;
                flock $fh, LOCK_EX;
                $is_new = 1;
            }

            $self->_sync_changes(
                $interface_name,
                $on_disk_config,
                $ref_hash_integrity_keys
            );
            # write down to file
            truncate $fh, 0;
            print $fh create_wg_config2($self->{parsed_config}{$interface_name});
            $self->{parsed_config}{$interface_name}{mtime} = get_mtime($file_name);
            $self->{n_conf_files}++ if (defined $is_new);
            $self->_reset_changed($interface_name);
            # Notify listeners about a file change
            $self->_call_reload_listeners($interface_name);
            close $fh;
        }
    }
}

sub _sync_changes($self, $interface, $ref_on_disk_config = undef, $ref_hash_integrity_keys = undef) {

    # first, we look for sections which are common (disk and internal), then we search for exclusive ones
    my @may_conflict;
    my @exclusive_disk;
    my @exclusive_internal;
    if (defined $ref_on_disk_config) {
        for my $identifier_internal (@{$self->{parsed_config}{$interface}{INTERNAL_KEY_PREFIX . 'section_order'}}) {
            if (exists $ref_on_disk_config->{$identifier_internal}) {
                push @may_conflict, $identifier_internal;
            }
            else {
                push @exclusive_internal, $identifier_internal;
            }
        }
        for my $identifier_ondisk (@{$ref_on_disk_config->{INTERNAL_KEY_PREFIX . 'section_order'}}) {
            unless (exists $self->{parsed_config}{$interface}{$identifier_ondisk}) {
                # if we have the latest data, we can safely assume the peer has been deleted
                if (!$self->_is_latest_data($interface)) {
                    push @exclusive_disk, $identifier_ondisk;
                }
            }
        }
    }
    else {
        # if no on-disk reference is provided all sections are considered as exclusive internal
        @exclusive_internal = @{$self->{parsed_config}{$interface}{INTERNAL_KEY_PREFIX . 'section_order'}};
    }

    for my $identifier (@may_conflict) {
        # if the shas differ, the configuration on disk had been changed in the mean time
        my $on_disk_sha = _calculate_sha1_from_section($ref_on_disk_config->{$identifier});
        my $internal_sha = _calculate_sha1_from_section($self->{parsed_config}{$interface}{$identifier});

        # if the shas differ, it means that the we either have not the most recent data or the on-disk version has been changed in the meantime.
        if ($on_disk_sha ne $internal_sha) {

            # we may have a integrity hash from this section which allows us to modify
            if (defined $ref_hash_integrity_keys && exists $ref_hash_integrity_keys->{$identifier}) {

                # if the on-disk sha differs from our integrity hash, this section has been changed by an other process or user.
                if ($on_disk_sha ne $ref_hash_integrity_keys->{$identifier}) {
                    die "your changes for `$identifier` were not applied";
                }
            }
            else {
                # take from disk (we have no integrity key for this section)
                $self->{parsed_config}{$interface}{$identifier} = $ref_on_disk_config->{$identifier};
            }
        }
        else {
            # take from disk
            #$self->{parsed_config}{$identifier} = $ref_on_disk_config->{$identifier};
        }

    }
    # exclusive mode
    for my $key (@exclusive_disk) {
        $self->{parsed_config}{$interface}{$key} = $ref_on_disk_config->{$key};
        push @{$self->{parsed_config}{$interface}{INTERNAL_KEY_PREFIX . 'section_order'}}, $key;
    }
}


=head3 may_reload_from_disk([$interface = undef])

This method is called before any data is returned from one of the C<get_*()> methods. It behaves as follows:

=over 1

=item *

If the interface is not defined, it loops through the known interfaces and reloads them individually (if needed).

=item *

If the interface is defined (and known), the modify timestamps are compared an if the on-disk version is newer, a reload is triggered.

=item *

If the interface is defined (but not known -> this could be the case if a new interface has been added), first we check if there is
actually a matching config file on disk and if yes, its loaded and parsed from disk.

=back

Remark: This method is not meant for public access, there is just this extensive documentation block since its behaviour
is crucial to the function of this class.

B<Parameters>

=over 1

=item

C<$interface> A (possibly) invalid (or new) interface name

=back

B<Returns>

None

=cut
# sub may_reload_from_disk($self, $interface = undef) {
#     unless (defined $interface) {
#         for my $known_interface (keys %{$self->{parsed_config}}) {
#             # my $s = $self->_get_my_mtime($known_interface);
#             # my $t = get_mtime($self->{parsed_config}{$known_interface}{config_path});
#             if ($self->_get_my_mtime($known_interface) < get_mtime($self->{parsed_config}{$known_interface}{config_path})) {
#                 $self->may_reload_from_disk($known_interface);
#             }
#         }
#     }
#     elsif (exists $self->{parsed_config}{$interface}) {
#         # my $s = $self->_get_my_mtime($interface);
#         # my $t = get_mtime($self->{parsed_config}{$interface}{config_path});
#         if ($self->_get_my_mtime($interface) < get_mtime($self->{parsed_config}{$interface}{config_path})) {
#             $self->may_reload_from_disk($interface);
#         }
#     }
#     else {
#         # we may have a new interface added in the meantime so we probe if there is actually a config file first
#         if (-e $self->{wireguard_home} . $interface . '.conf') {
#             $self->may_reload_from_disk($interface, TRUE);
#         }
#     }
#
# }

sub _get_my_mtime($self, $interface) {
    if (exists $self->{parsed_config}{$interface}) {
        return $self->{parsed_config}{$interface}{INTERNAL_KEY_PREFIX. 'mtime'};
    }
    else {
        return 0;
    }
}

sub _is_latest_data($self, $interface) {
    my $hot_path = $self->{wireguard_home} . $interface . ".conf";
    my $safe_path = $self->{wireguard_home} . $interface . $self->{not_applied_suffix};
    if (-e $safe_path) {
        return $self->_get_my_mtime($interface) ge get_mtime($hot_path) || $self->_get_my_mtime($interface) ge get_mtime($safe_path);
    }
    # my $t = $self->_get_my_mtime($interface);
    # my $s = get_mtime($conf_path);
    return $self->_get_my_mtime($interface) ge get_mtime($hot_path);
}

sub _sync_interfaces($self) {
    # check if there's maybe a new interface by comparing the file counts
    my ($conf_files, $count) = _get_all_conf_files($self->{wireguard_home});
    if ($self->{n_conf_files} != $count) {
        for my $conf_path (@{$conf_files}) {
            # read interface name
            my $i_name = basename($conf_path);
            $i_name =~ s/\.conf$//;
            unless (exists $self->{parsed_config}{$i_name}) {
                $self->may_reload_from_disk($i_name, TRUE);
            }
        }
    }
    # scan for deleted interfaces
    for my $internal_interface (keys %{$self->{parsed_config}}) {
        if (not -e $self->{parsed_config}{$internal_interface}{INTERNAL_KEY_PREFIX. 'config_path'}) {
            warn "Interface `$internal_interface` has been deleted in the meantime" if $self->_has_changed($internal_interface);
            delete $self->{parsed_config}{$internal_interface};
        }
    }
}
sub _calculate_sha1_from_section($ref_to_hash) {
    my %h = %{$ref_to_hash};
    return sha1_hex INTEGRITY_HASH_SALT . join '', map {$h{$_}} @{$ref_to_hash->{INTERNAL_KEY_PREFIX . 'order'}};
}

=head3 calculate_sha_from_internal($interface, $identifier)

Calculates the sha1 from a section (already parsed).

B<Caveat>

It is possible that this method does not return the most recent, on-disk version of this section! It returns your current
parsed state! This method does NOT trigger a C<may_reload_from_disk()>!

B<Parameters>

=over 1

=item

C<$interface> A valid interface name

=item

C<$identifier> A valid identifier for this interface

=back

B<Returns>

The sha1 (in HEX) the requested section

=cut
sub calculate_sha_from_internal($self, $interface, $identifier) {
    if (exists $self->{parsed_config}{$interface} && exists $self->{parsed_config}{$interface}{$identifier}) {
        return _calculate_sha1_from_section($self->{parsed_config}{$interface}{$identifier});
    }
    else {
        die "Invalid interface `$interface` or section `$identifier`";
    }

}

1;