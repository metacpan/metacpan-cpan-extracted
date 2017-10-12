package Win32::Net::Info;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

our $VERSION = '1.00';

use Exporter;

our %EXPORT_TAGS = (
    'subs' => [qw( interfaces lookupMac lookupMac6 )],
);
our @EXPORT_OK   = ( @{$EXPORT_TAGS{'subs'}} );

our @ISA = qw(Exporter);

our $LASTERROR;

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    return $self->interface(@_);
}

# Generic attribute methods
sub AUTOLOAD {
    my ( $self, $key ) = @_;

    my $attr = our $AUTOLOAD;
    $attr =~ s/.*:://;
    return if ( $attr eq 'DESTROY' );    # ignore destructor
    $self->{$attr} = $key if ( defined $key );
    return ( $self->{$attr} );
}

sub interface {
    my $self = shift;
    my $class = ref($self) || $self;

    my %params = (
        # _ifName     => 'Local Area Connection'
        pcap_prefix => '\Device\NPF_',
    );

    my %args;
    if ( @_ == 1 ) {
        ( $params{_ifName} ) = @_;
    } else {
        %args = @_;
        for ( keys(%args) ) {
            if ( (/^-?name$/i) || (/^-?interface$/i) || (/^-?dev(?:ice)?$/i) )
            {
                $params{_ifName} = $args{$_}

                  # pass through
            } else {
                $params{"_$_"} = $args{$_};
            }
        }
    }

    if ( !defined $params{_ifName} ) {
        $LASTERROR = "Interface not provided";
        return undef;
    }

    # Populate structure Adapter
    my $adapter
      = `wmic path Win32_NetworkAdapter where NetConnectionID="$params{_ifName}" get * /format:list 2>&1`;
    my @adapters = split /\n/, $adapter;
    for my $line (@adapters) {
        chomp $line;
        $line =~ s/\r//;
        if ( $line =~ /=/ ) {
            my ( $key, $value ) = split /=/, $line;
            if ( $value eq '' ) {
                $params{$key} = undef;
            } else {
                $params{$key} = $value;
            }
        }
    }

    # Populate structure AdapterConfiguration
    if ( defined( $params{Index} ) ) {
        my $adapter
          = `wmic path Win32_NetworkAdapterConfiguration where Index="$params{Index}" get * /format:list 2>&1`;
        my @adapters = split /\n/, $adapter;
        for my $line (@adapters) {
            chomp $line;
            $line =~ s/\r//;
            if ( $line =~ /=/ ) {
                my ( $key, $value ) = split /=/, $line;
                if ( $value eq '' ) {
                    $params{$key} = undef;
                } else {
                    $params{$key} = $value;
                }
            }
        }
    }

    # ipv4/6 and masks
    if ( defined( $params{IPAddress} ) ) {
        my $vari = $params{IPAddress};
        $vari =~ s/\{//g;
        $vari =~ s/\}//g;
        $vari =~ s/\"//g;
        my $vars = $params{IPSubnet};
        $vars =~ s/\{//g;
        $vars =~ s/\}//g;
        $vars =~ s/\"//g;
        my @ips   = split /,/, $vari;
        my @masks = split /,/, $vars;
        my ( @ipv4s,   @ipv4masks );
        my ( @ipv6s,   @ipv6masks );
        my ( @ipv6lls, @ipv6llmasks );

        for my $idx ( 0 .. $#ips ) {

            # ipv4
            if ( $ips[$idx] =~ /\./ ) {
                push @ipv4s,     $ips[$idx];
                push @ipv4masks, $masks[$idx]

                  # ipv6 link local
            } elsif ( $ips[$idx] =~ /^fe80\:/i ) {
                push @ipv6lls,     $ips[$idx];
                push @ipv6llmasks, $masks[$idx]

                  # ipv6
            } elsif ( $ips[$idx] =~ /\:/ ) {
                push @ipv6s,     $ips[$idx];
                push @ipv6masks, $masks[$idx];
            }
        }
        if ( $#ipv4s >= 0 ) {
            $params{_ipv4}         = \@ipv4s;
            $params{_ipv4_netmask} = \@ipv4masks;
        }
        if ( $#ipv6s >= 0 ) {
            $params{_ipv6}         = \@ipv6s;
            $params{_ipv6_netmask} = \@ipv6masks;
        }
        if ( $#ipv6lls >= 0 ) {
            $params{_ipv6_link_local}         = \@ipv6lls;
            $params{_ipv6_link_local_netmask} = \@ipv6llmasks;
        }
    }

    # ipv4/6 gateway
    if ( defined( $params{DefaultIPGateway} ) ) {
        my $varg = $params{DefaultIPGateway};
        $varg =~ s/\{//g;
        $varg =~ s/\}//g;
        $varg =~ s/\"//g;
        my $varm = $params{GatewayCostMetric};
        $varm =~ s/\{//g;
        $varm =~ s/\}//g;
        $varm =~ s/\"//g;
        my @gws = split /,/, $varg;
        my @met = split /,/, $varm;
        my ( @ipv4gws, @ipv4mets );
        my ( @ipv6gws, @ipv6mets );

        for my $idx ( 0 .. $#gws ) {

            # ipv4 gateway
            if ( $gws[$idx] =~ /\./ ) {
                push @ipv4gws,  $gws[$idx];
                push @ipv4mets, $met[$idx]

                  # ipv6 gateway
            } elsif ( $gws[$idx] =~ /\:/ ) {
                push @ipv6gws,  $gws[$idx];
                push @ipv6mets, $met[$idx];
            }
        }
        if ( $#ipv4gws >= 0 ) {
            $params{_ipv4_default_gateway} = \@ipv4gws;
            $params{_ipv4_gateway_metric}  = \@ipv4mets;
        }
        if ( $#ipv6gws >= 0 ) {
            $params{_ipv6_default_gateway} = \@ipv6gws;
            $params{_ipv6_gateway_metric}  = \@ipv6mets;
        }
    }

    # DNS Server
    if ( defined( $params{DNSServerSearchOrder} ) ) {
        my $var = $params{DNSServerSearchOrder};
        $var =~ s/\{//g;
        $var =~ s/\}//g;
        $var =~ s/\"//g;
        my @dns = split /,/, $var;
        my @ipv4dns;
        my @ipv6dns;
        for my $ds (@dns) {

            # ipv4 dns
            if ( $ds =~ /\./ ) {
                push @ipv4dns, $ds

                  # ipv6 dns
            } elsif ( $ds =~ /\:/ ) {
                push @ipv6dns, $ds;
            }
        }
        if ( $#ipv4dns >= 0 ) {
            $params{_ipv4_dns_server} = \@ipv4dns;
        }
        if ( $#ipv6dns >= 0 ) {
            $params{_ipv6_dns_server} = \@ipv6dns;
        }
    }

    # ipv4 gateway MAC
    if ( defined( $params{_ipv4_default_gateway} ) ) {
        for my $gw ( @{$params{_ipv4_default_gateway}} ) {
            my $output = `arp -a $gw`;
            my @lines = split /\n/, $output;
            my @ipv4gwmacs;
            for my $line (@lines) {
                if ( $line
                    =~ /^\s+$gw\s+((?:[0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2})\s+.*$/
                  ) {
                    my $ipv4gw = $1;
                    $ipv4gw =~ s/-/:/g;
                    $ipv4gw = lc($ipv4gw);
                    push @ipv4gwmacs, $ipv4gw;
                }
            }
            if ( $#ipv4gwmacs >= 0 ) {
                $params{_ipv4_gateway_mac} = \@ipv4gwmacs;
            }
        }
    }

    # ipv6 gateway MAC
    if ( defined( $params{_ipv6_default_gateway} ) ) {
        for my $gw ( @{$params{_ipv6_default_gateway}} ) {
            my $output
              = `netsh interface ipv6 show neighbors "$params{_ifName}"`;
            my @lines = split /\n/, $output;
            my @ipv6gwmacs;
            for my $line (@lines) {
                if ( $line
                    =~ /^$gw\s+((?:[0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2})\s+.*$/ )
                {
                    my $ipv6gw = $1;
                    $ipv6gw =~ s/-/:/g;
                    $ipv6gw = lc($ipv6gw);
                    push @ipv6gwmacs, $ipv6gw;
                }
            }
            if ( $#ipv6gwmacs >= 0 ) {
                $params{_ipv6_gateway_mac} = \@ipv6gwmacs;
            }
        }
    }

    # MTU v4
    if ( defined( $params{_ipv4} ) ) {
        my $output
          = `netsh interface ipv4 show subinterfaces "$params{_ifName}"`;
        my @lines = split /\n/, $output;
        for my $line (@lines) {
            if ( $line =~ /^\s*(\d+)\s*.*$params{_ifName}.*$/ ) {
                $params{_ipv4_mtu} = $1;
            }
        }
    }

    # MTU v6
    if ( defined( $params{_ipv6} ) ) {
        my $output
          = `netsh interface ipv6 show subinterfaces "$params{_ifName}"`;
        my @lines = split /\n/, $output;
        for my $line (@lines) {
            if ( $line =~ /^\s*(\d+)\s*.*$params{_ifName}.*$/ ) {
                $params{_ipv6_mtu} = $1;
            }
        }
    }

    # RETURN
    if ( defined( $params{Index} ) || !( defined( $params{_ifName} ) ) ) {
        return bless {
            %params,    # merge user parameters
        }, $class;
    } else {
        $LASTERROR = "Interface `$params{_ifName}' not found";
        return undef;
    }
}

sub name {
    my $self = shift;
    return $self->{_ifName};
}

sub adaptername {
    my $self = shift;
    return $self->{GUID};
}

sub host {
    return hostname(@_);
}

sub hostname {
    my $self = shift;
    return $self->{SystemName};
}

sub domain {
    return domainname(@_);
}

sub domainname {
    my $self  = shift;
    my $dname = $self->{DNSDomain};
    $dname =~ s/\.$//;
    return $dname;
}

sub dev {
    return devicename(@_);
}

sub device {
    return devicename(@_);
}

sub devicename {
    my $self = shift;
    return $self->{pcap_prefix} . $self->{GUID};
}

sub description {
    my $self = shift;
    return $self->{Description};
}

sub index {
    return ifindex(@_);
}

sub ifindex {
    my $self = shift;
    return $self->{InterfaceIndex};
}

sub mac {
    my $self = shift;
    return lc( $self->{MACAddress} );
}

sub ip {
    return ipv4(@_);
}

sub ipv4 {
    my $self = shift;
    wantarray ? return @{$self->{_ipv4}} : return $self->{_ipv4}->[0];
}

sub netmaskIp {
    return ipv4_netmask(@_);
}

sub ipv4_netmask {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv4_netmask}}
      : return $self->{_ipv4_netmask}->[0];
}

