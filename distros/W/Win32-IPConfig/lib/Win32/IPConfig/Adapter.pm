package Win32::IPConfig::Adapter;

use 5.006;
use strict;
use warnings;

use Carp;
use Win32::TieRegistry qw/:KEY_/;

sub new
{
    my $class = shift;
    my $hklm = shift; # connection to registry
    my $nic = shift;
    my $access = shift || 'ro';

    # We only need to test that $id is defined because $osversion and
    # $networkcards_key have already been tested by Win32::IPConfig, and
    # $description is not necessary for any of the object methods.

    my $osversion = $hklm->{"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\\\CurrentVersion"};
    my $networkcards_key = $hklm->{"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\NetworkCards\\"};
    my $description = $networkcards_key->{"$nic\\\\Description"};
    my $id = $networkcards_key->{"$nic\\\\ServiceName"}
        or return undef;

    my $self = {};
    $self->{"access"} = $access;
    $self->{"osversion"} = $osversion;
    $self->{"id"} = $id;
    $self->{"description"} = $description;

    # connect to the appropriate registry keys
    # HKLM\SYSTEM\CurrentControlSet\Services
    # HKLM\SYSTEM\CurrentControlSet\Tcpip\Parameters
    # HKLM\SYSTEM\CurrentControlSet\Netbt\Parameters

    # Win32::IPConfig has already tested that the following keys are defined
    # (or we wouldn't be here).
    my $services_key = $hklm->{"SYSTEM\\CurrentControlSet\\Services\\"};
    my $tcpip_params_key = $services_key->{"Tcpip\\Parameters\\"};
    my $netbt_params_key = $services_key->{"Netbt\\Parameters\\"};

    # 2000+ specific registry keys
    # HKLM\...\Services\Tcpip\Parameters\Interfaces\<id>
    # HKLM\...\Services\Netbt\Parameters\Interfaces\Tcpip_<id>
    # HKLM\...\Control\Network\{4D36E972-E325-11CE-BFC1-08002BE10318}
    my $tcpip_params_interface_key = $tcpip_params_key->{"Interfaces\\$id\\"};
    my $netbt_params_interface_key = $netbt_params_key->{"Interfaces\\Tcpip_$id\\"};
    my $network_connection_key = $hklm->{"SYSTEM\\CurrentControlSet\\Control\\Network\\{4D36E972-E325-11CE-BFC1-08002BE10318}\\"};

    # NT4 specific registry keys
    # HKLM\...\Services\<id>\Parameters
    # HKLM\...\Services\<id>\Parameters\Tcpip
    # HKLM\...\Services\Netbt\Adapters\<id>
    my $adapter_params_key = $services_key->{"$id\\Parameters\\"};
    my $adapter_params_tcpip_key = $adapter_params_key->{"Tcpip\\"};
    my $netbt_adapter_key = $services_key->{"Netbt\\Adapters\\$id\\"};

    # Abandon this adapter if any of the required registry keys are missing.
    if ($self->{"osversion"} >= 5.0) {
        defined $tcpip_params_interface_key or return undef;
        defined $netbt_params_interface_key or return undef;
        defined $network_connection_key or return undef;
    } else {
        defined $adapter_params_key or return undef;
        defined $adapter_params_tcpip_key or return undef;
        defined $netbt_adapter_key or return undef;
    }

    $self->{"tcpip_params_key"} = $tcpip_params_key;
    $self->{"netbt_params_key"} = $netbt_params_key;
    $self->{"tcpip_params_interface_key"} = $tcpip_params_interface_key;
    $self->{"netbt_params_interface_key"} = $netbt_params_interface_key;
    $self->{"network_connection_key"} = $network_connection_key;
    $self->{"adapter_params_key"} = $adapter_params_key;
    $self->{"adapter_params_tcpip_key"} = $adapter_params_tcpip_key;
    $self->{"netbt_adapter_key"} = $netbt_adapter_key;

    # Is DHCP enabled? As most of the methods need to know if DHCP is
    # enabled in order to determine which registry value to query, this
    # would entail an additional check of the EnableDHCP value for every value
    # queried. To avoid this, the EnableDHCP value is cached in the
    # Win32::IPConfig::Adapter object.

    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"adapter_params_tcpip_key"};
    if (my $enable_dhcp = $key->{"\\EnableDHCP"}) { # REG_DWORD
        $self->{"dhcp_enabled"} = hex($enable_dhcp);
    } else {
        die "Unable to determine if adapter is enabled for DHCP\n";
    }

    bless $self, $class;
    return $self;
}

