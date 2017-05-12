package Win32::NetPacket;

#
# Copyright (c) 2003 Jean-Louis Morel <jl_morel@bribes.org>
#
# Version 0.03 (08/02/2006)
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;

# use AutoLoader;

our @ISA     = qw(Exporter DynaLoader);
our $VERSION = '0.03';
our $DEBUG   = 0;
our $AUTOLOAD;

# for GetNetType
my @type = qw( NdisMedium802_3 NdisMedium802_5 NdisMediumFddi NdisMediumWan
  NdisMediumLocalTalk NdisMediumDix NdisMediumArcnetRaw
  NdisMediumArcnet878_2 NdisMediumAtm NdisMediumWirelessWan
  NdisMediumIrda NdisMediumMax
);

# Export

our %EXPORT_TAGS = (
  'hack' => [    # procedural interface, for hacker only ;-)
    qw(
      GetAdapterNames GetNetInfo GetVersion
      _PacketGetAdapterNames _PacketGetNetInfo _PacketOpenAdapter
      _PacketCloseAdapter _PacketAllocatePacket _GetBytesReceived
      _PacketFreePacket _PacketInitPacket _PacketReceivePacket _PacketSetHwFilter
      _PacketSetBuff _PacketGetStats _PacketSetReadTimeout _PacketResetAdapter
      _PacketGetRequest _PacketSetBpf _PacketSetNumWrites _PacketSendPacket
      _PacketSetMode _PacketSetMinToCopy _GetReadEvent
      )
  ],

  'ndis' => [
    qw(
      NDIS_802_3_MAC_OPTION_PRIORITY NDIS_PACKET_TYPE_DIRECTED
      NDIS_PACKET_TYPE_MULTICAST NDIS_PACKET_TYPE_ALL_MULTICAST
      NDIS_PACKET_TYPE_BROADCAST NDIS_PACKET_TYPE_SOURCE_ROUTING
      NDIS_PACKET_TYPE_PROMISCUOUS NDIS_PACKET_TYPE_SMT
      NDIS_PACKET_TYPE_ALL_LOCAL NDIS_PACKET_TYPE_MAC_FRAME
      NDIS_PACKET_TYPE_FUNCTIONAL NDIS_PACKET_TYPE_ALL_FUNCTIONAL
      NDIS_PACKET_TYPE_GROUP NDIS_RING_SIGNAL_LOSS NDIS_RING_HARD_ERROR
      NDIS_RING_SOFT_ERROR NDIS_RING_TRANSMIT_BEACON NDIS_RING_LOBE_WIRE_FAULT
      NDIS_RING_AUTO_REMOVAL_ERROR NDIS_RING_REMOVE_RECEIVED
      NDIS_RING_COUNTER_OVERFLOW NDIS_RING_SINGLE_STATION NDIS_RING_RING_RECOVERY
      NDIS_PROT_OPTION_ESTIMATED_LENGTH NDIS_PROT_OPTION_NO_LOOPBACK
      NDIS_PROT_OPTION_NO_RSVD_ON_RCVPKT NDIS_MAC_OPTION_COPY_LOOKAHEAD_DATA
      NDIS_MAC_OPTION_RECEIVE_SERIALIZED NDIS_MAC_OPTION_TRANSFERS_NOT_PEND
      NDIS_MAC_OPTION_NO_LOOPBACK NDIS_MAC_OPTION_FULL_DUPLEX
      NDIS_MAC_OPTION_EOTX_INDICATION NDIS_MAC_OPTION_RESERVED
      NDIS_CO_MAC_OPTION_DYNAMIC_LINK_SPEED
      )
  ],

  'oid' => [
    qw(
      OID_GEN_SUPPORTED_LIST OID_GEN_HARDWARE_STATUS OID_GEN_MEDIA_SUPPORTED
      OID_GEN_MEDIA_IN_USE OID_GEN_MAXIMUM_LOOKAHEAD OID_GEN_MAXIMUM_FRAME_SIZE
      OID_GEN_LINK_SPEED OID_GEN_TRANSMIT_BUFFER_SPACE
      OID_GEN_RECEIVE_BUFFER_SPACE OID_GEN_TRANSMIT_BLOCK_SIZE
      OID_GEN_RECEIVE_BLOCK_SIZE OID_GEN_VENDOR_ID OID_GEN_VENDOR_DESCRIPTION
      OID_GEN_CURRENT_PACKET_FILTER OID_GEN_CURRENT_LOOKAHEAD
      OID_GEN_DRIVER_VERSION OID_GEN_MAXIMUM_TOTAL_SIZE OID_GEN_PROTOCOL_OPTIONS
      OID_GEN_MAC_OPTIONS OID_GEN_MEDIA_CONNECT_STATUS
      OID_GEN_MAXIMUM_SEND_PACKETS OID_GEN_VENDOR_DRIVER_VERSION
      OID_GEN_SUPPORTED_GUIDS OID_GEN_NETWORK_LAYER_ADDRESSES
      OID_GEN_TRANSPORT_HEADER_OFFSET OID_GEN_MACHINE_NAME
      OID_GEN_RNDIS_CONFIG_PARAMETER OID_GEN_VLAN_ID OID_GEN_MEDIA_CAPABILITIES
      OID_GEN_PHYSICAL_MEDIUM OID_GEN_XMIT_OK OID_GEN_RCV_OK
      OID_GEN_XMIT_ERROR OID_GEN_RCV_ERROR OID_GEN_RCV_NO_BUFFER
      OID_GEN_DIRECTED_BYTES_XMIT OID_GEN_DIRECTED_FRAMES_XMIT
      OID_GEN_MULTICAST_BYTES_XMIT OID_GEN_MULTICAST_FRAMES_XMIT
      OID_GEN_BROADCAST_BYTES_XMIT OID_GEN_BROADCAST_FRAMES_XMIT
      OID_GEN_DIRECTED_BYTES_RCV OID_GEN_DIRECTED_FRAMES_RCV
      OID_GEN_MULTICAST_BYTES_RCV OID_GEN_MULTICAST_FRAMES_RCV
      OID_GEN_BROADCAST_BYTES_RCV OID_GEN_BROADCAST_FRAMES_RCV
      OID_GEN_RCV_CRC_ERROR OID_GEN_TRANSMIT_QUEUE_LENGTH OID_GEN_GET_TIME_CAPS
      OID_GEN_GET_NETCARD_TIME OID_GEN_NETCARD_LOAD OID_GEN_DEVICE_PROFILE
      OID_GEN_INIT_TIME_MS OID_GEN_RESET_COUNTS OID_GEN_MEDIA_SENSE_COUNTS
      OID_GEN_FRIENDLY_NAME OID_GEN_MINIPORT_INFO OID_GEN_RESET_VERIFY_PARAMETERS
      OID_GEN_CO_SUPPORTED_LIST OID_GEN_CO_HARDWARE_STATUS
      OID_GEN_CO_MEDIA_SUPPORTED OID_GEN_CO_MEDIA_IN_USE OID_GEN_CO_LINK_SPEED
      OID_GEN_CO_VENDOR_ID OID_GEN_CO_VENDOR_DESCRIPTION
      OID_GEN_CO_DRIVER_VERSION OID_GEN_CO_PROTOCOL_OPTIONS
      OID_GEN_CO_MAC_OPTIONS OID_GEN_CO_MEDIA_CONNECT_STATUS
      OID_GEN_CO_VENDOR_DRIVER_VERSION OID_GEN_CO_SUPPORTED_GUIDS
      OID_GEN_CO_GET_TIME_CAPS OID_GEN_CO_GET_NETCARD_TIME
      OID_GEN_CO_MINIMUM_LINK_SPEED OID_GEN_CO_XMIT_PDUS_OK
      OID_GEN_CO_RCV_PDUS_OK OID_GEN_CO_XMIT_PDUS_ERROR OID_GEN_CO_RCV_PDUS_ERROR
      OID_GEN_CO_RCV_PDUS_NO_BUFFER OID_GEN_CO_RCV_CRC_ERROR
      OID_GEN_CO_TRANSMIT_QUEUE_LENGTH OID_GEN_CO_BYTES_XMIT OID_GEN_CO_BYTES_RCV
      OID_GEN_CO_NETCARD_LOAD OID_GEN_CO_DEVICE_PROFILE
      OID_GEN_CO_BYTES_XMIT_OUTSTANDING OID_802_3_PERMANENT_ADDRESS
      OID_802_3_CURRENT_ADDRESS OID_802_3_MULTICAST_LIST
      OID_802_3_MAXIMUM_LIST_SIZE OID_802_3_MAC_OPTIONS
      OID_802_3_RCV_ERROR_ALIGNMENT OID_802_3_XMIT_ONE_COLLISION
      OID_802_3_XMIT_MORE_COLLISIONS OID_802_3_XMIT_DEFERRED
      OID_802_3_XMIT_MAX_COLLISIONS OID_802_3_RCV_OVERRUN OID_802_3_XMIT_UNDERRUN
      OID_802_3_XMIT_HEARTBEAT_FAILURE OID_802_3_XMIT_TIMES_CRS_LOST
      OID_802_3_XMIT_LATE_COLLISIONS OID_802_5_PERMANENT_ADDRESS
      OID_802_5_CURRENT_ADDRESS OID_802_5_CURRENT_FUNCTIONAL
      OID_802_5_CURRENT_GROUP OID_802_5_LAST_OPEN_STATUS
      OID_802_5_CURRENT_RING_STATUS OID_802_5_CURRENT_RING_STATE
      OID_802_5_LINE_ERRORS OID_802_5_LOST_FRAMES OID_802_5_BURST_ERRORS
      OID_802_5_AC_ERRORS OID_802_5_ABORT_DELIMETERS
      OID_802_5_FRAME_COPIED_ERRORS OID_802_5_FREQUENCY_ERRORS
      OID_802_5_TOKEN_ERRORS OID_802_5_INTERNAL_ERRORS
      OID_FDDI_LONG_PERMANENT_ADDR OID_FDDI_LONG_CURRENT_ADDR
      OID_FDDI_LONG_MULTICAST_LIST OID_FDDI_LONG_MAX_LIST_SIZE
      OID_FDDI_SHORT_PERMANENT_ADDR OID_FDDI_SHORT_CURRENT_ADDR
      OID_FDDI_SHORT_MULTICAST_LIST OID_FDDI_SHORT_MAX_LIST_SIZE
      OID_FDDI_ATTACHMENT_TYPE OID_FDDI_UPSTREAM_NODE_LONG
      OID_FDDI_DOWNSTREAM_NODE_LONG OID_FDDI_FRAME_ERRORS OID_FDDI_FRAMES_LOST
      OID_FDDI_RING_MGT_STATE OID_FDDI_LCT_FAILURES OID_FDDI_LEM_REJECTS
      OID_FDDI_LCONNECTION_STATE OID_FDDI_SMT_STATION_ID
      OID_FDDI_SMT_OP_VERSION_ID OID_FDDI_SMT_HI_VERSION_ID
      OID_FDDI_SMT_LO_VERSION_ID OID_FDDI_SMT_MANUFACTURER_DATA
      OID_FDDI_SMT_USER_DATA OID_FDDI_SMT_MIB_VERSION_ID OID_FDDI_SMT_MAC_CT
      OID_FDDI_SMT_NON_MASTER_CT OID_FDDI_SMT_MASTER_CT
      OID_FDDI_SMT_AVAILABLE_PATHS OID_FDDI_SMT_CONFIG_CAPABILITIES
      OID_FDDI_SMT_CONFIG_POLICY OID_FDDI_SMT_CONNECTION_POLICY
      OID_FDDI_SMT_T_NOTIFY OID_FDDI_SMT_STAT_RPT_POLICY
      OID_FDDI_SMT_TRACE_MAX_EXPIRATION OID_FDDI_SMT_PORT_INDEXES
      OID_FDDI_SMT_MAC_INDEXES OID_FDDI_SMT_BYPASS_PRESENT OID_FDDI_SMT_ECM_STATE
      OID_FDDI_SMT_CF_STATE OID_FDDI_SMT_HOLD_STATE
      OID_FDDI_SMT_REMOTE_DISCONNECT_FLAG OID_FDDI_SMT_STATION_STATUS
      OID_FDDI_SMT_PEER_WRAP_FLAG OID_FDDI_SMT_MSG_TIME_STAMP
      OID_FDDI_SMT_TRANSITION_TIME_STAMP OID_FDDI_SMT_SET_COUNT
      OID_FDDI_SMT_LAST_SET_STATION_ID OID_FDDI_MAC_FRAME_STATUS_FUNCTIONS
      OID_FDDI_MAC_BRIDGE_FUNCTIONS OID_FDDI_MAC_T_MAX_CAPABILITY
      OID_FDDI_MAC_TVX_CAPABILITY OID_FDDI_MAC_AVAILABLE_PATHS
      OID_FDDI_MAC_CURRENT_PATH OID_FDDI_MAC_UPSTREAM_NBR
      OID_FDDI_MAC_DOWNSTREAM_NBR OID_FDDI_MAC_OLD_UPSTREAM_NBR
      OID_FDDI_MAC_OLD_DOWNSTREAM_NBR OID_FDDI_MAC_DUP_ADDRESS_TEST
      OID_FDDI_MAC_REQUESTED_PATHS OID_FDDI_MAC_DOWNSTREAM_PORT_TYPE
      OID_FDDI_MAC_INDEX OID_FDDI_MAC_SMT_ADDRESS OID_FDDI_MAC_LONG_GRP_ADDRESS
      OID_FDDI_MAC_SHORT_GRP_ADDRESS OID_FDDI_MAC_T_REQ OID_FDDI_MAC_T_NEG
      OID_FDDI_MAC_T_MAX OID_FDDI_MAC_TVX_VALUE OID_FDDI_MAC_T_PRI0
      OID_FDDI_MAC_T_PRI1 OID_FDDI_MAC_T_PRI2 OID_FDDI_MAC_T_PRI3
      OID_FDDI_MAC_T_PRI4 OID_FDDI_MAC_T_PRI5 OID_FDDI_MAC_T_PRI6
      OID_FDDI_MAC_FRAME_CT OID_FDDI_MAC_COPIED_CT OID_FDDI_MAC_TRANSMIT_CT
      OID_FDDI_MAC_TOKEN_CT OID_FDDI_MAC_ERROR_CT OID_FDDI_MAC_LOST_CT
      OID_FDDI_MAC_TVX_EXPIRED_CT OID_FDDI_MAC_NOT_COPIED_CT OID_FDDI_MAC_LATE_CT
      OID_FDDI_MAC_RING_OP_CT OID_FDDI_MAC_FRAME_ERROR_THRESHOLD
      OID_FDDI_MAC_FRAME_ERROR_RATIO OID_FDDI_MAC_NOT_COPIED_THRESHOLD
      OID_FDDI_MAC_NOT_COPIED_RATIO OID_FDDI_MAC_RMT_STATE OID_FDDI_MAC_DA_FLAG
      OID_FDDI_MAC_UNDA_FLAG OID_FDDI_MAC_FRAME_ERROR_FLAG
      OID_FDDI_MAC_NOT_COPIED_FLAG OID_FDDI_MAC_MA_UNITDATA_AVAILABLE
      OID_FDDI_MAC_HARDWARE_PRESENT OID_FDDI_MAC_MA_UNITDATA_ENABLE
      OID_FDDI_PATH_INDEX OID_FDDI_PATH_RING_LATENCY OID_FDDI_PATH_TRACE_STATUS
      OID_FDDI_PATH_SBA_PAYLOAD OID_FDDI_PATH_SBA_OVERHEAD
      OID_FDDI_PATH_CONFIGURATION OID_FDDI_PATH_T_R_MODE
      OID_FDDI_PATH_SBA_AVAILABLE OID_FDDI_PATH_TVX_LOWER_BOUND
      OID_FDDI_PATH_T_MAX_LOWER_BOUND OID_FDDI_PATH_MAX_T_REQ
      OID_FDDI_PORT_MY_TYPE OID_FDDI_PORT_NEIGHBOR_TYPE
      OID_FDDI_PORT_CONNECTION_POLICIES OID_FDDI_PORT_MAC_INDICATED
      OID_FDDI_PORT_CURRENT_PATH OID_FDDI_PORT_REQUESTED_PATHS
      OID_FDDI_PORT_MAC_PLACEMENT OID_FDDI_PORT_AVAILABLE_PATHS
      OID_FDDI_PORT_MAC_LOOP_TIME OID_FDDI_PORT_PMD_CLASS
      OID_FDDI_PORT_CONNECTION_CAPABILITIES OID_FDDI_PORT_INDEX
      OID_FDDI_PORT_MAINT_LS OID_FDDI_PORT_BS_FLAG OID_FDDI_PORT_PC_LS
      OID_FDDI_PORT_EB_ERROR_CT OID_FDDI_PORT_LCT_FAIL_CT
      OID_FDDI_PORT_LER_ESTIMATE OID_FDDI_PORT_LEM_REJECT_CT OID_FDDI_PORT_LEM_CT
      OID_FDDI_PORT_LER_CUTOFF OID_FDDI_PORT_LER_ALARM
      OID_FDDI_PORT_CONNNECT_STATE OID_FDDI_PORT_PCM_STATE
      OID_FDDI_PORT_PC_WITHHOLD OID_FDDI_PORT_LER_FLAG
      OID_FDDI_PORT_HARDWARE_PRESENT OID_FDDI_SMT_STATION_ACTION
      OID_FDDI_PORT_ACTION OID_FDDI_IF_DESCR OID_FDDI_IF_TYPE OID_FDDI_IF_MTU
      OID_FDDI_IF_SPEED OID_FDDI_IF_PHYS_ADDRESS OID_FDDI_IF_ADMIN_STATUS
      OID_FDDI_IF_OPER_STATUS OID_FDDI_IF_LAST_CHANGE OID_FDDI_IF_IN_OCTETS
      OID_FDDI_IF_IN_UCAST_PKTS OID_FDDI_IF_IN_NUCAST_PKTS
      OID_FDDI_IF_IN_DISCARDS OID_FDDI_IF_IN_ERRORS OID_FDDI_IF_IN_UNKNOWN_PROTOS
      OID_FDDI_IF_OUT_OCTETS OID_FDDI_IF_OUT_UCAST_PKTS
      OID_FDDI_IF_OUT_NUCAST_PKTS OID_FDDI_IF_OUT_DISCARDS OID_FDDI_IF_OUT_ERRORS
      OID_FDDI_IF_OUT_QLEN OID_FDDI_IF_SPECIFIC OID_WAN_PERMANENT_ADDRESS
      OID_WAN_CURRENT_ADDRESS OID_WAN_QUALITY_OF_SERVICE OID_WAN_PROTOCOL_TYPE
      OID_WAN_MEDIUM_SUBTYPE OID_WAN_HEADER_FORMAT OID_WAN_GET_INFO
      OID_WAN_SET_LINK_INFO OID_WAN_GET_LINK_INFO OID_WAN_LINE_COUNT
      OID_WAN_PROTOCOL_CAPS OID_WAN_GET_BRIDGE_INFO OID_WAN_SET_BRIDGE_INFO
      OID_WAN_GET_COMP_INFO OID_WAN_SET_COMP_INFO OID_WAN_GET_STATS_INFO
      OID_WAN_CO_GET_INFO OID_WAN_CO_SET_LINK_INFO OID_WAN_CO_GET_LINK_INFO
      OID_WAN_CO_GET_COMP_INFO OID_WAN_CO_SET_COMP_INFO OID_WAN_CO_GET_STATS_INFO
      OID_LTALK_CURRENT_NODE_ID OID_LTALK_IN_BROADCASTS
      OID_LTALK_IN_LENGTH_ERRORS OID_LTALK_OUT_NO_HANDLERS OID_LTALK_COLLISIONS
      OID_LTALK_DEFERS OID_LTALK_NO_DATA_ERRORS OID_LTALK_RANDOM_CTS_ERRORS
      OID_LTALK_FCS_ERRORS OID_ARCNET_PERMANENT_ADDRESS
      OID_ARCNET_CURRENT_ADDRESS OID_ARCNET_RECONFIGURATIONS OID_TAPI_ACCEPT
      OID_TAPI_ANSWER OID_TAPI_CLOSE OID_TAPI_CLOSE_CALL
      OID_TAPI_CONDITIONAL_MEDIA_DETECTION OID_TAPI_CONFIG_DIALOG
      OID_TAPI_DEV_SPECIFIC OID_TAPI_DIAL OID_TAPI_DROP OID_TAPI_GET_ADDRESS_CAPS
      OID_TAPI_GET_ADDRESS_ID OID_TAPI_GET_ADDRESS_STATUS
      OID_TAPI_GET_CALL_ADDRESS_ID OID_TAPI_GET_CALL_INFO
      OID_TAPI_GET_CALL_STATUS OID_TAPI_GET_DEV_CAPS OID_TAPI_GET_DEV_CONFIG
      OID_TAPI_GET_EXTENSION_ID OID_TAPI_GET_ID OID_TAPI_GET_LINE_DEV_STATUS
      OID_TAPI_MAKE_CALL OID_TAPI_NEGOTIATE_EXT_VERSION OID_TAPI_OPEN
      OID_TAPI_PROVIDER_INITIALIZE OID_TAPI_PROVIDER_SHUTDOWN
      OID_TAPI_SECURE_CALL OID_TAPI_SELECT_EXT_VERSION
      OID_TAPI_SEND_USER_USER_INFO OID_TAPI_SET_APP_SPECIFIC
      OID_TAPI_SET_CALL_PARAMS OID_TAPI_SET_DEFAULT_MEDIA_DETECTION
      OID_TAPI_SET_DEV_CONFIG OID_TAPI_SET_MEDIA_MODE
      OID_TAPI_SET_STATUS_MESSAGES OID_TAPI_GATHER_DIGITS OID_TAPI_MONITOR_DIGITS
      OID_ATM_SUPPORTED_VC_RATES OID_ATM_SUPPORTED_SERVICE_CATEGORY
      OID_ATM_SUPPORTED_AAL_TYPES OID_ATM_HW_CURRENT_ADDRESS
      OID_ATM_MAX_ACTIVE_VCS OID_ATM_MAX_ACTIVE_VCI_BITS
      OID_ATM_MAX_ACTIVE_VPI_BITS OID_ATM_MAX_AAL0_PACKET_SIZE
      OID_ATM_MAX_AAL1_PACKET_SIZE OID_ATM_MAX_AAL34_PACKET_SIZE
      OID_ATM_MAX_AAL5_PACKET_SIZE OID_ATM_SIGNALING_VPIVCI OID_ATM_ASSIGNED_VPI
      OID_ATM_ACQUIRE_ACCESS_NET_RESOURCES OID_ATM_RELEASE_ACCESS_NET_RESOURCES
      OID_ATM_ILMI_VPIVCI OID_ATM_DIGITAL_BROADCAST_VPIVCI
      OID_ATM_GET_NEAREST_FLOW OID_ATM_ALIGNMENT_REQUIRED OID_ATM_LECS_ADDRESS
      OID_ATM_SERVICE_ADDRESS OID_ATM_CALL_PROCEEDING OID_ATM_CALL_ALERTING
      OID_ATM_PARTY_ALERTING OID_ATM_CALL_NOTIFY OID_ATM_MY_IP_NM_ADDRESS
      OID_ATM_RCV_CELLS_OK OID_ATM_XMIT_CELLS_OK OID_ATM_RCV_CELLS_DROPPED
      OID_ATM_RCV_INVALID_VPI_VCI OID_ATM_CELLS_HEC_ERROR
      OID_ATM_RCV_REASSEMBLY_ERROR OID_PNP_CAPABILITIES OID_PNP_SET_POWER
      OID_PNP_QUERY_POWER OID_PNP_ADD_WAKE_UP_PATTERN
      OID_PNP_REMOVE_WAKE_UP_PATTERN OID_PNP_WAKE_UP_PATTERN_LIST
      OID_PNP_ENABLE_WAKE_UP OID_PNP_WAKE_UP_OK OID_PNP_WAKE_UP_ERROR
      OID_TCP_TASK_OFFLOAD OID_TCP_TASK_IPSEC_ADD_SA OID_TCP_TASK_IPSEC_DELETE_SA
      OID_TCP_SAN_SUPPORT OID_TCP_TASK_IPSEC_ADD_UDPESP_SA
      OID_TCP_TASK_IPSEC_DELETE_UDPESP_SA
      )
  ],

  'mode' => [
    qw(
      MODE_CAPT MODE_STAT
      )
  ],

);

