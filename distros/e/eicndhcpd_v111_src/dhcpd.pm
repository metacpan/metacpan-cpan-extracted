#!/perl/bin
# ------------------------------------------------------------------------ 
# EICNDHCPD v1.11 for NT4 
# EICNDHCPD Copyright (c)1998,1999 EICN & Nils Reichen <eicndhcpd@worldcom.ch> 
# All rights reserved.
# http://home.worldcom.ch/nreichen/eicndhcpd.html
# DHCPD.PM part
# ------------------------------------------------------------------------ 
# EICNDHCPD is a static DHCP server for NT4.
# "static" because each computer is identified by his MAC address
# (ethernet addr.) and obtains the same configuration (IP addr., ...) all time.
# All the host configuration is centralized in a text file (netdata.dat).
#
# Made by Nils Reichen <eicndhcpd@worldcom.ch>
# EICN, NEUCHATEL SCHOOL OF ENGINEERING
# Le Locle, Switzerland
#
# under Perl 5.004_02 for WinNT4.0
# (c)1998,1999 Copyright EICN & Nils Reichen <eicndhcpd@worldcom.ch>
# 
# Use under GNU General Public License
# Details can be found at:http://www.gnu.org/copyleft/gpl.html
#
#$Header: dhcpd.pm,v 1.11 1999/06/27
# -----------------------------------------------------------------------------
# v0.9b Created: 19.May.1998 - Created by Nils Reichen <eicndhcpd@worldcom.ch>
# v0.901b Revised: 26.May.1998 - Renew bug solved, and optimized code
# v0.902b Revised: 04.Jun.1998 - EventLog and Service NT
# v1.0 Revised: 18.Jun.1998 - Fix some little bugs (inet_aton,...)
# v1.1 Revised: 07.Oct.1998 - Fix \x0a bug
# v1.11 Revised: 27.June.1999 - Fix a problem with particular MS DHCP client
$ver      = "v1.11";
$ver_date = "27.June.1999";
# -----------------------------------------------------------------------------

package Dhcpd;
require Exporter;      # For symbol export
@ISA=qw(Exporter);
@EXPORT=qw(*SERVER_PORT *CLIENT_PORT
	   *BOOTREQUEST *BOOTREPLY *DHCPDISCOVER *DHCPOFFER *DHCPREQUEST 
	   *DHCPDECLINE *DHCPACK *DHCPNAK *DHCPRELEASE *DHCPINFORM
	   *HTYPE_ETHER *HTYPE_IEEE802 *HLEN_ETHER *BROADCAST
	   *NOBROADCAST *SNAME *FILE *MAGIC_COOKIE *O_PAD *O_SUBNET_MASK 
	   *O_ROUTER *O_DNS_SERVER *O_HOST_NAME *O_OVERLOAD
	   *O_DOMAIN_NAME *O_VENDOR_SPECIFIC *O_NETBIOS_NAME_SERVER
	   *O_NETBIOS_NODE_TYPE *O_NETBIOS_SCOPE *O_ADDRESS_REQUEST
	   *O_ADDRESS_TIME *O_DHCP_MSG_TYPE *O_DHCP_SERVER_ID
	   *O_PARAMETER_LIST *O_DHCP_MESSAGE
	   *O_RENEWAL_TIME *O_REBINDING_TIME *O_CLIENT_ID *O_END
	   );

############################# UDP/IP port ####################################
*SERVER_PORT=\67; # Msg from client to a server are sent to the port 67d,
*CLIENT_PORT=\68; # and server to client msg to the port 68d (=44h).


############################# DHCP frame #####################################

# op field: Message op code (BOOTP (rfc951) message types)
*BOOTREQUEST=\"\x1";
*BOOTREPLY=\"\x2";

# htype field: Hardware address type 
*HTYPE_ETHER=\"\x1";                        # Ethernet 10Mbps
*HTYPE_IEEE802=\"\x6";                      # IEEE 802.2 Token Ring

# hlen field: Harware address length
*HLEN_ETHER=\"\x6";                         # 10Mb ethernet

# hops field: Should be zero in client's message
# Must not be set here !

# xid field: random number chosen by the client, used by the client
#            and server to associate messages and responses.

# secs field: Filled in by the client

# flags field: Flags
*BROADCAST=\"\x80\x00";                      # Broadcast flag
*NOBROADCAST=\"\x00\x00";                    # No broadcast

# ciaddr field: Client IP address
# Must not be set here !

# yiaddr field: 'your' IP address
# Must not be set here !

# siaddr field: IP address of next server to use in bootstrap;
#               returned in DHCPOFFER, DHCPACK by server
# Not set here, but in the dhcpd.conf

# giaddr field: Relay agent IP address, used in booting via a relay agent
# Must not be set here !

# chaddr field: Client hardware address
# Must not be set here !