sub get_id { return $_[0]->{"id"}; }

sub get_description { return $_[0]->{"description"}; }

sub get_name
{
    my $self = shift;

    my $id = $self->get_id;
    my $name;
    if ($self->{"osversion"} >= 5.0) {
        $name = $self->{"network_connection_key"}{"$id\\Connection\\\\Name"};
    }
    return $name || $id;
}

# Value: EnableDHCP (REG_DWORD)
# NT:    <adapter>\Parameters\Tcpip
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

sub is_dhcp_enabled { return $_[0]->{"dhcp_enabled"}; }

# Value: IPAddress (REG_MULTI_SZ)
# NT:    <adapter>\Parameters\Tcpip
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

sub _get_static_ipaddresses
{
    my $self = shift;

    my @ipaddresses = ();
    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"adapter_params_tcpip_key"};
    if (my $ipaddresses = $key->{"\\IPAddress"}) { # REG_MULTI_SZ
        @ipaddresses = @{$ipaddresses};
    }
    return @ipaddresses;
}

# Value: DhcpIPAddress (REG_SZ)
# NT:    <adapter>\Parameters\Tcpip
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

sub _get_dhcp_ipaddresses
{
    my $self = shift;

    my @ipaddresses = ();
    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"adapter_params_tcpip_key"};
    if (my $dhcpipaddress = $key->{"\\DhcpIPAddress"}) { # REG_SZ
        @ipaddresses = ($dhcpipaddress);
    }
    return @ipaddresses;
}

sub get_ipaddresses
{
    my $self = shift;

    # According to Q120642, if IPAddress has a first value set to something
    # other than 0.0.0.0, it will override DhcpIPAddress. However, in testing,
    # ipconfig did NOT show the statically assigned IP addresses overriding the
    # DHCP IP address. Additionally, pings showed that the original DHCP IP
    # address was still being used.

    # Anyway, I still can't get my head around statically configured
    # IP addresses on an adapter that is enabled for DHCP.

    # Hence the ip address returned is determined solely by whether or not the
    # adapter is configured for DHCP.

    my @ipaddresses = $self->_get_static_ipaddresses;
    if ($self->is_dhcp_enabled) {
        @ipaddresses = $self->_get_dhcp_ipaddresses;
    }
    return wantarray ? @ipaddresses : \@ipaddresses;
}

# Value: SubnetMask (REG_MULTI_SZ)
# NT:    <adapter>\Parameters\Tcpip
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

sub _get_static_subnet_masks
{
    my $self = shift;

    my @subnet_masks = ();
    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"adapter_params_tcpip_key"};
    if (my $subnet_masks = $key->{"\\SubnetMask"}) { # REG_MULTI_SZ
        @subnet_masks = @{$subnet_masks};
    }
    return @subnet_masks;
}

# Value: DhcpSubnetMask (REG_SZ)
# NT:    <adapter>\Parameters\Tcpip
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

sub _get_dhcp_subnet_masks
{
    my $self = shift;

    my @subnet_masks = ();
    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"adapter_params_tcpip_key"};
    if (my $subnet_masks = $key->{"\\DhcpSubnetMask"}) { # REG_SZ
        @subnet_masks = ($subnet_masks);
    }
    return @subnet_masks;
}

sub get_subnet_masks
{
    my $self = shift;

    # On a Windows NT 4.0 machine configured for DHCP, IPAddress was set to
    # ["0.0.0.0"] and SubnetMask set to ["255.0.0.0"]. On a Windows XP machine
    # configured for DHCP, IPAddress was set to ["0.0.0.0"] and SubnetMask set
    # to ["0.0.0.0"].

    # The subnet mask returned is determined solely by whether or not the
    # adapter is configured for DHCP (just like the ip address, and unlike all
    # the other settings in which static settings DO override dynamic settings).

    my @subnet_masks = $self->_get_static_subnet_masks;
    if ($self->is_dhcp_enabled) {
        @subnet_masks = $self->_get_dhcp_subnet_masks;
    }
    return wantarray ? @subnet_masks : \@subnet_masks;
}

