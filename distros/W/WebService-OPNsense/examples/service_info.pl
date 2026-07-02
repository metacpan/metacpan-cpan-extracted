#!perl

use strictures 2;
use Ref::Util qw( is_plain_hashref is_plain_arrayref );
use WebService::OPNsense ();

my $base_url = $ENV{OPN_URL}    or die "Set OPN_URL, OPN_KEY, OPN_SECRET\n";
my $username = $ENV{OPN_KEY}    or die "Set OPN_URL, OPN_KEY, OPN_SECRET\n";
my $password = $ENV{OPN_SECRET} or die "Set OPN_URL, OPN_KEY, OPN_SECRET\n";

my $opn = WebService::OPNsense->new(
    base_url => $base_url,
    username => $username,
    password => $password,
);

if ( $ENV{OPN_INSECURE} ) {
    $opn->ua->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0 );
}

# Present any API response: hashref (with optional key lookup),
# arrayref, or plain scalar
sub _show {
    my ( $label, $data, $key ) = @_;
    return unless defined $data;
    printf "%s\n", $label;
    if ( is_plain_hashref($data) ) {
        if ($key) {
            my $val = $data->{$key};
            if ( defined $val ) {
                printf "  %s\n", $val;
            }
            else {
                printf "  (no %s key)\n", $key;
            }
        }
        else {
            my $rows = $data->{rows};
            if ( is_plain_arrayref($rows) ) {
                _list_data($rows, 2);
            }
            else {
                _dump_hash($data, 1);
            }
        }
    }
    elsif ( is_plain_arrayref($data) ) {
        _list_data($data, 1);
    }
    else {
        printf "  %s\n", $data // q();
    }
}

sub _dump_hash {
    my ( $data, $indent ) = @_;
    for my $k ( sort keys %{$data} ) {
        my $v = $data->{$k};
        if ( is_plain_hashref($v) ) {
            printf "%s%s:\n", '  ' x $indent, $k;
            _dump_hash( $v, $indent + 1 );
        }
        elsif ( is_plain_arrayref($v) ) {
            printf "%s%s (%d items)\n", '  ' x $indent, $k, scalar @{$v};
        }
        else {
            my $display = $v // q();
            $display = substr( $display, 0, 120 ) . '...'
                if length($display) > 120;
            printf "%s%s: %s\n", '  ' x $indent, $k, $display;
        }
    }
}

sub _list_data {
    my ( $data, $indent ) = @_;
    my $idx = 0;
    for my $item ( @{$data} ) {
        if ( is_plain_hashref($item) ) {
            printf "%s[%d]:\n", '  ' x $indent, $idx++;
            _dump_hash( $item, $indent + 1 );
        }
        else {
            my $display = $item // q();
            $display = substr( $display, 0, 120 ) . '...'
                if length($display) > 120;
            printf "%s[%d] %s\n", '  ' x $indent, $idx++, $display;
        }
    }
    unless (@{$data}) {
        printf "%s(empty)\n", '  ' x $indent;
    }
}

# ===== System =====
print "=== System ===\n";

my $sys = $opn->system;

_show( 'System status', $sys->status );
_show( 'Firmware info', $sys->firmware_info );
_show( 'Update status', $sys->firmware_status, 'status' );

# ===== Diagnostics =====
print "\n=== Diagnostics ===\n";

my $diag = $opn->diagnostics;

_show( 'Hostname',      $diag->system_information, 'name' );
_show( 'Disk parts',    $diag->system_disk );
_show( 'Activity',      $diag->activity );
_show( 'Interfaces',    $diag->interface_names );
_show( 'Intf stats',    $diag->interface_statistics );
_show( 'Intf configs',  $diag->interface_config );
_show( 'ARP table',     $diag->arp_table );
_show( 'NDP table',     $diag->ndp_table );
_show( 'Diagnostics routes', $diag->routes );
_show( 'pf states',     $diag->pf_states );
_show( 'pf statistics', $diag->pf_statistics );
_show( 'FW stats',      $diag->firewall_stats );
_show( 'FW log filters',$diag->firewall_log_filters );
_show( 'Traffic',       $diag->traffic );
_show( 'Services',      $diag->search_service );

_show( 'Memory',      $diag->memory );
_show( 'System time', $diag->system_time );

# ===== Routes =====
print "\n=== Routes ===\n";

_show( 'Gateway status', $opn->routes->status );

# ===== Interfaces =====
print "\n=== Interfaces ===\n";

_show( 'Interface overview', $opn->interfaces->overview );
_show( 'Intf settings',      $opn->interfaces->settings_get );