# Waring: The options field may be extended into the 'file'
#         and 'sname' fields. See 'magic cookie' in RFC 2132

# sname field: Optional server host name, null terminated string
# Must not be change ! (64 bytes)
*SNAME=\"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";

# file field: Boot file name, null terminated string.
# Must not  be change ! (128 bytes)
*FILE=\"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";

# options field: Optional parameters
#                See the options documents in rfc2131 
#                or the IANA assignments bootp-dhcp-parameters
#                for defined options.
# Options supported by Microsoft DHCP client and serveur (March 1998):
# 0,1,3,6,15,44,46,47,50,51,53,54,58,59,61,255

# magic cookie: The options area includes first a four-octet 'magic cookie'
#               followed by the options (See RFC 2132).
*MAGIC_COOKIE=\"\x63\x82\x53\x63";

# op field: Message type
*DHCPDISCOVER=\"\x1";
*DHCPOFFER=\"\x2";
*DHCPREQUEST=\"\x3";
*DHCPDECLINE=\"\x4";
*DHCPACK=\"\x5";
*DHCPNAK=\"\x6";
*DHCPRELEASE=\"\x7";
*DHCPINFORM=\"\x8";

# options types:
*O_PAD=\"\x0";
*O_SUBNET_MASK=\"\x01";
# *O_TIME_OFFSET=\"\x02";
*O_ROUTER=\"\x03";
# *O_TIME_SERVER=\"\x04";
# *O_NAME_SERVER=\"\x05";
*O_DNS_SERVER=\"\x06";
# *O_LOG_SERVER=\"\x07";
# *O_QUOTES_SERVER=\"\x08";
# *O_LPR_SERVER=\"\x09";
# *O_IMPRESS_SERVER=\"\x0a";
# *O_RLP_SERVER=\"\x0b";
*O_HOST_NAME=\"\x0c";
# *O_BOOT_SIZE=\"\x0d";
# *O_MERIT_DUMP=\"\x0e";
*O_DOMAIN_NAME=\"\x0f";
# *O_SWAP_SERVER=\"\x10";
# *O_ROOT_PATH=\"\x11";
# *O_EXTENSION_FILE=\"\x12";
# *O_IP_FORWARDING=\"\x13";
# *O_SOURCE_ROUTING=\"\x14";
# *O_POLICY_FILTER=\"\x15";
# *O_MAX_DGRAM_REASSEMBLY=\"\x16";
# *O_DEFAULT_IP_TTL=\"\x17";
# *O_MTU_TIMEOUT=\"\x18";
# *O_MTU_PLATEAU=\"\x19";
# *O_MTU_INTERFACE=\"\x1a";
# *O_MTU_SUBNET=\"\x1b";
# *O_BROADCAST_ADDRESS=\"\x1c";
# *O_MASK_DISCOVERY=\"\x1d";
# *O_MASK_SUPPLIER=\"\x1e";
# *O_ROUTER_DISCOVERY=\"\x1f";
# *O_ROUTER_REQUEST=\"\x20";
# *O_STATIC_ROUTE=\"\x21";
# *O_TRAILERS=\"\x22";
# *O_ARP_TIMEOUT=\"\x23";
# *O_ETHERNET_ENCAPSULATION=\"\x24";
# *O_DEFAULT_TCP_TTL=\"\x25";
# *O_KEEPALIVE_TIME=\"\x26";
# *O_KEEPALIVE_DATA=\"\x27";
# *O_NIS_DOMAIN=\"\x28";
# *O_NIS_SERVERS=\"\x29";
# *O_NTP_SERVERS=\"\x2a";
*O_VENDOR_SPECIFIC=\"\x2b";
*O_NETBIOS_NAME_SERVER=\"\x2c";
# *O_NETBIOS_DIST_SERVER=\"\x2d";
*O_NETBIOS_NODE_TYPE=\"\x2e";
*O_NETBIOS_SCOPE=\"\x2f";
# *O_X_WINDOW_FONT=\"\x30";
# *O_X_WINDOW_MANAGER=\"\x31";
*O_ADDRESS_REQUEST=\"\x32";
*O_ADDRESS_TIME=\"\x33";
*O_OVERLOAD=\"\x34";
*O_DHCP_MSG_TYPE=\"\x35";
*O_DHCP_SERVER_ID=\"\x36";
*O_PARAMETER_LIST=\"\x37";
*O_DHCP_MESSAGE=\"\x38";
# *O_DHCP_MAX_MSG_SIZE=\"\x39";
*O_RENEWAL_TIME=\"\x3a";
*O_REBINDING_TIME=\"\x3b";
# *O_CLASS_ID=\"\x3c";
*O_CLIENT_ID=\"\x3d";
*O_END=\"\xff";          # The last option must always be the 'end' option


############################# END OF DHCPD.PM #############################
1;