our @EXPORT_OK = (
  'GetAdapterNames',         'GetNetInfo',
  'GetVersion',              'MODE_CAPT',
  'MODE_STAT',               @{ $EXPORT_TAGS{'hack'} },
  @{ $EXPORT_TAGS{'ndis'} }, @{ $EXPORT_TAGS{'oid'} },
  @{ $EXPORT_TAGS{'mode'} },
);

our @EXPORT = qw(
);

sub AUTOLOAD {

  # This AUTOLOAD is used to 'autoload' constants from the constant()
  # XS function.

  my $constname;
  our $AUTOLOAD;
  ( $constname = $AUTOLOAD ) =~ s/.*:://;
  croak "&Win32::NetPacket::constant not defined" if $constname eq 'constant';
  my ( $error, $val ) = constant($constname);
  if ($error) { croak $error; }
  {
    no strict 'refs';
    *$AUTOLOAD = sub {$val};
  }
  goto &$AUTOLOAD;
}

use constant MODE_CAPT => 0;
use constant MODE_STAT => 1;

bootstrap Win32::NetPacket $VERSION;

# Preloaded methods go here.

###########################################################

# ====== Auxiliary functions

sub GetAdapterNames {
  croak "Usage: GetAdapterNames([\\%description])" unless @_ <= 1;
  croak "arg1 not a hash ref" if 1 == @_ and ref $_[0] ne 'HASH';
  my $buff = ' ' x 8192;
  Win32::NetPacket::_PacketGetAdapterNames($buff);
  my ( $names, $descs ) = split /\x00\x00/, $buff;
  my @names = split /\x00/, $names;
  my @descs = split /\x00/, $descs;
  %{ $_[0] } = map { $_ => shift(@descs) } @names if @_;
  push @names, shift @names if $names[0] =~ /GenericDialupAdapter/;
  return @names if wantarray;
  return undef  if @names == 0;
  return $names[0];
}