sub ip6 {
    return ipv6(@_);
}

sub ipv6 {
    my $self = shift;
    wantarray ? return @{$self->{_ipv6}} : return $self->{_ipv6}->[0];
}

sub netmaskIp6 {
    return ipv6_netmask(@_);
}

sub ipv6_netmask {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv6_netmask}}
      : return $self->{_ipv6_netmask}->[0];
}

sub ipv6_link_local {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv6_link_local}}
      : return $self->{_ipv6_link_local}->[0];
}

sub ipv6_link_local_netmask {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv6_link_local_netmask}}
      : return $self->{_ipv6_link_local_netmask}->[0];
}

# sub dhcpv6_iaid {
# my $self = shift;
# return $self->{dhcpv6_iaid}
# }

# sub dhcpv6_duid {
# my $self = shift;
# return $self->{dhcpv6_duid}
# }

sub gatewayIp {
    return ipv4_default_gateway(@_);
}

sub ipv4_default_gateway {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv4_default_gateway}}
      : return $self->{_ipv4_default_gateway}->[0];
}

sub metric {
    return ipv4_gateway_metric(@_);
}

sub ipv4_gateway_metric {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv4_gateway_metric}}
      : return $self->{_ipv4_gateway_metric}->[0]
      + $self->{IPConnectionMetric};
}

