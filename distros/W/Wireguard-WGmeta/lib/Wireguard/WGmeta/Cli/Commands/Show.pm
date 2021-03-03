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
use Wireguard::WGmeta::ValidAttributes;

use constant TRUE => 1;
use constant FALSE => 0;

sub new($class, @input_arguments) {
    my $self = $class->SUPER::new(@input_arguments);

    # list of attributes shown in output. Prefix attributes originating from `wg-show` using `#S#`.
    my @attr_list = (
        'name',
        'alias',
        'public-key',
        'allowed-ips',
        '#S#endpoint',
        '#S#latest-handshake',
        '#S#transfer-rx',
        '#S#transfer-tx',
        'disabled'
    );

    # register attribute converters here (no special prefix needed)
    my %attr_converters = (
        'latest-handshake' => \&timestamp2human,
        'transfer-rx'      => \&bits2human,
        'transfer-tx'      => \&bits2human
    );

    $self->{'attr_converters'} = \%attr_converters;
    $self->{'attr_list'} = \@attr_list;

    bless $self, $class;
    return $self;
}

sub entry_point($self) {
    $self->check_privileges();

    # set defaults
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
    if (exists $self->{interface} && !$wg_meta->is_valid_interface($self->{interface})) {
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
        print BOLD . "  ListenPort: " . RESET . $interface{'listen-port'} . "\n";
        #print BOLD . "  Address: " . RESET . $interface{'address'} . "\n";
        print BOLD . "  FQDN: " . RESET . $wg_meta->get_interface_fqdn($iface) . "\n";
        # try to derive iface public key from privatekey
        my $iface_pubkey = do {
            local $@;
            eval {
                get_pub_key($interface{'private-key'})
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
                $self->_print_section(\%interface_section, \%show_section);
                $output .= "\n";
            }
        }
    }
}

sub _print_section($self, $ref_config_section, $ref_show_section) {
    #Disabled state
    if (exists $ref_config_section->{disabled}) {
        if ($ref_config_section->{disabled} == 1) {
            print BOLD . RED . '-' . RESET;
        }
        else {
            print BOLD . GREEN . '+' . RESET;
        }
    }
    else {
        print BOLD . GREEN . '+' . RESET;
    }
    print BOLD . 'peer:' . RESET . " $ref_config_section->{'public-key'}\n";
    for my $attr (@{$self->{attr_list}}) {
        my $attr_copy = $attr;
        if ($attr_copy !~ s/^\#S\#//g) {
            my $attr_type = decide_attr_type($attr_copy);
            # exclude PublicKey and Disabled attrs
            unless ($attr_copy eq 'public-key' or $attr_copy eq 'disabled') {
                if (defined($ref_config_section) && exists $ref_config_section->{$attr_copy}) {
                    my $cleaned_attr = get_attr_config($attr_type)->{$attr_copy}{in_config_name};
                    print "  " . BOLD . $cleaned_attr . ": " . RESET . $ref_config_section->{$attr_copy} . "\n";
                }
            }
        }
        else {
            # wg_show
            if (defined($ref_show_section) && exists $ref_show_section->{$attr_copy}) {
                my $cleaned_attr = $ref_show_section->{$attr_copy};

                # check if a converter function is defined
                if (exists $self->{attr_converters}{$attr_copy}) {
                    $cleaned_attr = $self->{attr_converters}{$attr_copy}($cleaned_attr);
                }
                if ($ref_show_section->{$attr_copy} ne '(none)') {
                    print "  " . BOLD . $attr_copy . ": " . RESET . $cleaned_attr;
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