sub GetNetInfo {
  my $name = shift;
  my ( $ip, $mask ) = _PacketGetNetInfo($name);
  return unless $ip;
  $ip   = join '.', unpack "C4", pack 'L', $ip;
  $mask = join '.', unpack "C4", pack 'L', $mask;
  return $ip, $mask;
}

# ====== Constructor

sub new {
  my $class = shift;
  my %arg   = @_;
  my $self  = {
    _name    => undef,
    _adapter => undef,
    _packet  => undef
  };

  # ------------ adapter
  $self->{_name}
    = exists $arg{adapter_name} ? $arg{adapter_name} : GetAdapterNames();
  unless ( $self->{_adapter} = _PacketOpenAdapter( $self->{_name} ) ) {
    $@ = "Unable to open adapter \"$self->{_name}\"";
    return undef;
  }
  print STDERR "Adapter open...Ok\n" if $DEBUG;

  # ------------ packet
  unless ( $self->{_packet} = _PacketAllocatePacket() ) {
    $@ = "Unable to allocate packet to adapter \"$self->{_name}\"";
    _PacketFreePacket( $self->{_packet} );
    return undef;
  }
  print STDERR "Allocate packet...Ok\n" if $DEBUG;

  # ------------ driver buffer size
  my $dbs = 256 * 1024;    # default driver buffer size = 256 ko
  if ( exists $arg{driver_buffer_size} ) {
    if ( $arg{driver_buffer_size} =~ /^\d+$/ ) {
      $dbs = $arg{driver_buffer_size};
    }
    else {
      _fatal_error( $self,
        "driver_buffer_size must be a positive integer, not \"$arg{driver_buffer_size}\""
      );
    }
  }
  _PacketSetBuff( $self->{_adapter}, $dbs )
    or _fatal_error( $self, "Unable to set the driver buffer size" );

  # ------------ read timeout
  my $rt = 1000;    # default timeout = 1000 ms
  if ( exists $arg{read_timeout} ) {
    if ( $arg{read_timeout} =~ /^[+-]?\d+$/ ) {
      $rt = $arg{read_timeout};
    }
    else {
      _fatal_error( $self,
        "read_timeout must be an integer, not \"$arg{read_timeout}\"" );
    }
  }
  _PacketSetReadTimeout( $self->{_adapter}, $rt )
    or _fatal_error( $self, "Unable to set read timeout" );

  # ------------ min to copy
  if ( exists $arg{min_to_copy} ) {
    if ( $arg{min_to_copy} =~ /^\d+$/ ) {
      _PacketSetMinToCopy( $self->{_adapter}, $arg{min_to_copy} )
        or _fatal_error( $self, "Unable to set the min_to_copy" );
    }
    else {
      _fatal_error( $self,
        "min_to_copy must be a positive integer, not \"$arg{min_to_copy}\"" );
    }
  }

  # ------------ mode
  if ( exists $arg{mode} ) {
    _PacketSetMode( $self->{_adapter}, $arg{'mode'} )
      or _fatal_error( $self, "Unable to set the mode" );
  }

  # ------------ end of config
  bless $self, $class;
  return $self;
}