sub gatewayIp6 {
    return ipv6_default_gateway(@_);
}

sub ipv6_default_gateway {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv6_default_gateway}}
      : return $self->{_ipv6_default_gateway}->[0];
}

sub metric6 {
    return ipv6_gateway_metric(@_);
}

sub ipv6_gateway_metric {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv6_gateway_metric}}
      : return $self->{_ipv6_gateway_metric}->[0]
      + $self->{IPConnectionMetric};
}

sub gatewayMac {
    return ipv4_gateway_mac(@_);
}

sub ipv4_gateway_mac {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv4_gateway_mac}}
      : return $self->{_ipv4_gateway_mac}->[0];
}

sub gatewayMac6 {
    return ipv6_gateway_mac(@_);
}

sub ipv6_gateway_mac {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv6_gateway_mac}}
      : return $self->{_ipv6_gateway_mac}->[0];
}

sub ipv4_mtu {
    my $self = shift;
    return $self->{_ipv4_mtu};
}

sub ipv6_mtu {
    my $self = shift;
    return $self->{_ipv6_mtu};
}

sub mtu {
    my $self = shift;

    my $mtu;
    if ( defined( $self->{_ipv4_mtu} ) && defined( $self->{_ipv6_mtu} ) ) {
        $mtu = ( $self->{_ipv4_mtu}, $self->{_ipv6_mtu} )
          [$self->{_ipv4_mtu} > $self->{_ipv6_mtu}];
    } elsif ( defined( $self->{_ipv4_mtu} )
        && !defined( $self->{_ipv6_mtu} ) ) {
        $mtu = $self->{_ipv4_mtu};
    } elsif ( !defined( $self->{_ipv4_mtu} )
        && defined( $self->{_ipv6_mtu} ) ) {
        $mtu = $self->{_ipv6_mtu};
    } else {
        $mtu       = undef;
        $LASTERROR = "Cannot determine MTU";
    }

    return $mtu;
}