# Value: DefaultGateway (REG_MULTI_SZ)
# NT:    <adapter>\Parameters\Tcpip
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

sub _get_static_gateways
{
    my $self = shift;

    my @gateways = ();
    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"adapter_params_tcpip_key"};
    if (my $gateways = $key->{"\\DefaultGateway"}) { # REG_MULTI_SZ
        @gateways = @{$gateways};
    }
    @gateways = grep { $_ } @gateways; # remove any empty entries
    return @gateways;
}

# Value: DhcpDefaultGateway (REG_MULTI_SZ)
# NT:    <adapter>\Parameters\Tcpip
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

sub _get_dhcp_gateways
{
    my $self = shift;

    my @gateways = ();
    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"adapter_params_tcpip_key"};
    if (my $gateways = $key->{"\\DhcpDefaultGateway"}) { # REG_MULTI_SZ
        @gateways = @{$gateways};
    }
    return @gateways;
}

sub get_gateways
{
    my $self = shift;

    # statically configured gateways override dhcp assigned gateways
    my @gateways = $self->_get_static_gateways;
    if (@gateways == 0 && $self->is_dhcp_enabled) {
        @gateways = $self->_get_dhcp_gateways;
    }
    return wantarray ? @gateways : \@gateways;
}

# Value: Domain (REG_SZ)
# NT:    Tcpip\Parameters
# 2000+: Tcpip\Parameters (primary)
# 2000+: Tcpip\Parameters\Interfaces\<adapter> (connection-specific)

# Value: NV Domain (REG_SZ)
# 2000+: Tcpip\Parameters

# Note: NT stores the Domain setting for the machine, not for the card

sub _get_static_domain
{
    my $self = shift;

    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"tcpip_params_key"};

    # Returns the connection-specific DNS suffix on Windows 2000 and later.
    # As a convenience, returns the host DNS suffix on Windows NT.

    my $domain = $key->{"\\Domain"} || ""; # REG_SZ
    return $domain;
}

# Value: DhcpDomain (REG_SZ)
# NT:    Tcpip\Parameters
# 2000+: Tcpip\Parameters
# 2000+: Tcpip\Parameters\Interfaces\<adapter> (connection-specific)

# Note: NT stores the DhcpDomain setting for the machine, not for the card

sub _get_dhcp_domain
{
    my $self = shift;

    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"tcpip_params_key"};

    # Returns the connection-specific DNS suffix on Windows 2000 and later.
    # As a convenience, returns the host DNS suffix on Windows NT.

    my $domain = $key->{"\\DhcpDomain"} || ""; # REG_SZ
    return $domain;
}

sub get_domain
{
    my $self = shift;

    # statically configured domain overrides dhcp configured domain
    my $domain = $self->_get_static_domain;
    if ($self->is_dhcp_enabled && $domain eq "") {
        $domain = $self->_get_dhcp_domain;
    }
    return $domain;
}

# Value: NameServer (REG_SZ) (space delimited on NT, comma delimited on 2000+)
# NT:    Tcpip\Parameters
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

# The Microsoft Support Articles Q120642 and Q314053 indicate that NameServer is
# in the Tcpip\Parameters key on Windows NT, 2000, and XP. But this is wrong.
# NameServer also appears to be comma delimited on Windows 2000 and later,
# and not space delimited as the support articles state.

sub _get_static_dns
{
    my $self = shift;

    my @dns = ();
    # actually a NT4 host setting rather than an adapter one
    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"tcpip_params_key"};
    if (my $dns = $key->{"\\NameServer"}) { # REG_SZ
        @dns = split /[ ,]/, $dns;
    }
    return @dns;
}

# Value: DhcpNameServer (REG_SZ) (a space delimited list)
# NT:    Tcpip\Parameters
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

# The comment that applies to NameServer above also applies to DhcpNameServer.
# However, unlike NameServer, DhcpNameServer is actually space delimited
# on all platforms (that I've seen so far).