sub _fatal_error {
  my $self = shift;
  my $s    = shift;
  _PacketFreePacket( $self->{_packet} )    if $self->{_packet};
  _PacketCloseAdapter( $self->{_adapter} ) if $self->{_adapter};
  print STDERR "$self->{_name} destoyed\n" if $DEBUG;
  croak $s;
}

# ====== Destructor

sub DESTROY {
  my $self = shift;
  _PacketFreePacket( $self->{_packet} );
  _PacketCloseAdapter( $self->{_adapter} );
  print STDERR "$self->{_name} destoyed\n" if $DEBUG;
}

# ====== SetUserBuffer

sub SetUserBuffer {
  my $self = shift;
  if ( $_[1] =~ /^\d+$/ ) {
    $_[0] = '*' x $_[1];
    _PacketInitPacket( $self->{_packet}, $_[0] );
  }
  else {
    croak("Second arg must be a positive integer");
  }
}

# ====== SetHwFilter

sub SetHwFilter {
  my $self   = shift;
  my $filter = shift;
  return _PacketSetHwFilter( $self->{_adapter}, $filter );
}

# ====== SetReadTimeout

sub SetReadTimeout {
  my $self = shift;
  my $t    = shift;
  return _PacketSetReadTimeout( $self->{_adapter}, $t );
}

