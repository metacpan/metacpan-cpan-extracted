#!/bin/false
# ABSTRACT: Cross-cutting constants for the OPNsense REST API
# PODNAME: WebService::OPNsense::Constants
use strictures 2;

package WebService::OPNsense::Constants;
$WebService::OPNsense::Constants::VERSION = '0.001';
use Const::Fast::Exporter qw( const );

# Actions
const our $ACTION_BLOCK  => 'block';
const our $ACTION_PASS   => 'pass';
const our $ACTION_REJECT => 'reject';

# Address families
const our $AF_INET   => 'inet';
const our $AF_INET6  => 'inet6';
const our $AF_INET46 => 'inet46';

# Alias types
const our $ALIAS_ASN           => 'asn';
const our $ALIAS_AUTHGROUP     => 'authgroup';
const our $ALIAS_DYNIPV6HOST   => 'dynipv6host';
const our $ALIAS_EXTERNAL      => 'external';
const our $ALIAS_GEOIP         => 'geoip';
const our $ALIAS_HOST          => 'host';
const our $ALIAS_INTERNAL      => 'internal';
const our $ALIAS_MAC           => 'mac';
const our $ALIAS_NETWORK       => 'network';
const our $ALIAS_NETWORK_GROUP => 'networkgroup';
const our $ALIAS_PORT          => 'port';
const our $ALIAS_URL           => 'url';
const our $ALIAS_URL_JSON      => 'urljson';
const our $ALIAS_URL_TABLE     => 'urltable';

# Directions
const our $DIRECTION_ANY => 'any';
const our $DIRECTION_IN  => 'in';
const our $DIRECTION_OUT => 'out';

# Enabled / Disabled state
const our $DISABLED => 0;
const our $ENABLED  => 1;

# Gateway
const our $GATEWAY_DEFAULT => 'default';

# Interface names (standard)
const our $INTERFACE_DMZ       => 'dmz';
const our $INTERFACE_GUEST     => 'guest';
const our $INTERFACE_LAN       => 'lan';
const our $INTERFACE_LOOPBACK  => 'lo0';
const our $INTERFACE_OPT1      => 'opt1';
const our $INTERFACE_OPT2      => 'opt2';
const our $INTERFACE_OPT3      => 'opt3';
const our $INTERFACE_OPT4      => 'opt4';
const our $INTERFACE_OPT5      => 'opt5';
const our $INTERFACE_OPT6      => 'opt6';
const our $INTERFACE_OPT7      => 'opt7';
const our $INTERFACE_OPT8      => 'opt8';
const our $INTERFACE_OPT9      => 'opt9';
const our $INTERFACE_WAN       => 'wan';
const our $INTERFACE_WAN2      => 'wan2';
const our $INTERFACE_WAN_DHCP  => 'wan_dhcp';
const our $INTERFACE_WAN_PPPOE => 'wan_pppoe';

# Interface group names
const our $IF_GROUP_DMZ   => 'dmz';
const our $IF_GROUP_GUEST => 'guest';
const our $IF_GROUP_LAN   => 'lan';
const our $IF_GROUP_OPT1  => 'opt1';
const our $IF_GROUP_OPT2  => 'opt2';
const our $IF_GROUP_OPT3  => 'opt3';
const our $IF_GROUP_OPT4  => 'opt4';
const our $IF_GROUP_OPT5  => 'opt5';
const our $IF_GROUP_OPT6  => 'opt6';
const our $IF_GROUP_OPT7  => 'opt7';
const our $IF_GROUP_OPT8  => 'opt8';
const our $IF_GROUP_OPT9  => 'opt9';
const our $IF_GROUP_WAN   => 'wan';

# Log levels
const our $LOG_LEVEL_NONE   => 'none';
const our $LOG_LEVEL_NORMAL => 'normal';
const our $LOG_LEVEL_HIGH   => 'high';

# One-to-one NAT types
const our $ONETOONE_BINAT => 'binat';
const our $ONETOONE_NAT   => 'nat';

# Protocols
const our $PROTO_ANY     => 'any';
const our $PROTO_ESP     => 'ESP';
const our $PROTO_GRE     => 'GRE';
const our $PROTO_ICMP    => 'ICMP';
const our $PROTO_OSPF    => 'OSPF';
const our $PROTO_PIM     => 'PIM';
const our $PROTO_SCTP    => 'SCTP';
const our $PROTO_TCP     => 'TCP';
const our $PROTO_TCP_UDP => 'TCP/UDP';
const our $PROTO_UDP     => 'UDP';
const our $PROTO_VRRP    => 'VRRP';

# Rule sequence positions
const our $SEQ_EARLY    => 'early';
const our $SEQ_FIRST    => 'first';
const our $SEQ_FLOATING => 'floating';
const our $SEQ_LAST     => 'last';

# SNAT modes
const our $SNAT_ADVANCED  => 'advanced';
const our $SNAT_AUTOMATIC => 'automatic';
const our $SNAT_DISABLED  => 'disabled';
const our $SNAT_HYBRID    => 'hybrid';

# State types
const our $STATETYPE_KEEP     => 'keep';
const our $STATETYPE_MODULATE => 'modulate';
const our $STATETYPE_NONE     => 'none';
const our $STATETYPE_SLOPPY   => 'sloppy';
const our $STATETYPE_SYNPROXY => 'synproxy';

# TCP flags
const our $TCP_FLAG_ACK => 'ack';
const our $TCP_FLAG_CWR => 'cwr';
const our $TCP_FLAG_ECE => 'ece';
const our $TCP_FLAG_FIN => 'fin';
const our $TCP_FLAG_PSH => 'psh';
const our $TCP_FLAG_RST => 'rst';
const our $TCP_FLAG_SYN => 'syn';
const our $TCP_FLAG_URG => 'urg';