sub _get_dhcp_dns
{
    my $self = shift;

    my @dns = ();
    # actually a NT4 host setting rather than an adapter one
    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"tcpip_params_key"};
    if (my $dns = $key->{"\\DhcpNameServer"}) { # REG_SZ
        @dns = split / /, $dns;
    }
    return @dns;
}

sub get_dns
{
    my $self = shift;

    # statically configured dns servers override dhcp assigned dns servers
    my @dns = $self->_get_static_dns;
    if (@dns == 0 && $self->is_dhcp_enabled) {
        @dns = $self->_get_dhcp_dns;
    }
    return wantarray ? @dns : \@dns;
}

# Value: NameServer (REG_SZ)
# NT:    Netbt\Adapters\<adapter>

# Value: NameServerBackup (REG_SZ)
# NT:    Netbt\Adapters\<adapter>

# Value: NameServerList (REG_MULTI_SZ)
# 2000+: Netbt\Parameters\Interfaces\Tcpip_<adapter>

# Q120642 and Q314053 talk about NameServer and NameServerBackup
# existing on Windows 2000 in the Netbt\Parameters\Interfaces\Tcpip_<adapter>
# registry key, but this appears to be wrong. The values actually
# appear to be stored in the NameServerList setting.

sub _get_static_wins
{
    my $self = shift;

    my @wins = ();
    if ($self->{"osversion"} >= 5.0) {
        my $key = $self->{"netbt_params_interface_key"};
        if (my $wins = $key->{"\\NameServerList"}) { # REG_MULTI_SZ
            @wins = @{$wins};
            @wins = grep { $_ } @wins; # remove empty entries
        }
    } else {
        my $key = $self->{"netbt_adapter_key"};
        my $nameserver = $key->{"\\NameServer"}; # REG_SZ
        my $nameserverbackup = $key->{"\\NameServerBackup"}; # REG_SZ
        push @wins, $nameserver if $nameserver;
        push @wins, $nameserverbackup if $nameserverbackup;
    }
    return @wins;
}

# Value: DhcpNameServer (REG_SZ)
# NT:    Netbt\Adapters\<adapter>

# Value: DhcpNameServerBackup (REG_SZ)
# NT:    Netbt\Adapters\<adapter>

# Value: DhcpNameServerList (REG_MULTI_SZ)
# 2000+: Netbt\Parameters\Interfaces\Tcpip_<adapter>

# Q120642 and Q314053 talk about DhcpNameServer and DhcpNameServerBackup
# existing on Windows 2000, but the values appear to be stored in the
# DhcpNameServerList setting.

sub _get_dhcp_wins
{
    my $self = shift;

    my @wins = ();
    if ($self->{"osversion"} >= 5.0) {
        my $key = $self->{"netbt_params_interface_key"};
        if (my $wins = $key->{"\\DhcpNameServerList"}) { # REG_MULTI_SZ
            @wins = @{$wins};
        }
    } else {
        my $key = $self->{"netbt_adapter_key"};
        my $nameserver = $key->{"\\DhcpNameServer"}; # REG_SZ
        my $nameserverbackup = $key->{"\\DhcpNameServerBackup"}; # REG_SZ
        push @wins, $nameserver if $nameserver;
        push @wins, $nameserverbackup if $nameserverbackup;
    }
    return @wins;
}

sub get_wins
{
    my $self = shift;

    # statically configured wins servers override dhcp assigned wins servers
    my @wins = $self->_get_static_wins;
    if (@wins == 0 && $self->is_dhcp_enabled) {
        @wins = $self->_get_dhcp_wins;
    }
    return wantarray ? @wins : \@wins;
}

# Value: DhcpServer (REG_SZ)
# NT:    <adapter>\Parameters\Tcpip
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

sub get_dhcp_server
{
    my $self = shift;

    croak "Adapter is not configured through DHCP"
        unless $self->is_dhcp_enabled;

    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"adapter_params_tcpip_key"};
    my $dhcpserver = $key->{"\\DhcpServer"} || "";
    return $dhcpserver;
}

sub _format_time
{
    my @time = localtime shift;
    return sprintf "%04d-%02d-%02d %02d:%02d",
        $time[5]+1900, $time[4]+1, $time[3], $time[2], $time[1];
}

# Value: LeaseObtainedTime (REG_DWORD)
# NT:    <adapter>\Parameters\Tcpip
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