# ====== ReceivePacket

sub ReceivePacket {
  my $self = shift;
  return _PacketReceivePacket( $self->{_adapter}, $self->{_packet} );
}

# ====== GetBytesReceived

sub GetBytesReceived {
  my $self = shift;
  return _GetBytesReceived( $self->{_packet} );
}

# ====== GetStats

sub GetStats {
  my $self = shift;
  return _PacketGetStats( $self->{_adapter} );
}

# ====== GetInfo

sub GetInfo {
  my $self        = shift;
  my $description = '';
  my $TOid        = constant('OID_GEN_VENDOR_DESCRIPTION');
  my $Oid         = pack "LLC256", $TOid, 256;
  $description = ( unpack "LLA*", $Oid )[2]
    if _PacketGetRequest( $self->{_adapter}, $Oid );
  my ( $t,  $speed ) = _PacketGetNetType( $self->{_adapter} );
  my ( $ip, $mask )  = GetNetInfo( $self->{_name} );
  $TOid =
      $type[$t] eq 'NdisMedium802_3' ? constant('OID_802_3_CURRENT_ADDRESS')
    : $type[$t] eq 'NdisMedium802_5' ? constant('OID_802_5_CURRENT_ADDRESS')
    : $type[$t] eq 'NdisMediumFddi'  ? constant('OID_FDDI_LONG_CURRENT_ADDR')
    : $type[$t] eq 'NdisMediumWan'   ? constant('OID_WAN_CURRENT_ADDRESS')
    : $type[$t] eq 'NdisMediumAtm'   ? constant('OID_ATM_HW_CURRENT_ADDRESS')
    : '';
  my $mac = '';

  if ($TOid) {
    $Oid = pack "LLC6", $TOid, 6;
    $mac = ( unpack "LLH*", $Oid )[2]
      if _PacketGetRequest( $self->{_adapter}, $Oid );
  }
  return $self->{_name}, $description, $type[$t], $speed, $ip, $mask, $mac;
}

# ====== SetDriverBufferSize

sub SetDriverBufferSize {
  my $self = shift;
  my $size = shift;
  return _PacketSetBuff( $self->{_adapter}, $size ) if $size =~ /^\d+$/;
  croak "Size must be a positive integer";
}

# ====== SetMode

sub SetMode {
  my $self = shift;
  my $mode = shift;
  return _PacketSetMode( $self->{_adapter}, $mode );
}

# ====== SetNumWrites

sub SetNumWrites {
  my $self    = shift;
  my $nwrites = shift;
  return _PacketSetNumWrites( $self->{_adapter}, $nwrites );
}

# ====== SetMinToCopy

sub SetMinToCopy {
  my $self   = shift;
  my $nbytes = shift;
  _PacketSetMinToCopy( $self->{_adapter}, $nbytes );
}

# ====== GetReadEvent

sub GetReadEvent {
  my $self = shift;
  _GetReadEvent( $self->{_adapter} );
}

# ====== SendPacket

sub SendPacket {
  my $self = shift;
  my $p    = shift;
  _PacketInitPacket( $self->{_packet}, $p );
  return _PacketSendPacket( $self->{_adapter}, $self->{_packet} );
}

# ====== GetRequest

sub GetRequest {
  my $self = shift;
  return _PacketGetRequest( $self->{_adapter}, $_[0] );
}

# ====== SetRequest

sub SetRequest {
  my $self = shift;
  return _PacketSetRequest( $self->{_adapter}, $_[0] );
}

# ====== SetBpf

sub SetBpf {
  my $self = shift;
  my $filter;
  if ( @_ == 1 ) {
    $filter = shift;
  }
  else {
    shift if @_ % 4 == 1;
    my $len = @_;
    $len >>= 2;
    $filter = pack 'SCCi' x $len, @_;
  }
  return _PacketSetBpf( $self->{_adapter}, $filter );
}

1;
__END__

# POD documentation

=head1 NAME

Win32::NetPacket - OO-interface to the WinPcap Packet Driver API.

=head1 SYNOPSIS

  use Win32::NetPacket;

  my $nic = Win32::NetPacket->new();
  my ($name, $description, $type, $speed, $ip, $mask, $mac) = $nic->GetInfo();
  print "Name: $name\n$description\nType: $type (speed: $speed bits/s)\n";
  print "MAC: $mac IP: $ip Net mask: $mask\n";

=head1 DESCRIPTION

This module is an Object-Oriented interface to the Packet Driver API (Packet.dll).
Packet.dll is a part of WinPcap: the Free Packet Capture Architecture
for Windows. To use this module, it is necessary to install WinPcap 3.1
on your system (Go to L<SEE ALSO> section).

=head2 Methods

=over

=item new

=item $nic = Win32::NetPacket-E<gt>new( [option =E<gt> value] );

This method opens a B<n>etwork B<i>nterface B<c>ard (nic) adapter,
creates a Win32::NetPacket object for this adapter and returns a
reference to this object. If the constructor fails, I<undef> will be
returned and an error message will be in $@.

