package Win32::IPConfig;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.10';

use Carp;
use Win32::TieRegistry qw/:KEY_/;
use Win32::IPConfig::Adapter;

sub new
{
    my $class = shift;
    my $host = shift || "";
    my $access = shift || "ro";

    my $hklm = $Registry->Connect($host, "HKEY_LOCAL_MACHINE",
            { Access => $access eq 'rw' ? KEY_READ|KEY_WRITE : KEY_READ })
        or return undef;

    $hklm->SplitMultis(1); # return REG_MULTI_SZ as arrays

    my $osversion = $hklm->{"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\\\CurrentVersion"} or return undef;

    my $self = {};
    $self->{"osversion"} = $osversion;
    $self->{"access"} = $access;

    # Remember the necessary registry keys
    my $services_key = $hklm->{"SYSTEM\\CurrentControlSet\\Services\\"}
        or return undef;
    $self->{"netbt_params_key"} = $services_key->{"Netbt\\Parameters\\"}
        or return undef;
    $self->{"tcpip_params_key"} = $services_key->{"Tcpip\\Parameters\\"}
        or return undef;

    # Retrieve each network card's config
    my $networkcards_key = $hklm->{"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\NetworkCards\\"} or return undef;
    for my $nic ($networkcards_key->SubKeyNames) {
        if (my $adapter = Win32::IPConfig::Adapter->new($hklm, $nic, $access)) {
            push @{$self->{"adapters"}}, $adapter;
        }
    }

    bless $self, $class;
    return $self;
}

sub get_adapters
{
    return wantarray ? @{$_[0]->{"adapters"}} : $_[0]->{"adapters"};
}

sub get_configured_adapters
{
    my @adapters = ();
    for my $adapter (@{$_[0]->{"adapters"}}) {
        if (my @ipaddresses = $adapter->get_ipaddresses) {
            push @adapters, $adapter unless $ipaddresses[0] eq "0.0.0.0";
        }
    }
    return wantarray ? @adapters : \@adapters;
}

sub get_osversion { return $_[0]->{"osversion"}; }

# Value: Hostname (REG_SZ)
# NT:    Tcpip\Parameters
# 2000+: Tcpip\Parameters

# Value: NV Hostname (REG_SZ)
# 2000+: Tcpip\Parameters

sub get_hostname
{
    my $self = shift;

    return $self->{"tcpip_params_key"}{"\\Hostname"};
}

# Value: Domain (REG_SZ)
# NT:    Tcpip\Parameters
# 2000+: Tcpip\Parameters (primary)
# 2000+: Tcpip\Parameters\Interfaces\<adapter> (connection-specific)

# Value: NV Domain (REG_SZ)
# 2000+: Tcpip\Parameters

# Value: DhcpDomain (REG_SZ)
# NT:    Tcpip\Parameters
# 2000+: Tcpip\Parameters
# 2000+: Tcpip\Parameters\Interfaces\<adapter> (connection-specific)

# How do you know when to read the Domain value and when to read the DhcpDomain
# value? The Domain and DhcpDomain values are attributes of a host, but
# the EnableDHCP value is an attribute of an adapter.

# On Windows NT 4.0, when I set the adapter to static, the DhcpDomain
# setting disappears from the registry to leave only the empty Domain setting.
# This also appears to be the case on Windows XP.

# What happens when Domain setting is set statically and an adapter card adds a
# DhcpDomain setting as well - i.e. when both Domain and DhcpDomain exist?

# On Windows NT 4.0, when I set the adapter to dynamic and set a static domain
# setting, the static domain setting is returned by ipconfig /all while both
# settings exist in the registry.

# This suggests: return the Domain setting if it is non-empty. Otherwise
# return the DhcpDomain if it is present. Otherwise, return an empty string.

sub get_domain
{
    my $self = shift;

    my $domain = $self->{"tcpip_params_key"}{"\\Domain"};
    if (! $domain) {
        $domain = $self->{"tcpip_params_key"}{"\\DhcpDomain"} || "";
    }
    return $domain;
}

# Value: SearchList (REG_SZ) (space delimited on NT, comma delimited on 2000+)
# NT:    Tcpip\Parameters
# 2000+: Tcpip\Parameters