sub get_dhcp_lease_obtained_time
{
    my $self = shift;

    croak "Adapter is not configured through DHCP"
        unless $self->is_dhcp_enabled;

    my $lease_obtained;
    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"adapter_params_tcpip_key"};
    if (my $time = $key->{"\\LeaseObtainedTime"}) {
        $lease_obtained = _format_time(hex($time));
    } else {
        $lease_obtained = "";
    }
    return $lease_obtained;
}

# Value: LeaseTerminatesTime (REG_DWORD)
# NT:    <adapter>\Parameters\Tcpip
# 2000+: Tcpip\Parameters\Interfaces\<adapter>

sub get_dhcp_lease_terminates_time
{
    my $self = shift;

    croak "Adapter is not configured through DHCP"
        unless $self->is_dhcp_enabled;

    my $lease_terminates;
    my $key = $self->{"osversion"} >= 5.0
            ? $self->{"tcpip_params_interface_key"}
            : $self->{"adapter_params_tcpip_key"};
    if (my $time = $key->{"\\LeaseTerminatesTime"}) {
        $lease_terminates = _format_time(hex($time));
    } else {
        $lease_terminates = "";
    }
    return $lease_terminates;
}

sub dump
{
    my $self = shift;

    print "name=", $self->get_name, "\n";
    print "id=", $self->get_id, "\n";
    print "description=", $self->get_description, "\n";

    print "domain=", $self->get_domain, " ";
    if ($self->_get_static_domain && $self->is_dhcp_enabled) {
        print "(statically overridden)";
    }
    print "\n";

    print "dhcp enabled=", $self->is_dhcp_enabled ? "Yes" : "No", "\n";

    my @ipaddresses = $self->get_ipaddresses;
    print "ip addresses=@ipaddresses (", scalar @ipaddresses, ")\n";

    my @subnet_masks = $self->get_subnet_masks;
    print "subnet masks=@subnet_masks (", scalar @subnet_masks, ")\n";

    my @gateways = $self->get_gateways;
    print "gateways=@gateways (", scalar @gateways, ") ";
    if ($self->_get_static_gateways != 0 && $self->is_dhcp_enabled) {
        print "(statically overridden)";
    }
    print "\n";

    my @dns = $self->get_dns;
    print "dns=@dns (", scalar @dns, ") ";
    if ($self->_get_static_dns != 0 && $self->is_dhcp_enabled) {
        print "(statically overridden)";
    }
    print "\n";

    my @wins = $self->get_wins;
    print "wins=@wins (", scalar @wins, ") ";
    if ($self->_get_static_wins != 0 && $self->is_dhcp_enabled) {
        print "(statically overridden)";
    }
    print "\n";

    if ($self->is_dhcp_enabled) {
        print "dhcp server=", $self->get_dhcp_server, "\n";
        print "dhcp lease obtained=", $self->get_dhcp_lease_obtained_time, "\n";
        print "dhcp lease terminates=", $self->get_dhcp_lease_terminates_time, "\n";
    }
}

sub set_domain
{
    my $self = shift;

    # bail if dhcp enabled
    croak "Adapter is configured through DHCP" if $self->is_dhcp_enabled;

    # bail if access is not read/write
    croak "Access is read only, settings cannot be changed"
        if $self->{"access"} ne 'rw';

    my $domain = shift;
    croak "Invalid Domain Name Suffix" unless $domain =~ /^[\w\.\-]+$/;

    if ($self->{"osversion"} >= 5.0) {
        # Set connection-specific domain
        $self->{"tcpip_params_interface_key"}{"\\Domain"} = $domain;
    } else {
        # As a convenience, set the host-specific domain
        $self->{"tcpip_params_key"}{"\\Domain"} = $domain;
    }
}

sub set_dns
{
    my $self = shift;

    # bail if dhcp enabled
    croak "Adapter is configured through DHCP" if $self->is_dhcp_enabled;

    # bail if access is not read/write
    croak "Access is read only, settings cannot be changed"
        if $self->{"access"} ne 'rw';

    my @dns = @_;
    for (@dns) {
        croak "Invalid IP address" if $_ !~ /^\d+\.\d+\.\d+\.\d+$/;
    }
    @dns = grep { $_ } @dns; # remove empty entries
    # could also check number of dns servers?

    if ($self->{"osversion"} >= 5.0) {
        $self->{"tcpip_params_interface_key"}{"\\NameServer"} = join(",", @dns);
    } else {
        $self->{"tcpip_params_key"}{"\\NameServer"} = join(" ", @dns);
    }
}