The options are passed in a hash like fashion, using key and value
pairs. Possible options are:

=over

=item * adapter_name

Set the name of the network interface card adapter to open. If this
option is not set, the adapter name returned by GetAdapterNames() is
used by default.

The list of all network cards installed on the system can be gotten
with the function GetAdapterNames() in a list context.

=item * driver_buffer_size

Set the size, in bytes, of the driver’s circular buffer associated with the adapter.
The default value is 256 kbytes. Can be changed later with the SetDriverBufferSize()
method.

=item * read_timeout

Set the timeout in milliseconds after which ReceivePacket() will return
even though no packet has been captured. The default value is 1 seconde
(1000 ms). Can be changed later with the SetReadTimeout() method.

=item * min_to_copy

Set the minimum amount of data, in bytes, in the driver buffer that will cause
the method ReceivePacket() to return. The default value is 0.
Can be changed later with the SetMinToCopy() method.
(Works on WinNT/2000/XP system only)

=item * mode

Set the mode of the adapter: MODE_CAPT for standard capture mode or
MODE_STAT for statistics mode. For more details, see SetMode() .
The default value is MODE_CAPT.

=back

Example :

  use Win32::NetPacket ':mode';

  my $nic = Win32::NetPacket->new(
    adapter_name => '\Device\NPF_{400FA737-5BA8-489F-9FF7-D74B4D3DAA72}',
    driver_buff_size => 512*1024,
    read_timeout => 0,
    min_to_copy => 16*1024,
    mode => MODE_CAPT
  ) or die $@;


=item SetUserBuffer

=item $nic-E<gt>SetUserBuffer($Buffer, $size);

C<$Buffer> is the user-allocated buffer that will contain the captured data,
and C<$size> is its size. This method returns nothing.

Example:

  my $buffer;
  $nic->SetUserBuffer($buffer, 256*1024);   # 256 ko buffer for captured packets


=item SetHwFilter

=item  $success = $nic-E<gt>SetHwFilter( CONSTANT );

Sets a hardware filter on the incoming packets. The value returned is I<true> if
the operation was successful.

The constants that define the filters are:

    NDIS_PACKET_TYPE_DIRECTED
    NDIS_PACKET_TYPE_MULTICAST
    NDIS_PACKET_TYPE_ALL_MULTICAST
    NDIS_PACKET_TYPE_BROADCAST
    NDIS_PACKET_TYPE_SOURCE_ROUTING
    NDIS_PACKET_TYPE_PROMISCUOUS
    NDIS_PACKET_TYPE_SMT
    NDIS_PACKET_TYPE_ALL_LOCAL
    NDIS_PACKET_TYPE_MAC_FRAME
    NDIS_PACKET_TYPE_FUNCTIONAL
    NDIS_PACKET_TYPE_ALL_FUNCTIONAL
    NDIS_PACKET_TYPE_GROUP

Example:

  use Win32::NetPacket qw/ :ndis /;                 # NDIS_* constants available
  my $nic = Win32::NetPacket->new();                # open nic adapter
  $nic->SetHwFilter(NDIS_PACKET_TYPE_PROMISCUOUS);  # set nic in promiscuous mode

=item SetReadTimeout

=item  $success = $nic-E<gt>SetReadTimeout( $timeout );

This method sets the value of the read timeout associated with the C<$nic>
adapter. C<$timeout> indicates the timeout in milliseconds after which
ReceivePacket() will return (also if no packets have been captured by
the driver). Setting timeout to 0 means no timeout, i.e. ReceivePacket()
never returns if no packet arrives.  A timeout of -1 causes ReceivePacket()
to always return immediately.

This method works also if the adapter is working in statistics mode, and
can be used to set the time interval between two statistic reports.

=item SetMinToCopy

=item $success = $nic-E<gt>SetMinToCopy( $nbytes )

This method can be used to define the minimum amount of data in the kernel
buffer that will cause the driver to release a read (i.e. a ReceivePacket() )
in progress. C<$nbytes> specifies this value in bytes.

This method has effect only in Windows NT/2000. The driver for Windows 95/98/ME
does not offer this possibility to modify the amount of data to unlock a read,
therefore this call is implemented under these systems only for compatibility.

=item ReceivePacket

=item  $BytesReceived = $nic-E<gt>ReceivePacket();

This method performs the capture of a set of packets.
Returns the length of the buffer’s portion containing valid data.
The number of packets received with this method is variable.
It depends on the number of packets actually stored in the driver’s buffer,
on the size of these packets and on the size of the buffer associated
with C<$nic>. It is possible to set a timeout on read calls with the
SetReadTimeout() method. In this case the call returns even if no packets
have been captured if the timeout set by this method expires.

The format used by the driver to send packets to the application is as follow:

    packet #1 -->   ---------        ------ bpf_hdr structure ------
                   | bpf_hdr | ---> | tv_sec     l = int            |
                    ---------       | tv_usec    l = int            |
                   |  data   |      | bh_caplen  I = unsigned int   |
                    ---------       | bh_datalen I = unsigned int   |
                   | Padding |      | bh_hdrlen  S = unsigned short |
    packet #2 -->   ---------        -------------------------------
                   | bpf_hdr |
                    ---------
                   |  data   |
                    ---------
                   | Padding |
                    ---------
       ...etc

Each packet has a header consisting in a C<bpf_hdr> structure that defines
its length and holds its timestamp. A padding field is used to word-align
the data in the buffer (to increase the speed of the copies).

The C<bpf_hdr> has the following fields:

=over

=item * tv_sec

capture date in the standard UNIX time format,

=item * tv_usec

microseconds of the capture,

=item * bh_caplen

the length of captured portion,

=item * bh_datalen

the original length of the packet,

=item * bh_hdrlen

the length of the header that encapsulates the packet.

=back

For example, one can get the values of the first header of the user's
buffer C<$buffer> with:

  ($tv_sec, $tv_usec, $caplen, $datalen, $hdrlen) = unpack 'llIIS', $buffer;

and then extract the first packet of this buffer with:

  my $packet = substr $buffer, 0, $datalen;

Example: this script prints all successive packets of only one capture.

  #!/usr/bin/perl -w
  use strict;
  use Win32::NetPacket qw/ :ndis /;

  use constant SizeOfInt => 4;    # int = 4 bytes on Win32

  my $nic = Win32::NetPacket->new(
      driver_buffer_size => 512*1024,     # 512 kbytes buffer
      read_timeout => 0,                  # no timeout
      min_to_copy => 8*1024,              # return if > 8 kbytes
      ) or die $@;

  $nic->SetHwFilter(NDIS_PACKET_TYPE_PROMISCUOUS);  # nic in promiscuous mode
  my $Buff;
  $nic->SetUserBuffer($Buff, 128*1024);   # 128 kbytes user's buffer

  my $BytesReceived = $nic->ReceivePacket();  # capture packets

  my $offset = 0;
  while($offset < $BytesReceived) {
    my ($tv_sec, $tv_usec, $caplen, $datalen, $hdrlen)
      = unpack 'llIIS', substr $Buff, $offset;  # read the bpf_hdr structure
    printf "\nPacket length, captured portion: %ld, %ld\n", $datalen, $caplen;
    $offset += $hdrlen;
    my $data = substr $Buff, $offset, $datalen; # extract the datagram
    my $i;
    print map { ++$i % 16 ? "$_ " : "$_\n" }    # print the datagram in hexa
          unpack( 'H2' x length( $data ), $data ),
          length( $data ) % 16 ? "\n" : '';
    # The next packet is at $offset + $caplen + 0, 1, 2 or 3 padding bytes
    # i.e. $offset must be a multiple of SizeOfInt (word alignment)
    $offset = (($offset+$caplen)+(SizeOfInt-1)) & ~(SizeOfInt-1);
  }