# The Windows 2000 Advanced TCP/IP Settings dialog gives you the choice of
# resolving unqualified names by:
# 1. appending primary and connection specific DNS suffixes
# 2. appending a user-specified list of DNS suffixes
# It appears to choose between each method simply by seeing if
# SearchList is set or not: if it is set, use it, otherwise append
# the primary and connection specific DNS suffixes.

# The Windows NT Microsoft TCP/IP Properties dialog simply allows you
# the option of specifying a domain suffix search order.

sub get_searchlist
{
    my $self = shift;

    my @searchlist;
    if ($self->{"osversion"} >= 5.0) {
        @searchlist = split /,/, $self->{"tcpip_params_key"}{"\\SearchList"};
    } else {
        @searchlist = split / /, $self->{"tcpip_params_key"}{"\\SearchList"};
    }
    return wantarray ? @searchlist : \@searchlist;
}

# Value: NodeType (REG_DWORD)
# NT:    Netbt\Parameters
# 2000+: Netbt\Parameters

# Value: DhcpNodeType (REG_DWORD) (overidden by NodeType)
# NT:    Netbt\Parameters
# 2000+: Netbt\Parameters

# On Windows NT 4.0, if the adapter receives a DhcpNodeType setting from the
# DHCP server, the DhcpNodeType setting is present. Otherwise neither the
# NodeType nor the DhcpNodeType setting is present. When neither setting is
# present, Windows NT 4.0 reports "Node Type = Broadcast".

# According to the Q120642 and Q314053 the NodeType setting will override the
# DhcpNodeType setting.

# This suggests: use the NodeType value if set. Otherwise check for a
# DhcpNodeType setting. If there is no DhcpNodeType make a stab at getting the
# default NodeType. Check all the adapters present for WINS settings. If there
# are any set, then return H-node, else return B-node.

sub get_nodetype
{
    my $self = shift;

    my %nodetypes = (1=>"B-node", 2=>"P-node", 4=>"M-node", 8=>"H-node");

    # Windows NT 4.0's ipconfig reports these node types as
    # Broadcast, Peer-Peer, Mixed, Hybrid

    my $nodetype;
    if (my $type = $self->{"netbt_params_key"}{"\\NodeType"}) {
        $nodetype = hex($type);
    } elsif ($type = $self->{"netbt_params_key"}{"\\DhcpNodeType"}) {
        $nodetype = hex($type)
    } else {
        my $wins_count = 0;
        for my $adapter ($self->get_adapters) {
            my @wins = $adapter->get_wins;
            $wins_count += @wins;
        }
        $nodetype = $wins_count ? 8 : 1;
    }
    return $nodetypes{$nodetype};
}

# Value: IPEnableRouter (REG_DWORD)
# NT:    Tcpip\Parameters
# 2000+: Tcpip\Parameters

sub is_router
{
    my $self = shift;

    if (my $router = $self->{"tcpip_params_key"}{"\\IPEnableRouter"}) {
        return hex($router);
    } else {
        return 0; # defaults to 0
    }
}

# Value: EnableProxy (REG_DWORD)
# NT:    Netbt\Parameters
# 2000+: Netbt\Parameters

sub is_wins_proxy
{
    my $self = shift;

    if (my $proxy = $self->{"netbt_params_key"}{"\\EnableProxy"}) {
        return hex($proxy);
    } else {
        return 0; # defaults to 0
    }
}

# Value: EnableLMHOSTS (REG_DWORD)
# NT:    Netbt\Parameters
# 2000+: Netbt\Parameters

sub is_lmhosts_enabled
{
    my $self = shift;

    if (my $lmhosts_enabled = $self->{"netbt_params_key"}{"\\EnableLMHOSTS"}) {
        return hex($lmhosts_enabled);
    } else {
        return 1; # defaults to 1
    }
}

# Value: EnableDns (REG_DWORD)
# NT:    Netbt\Parameters
# 2000+: Netbt\Parameters

sub is_dns_enabled_for_netbt
{
    my $self = shift;

    if (my $dns_enabled_for_netbt = $self->{"netbt_params_key"}{"\\EnableDns"}) {
        return hex($dns_enabled_for_netbt);
    } else {
        return 0; # defaults to 0
    }
}