# ===== Firewall =====
print "\n=== Firewall ===\n";

_show( 'Filter rules',      $opn->firewall_filter->search_rule );
_show( 'Interface list',    $opn->firewall_filter->get_interface_list );
_show( 'Aliases',           $opn->firewall_alias->search_item );
_show( 'Alias table sizes', $opn->firewall_alias->get_table_size );
_show( 'Alias categories',  $opn->firewall_alias->list_categories );
_show( 'Countries',         $opn->firewall_alias->list_countries );
_show( 'Network aliases',   $opn->firewall_alias->list_network_aliases );
_show( 'User groups',       $opn->firewall_alias->list_user_groups );
_show( 'Categories',        $opn->firewall_category->search_item );
_show( 'DNAT rules',        $opn->firewall_d_nat->search_rule );
_show( '1:1 NAT rules',     $opn->firewall_one_to_one->search_rule );
_show( 'Src NAT rules',     $opn->firewall_source_nat->search_rule );
_show( 'NPT rules',         $opn->firewall_npt->search_rule );

# ===== Unbound (DNS) =====
print "\n=== Unbound (DNS) ===\n";

_show( 'Unbound settings',  $opn->unbound_settings->get_settings );
_show( 'Unbound enabled',   $opn->unbound_overview->is_enabled, 'enabled' );
_show( 'Unbound stats',     $opn->unbound_diagnostics->stats );
_show( 'Unbound service',   $opn->unbound_service->status, 'status' );
_show( 'Unbound policies',  $opn->unbound_overview->get_policies );

# ===== Dnsmasq =====
print "\n=== Dnsmasq ===\n";

_show( 'Dnsmasq settings',  $opn->dnsmasq_settings->get_settings );
_show( 'Dnsmasq service',   $opn->dnsmasq_service->status, 'status' );

# ===== Kea DHCP =====
print "\n=== Kea DHCP ===\n";

_show( 'Kea DHCPv4',        $opn->kea_dhcpv4->get_settings );
_show( 'Kea DHCPv6',        $opn->kea_dhcpv6->get_settings );
_show( 'Kea service',       $opn->kea_service->status, 'status' );

# ===== IPsec =====
print "\n=== IPsec ===\n";

_show( 'IPsec service',     $opn->ipsec_service->status, 'status' );
_show( 'IPsec settings',    $opn->ipsec_settings->get_settings );
_show( 'IPsec pools',       $opn->ipsec_leases->pools );
_show( 'IPsec conn enabled',$opn->ipsec_connections->is_enabled );
_show( 'IPsec ph1 sessions',$opn->ipsec_sessions->search_phase1 );
_show( 'IPsec SPD',         $opn->ipsec_spd->search );
_show( 'IPsec SAD',         $opn->ipsec_sad->search );

# ===== OpenVPN =====
print "\n=== OpenVPN ===\n";

_show( 'OVPN sessions',     $opn->openvpn_service->search_sessions );
_show( 'OVPN routes',       $opn->openvpn_service->search_routes );
_show( 'OVPN providers',    $opn->openvpn_export->providers );
_show( 'OVPN templates',    $opn->openvpn_export->templates );

# ===== IDS =====
print "\n=== IDS ===\n";

_show( 'IDS service',       $opn->ids_service->status, 'status' );
_show( 'IDS rulesets',      $opn->ids_settings->list_rulesets );
_show( 'IDS rule metadata', $opn->ids_settings->list_rule_metadata );

# ===== Backup =====
print "\n=== Backup ===\n";

_show( 'Backup providers',  $opn->backup->providers );

# ===== Cron =====
print "\n=== Cron ===\n";

_show( 'Cron settings',     $opn->cron_settings->get_settings );
_show( 'Cron jobs',         $opn->cron_settings->search_jobs );

# ===== Traffic Shaper =====
print "\n=== Traffic Shaper ===\n";

_show( 'Shaper settings',   $opn->trafficshaper_settings->get_settings );
_show( 'Shaper statistics', $opn->trafficshaper_service->statistics );

# ===== HA-Sync =====
print "\n=== HA-Sync ===\n";

_show( 'HA services',       $opn->hasync->services );
_show( 'HA version',        $opn->hasync->version );
_show( 'HA config',         $opn->hasync->get );

# ===== Captive Portal =====
print "\n=== Captive Portal ===\n";

_show( 'CP zones',          $opn->captive_portal_settings->search_zones );
_show( 'CP service',        $opn->captive_portal_service->status, 'status' );

print "\nDone.\n";