Really raw packets, is not it? ;-)

=item GetStats

=item ($packets_received, $packets_lost) = $nic-E<gt>GetStats();

Returns, in a list, the number of packets that have been received by the
adapter, starting at the time in which it was opened and the number of packets
received by the adapter but that have been dropped by the kernel.
A packet is dropped when the user-level application is not ready to get
it and the kernel buffer associated with the adapter is full.

=item GetInfo

=item ($name, $description, $type, $speed, $ip, $mask, $mac) = $nic-E<gt>GetInfo();

Returns, in a list, the name, the description string, the type, the speed
in bits per second, the IP address, the net mask and the MAC address of C<$nic>

The type is one of the following values:

    NdisMedium802_3:       Ethernet (802.3)
    NdisMedium802_5:       Token Ring (802.5)
    NdisMediumFddi:        FDDI
    NdisMediumWan:         WAN
    NdisMediumLocalTalk:   LocalTalk
    NdisMediumDix:         DIX
    NdisMediumAtm:         ATM
    NdisMediumArcnetRaw:   ARCNET (raw)
    NdisMediumArcnet878_2: ARCNET (878.2)
    NdisMediumWirelessWan: Various types of NdisWirelessXxx media.

=item SetMode

=item $success = $nic-E<gt>SetMode( MODE );

This method sets the mode of the adapter. MODE can have two possible values:

=over

=item * MODE_CAPT: standard capture mode.

It is set by default after the PacketOpenAdapter call.

=item * MODE_STAT: statistics mode.

It's a particular working mode of the BPF capture driver that can be used to
perform real time statistics on the network traffic. The driver does not capture
anything when in statistics mode and it limits itself to count the number of
packets and the amount of bytes that satisfy the user-defined BPF filter.
These counters can be obtained by the application with the
ReceivePacket() method, and are received at regular intervals, every time
a timeout expires. The default value of this timeout is 1 second, but it can be
set to any other value (with a 1 ms precision) with the SetReadTimeout() method.
The counters are encapsulated in a C<bpf_hdr> structure before being passed to the
application. This allows microsecond-precise timestamps in order to have the same
time scale among the data capture in this way and the one captured using libpcap.
Captures in this mode have a very low impact with the system performance.

The data returned by PacketReceivePacket() when the adapter is in this mode
is as follow:

      -------- bpf_hdr structure ---------
     | tv_sec          l = int            |
     | tv_usec         l = int            |
     | bh_caplen       I = unsigned int   |
     | bh_datalen      I = unsigned int   |
     | bh_hdrlen       S = unsigned short |
      -------- data ----------------------
     | PacketsAccepted LL = large int     |
     | BytesAccepted   LL = large int     |
      ------------------------------------

The buffer is 34 bytes long under Win9x and 36 bytes long under WinNT
(there is 2 padding bytes after bpf_hdr structure).
A C<Large int> is a 64 bits integer.

Example: this script prints the number of bytes received every second.
Note the two padding bytes (xx) in the unpack template.

  #!/usr/bin/perl -w
  use strict;
  use Term::ReadKey;
  use Win32::NetPacket qw/ :ndis MODE_STAT /;

  my $nic = Win32::NetPacket->new(
        driver_buff_size => 0,      # no buffer needed
        read_timeout => 1000,       # every second
        mode => MODE_STAT,          # statistics mode
      ) or die $@;

  $nic->SetHwFilter(NDIS_PACKET_TYPE_PROMISCUOUS);   # set nic in promiscuous mode

  my $Buff;
  $nic->SetUserBuffer($Buff, 36);   # 36 bytes user's buffer, it's enough

  # 2 padding bytes (xx) in the bpf_hdr structure under WinNT
  my $bpf_hdr = Win32::IsWinNT() ? "llIISxxLLLL" : "llIISLLLL";

  while( !ReadKey(-1) ) {   # press (enter) to terminate
    $nic->ReceivePacket();  # get stats
    my ($tv_sec, $tv_usec, $caplen, $datalen, $hdrlen,
        $p0, $p1, $b0, $b1) = unpack $bpf_hdr, $Buff;  # read stats
    print $b1*2**32+$b0, " bytes/s\n";
  }

=back

=item SetDriverBufferSize

=item $success = $nic-E<gt>SetDriverBufferSize( $size );

This method sets to a new size the driver’s buffer associated with
the C<$nic> adapter. C<$size> is the new dimension in bytes.
Returns a I<true> value if successfully completed, a I<false> value if there
is not enough memory to allocate the new buffer. When a new dimension
is set, the data in the old buffer is discarded and the packets stored
in it are lost.

=item SendPacket

=item $success = $nic-E<gt>SendPacket( $packet )

This method is used to send a raw C<$packet> to the network through the
C<$nic> adapter . "Raw packet" means that the programmer will have to build
the various headers because the packet is sent to the network "I<as is>".
The user will not have to put a C<bpf_hdr> header before the packet.
Either the CRC needs not to be calculated and added to the packet, because
it is transparently put after the end of the data portion by the network interface.

The optimised sending process is still limited to one packet at a time:
for the moment it cannot be used to send a buffer with multiple packets.

=item SetNumWrites

=item $success = $nic-E<gt>SetNumWrites( $nwrites );

This method sets to C<$nwrites>  the number of times a single write on the C<$nic>
adapter must be repeated. See SendPacket() for more details.

=item GetRequest

=item $success = $nic-E<gt>GetRequest( $Oid );

This method is used to perform a query operation on the C<$nic> adapter.
With this method it is possible to obtain various parameters of the network
adapter, like the dimension of the internal buffers, the link speed or the
counter of corrupted packets.

NDIS (Network Device Interface Specification) Object IDentifiers (OIDs) are
a set of system-defined constants that take the form OID_XXX.
To call GetRequest() or SetRequest() methods, it is necessary to set
these OIDs in an OID-structure:

         -------- OID structure --------
        | Oid     L  = unsigned long    |
        | Length  L  = unsigned long    |
        | Data    C* = unsigned char [] |
         -------------------------------

=over

=item * Oid

Oid is a numeric identifier that indicates the type of query/set function to
perform on the adapter,

=item * Length

Length indicates the length of the Data field,

=item * Data

Data field, that contains the information passed to or received from the adapter.

=back

The constants that define the Oids are declared in the file ntddndis.h.
More details on the argument can be found in the documentation provided
with the Microsoft DDK.

Example: The OID_GEN_VENDOR_DESCRIPTION OID points to a zero-terminated string
describing the C<$nic>. We define, with pack, an OID-structure that contains the
OID and a small buffer of 256 characters. After the call to GetRequest(), we
unpack the structure to get the string C<$description> (its length is C<$len>).

  use Win32::NetPacket qw/ :oid /;

  my $nic = Win32::NetPacket->new();
  my $Oid = pack "LLC256", OID_GEN_VENDOR_DESCRIPTION, 256;
  $nic->GetRequest($Oid) or die "Unable to get OID_GEN_VENDOR_DESCRIPTION";
  my ($code, $len, $description) = unpack "LLA*", $Oid;
  print $description;