sub get_adapter
{
    my $self = shift;
    my $adapter_name_or_num = shift;

    if ($adapter_name_or_num =~ m/^\d+$/) {
        my $adapter = $self->{"adapters"}[$adapter_name_or_num];
        return $adapter;
    } else {
        for my $adapter ($self->get_adapters) {
            if (uc $adapter->get_name eq uc $adapter_name_or_num) {
                return $adapter;
            }
        }
        return undef; # couldn't find a matching adapter.
    }
}

sub dump
{
    my $self = shift;

    print "hostname=", $self->get_hostname, "\n";
    print "domain=", $self->get_domain, "\n";
    my @searchlist = $self->get_searchlist;
    print "searchlist=@searchlist (", scalar @searchlist, ")\n";
    print "nodetype=", $self->get_nodetype, "\n";
    print "ip router enabled=", $self->is_router ? "Yes":"No", "\n";
    print "wins proxy enabled=", $self->is_wins_proxy ? "Yes":"No", "\n";
    print "LMHOSTS enabled=", $self->is_lmhosts_enabled ? "Yes":"No", "\n";
    print "dns enabled for netbt=", $self->is_dns_enabled_for_netbt ? "Yes":"No", "\n";
    my $i = 0;
    for ($self->get_adapters) {
        print "\nAdapter ", $i++, ":\n";
        $_->dump;
    }
}

1;

__END__

=head1 NAME

Win32::IPConfig - IP Configuration Settings for Windows NT/2000/XP/2003

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

Win32::IPConfig is a module for retrieving TCP/IP network settings from a
Windows NT/2000/XP/2003 host machine. Specify the host and the module will
retrieve and collate all the information from the specified machine's registry
(using Win32::TieRegistry). For this module to retrieve information from a host
machine, you must have read access to the registry on that machine.

Important Note: The functionality of this module has been superseded by WMI
(Windows Management Instrumentation).

=head1 METHODS

=over 4

=item $ipconfig = Win32::IPConfig->new($host, $access);

Creates a new Win32::IPConfig object. $host is passed directly to
Win32::TieRegistry, and can be a computer name or an IP address.

$access should be set to 'rw' if write access is required.
This is only necessary if you intend to use the
set_domain, set_dns, or set_wins methods
of the Win32::IPConfig::Adapter object.
If $access is not set, it will default to 'ro', or read-only access.

=item $ipconfig->get_hostname

Returns a string containing the DNS hostname of the machine.

=item $ipconfig->get_domain

Returns a string containing the domain name suffix of the machine.
For machines running Windows 2000 or later
(which can have connection-specific domain name suffixes for each adapter)
this is the primary domain name for the machine.

=item $ipconfig->get_searchlist

Returns a list of domain name suffixes added during
DNS name resolution.
They are only used if the initial DNS name lookup fails.
(Returns a reference to a list in a scalar context.)

=item $ipconfig->get_nodetype

Returns the NetBIOS over TCP/IP node type of the machine.
The four possible node types are:

    B-node - resolve NetBIOS names by broadcast
    P-node - resolve NetBIOS names using a WINS server
    M-node - resolve NetBIOS names by broadcast, then using a WINS server
    H-node - resolve NetBIOS names using a WINS server, then by broadcast

Windows defaults to B-node if no WINS servers are configured,
and defaults to H-node if there are.

=item $ipconfig->is_router

Returns 1 if the host is configured to route packets between its network
adapters; returns 0 if it is not. Only applicable to machines with
more than one adapter. By default, this is set to 0 (no routing).

=item $ipconfig->is_wins_proxy

Returns 1 if the host is configured to be a WINS proxy for NetBIOS over TCP/IP
name resolution; returns 0 if it is not.
By default, this is set to 0 (do not act as a WINS proxy).
A WINS proxy will answer broadcast name queries it detects on its subnet.
It is only required in networks where there are hosts that cannot be
configured to use WINS servers.

=item $ipconfig->is_lmhosts_enabled

Returns 1 if the host is configured to use the LMHOSTS file for NetBIOS over
TCP/IP name resolution; returns 0 if it is not.
By default, this is set to 1 (use LMHOSTS).
The LMHOSTS file does not exist unless created by an administrator
at %SystemRoot%\system32\drivers\etc\LMHOSTS.

=item $ipconfig->is_dns_enabled_for_netbt

