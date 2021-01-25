package Wireguard::WGmeta::Cli::Commands::Show;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use parent 'Wireguard::WGmeta::Cli::Commands::Command';

use Wireguard::WGmeta::Cli::Human;
use Wireguard::WGmeta::Cli::TerminalHelpers;
use Wireguard::WGmeta::Wrapper::Config;
use Wireguard::WGmeta::Wrapper::Show;
use Wireguard::WGmeta::Wrapper::Bridge;
use Wireguard::WGmeta::Utils;

use constant TRUE => 1;
use constant FALSE => 0;
use constant WG_CONFIG => 1;
use constant WG_SHOW => 2;
use constant NA_PLACEHOLDER => '#na';



sub entry_point($self) {
    # set defaults
    $self->check_privileges();
    $self->{human_readable} = TRUE;
    $self->{wg_meta_prefix} = '#+';

    my $len = @{$self->{input_args}};

    if ($len > 0) {
        if ($self->_retrieve_or_die($self->{input_args}, 0) eq 'help') {
            $self->cmd_help();
            return
        }
        if ($self->_retrieve_or_die($self->{input_args}, -1) eq 'dump') {
            $self->{human_readable} = FALSE;
            if ($len == 2) {
                $self->{interface} = $self->_retrieve_or_die($self->{input_args}, 0)
            }
            $self->_run_command();
        }
        $self->{interface} = $self->_retrieve_or_die($self->{input_args}, 0)
    }
    $self->_run_command();
}

sub _run_command($self) {
    my $wg_meta = Wireguard::WGmeta::Wrapper::Config->new($self->{wireguard_home});
    if (exists $self->{interface} && !$wg_meta->_is_valid_interface($self->{interface})) {
        die "Invalid interface `$self->{interface}`";
    }
    my $out;
    if (defined $ENV{IS_TESTING}) {
        use FindBin;
        $out = read_file($FindBin::Bin . '/../t/test_data/wg_show_dump');
    }
    else {
        my @std_out = run_external('wg show all dump');
        $out = join '', @std_out;
    }
    my $wg_show = Wireguard::WGmeta::Wrapper::Show->new($out);

    my $spacer = "\t";
    if ($self->{human_readable} == TRUE) {
        $spacer = "";
    }

    # the individual attributes are configured here
    my $attrs = {
        $self->{wg_meta_prefix} . 'Name'     => {
            human_readable => \&return_self,
            dest           => WG_CONFIG,
            compact        => 'NAME',
            len            => 15,
        },
        $self->{wg_meta_prefix} . 'Alias'    => {
            human_readable => \&return_self,
            dest           => WG_CONFIG,
            compact        => 'ALIAS',
            len            => 12
        },
        'PublicKey'                          => {
            human_readable => \&return_self,
            dest           => WG_CONFIG,
            compact        => 'PUBKEY',
            len            => 45
        },
        'endpoint'                           => {
            human_readable => \&return_self,
            dest           => WG_SHOW,
            compact        => 'ENDPOINT',
            len            => 23
        },
        'AllowedIPs'                         => {
            human_readable => \&return_self,
            dest           => WG_CONFIG,
            compact        => 'IPS',
            len            => 30
        },
        'latest-handshake'                   => {
            human_readable => \&timestamp2human,
            dest           => WG_SHOW,
            compact        => 'L-HANDS',
            len            => 13
        },
        'transfer-rx'                        => {
            human_readable => \&bits2human,
            dest           => WG_SHOW,
            compact        => 'RX',
            len            => 12
        },
        'transfer-tx'                        => {
            human_readable => \&bits2human,
            dest           => WG_SHOW,
            compact        => 'TX',
            len            => 12
        },
        $self->{wg_meta_prefix} . 'Disabled' => {
            human_readable => \&disabled2human,
            dest           => WG_CONFIG,
            compact        => 'ACTIVE',
            len            => 6
        }
    };

    # this list defines a) the order of the attrs and b) which one are actually displayed
    my @attr_list = (
        $self->{wg_meta_prefix} . 'Name',
        $self->{wg_meta_prefix} . 'Alias',
        'PublicKey',
        'AllowedIPs',
        'endpoint',
        'latest-handshake',
        'transfer-rx',
        'transfer-tx',
        $self->{wg_meta_prefix} . 'Disabled'
    );

    # There is maybe better way to solve this:
    # Requirements: The solution shouldn't be dependent on external modules, should preserve order and provide a mapping
    # from where the value is sourced

    # the config files are our reference, otherwise we would miss inactive peers

    my $output = '';
    my @interface_list;
    if (defined($self->{interface})) {
        @interface_list = ($self->{interface});
    }
    else {
        @interface_list = $wg_meta->get_interface_list()
    }

    for my $iface (sort @interface_list) {
        # interface "header"
        print BOLD . "interface: " . RESET . $iface . "\n";
        my %interface = $wg_meta->get_interface_section($iface, $iface);
        # Print Interface state
        print BOLD . "  State: " . RESET . (($wg_show->iface_exists($iface)) ? GREEN . "UP" : RED . "DOWN") . RESET . "\n";
        print BOLD . "  ListenPort: " . RESET . $interface{'ListenPort'} . "\n";
        # try to derive iface public key from privatekey
        my $iface_pubkey = do {
            local $@;
            eval {
                get_pub_key($interface{PrivateKey})
            } or "could_not_derive_publickey_from_privatekey"
        };
        print BOLD . "  PublicKey: " . RESET . $iface_pubkey . "\n\n";

        # Attribute values
        for my $identifier ($wg_meta->get_section_list($iface)) {
            my %interface_section = $wg_meta->get_interface_section($iface, $identifier);
            unless (%interface_section) {
                die "Interface `$iface` does not exist";
            }

            # skip if type interface
            if ($interface_section{type} eq 'Peer') {
                my %show_section = $wg_show->get_interface_section($iface, $identifier);
                $self->_print_section(\%interface_section, \%show_section, $attrs, \@attr_list);
                $output .= "\n";
            }
        }
    }
}

