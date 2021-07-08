package Wireguard::WGmeta::Cli::Commands::Show;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use parent 'Wireguard::WGmeta::Cli::Commands::Command';
use FindBin;

use Wireguard::WGmeta::Cli::Human;
use Wireguard::WGmeta::Cli::TerminalHelpers;
use Wireguard::WGmeta::Wrapper::Config;
use Wireguard::WGmeta::Wrapper::Show;
use Wireguard::WGmeta::Wrapper::Bridge;
use Wireguard::WGmeta::Utils;
use Wireguard::WGmeta::Parser::Conf qw(INTERNAL_KEY_PREFIX);
use Wireguard::WGmeta::ValidAttributes qw(KNOWN_ATTRIBUTES);

sub new($class, @input_arguments) {
    my $self = $class->SUPER::new(@input_arguments);

    my @default_attr_list_peer = (
        'public-key',
        'preshared-key',
        'allowed-ips',
        'endpoint',
        'latest-handshake',
        'transfer-rx',
        'transfer-tx',
        'persistent-keepalive',
        'disabled',
        'alias'
    );

    my @default_attr_list_interface = (
        'private-key',
        'public-key',
        'listen-port',
        'fwmark',
        'disabled',
        'alias'
    );
    my %wg_show = (
        'endpoint'         => 1,
        'transfer-rx'      => 1,
        'transfer-tx'      => 1,
        'latest-handshake' => 1,
    );

    # register attribute converters here (no special prefix needed)
    my %attr_converters = (
        'latest-handshake' => \&timestamp2human,
        'transfer-rx'      => \&bits2human,
        'transfer-tx'      => \&bits2human
    );

    $self->{attr_converters} = \%attr_converters;
    $self->{wg_show_lookup} = \%wg_show;
    $self->{default_attr_list_peer} = \@default_attr_list_peer;
    $self->{default_attr_list_interface} = \@default_attr_list_interface;

    bless $self, $class;
    return $self;
}

sub entry_point($self) {
    $self->check_privileges();
    my $len = @{$self->{input_args}};
    my $is_dump = 0;
    my $interface = 'all';
    if ($len > 0) {
        my $first_arg = $self->_retrieve_or_die($self->{input_args}, 0);
        return $self->cmd_help() if $first_arg eq 'help';
        $is_dump = 1 if $self->_retrieve_or_die($self->{input_args}, -1) eq 'dump';
        $interface = $first_arg;
        if ($len > 1) {
            my @requested_attributes = @{$self->{input_args}}[1 .. $len - 1];
            return $self->_run_command($interface, $is_dump, \@requested_attributes);
        }
    }
    # Default case
    $self->_run_command($interface, $is_dump, undef);
}

sub _run_command($self, $interface, $is_dump, $ref_attr_list) {

    if (not $interface eq 'all' and not $self->wg_meta->is_valid_interface($interface)) {
        die "Invalid interface `$interface`";
    }
    my $out;
    if (defined $ENV{IS_TESTING}) {
        $out = read_file($FindBin::Bin . '/../t/test_data/wg_show_dump');
    }
    else {
        my @std_out = run_external('wg show all dump');
        $out = join '', @std_out;
    }
    my $wg_show = Wireguard::WGmeta::Wrapper::Show->new($out);

    my $output = '';
    my @interface_list;
    if (not $interface eq 'all') {
        @interface_list = ($interface);
    }
    else {
        @interface_list = $self->wg_meta->get_interface_list()
    }

    my $use_default = defined $ref_attr_list ? 0 : 1;
    for my $printed_interface (sort @interface_list) {
        my $interface_is_active = $wg_show->iface_exists($printed_interface);
        my $state = 0;
        for my $identifier ($self->wg_meta->get_section_list($printed_interface)) {
            my %wg_show_section = ($interface_is_active) ? $wg_show->get_interface_section($printed_interface, $identifier) : ();
            my %config_section = $self->wg_meta->get_interface_section($printed_interface, $identifier);
            my $type = $config_section{INTERNAL_KEY_PREFIX . 'type'};
            if ($use_default) {
                $ref_attr_list = ($type eq 'Interface') ? $self->{default_attr_list_interface} : $self->{default_attr_list_peer}
            }
            if ($is_dump) {
                $output .= "$printed_interface "
                    . $self->_get_dump_line(\%config_section, \%wg_show_section, $ref_attr_list)
                    . "\t"
                    . $config_section{INTERNAL_KEY_PREFIX . 'type'}
                    . "\n";
            }
            else {
                $identifier = $config_section{'alias'} if exists $config_section{'alias'};

                # we only show a green dot when the peer appears in the show output
                $state = ($interface_is_active and keys %wg_show_section > 1) ? 1 : 0;
                my $state_marker = ($state == 1) ? BOLD . GREEN . '●' . RESET : BOLD . RED . '●' . RESET;
                $output .= $state_marker . BOLD . lc($type) . ": " . RESET . $identifier . "\n";
                $output .= $self->_get_pretty_line(\%config_section, \%wg_show_section, $ref_attr_list) . "\n";
            }

        }
    }
    print $output;
}


sub _get_pretty_line($self, $ref_config_section, $ref_show_section, $ref_attr_list) {
    my @line;
    for my $printed_attribute (@{$ref_attr_list}) {
        # skip redundant information
        next if $printed_attribute eq 'alias' or $printed_attribute eq 'disabled';

        # first lets check if we have to look in the show output
        my $value = '(none)';
        if (exists $self->{wg_show_lookup}{$printed_attribute}) {
            $value = $ref_show_section->{$printed_attribute} if exists $ref_show_section->{$printed_attribute};
        }
        # any other case
        else {
            if (exists $ref_config_section->{$printed_attribute}) {
                $value = $ref_config_section->{$printed_attribute}
            }
            else {
                # Check if info maybe available in show output
                $value = $ref_show_section->{$printed_attribute} if exists $ref_show_section->{$printed_attribute};
            }
        }
        # apply attr converters if any
        $value = &{$self->{attr_converters}{$printed_attribute}}($value) if exists $self->{attr_converters}{$printed_attribute};
        push @line, '  ' . $printed_attribute . ': ' . $value;
    }
    return join("\n", @line);
}

sub _get_dump_line($self, $ref_config_section, $ref_show_section, $ref_attr_list) {
    my @line;
    for my $printed_attribute (@{$ref_attr_list}) {
        # first lets check if we have to look in the show output
        my $value = ('none');
        if (exists $self->{wg_show_lookup}{$printed_attribute}) {
            $value = $ref_show_section->{$printed_attribute} if exists $ref_show_section->{$printed_attribute};
            push @line, $value;
        }
        # any other case
        else {
            if (exists $ref_config_section->{$printed_attribute}) {
                $value = $ref_config_section->{$printed_attribute}
            }
            else {
                # Check if info maybe available in show output
                $value = $ref_show_section->{$printed_attribute} if exists $ref_show_section->{$printed_attribute};
            }
            push @line, $value;
        }
    }
    return join("\t", @line);
}

sub cmd_help($self) {
    print "Usage: wg-meta show {interface|all} [attribute1, attribute2, ...] [dump] \n"
        . "Notes:\n"
        . "A green dot indicates an interface/peer's 'real' state which means that its currently possible\n"
        . "to connect to this interface/peer.\n"
        . "A red dot on the other hand indicates that its not possible to connect. This could mean not applied changes, \n"
        . "a disabled peer or the parent interface is down. \n"
}

1;