Returns 1 if the host is configured to use DNS for NetBIOS over TCP/IP name
resolution; returns 0 if it is not.
By default, this is set to 0 (do not use DNS).
DNS will only be used for NetBIOS over TCP/IP name resolution
after all standard methods have failed (cache, WINS, broadcast, LMHOSTS).

This setting has little relevance to Windows 2000 and later,
as these operating systems were designed to work without WINS servers
and already use DNS (through "direct hosting")
to resolve Windows computer names.

=item $ipconfig->get_adapters

The real business of the module. Returns a list of
Win32::IPConfig::Adapter objects.
(Returns a reference to a list in a scalar context.)

Each adapter object contains the TCP/IP network settings for an
individual adapter.
See the Win32::IPConfig::Adapter documentation for more information.

=item $ipconfig->get_configured_adapters

Returns a list of Win32::IPConfig::Adapter objects that have IP
addresses configured, whether manually or through DHCP.
(Returns a reference to a list in a scalar context.)

=item $ipconfig->get_adapter($name_or_num)

Returns the Win32::IPConfig::Adapter specified by $name_or_num.
If you specify a string (e.g. "Local Area Connection")
it will look for an adapter with that name,
otherwise it will take the adapter from the list of
Win32::IPConfig::Adapter objects with the index value of $name_or_num.
Use get_adapter(0) to retrieve the first adapter.

You could use the following code to retrieve the adapter named
"Local Area Connection" on Windows 2000 (or later) or the first adapter
on Windows NT.

    my $adapter = $ipconfig->get_adapter("Local Area Connection") ||
                  $ipconfig->get_adapter(0);

=back

=head1 EXAMPLES

=head2 Displaying the IP Settings for a PC

This example is a variation on the code given in the synopsis; it
prints the output in a style closer to the ipconfig command. Specify
the target computer's name as the first command line parameter.

It also uses the get_configured_adapters method to filter out adapters that
do not have IP addresses.

    use strict;
    use Win32::IPConfig;

    my $host = shift || Win32::NodeName;

    my $ipconfig = Win32::IPConfig->new($host)
        or die "Unable to connect to $host\n";

    print "Host Name. . . . . . . . . . . . : ", $ipconfig->get_hostname, "\n";
    print "Domain Name (Primary). . . . . . : ", $ipconfig->get_domain, "\n";
    my @searchlist = $ipconfig->get_searchlist;
    print "Search List. . . . . . . . . . . : $searchlist[0]\n";
    print "                                   $searchlist[$_]\n"
        for (1..@searchlist-1);
    print "Node Type  . . . . . . . . . . . : ", $ipconfig->get_nodetype, "\n";
    print "IP Routing Enabled . . . . . . . : ",
        $ipconfig->is_router ? "Yes" : "No", "\n";
    print "WINS Proxy Enabled . . . . . . . : ",
        $ipconfig->is_wins_proxy ? "Yes" : "No", "\n";
    print "LMHOSTS Enabled. . . . . . . . . : ",
        $ipconfig->is_lmhosts_enabled ? "Yes" : "No", "\n";
    print "DNS Enabled for NetBT. . . . . . : ",
        $ipconfig->is_dns_enabled_for_netbt ? "Yes" : "No", "\n";

    for my $adapter ($ipconfig->get_configured_adapters) {
        print "\nAdapter '", $adapter->get_name, "':\n\n";
        print "DHCP Enabled . . . . . . . . . . : ",
            $adapter->is_dhcp_enabled ? "Yes" : "No", "\n";
        print "Domain Name. . . . . . . . . . . : ", $adapter->get_domain, "\n";

        my @ipaddresses = $adapter->get_ipaddresses;
        my @subnet_masks = $adapter->get_subnet_masks;
        for (0..@ipaddresses-1) {
            print "IP Address . . . . . . . . . . . : $ipaddresses[$_]\n";
            print "Subnet Mask. . . . . . . . . . . : $subnet_masks[$_]\n";
        }

        my @gateways = $adapter->get_gateways;
        print "Default Gateway. . . . . . . . . : $gateways[0]\n";
        print "                                   $gateways[$_]\n"
            for (1..@gateways-1);

        my @dns = $adapter->get_dns;
        print "DNS Servers. . . . . . . . . . . : $dns[0]\n";
        print "                                   $dns[$_]\n" for (1..@dns-1);

        my @wins = $adapter->get_wins;
        print "WINS Servers . . . . . . . . . . : $wins[0]\n";
        print "                                   $wins[$_]\n" for (1..@wins-1);
    }