sub dnsserver {
    return ipv4_dns_server(@_);
}

sub ipv4_dns_server {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv4_dns_server}}
      : return $self->{_ipv4_dns_server}->[0];
}

sub dnsserver6 {
    return ipv6_dns_server(@_);
}

sub ipv6_dns_server {
    my $self = shift;
    wantarray
      ? return @{$self->{_ipv6_dns_server}}
      : return $self->{_ipv6_dns_server}->[0];
}

sub info {
    my $self = shift;
    return $self->dump(@_);
}

sub dump {
    my $self = shift;
    use Data::Dumper;
    $Data::Dumper::Sortkeys = 1;
    print Dumper $self;
    return

      # for my $key (sort(keys(%{$self}))) {
      # if (ref($self->{$key}) eq 'ARRAY') {
      # print "'$key' => [\n";
      # for my $i (@{$self->{$key}}) {
      # print "            $i\n"
      # }
      # print "            ]\n"
      # } else {
      # print "'$key' => $self->{$key}\n"
      # }
      # }
}

sub pcap_prefix {
    my $self = shift;
    my ($arg) = @_;

    if ( !defined($arg) ) {
        return $self->{pcap_prefix};
    } else {
        if ( defined( $self->{device} ) ) {
            my $pcap_prefix = $self->{pcap_prefix};
            $pcap_prefix =~ s/\\/\\\\/g;
            $self->{device} =~ s/^$pcap_prefix//;
            $self->{device} = $arg . $self->{device};
        }
        $self->{pcap_prefix} = $arg;
        return $self->{pcap_prefix};
    }
}