# TLS versions
const our $TLS_VERSION_1_0 => '1.0';
const our $TLS_VERSION_1_1 => '1.1';
const our $TLS_VERSION_1_2 => '1.2';
const our $TLS_VERSION_1_3 => '1.3';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Constants - Cross-cutting constants for the OPNsense REST API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WebService::OPNsense::Constants;

    # All constants are exported by default
    print $ACTION_PASS;
    print $PROTO_TCP;
    print $INTERFACE_WAN;

=head1 DESCRIPTION

Provides shared constant values used across the OPNsense API.  Constants
cover actions, protocols, interfaces, directions, state types, and other
enum-like values that appear in multiple API controllers.

Constants are exported automatically on C<use>.  No explicit import list
is needed.

=head1 NAME

WebService::OPNsense::Constants - Cross-cutting constants for the OPNsense REST API

=head1 CONSTANTS

=head2 Actions

=over

=item C<$ACTION_BLOCK>

=item C<$ACTION_PASS>

=item C<$ACTION_REJECT>

=back

=head2 Address families

=over

=item C<$AF_INET> - IPv4

=item C<$AF_INET6> - IPv6

=item C<$AF_INET46> - IPv4+IPv6

=back

=head2 Alias types

=over

=item C<$ALIAS_ASN> - BGP ASN

=item C<$ALIAS_AUTHGROUP> - OpenVPN group

=item C<$ALIAS_DYNIPV6HOST> - Dynamic IPv6 Host

=item C<$ALIAS_EXTERNAL> - External (advanced)

=item C<$ALIAS_GEOIP> - GeoIP

=item C<$ALIAS_HOST> - Host(s)

=item C<$ALIAS_INTERNAL> - Internal (automatic)

=item C<$ALIAS_MAC> - MAC address

=item C<$ALIAS_NETWORK> - Network(s)

=item C<$ALIAS_NETWORK_GROUP> - Network group

=item C<$ALIAS_PORT> - Port(s)

=item C<$ALIAS_URL> - URL (IPs)

=item C<$ALIAS_URL_JSON> - URL Table in JSON format (IPs)

=item C<$ALIAS_URL_TABLE> - URL Table (IPs)

=back

=head2 Directions

=over

=item C<$DIRECTION_ANY>

=item C<$DIRECTION_IN>

=item C<$DIRECTION_OUT>

=back

=head2 Enabled / Disabled

=over

=item C<$ENABLED>

=item C<$DISABLED>

=back

=head2 Gateway

=over

=item C<$GATEWAY_DEFAULT>

=back

=head2 Interfaces

=over

=item C<$INTERFACE_DMZ>

=item C<$INTERFACE_GUEST>

=item C<$INTERFACE_LAN>

=item C<$INTERFACE_LOOPBACK>

=item C<$INTERFACE_OPT1> through C<$INTERFACE_OPT9>

=item C<$INTERFACE_WAN>

=item C<$INTERFACE_WAN2>

=item C<$INTERFACE_WAN_DHCP>

=item C<$INTERFACE_WAN_PPPOE>

=back

=head2 Interface groups

=over

=item C<$IF_GROUP_DMZ>

=item C<$IF_GROUP_GUEST>

=item C<$IF_GROUP_LAN>

=item C<$IF_GROUP_OPT1> through C<$IF_GROUP_OPT9>

=item C<$IF_GROUP_WAN>

=back

=head2 Log levels

=over

=item C<$LOG_LEVEL_NONE>

=item C<$LOG_LEVEL_NORMAL>

=item C<$LOG_LEVEL_HIGH>

=back

=head2 One-to-one NAT types

=over

=item C<$ONETOONE_BINAT>

=item C<$ONETOONE_NAT>

=back

=head2 Protocols

=over

=item C<$PROTO_ANY>

=item C<$PROTO_ESP>

=item C<$PROTO_GRE>

=item C<$PROTO_ICMP>

=item C<$PROTO_OSPF>

=item C<$PROTO_PIM>

=item C<$PROTO_SCTP>

=item C<$PROTO_TCP>

=item C<$PROTO_TCP_UDP>

=item C<$PROTO_UDP>

=item C<$PROTO_VRRP>

=back

=head2 Rule sequence positions

=over

=item C<$SEQ_EARLY>

=item C<$SEQ_FIRST>

=item C<$SEQ_FLOATING>

=item C<$SEQ_LAST>

=back

=head2 SNAT modes

=over

=item C<$SNAT_ADVANCED>

=item C<$SNAT_AUTOMATIC>

=item C<$SNAT_DISABLED>

=item C<$SNAT_HYBRID>

=back

=head2 State types

=over

=item C<$STATETYPE_KEEP>

=item C<$STATETYPE_MODULATE>

=item C<$STATETYPE_NONE>

=item C<$STATETYPE_SLOPPY>

=item C<$STATETYPE_SYNPROXY>

=back

=head2 TCP flags

=over

=item C<$TCP_FLAG_ACK>

=item C<$TCP_FLAG_CWR>

=item C<$TCP_FLAG_ECE>

=item C<$TCP_FLAG_FIN>

=item C<$TCP_FLAG_PSH>

=item C<$TCP_FLAG_RST>

=item C<$TCP_FLAG_SYN>

=item C<$TCP_FLAG_URG>

=back

=head2 TLS versions

=over

=item C<$TLS_VERSION_1_0>

=item C<$TLS_VERSION_1_1>

=item C<$TLS_VERSION_1_2>

=item C<$TLS_VERSION_1_3>

=back

=head1 SEE ALSO

L<WebService::OPNsense> - main client class

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