=head2 Collecting IP Settings for a list of PCs

This example outputs data in CSV format with the hostname and domain followed
by the IP configuration settings for the first adapter. (Additional adapters
are ignored.)

    use strict;
    use Win32::IPConfig;

    print "hostname,domain,";
    print "dhcp?,ip addresses,subnet masks,gateways,dns servers,wins servers\n";

    while (<DATA>) {
        chomp;
        if (my $ipconfig = Win32::IPConfig->new($_)) {
            print $ipconfig->get_hostname, ",";
            print $ipconfig->get_domain, ",";

            if (my $adapter = $ipconfig->get_adapter(0)) {
                print $adapter->is_dhcp_enabled ? "Y," : "N,";
                my @ipaddresses = $adapter->get_ipaddresses;
                print "@ipaddresses,";
                my @subnet_masks = $adapter->get_subnet_masks;
                print "@subnet_masks,";
                my @gateways = $adapter->get_gateways;
                print "@gateways,";
                my @dns = $adapter->get_dns;
                print "@dns,";
                my @wins = $adapter->get_wins;
                print "@wins";
            }
            print "\n";
        }
    }

    __DATA__
    HOST1
    HOST2
    HOST3

=head2 Setting a PC's DNS servers

This example demonstrates how you can change the DNS servers set on a remote
host. It reads the target machine name and the IP addresses for the DNS servers
from the command line.

    use strict;
    use Win32::IPConfig;

    my $host = shift or die "You must specify a host\n";
    if (my $ipconfig = Win32::IPConfig->new($host, 'rw')) {
        if (my $adapter = $ipconfig->get_adapter("Local Area Connection") ||
                          $ipconfig->get_adapter(0)) {
            if (! $adapter->is_dhcp_enabled) {
                $adapter->set_dns(@ARGV);
                my @dns = $adapter->get_dns;
                if (@dns) {
                    print "Set to @dns\n";
                } else {
                    print "Cleared\n";
                }
            } else {
                warn "Adapter is configured for DHCP\n";
            }
        } else {
            warn "Could not find an adapter to configure\n";
        }
    } else {
        warn "Host '$host' is down or you do not have Administrator access\n";
    }

=head1 REGISTRY KEYS USED

IP configuration information is stored in a number of registry keys under
HKLM\SYSTEM\CurrentControlSet\Services.

To find adapter-specific configuration information, you need the adapter id,
which can be found by examining the list of installed network cards at
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkCards.

Note that on Windows NT the adapter id will look like a service or driver,
while on Windows 2000 and later it will be a GUID.

There are some variations in where the
TCP/IP configuration data is stored.
For all operating systems, the main keys are:

    Tcpip\Parameters
    Netbt\Parameters

Adapter-specific TCP/IP settings are stored in:

    <adapter_id>\Parameters\Tcpip (Windows NT)
    Tcpip\Parameters\Interfaces\<adapter_id> (Windows 2000 and later)

NetBIOS over TCP/IP stores adapter-specific settings in:

    Netbt\Adapters\<adapter_id> (Windows NT)
    Netbt\Parameters\Interfaces\Tcpip_<adapter_id> (Windows 2000 and later)

=head1 NOTES

Windows 2000 and later will use DNS and WINS to resolve Windows computer names,
whereas Windows NT will use WINS and only use DNS if configured to do so (see
the is_dns_enabled_for_netbt method).

For Windows 2000 and later, both the primary and connection-specific domain
settings are significant and will be used in this initial name
resolution process.

The DHCP Server options correspond to the following registry values:

    003 Router              ->  DhcpDefaultGateway
    006 DNS Servers         ->  DhcpNameServer
    015 DNS Domain Name     ->  DhcpDomain
    044 WINS/NBNS Servers   ->  DhcpNameServer/DhcpNameServerList
    046 WINS/NBT Node Type  ->  DhcpNodeType

=head1 SEE ALSO

Win32::IPConfig::Adapter

Win32::TieRegistry

The following Microsoft support articles were helpful:

=over 4

=item *

Q120642 TCP/IP and NBT Configuration Parameters for Windows 2000 or Windows NT

=item *

Q314053 TCP/IP and NBT Configuration Parameters for Windows XP

=back

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