sub set_wins
{
    my $self = shift;

    # bail if dhcp enabled
    croak "Adapter is configured through DHCP" if $self->is_dhcp_enabled;

    # bail if access is not read/write
    croak "Access is read only, settings cannot be changed"
        if $self->{"access"} ne 'rw';

    my @wins = @_;
    for (@wins) {
        croak "Invalid IP address" if $_ !~ /^\d+\.\d+\.\d+\.\d+$/;
    }
    @wins = grep { $_ } @wins; # remove empty entries
    # could also check number of wins servers?

    if ($self->{"osversion"} >= 5.0) {
        $self->{"netbt_params_interface_key"}{"\\NameServerList"} = [[@wins], "REG_MULTI_SZ"];
    } else {
        $self->{"netbt_adapter_key"}{"\\NameServer"} = $wins[0];
        $self->{"netbt_adapter_key"}{"\\NameServerBackup"} = $wins[1];
    }
}

1;

__END__

=head1 NAME

Win32::IPConfig::Adapter - Network Adapter IP Configuration Settings for Windows NT/2000/XP/2003

=head1 SYNOPSIS

    use Win32::IPConfig;

    $host = shift || "";
    if ($ipconfig = Win32::IPConfig->new($host)) {
        print "hostname=", $ipconfig->get_hostname, "\n";

        print "domain=", $ipconfig->get_domain, "\n";

        my @searchlist = $ipconfig->get_searchlist;
        print "searchlist=@searchlist (", scalar @searchlist, ")\n";

        print "nodetype=", $ipconfig->get_nodetype, "\n";

        print "IP routing enabled=", $ipconfig->is_router ? "Yes" : "No", "\n";

        print "WINS proxy enabled=",
            $ipconfig->is_wins_proxy ? "Yes" : "No", "\n";

        print "LMHOSTS enabled=",
            $ipconfig->is_lmhosts_enabled ? "Yes" : "No", "\n";

        print "DNS enabled for netbt=",
            $ipconfig->is_dns_enabled_for_netbt ? "Yes" : "No", "\n";

        foreach $adapter ($ipconfig->get_adapters) {
            print "\nAdapter '", $adapter->get_name, "':\n";

            print "Description=", $adapter->get_description, "\n";

            print "DHCP enabled=",
                $adapter->is_dhcp_enabled ? "Yes" : "No", "\n";

            @ipaddresses = $adapter->get_ipaddresses;
            print "IP addresses=@ipaddresses (", scalar @ipaddresses, ")\n";

            @subnet_masks = $adapter->get_subnet_masks;
            print "subnet masks=@subnet_masks (", scalar @subnet_masks, ")\n";

            @gateways = $adapter->get_gateways;
            print "gateways=@gateways (", scalar @gateways, ")\n";

            print "domain=", $adapter->get_domain, "\n";

            @dns = $adapter->get_dns;
            print "dns=@dns (", scalar @dns, ")\n";

            @wins = $adapter->get_wins;
            print "wins=@wins (", scalar @wins, ")\n";
        }
    }

=head1 DESCRIPTION

Win32::IPConfig::Adapter encapsulates the TCP/IP
configuration settings for a Windows NT/2000/XP/2003 network adapter.

=head1 METHODS

=over 4

=item $adapter->get_name

On Windows 2000 and later, returns the name of the connection as it
appears in Network Connections, e.g. "Local Area Connection".
On Windows NT returns the service name of the adapter
(the same value as get_id).

=item $adapter->get_id

Returns the adapter id. This is used to determine where the adapter
settings are stored. See REGISTRY KEYS USED in the Win32::IPConfig
documentation.

=item $adapter->get_description

Returns the Network Adapter Description.

=item $adapter->is_dhcp_enabled

Returns 1 if DHCP is enabled, 0 otherwise. If DHCP is enabled, the values
returned from the get_ipaddresses, get_gateways, get_domain, get_dns, and
get_wins methods will be retrieved from the DHCP-specific registry keys.