sub _print_section($self, $ref_config_section, $ref_show_section, $ref_attrs, $ref_attr_list) {
    #Disabled state
    if (exists $ref_config_section->{$self->{wg_meta_prefix} . 'Disabled'}) {
        if ($ref_config_section->{$self->{wg_meta_prefix} . 'Disabled'} == 1) {
            print BOLD . RED . '-' . RESET;
        }
        else {
            print BOLD . GREEN . '+' . RESET;
        }
    }
    else {
        print BOLD . GREEN . '+' . RESET;
    }
    print BOLD . 'peer:' . RESET . " $ref_config_section->{PublicKey}\n";
    for my $attr (@{$ref_attr_list}) {
        if ($ref_attrs->{$attr}{dest} == WG_CONFIG) {
            # exclude PublicKey and Disabled attrs
            unless ($attr eq 'PublicKey' or $attr eq $self->{wg_meta_prefix} . 'Disabled') {
                if (defined($ref_config_section) && exists $ref_config_section->{$attr}) {
                    # remove possible wg-meta prefix
                    my $cleaned_attr = $attr;
                    $cleaned_attr =~ s/\#\+//;
                    print "  " . BOLD . $cleaned_attr . ": " . RESET . $ref_config_section->{$attr} . "\n";
                }
            }
        }
        else {
            # wg_show
            if (defined($ref_show_section) && exists $ref_show_section->{$attr}) {
                if ($ref_show_section->{$attr} ne '(none)') {
                    print "  " . BOLD . $attr . ": " . RESET . $ref_attrs->{$attr}->{human_readable}($ref_show_section->{$attr});
                }
            }
        }
    }
    print "\n\n";
}

sub cmd_help($self) {
    print "Usage: wg-meta show {interface} \n"
}

1;