sub error {
    return ($LASTERROR);
}

sub interfaces {
    my @rets;
    my $retType = wantarray;

    my $interface;
    my @ints = `netsh interface show interface`;

    for (@ints) {
        next if ( $_ !~ /^Enabled\s+/ );
        chomp $_;
        my ( undef, undef, undef, $iface ) = split /\s+/, $_, 4;
        $interface->{$iface}++;
    }

    for ( sort( keys( %{$interface} ) ) ) {
        if ( !defined($retType) ) {
            print "$_\n";
        } else {
            push @rets, $_;
        }
    }

    if ( !defined($retType) ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub lookupMac {
    my $self = shift;
    my $class = ref($self) || $self;

    my ( $ip, $retry, $timeout ) = @_;

    $retry   ||= 1;
    $timeout ||= 1;

    if ( !defined($ip) ) {
        $LASTERROR = "IP Address required";
        return;
    }

    my $output = `arp -a "$ip"`;

    my @lines = split /\n/, $output;
    for my $line (@lines) {
        if ( $line =~ /^\s*$ip\s*.*$/ ) {
            $line =~ s/^\s*//;
            my @parts = split /\s+/, $line;
            $parts[1] =~ s/\-/\:/g;
            return $parts[1];
        }
    }

    # else return default gateway mac
    return ipv4_gateway_mac($self);
}

sub lookupMac6 {
    my $self = shift;
    my $class = ref($self) || $self;

    my ( $ip6, $retry, $timeout ) = @_;

    $retry   ||= 1;
    $timeout ||= 1;

    if ( !defined($ip6) ) {
        $LASTERROR = "IPv6 Address required";
        return;
    }

    my $output = `netsh interface ipv6 show neighbors address=$ip6`;

    my @lines = split /\n/, $output;
    for my $line (@lines) {
        if ( $line =~ /^\s*$ip6\s*.*$/ ) {
            $line =~ s/^\s*//;
            my @parts = split /\s+/, $line;
            $parts[1] =~ s/\-/\:/g;
            return $parts[1];
        }
    }

    # else return default gateway mac
    return ipv6_gateway_mac($self);
}

1;

__END__

=head1 NAME

Win32::Net::Info - Win32 Network Adapter Interface

=head1 SYNOPSIS

  use Win32::Net::Info;

  my $interface = Win32::Net::Info->new('Wireless Network Connection');

  printf "Name: %s\n", $interface->name;
  printf "MAC: %s\n", $interface->mac;
  printf "IPv4: %s\n", $interface->ipv4;

=head1 DESCRIPTION

Win32::Net::Info is a module to retrieve Windows interface adapter 
information (such as IP[v6] addresses, gateways, MAC, etc...).  It is 
implemented with system functions such as C<wmic>, C<netsh> and C<arp>.  A 
better approach may be to use XS with C<GetAdaptersAddresses()> and parse the
C<IP_ADAPTER_ADDRESSES> structure.  Alas, that is proving difficult to do.

This module was developed since I couldn't find an existing CPAN module that 
handled this information specifically for Windows, let alone find Win32 
support in the many interface modules already on CPAN (see B<SEE ALSO>).  
The existing CPAN interface modules also used different APIs so finding a 
common interface for both Windows and *nix with all the features was not 
possible.

This modules attempts to provide many of the API calls from *nix interface 
modules specifically to Win32.

=head1 METHODS

=head2 new() - create a new Win32::Net::Info object

  my $interfaces = Win32::Net::Info->new([OPTIONS]);

Create a new Win32::Net::Info object with OPTIONS as optional parameters.
Valid options are:

  Option      Description                           Default
  ------      -----------                           -------
  -interface  Friendly name of interface            Local Area Connection
  -dev
  -device

Called with option eliminates the need to call the interface() method.

Single option indicates B<interface>.

=head2 interface() - find provided interface

  my $interface = $interfaces->interface(OPTIONS);

Find provided interface and populate the return object.  Valid options are:

  Option      Description                           Default
  ------      -----------                           -------
  -interface  Friendly name of interface            [none]
  -dev
  -device

Single option indicates B<interface>.

Allows the following to be called.

=head3 name() - return name of interface

  $interface->name();

Return friendly name of interface.  This in in the form of 
'Local Area Connection', for example.

=head3 adaptername() - return adapter name of interface

  $interface->adaptername();

Return adapter name of interface.  This is in the form of
'{1234ABCD-12AB-34CD-56EF-123456ABCDEF}', for example.

=head3 hostname() - return host name of interface

  $interface->hostname();

Return host name of interface.

Alias:

=over 4

=item B<host>

=back

=head3 domainname() - return domain name of interface

  $interface->domainname();

Return domain name of interface.

Alias:

=over 4

=item B<domain>

=back

=head3 devicename() - return device name of interface

  $interface->devicename();

Return adapter name of interface.  This is in the form of
'\Device\NPF_{1234ABCD-12AB-34CD-56EF-123456ABCDEF}', for example.
Optional argument drops the PCap prefix (default '\Device\NPF_').

Alias:

=over 4

=item B<dev>

=item B<device>

=back

=head3 description() - return description of interface

  $interface->description();

Return description of interface.

=head3 ifindex() - return ifIndex of interface

  $interface->ifindex();

Return interface index of interface.

Alias:

=over 4

=item B<index>

=back

=head3 mac() - return MAC address of interface

  $interface->mac();

Return MAC address of interface.

=head3 ipv4() - return IPv4 address of interface

  [$ret | @ret =] $interface->ipv4();

Return IPv4 address of interface.  Scalar context returns first, array context returns all.

Alias:

=over 4

=item B<ip>

=back

=head3 ipv4_netmask() - return IPv4 network mask of interface

  [$ret | @ret =] $interface->ipv4_netmask();

Return IPv4 network mask of interface.  Scalar context returns first, array context returns all.

Alias:

=over 4

=item B<netmaskIp>

=back

=head3 ipv6() - return IPv6 address of interface

  [$ret | @ret =] $interface->ipv6();

Return IPv6 address of interface.  Scalar context returns first, array context returns all.

Alias:

=over 4

=item B<ip6>

=back

=head3 ipv6_netmask() - return IPv6 network mask of interface

  [$ret | @ret =] $interface->ipv6_netmask();

Return IPv6 network mask of interface.  Scalar context returns first, array context returns all.

Alias:

=over 4

=item B<netmaskIp6>

=back

=head3 ipv6_link_local() - return IPv6 link-local address of interface

  [$ret | @ret =] $interface->ipv6_link_local();

Return IPv6 link-local address of interface.  Scalar context returns first, array context returns all.

=head3 ipv6_link_local_netmask() - return IPv6 link local network mask of interface

  [$ret | @ret =] $interface->ipv6_link_local_netmask();

Return IPv6 link local network mask of interface.  Scalar context returns first, array context returns all.

=head3 ipv4_default_gateway() - return IPv4 default gateway of interface

  [$ret | @ret =] $interface->ipv4_default_gateway();

Return IPv4 default gateway of interface.  Scalar context returns first, array context returns all.

Alias:

=over 4

=item B<gatewayIp>

=back

=head3 ipv4_gateway_metric() - return IPv4 gateway metric of interface

  [$ret | @ret =] $interface->ipv4_gateway_metric();

Return IPv4 gateway metric of interface.  Scalar context returns first, array context returns all.

Alias:

=over 4

=item B<metric>

=back

=head3 ipv6_default_gateway() - return IPv6 default gateway of interface

  [$ret | @ret =] $interface->ipv6_default_gateway();

Return IPv6 default gateway of interface.  Scalar context returns first, array context returns all.

Alias:

=over 4

=item B<gatewayIp6>

=back

=head3 ipv6_gateway_metric() - return IPv6 gateway metric of interface

  [$ret | @ret =] $interface->ipv6_gateway_metric();

Return IPv6 gateway metric of interface.  Scalar context returns first, array context returns all.

Alias:

=over 4

=item B<metric6>

=back

=head3 ipv4_gateway_mac() - return MAC address of IPv4 default gateway of interface

  $interface->ipv4_gateway_mac();

Return MAC address of IPv4 default gateway of interface.

Alias:

=over 4

=item B<gatewayMac>

=back

=head3 ipv6_gateway_mac() - return MAC address of IPv6 default gateway of interface

  $interface->ipv6_gateway_mac();

Return MAC address of IPv6 default gateway of interface.

Alias:

=over 4

=item B<gatewayMac6>

=back

=head3 ipv4_mtu() - return MTU of interface for IPv4

  $interface->ipv4_mtu();

Return MTU of interface for IPv4.

=head3 ipv6_mtu() - return MTU of interface for IPv6

  $interface->ipv6_mtu();

Return MTU of interface for IPv6.

=head3 mtu() - return MTU of interface

  $interface->mtu();

Return MTU of interface.  Minimum value between IPv4 and IPv6 MTU if 
both exist; otherwise, just the value of the MTU that does exist.  Undef 
if neither exist.

=head3 ipv4_dns_server() - return IPv4 DNS servers of interface

  [$ret | @ret =] $interface->ipv4_dns_server();

Return IPv4 DNS servers of interface.  Scalar context returns first, array context returns all.

Alias:

=over 4

=item B<dnsserver>

=back

=head3 ipv6_dns_server() - return IPv6 DNS servers of interface

  [$ret | @ret =] $interface->ipv6_dns_server();

Return IPv6 DNS servers of interface.  Scalar context returns first, array context returns all.

Alias:

=over 4

=item B<dnsserver6>

=back

=head2 dump() - dump interface information

  $interface->dump;

Dump all interface information (basically, all of the above).

Alias:

=over 4

=item B<info>

=back

=head2 pcap_prefix() - get or set pcap prefix

  $interface->pcap_prefix([name]);

Return the PCap prefix (default '\Device\NPF_').  Optional B<name> sets 
the PCap prefix for future calls to B<adaptername>.

=head2 error() - print last error

  printf "Error: %s\n", Win32::Net::Info->error;

Return last error.

=head1 SUBROUTINES

=head2 interfaces() - list available interfaces

  my $interfaces = Win32::Net::Info->interfaces;

List available interfaces by friendly name.

  Context   Usage                                Return
  -------   -----                                ------
  none      Win32::Net::Info->interfaces;       (print list)
  SCALAR    $i = Win32::Net::Info->interfaces;  array ref
  ARRAY     @i = Win32::Net::Info->interfaces;  array

=head2 lookupMac() - lookup IPv4 address MAC address

  my $mac = Win32::Net::Info->lookupMac(ipv4_addr);

Return MAC address for provided IPv4 address.

=head2 lookupMac6() - lookup IPv6 address MAC address

  my $mac = Win32::Net::Info->lookupMac6(ipv6_addr);

Return MAC address for provided IPv6 address.

=head1 EXPORTS

Load them: C<use Win32::Net::Info qw(:subs)>:

=over 4

=item B<interfaces>

=item B<lookupMac>

=item B<lookupMac6>

=back

=head1 SEE ALSO

L<IO::Interface>, L<Net::Interface>, L<Win32::IPHelper>, L<Win32::IPConfig>, 
L<Net::Libdnet>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2011 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