Not all the network adapters implement all the query/set functions.
There is a set of mandatory OID functions that is granted to be present
on all the adapters, and a set of facultative functions, not provided by
all the adapters (see the DDK to see which functions are mandatory).

Example: OID_GEN_SUPPORTED_LIST is a mandatory OID that specifies an array
of OIDs that the underlying driver or its NIC supports.
The following script prints the list of all OIDs supported by the default C<$nic>.

  #!/usr/bin/perl -w
  use strict;
  use Win32::NetPacket qw/ :oid /;

  my %OIDTAG;    # for conversion OID_num --> OID_tag
  foreach my $tag ( @{ $Win32::NetPacket::EXPORT_TAGS{'oid'} } ) {
    my $hexa = scalar Win32::NetPacket::constant($tag);
    if ( $hexa !~ /Your vendor/ ) {
      $hexa = sprintf "0x%08X", $hexa;
      $OIDTAG{$hexa} = $tag unless $tag =~ /^OID_GEN_CO_/;
    }
  }

  my $nic = Win32::NetPacket->new();
  my $Oid = pack "LLC1024", OID_GEN_SUPPORTED_LIST, 1024;
  $nic->GetRequest($Oid) or die "Unable to get OID_GEN_SUPPORTED_LIST";
  my ( $code, $num, @supported ) = unpack "LLL*", $Oid;

  foreach (@supported) {
    last unless $_;
    my $hexa = sprintf "0x%08X", $_;
    printf "$hexa == %s\n", exists $OIDTAG{$hexa} ? $OIDTAG{$hexa} : '??';
  }

=item SetRequest

=item $success = $nic-E<gt>SetRequest( $Oid );

This method is used to perform a set operation on the adapter pointed by C<$nic>.
For the OID-structure, see GetRequest() .

Example: with the OID_GEN_CURRENT_PACKET_FILTER one can set an hardware filter like
with SetHwFilter() . To set C<$nic> in promiscuous mode:

  use Win32::NetPacket qw/ :oid :ndis /;

  my $nic = Win32::NetPacket->new();
  my $Oid = pack "LLL", OID_GEN_CURRENT_PACKET_FILTER , NDIS_PACKET_TYPE_PROMISCUOUS ;
  $nic->SetRequest($Oid) or die "Unable to set OID_GEN_CURRENT_PACKET_FILTER";

=item SetBpf

=item $success = $nic-E<gt>SetBpf( @filter );

=item $success = $nic-E<gt>SetBpf( $filter );

This method associates a new BPF filter to the C<$nic> adapter. The C<@filter>
is a set of instructions that the BPF register-machine of the driver will
execute on each incoming packet.
This method returns I<true> if the driver is set successfully, I<false> if an error occurs
or if the filter program is not accepted. The driver performs a check on every new
filter in order to avoid system crashes due to bogus or buggy programs, and it
rejects invalid filters.

You can launch WinDump with the -ddd parameter to obtain the pseudocode of the filter.

Example: suppose that you want a filter for the tcp packets having the flags SYN and FIN
set (why not? ;-). In a console, the command:

  windump -ddd "tcp[13] & 3 = 3"

give you the pseudocodes of the filter:

  12
  40 0 0 12
  21 0 9 2048
  48 0 0 23
  21 0 7 6
  40 0 0 20
  69 5 0 8191
  177 0 0 14
  80 0 0 27
  84 0 0 3
  21 0 1 3
  6 0 0 96
  6 0 0 0

then you can set this filter:

  my @filter = qw/
  12
  40 0 0 12
  21 0 9 2048
  48 0 0 23
  21 0 7 6
  40 0 0 20
  69 5 0 8191
  177 0 0 14
  80 0 0 27
  84 0 0 3
  21 0 1 3
  6 0 0 96
  6 0 0 0
  /;

  $nic->SetBpf(@filter) or die "Unable to set Bpf filter";

You can also pack this filter:

  my $filter = pack 'SCCi'x12, qw/40 0 0 12 21 0 9 2048 48 0 0 23 21 0 7 6
                                  40 0 0 20 69 5 0 8191 177 0 0 14 80 0 0 27
                                  84 0 0 3 21 0 1 3 6 0 0 96 6 0 0 0 /;

and then set it:

  $nic->SetBpf($filter) or die "Unable to set Bpf filter";


=back

=head2 Auxiliary functions

=over

=item GetAdapterNames

=item @list = GetAdapterNames( [ \%description ] );

=item $card = GetAdapterNames( [ \%description ] );

In a list context, return the names of all network cards installed on the system.
In a scalar context, return the first name of the list.

If you give a reference to a hash C<%description>, this hash will establish
an association between the system name of the adapter and a "human
readable" description of it.

Example:

  use Win32::NetPacket 'GetAdapterNames';

  my %description;
  foreach ( GetAdapterNames(\%description) ) {
    print "* $description{$_}\n  $_\n\n";
  }

=item GetAdapterInfo

=item ($ip, $mask) = GetNetInfo( $adapter_name )

Returns the IP address and the netmask of the named adapter.

Example:

  use Win32::NetPacket qw/ GetAdapterNames GetNetInfo /;

  my $default_adapter = GetAdapterNames();
  my ($ip, $mask) = GetNetInfo( $default_adapter );
  print "NIC: $default_adapter\nIP: $ip  MASK: $mask\n"

=item GetVersion

=item $version = GetVersion();

Returns a string with the packet.dll version.

Example:

  use Win32::NetPacket 'GetVersion';
  print GetVersion();

=back

=head2 Export

By default, Win32::NetPacket exports no symbols into the callers namespace.
The following tags can be used to selectively import symbols into the main
namespace.

=over

=item :mode

Exports all symbols C<MODE_*>. See SetMode() method.

=item :ndis

Exports all symbols C<NDIS_*>. See SetHwFilter() method.

=item :oid

Exports all symbols C<OID_*>. See GetRequest() and SetRequest() methods.

=back

=head1 SEE ALSO

Win32::NetPacket Home Page: http://www.bribes.org/perl/wNetPacket.html

WinPCap Home Page: http://www.winpcap.org/default.htm

WinPCap download page (download and install the WinPcap 3.1 auto-installer
(driver +DLLs):

  http://www.winpcap.org/install/default.htm

WinDump (tcpdump for Windows):

  http://www.winpcap.org/windump/default.htm

Microsoft DDK doc (NDIS OID):

  http://msdn.microsoft.com/library/default.asp?url=/library/en-us/NetXP_r/hh/NetXP_r/21oidovw_b5d8c785-211e-4d39-8007-1d38b3a1c888.xml.asp

(Search for "NDIS Object Identifiers" if this link is broken.)

=head1 CREDITS

This module uses WinPCap, a software developed by the Politecnico di Torino,
and its contributors.

Licence: http://www.winpcap.org/misc/copyright.htm

=head1 AUTHOR

J-L Morel E<lt>jl_morel@bribes.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003-2006 J-L Morel. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