=item $adapter->get_ipaddresses

Returns a list of IP addresses for this adapter.
(Returns a reference to a list in a scalar context.)

=item $adapter->get_subnet_masks

Returns a list of subnet masks for this adapter.
(Returns a reference to a list in a scalar context.)
The order of subnet masks follows the order of IP addresses, so,
for example, the 2nd subnet mask will match the 2nd IP address.

=item $adapter->get_gateways

Returns a list containing the default gateway IP addresses.
(Returns a reference to a list in a scalar context.)
If no default gateways are configured, an empty list will be returned.
Statically configured default gateways will override any assigned by DHCP.

(Bet you didn't realise Windows allowed you to have multiple
default gateways.)

=item $adapter->get_domain

Returns the connection-specific domain name suffix.
A statically configured domain name suffix will override any assigned by DHCP.

Connection-specific domain name suffixes were introduced on Windows 2000.
Windows NT machines do not support connection-specific domain names, so when run
on Windows NT this method will return the domain name suffix for the host: all
adapters on a Windows NT machine will therefore return the same domain name.

=item $adapter->get_dns

Returns a list containing DNS server IP addresses.
(Returns a reference to a list in a scalar context.)
If no DNS servers are configured, an empty list will be returned.
Statically configured DNS Servers will override any assigned by DHCP.

Only Windows 2000 and later have DNS servers configured per adapter. Windows NT
machines store the DNS servers as a property of the host, not of the adapter, so
when run on Windows NT this method will return the DNS servers set for the host:
all adapters on a Windows NT machine will therefore return the same DNS servers.

=item $adapter->get_wins

Returns a list containing WINS server IP addresses.
(Returns a reference to a list in a scalar context.)
If no WINS servers are configured, an empty list will be returned.
Statically configured WINS Servers will override any assigned by DHCP.

=item $adapter->get_dhcp_server

Returns the IP address of the DHCP server that supplied the adapter's
IP address.

You will only be able to read this value if the host adapter is
configured through DHCP.

=item $adapter->get_dhcp_lease_obtained_time

Returns the time the DHCP lease began in the format YYYY-MM-DD HH-MM.

You will only be able to read this value if the host adapter is
configured through DHCP.

=item $adapter->get_dhcp_lease_terminates_time

Returns the time the DHCP lease runs out in the format YYYY-MM-DD HH-MM.

You will only be able to read this value if the host adapter is
configured through DHCP.

=item $adapter->set_domain($domain_suffix)

On Windows 2000 and later, sets the connection-specific domain name suffix.
On Windows NT, sets the host-specific domain name suffix.

You will not be allowed to set this value if the host adapter is
configured through DHCP.

When tested on a Windows NT system, the setting appeared to take effect
immediately. When tested on a Windows 2000 system, the setting did not appear to
take effect until the DNS Client service was restarted or the machine was
rebooted.

=item $adapter->set_dns(@dns_servers)

Sets the DNS servers to @dns_servers. You can use an empty list
to remove all configured DNS servers. On Windows 2000 and later, sets the
DNS servers for the adapter; on Windows NT, sets the DNS servers for the
host.

You will not be allowed to set this value if the host adapter is
configured through DHCP.

When tested on a Windows NT system, the machine needed to be rebooted for it to
take effect. When tested on a Windows 2000 system, the DNS Client
service needed to be restarted or the machine rebooted.

=item $adapter->set_wins(@wins_servers)

Set the host's WINS servers to @wins_servers, which should be a list of
contactable WINS servers on the network. You can use an empty list
to remove all configured WINS servers.
On Windows NT only the first two WINS servers will actually be set; on Windows
2000 and later, all the WINS servers you specify will be be inserted into the
registry.

You will not be allowed to set this value if the host adapter is
configured through DHCP.

When tested on a Windows NT system, the machine needed to be rebooted for the
change to take effect. When tested on a Windows 2000 system, the machine
also needed to be rebooted.

=back

=head1 SEE ALSO

Win32::IPConfig

=head1 AUTHOR

James Macfarlane, E<lt>jmacfarla@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003,2004,2006,2010 by James Macfarlane

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION,
THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS
FOR A PARTICULAR PURPOSE.

=cut
