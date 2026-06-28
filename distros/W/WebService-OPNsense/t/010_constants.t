#!perl
use strictures 2;

use Test2::V1 qw( is subtest done_testing );

use WebService::OPNsense::Constants qw(
    $ACTION_BLOCK
    $ACTION_PASS
    $ACTION_REJECT
    $AF_INET
    $AF_INET6
    $AF_INET46
    $ALIAS_ASN
    $ALIAS_AUTHGROUP
    $ALIAS_DYNIPV6HOST
    $ALIAS_EXTERNAL
    $ALIAS_GEOIP
    $ALIAS_HOST
    $ALIAS_INTERNAL
    $ALIAS_MAC
    $ALIAS_NETWORK
    $ALIAS_NETWORK_GROUP
    $ALIAS_PORT
    $ALIAS_URL
    $ALIAS_URL_JSON
    $ALIAS_URL_TABLE
    $DIRECTION_ANY
    $DIRECTION_IN
    $DIRECTION_OUT
    $GATEWAY_DEFAULT
    $OPN_DISABLED
    $OPN_ENABLED
    $INTERFACE_DMZ
    $INTERFACE_GUEST
    $INTERFACE_LAN
    $INTERFACE_LOOPBACK
    $INTERFACE_OPT1
    $INTERFACE_OPT2
    $INTERFACE_OPT3
    $INTERFACE_OPT4
    $INTERFACE_OPT5
    $INTERFACE_OPT6
    $INTERFACE_OPT7
    $INTERFACE_OPT8
    $INTERFACE_OPT9
    $INTERFACE_WAN
    $INTERFACE_WAN2
    $INTERFACE_WAN_DHCP
    $INTERFACE_WAN_PPPOE
    $IF_GROUP_DMZ
    $IF_GROUP_GUEST
    $IF_GROUP_LAN
    $IF_GROUP_OPT1
    $IF_GROUP_OPT2
    $IF_GROUP_OPT3
    $IF_GROUP_OPT4
    $IF_GROUP_OPT5
    $IF_GROUP_OPT6
    $IF_GROUP_OPT7
    $IF_GROUP_OPT8
    $IF_GROUP_OPT9
    $IF_GROUP_WAN
    $LOG_LEVEL_NONE
    $LOG_LEVEL_NORMAL
    $LOG_LEVEL_HIGH
    $ONETOONE_BINAT
    $ONETOONE_NAT
    $PROTO_ANY
    $PROTO_ESP
    $PROTO_GRE
    $PROTO_ICMP
    $PROTO_OSPF
    $PROTO_PIM
    $PROTO_SCTP
    $PROTO_TCP
    $PROTO_TCP_UDP
    $PROTO_UDP
    $PROTO_VRRP
    $SEQ_EARLY
    $SEQ_FIRST
    $SEQ_FLOATING
    $SEQ_LAST
    $SNAT_ADVANCED
    $SNAT_AUTOMATIC
    $SNAT_DISABLED
    $SNAT_HYBRID
    $STATETYPE_KEEP
    $STATETYPE_MODULATE
    $STATETYPE_NONE
    $STATETYPE_SLOPPY
    $STATETYPE_SYNPROXY
    $TCP_FLAG_ACK
    $TCP_FLAG_CWR
    $TCP_FLAG_ECE
    $TCP_FLAG_FIN
    $TCP_FLAG_PSH
    $TCP_FLAG_RST
    $TCP_FLAG_SYN
    $TCP_FLAG_URG
    $TLS_VERSION_1_0
    $TLS_VERSION_1_1
    $TLS_VERSION_1_2
    $TLS_VERSION_1_3
);

## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
subtest 'actions' => sub {
    is( $ACTION_BLOCK,  'block',  '$ACTION_BLOCK' );
    is( $ACTION_PASS,   'pass',   '$ACTION_PASS' );
    is( $ACTION_REJECT, 'reject', '$ACTION_REJECT' );
};

subtest 'address families' => sub {
    is( $AF_INET,   'inet',   '$AF_INET' );
    is( $AF_INET6,  'inet6',  '$AF_INET6' );
    is( $AF_INET46, 'inet46', '$AF_INET46' );
};

subtest 'alias types' => sub {
    is( $ALIAS_ASN,           'asn',          '$ALIAS_ASN' );
    is( $ALIAS_AUTHGROUP,     'authgroup',    '$ALIAS_AUTHGROUP' );
    is( $ALIAS_DYNIPV6HOST,   'dynipv6host',  '$ALIAS_DYNIPV6HOST' );
    is( $ALIAS_EXTERNAL,      'external',     '$ALIAS_EXTERNAL' );
    is( $ALIAS_GEOIP,         'geoip',        '$ALIAS_GEOIP' );
    is( $ALIAS_HOST,          'host',         '$ALIAS_HOST' );
    is( $ALIAS_INTERNAL,      'internal',     '$ALIAS_INTERNAL' );
    is( $ALIAS_MAC,           'mac',          '$ALIAS_MAC' );
    is( $ALIAS_NETWORK,       'network',      '$ALIAS_NETWORK' );
    is( $ALIAS_NETWORK_GROUP, 'networkgroup', '$ALIAS_NETWORK_GROUP' );
    is( $ALIAS_PORT,          'port',         '$ALIAS_PORT' );
    is( $ALIAS_URL,           'url',          '$ALIAS_URL' );
    is( $ALIAS_URL_JSON,      'urljson',      '$ALIAS_URL_JSON' );
    is( $ALIAS_URL_TABLE,     'urltable',     '$ALIAS_URL_TABLE' );
};

subtest 'directions' => sub {
    is( $DIRECTION_ANY, 'any', '$DIRECTION_ANY' );
    is( $DIRECTION_IN,  'in',  '$DIRECTION_IN' );
    is( $DIRECTION_OUT, 'out', '$DIRECTION_OUT' );
};

subtest 'enabled / disabled state' => sub {
    is( $OPN_ENABLED,  1, '$OPN_ENABLED' );
    is( $OPN_DISABLED, 0, '$OPN_DISABLED' );
};

subtest 'gateway' => sub {
    is( $GATEWAY_DEFAULT, 'default', '$GATEWAY_DEFAULT' );
};

subtest 'interface names' => sub {
    is( $INTERFACE_DMZ,       'dmz',       '$INTERFACE_DMZ' );
    is( $INTERFACE_GUEST,     'guest',     '$INTERFACE_GUEST' );
    is( $INTERFACE_LAN,       'lan',       '$INTERFACE_LAN' );
    is( $INTERFACE_LOOPBACK,  'lo0',       '$INTERFACE_LOOPBACK' );
    is( $INTERFACE_OPT1,      'opt1',      '$INTERFACE_OPT1' );
    is( $INTERFACE_OPT2,      'opt2',      '$INTERFACE_OPT2' );
    is( $INTERFACE_OPT3,      'opt3',      '$INTERFACE_OPT3' );
    is( $INTERFACE_OPT4,      'opt4',      '$INTERFACE_OPT4' );
    is( $INTERFACE_OPT5,      'opt5',      '$INTERFACE_OPT5' );
    is( $INTERFACE_OPT6,      'opt6',      '$INTERFACE_OPT6' );
    is( $INTERFACE_OPT7,      'opt7',      '$INTERFACE_OPT7' );
    is( $INTERFACE_OPT8,      'opt8',      '$INTERFACE_OPT8' );
    is( $INTERFACE_OPT9,      'opt9',      '$INTERFACE_OPT9' );
    is( $INTERFACE_WAN,       'wan',       '$INTERFACE_WAN' );
    is( $INTERFACE_WAN2,      'wan2',      '$INTERFACE_WAN2' );
    is( $INTERFACE_WAN_DHCP,  'wan_dhcp',  '$INTERFACE_WAN_DHCP' );
    is( $INTERFACE_WAN_PPPOE, 'wan_pppoe', '$INTERFACE_WAN_PPPOE' );
};

subtest 'interface group names' => sub {
    is( $IF_GROUP_DMZ,   'dmz',   '$IF_GROUP_DMZ' );
    is( $IF_GROUP_GUEST, 'guest', '$IF_GROUP_GUEST' );
    is( $IF_GROUP_LAN,   'lan',   '$IF_GROUP_LAN' );
    is( $IF_GROUP_OPT1,  'opt1',  '$IF_GROUP_OPT1' );
    is( $IF_GROUP_OPT2,  'opt2',  '$IF_GROUP_OPT2' );
    is( $IF_GROUP_OPT3,  'opt3',  '$IF_GROUP_OPT3' );
    is( $IF_GROUP_OPT4,  'opt4',  '$IF_GROUP_OPT4' );
    is( $IF_GROUP_OPT5,  'opt5',  '$IF_GROUP_OPT5' );
    is( $IF_GROUP_OPT6,  'opt6',  '$IF_GROUP_OPT6' );
    is( $IF_GROUP_OPT7,  'opt7',  '$IF_GROUP_OPT7' );
    is( $IF_GROUP_OPT8,  'opt8',  '$IF_GROUP_OPT8' );
    is( $IF_GROUP_OPT9,  'opt9',  '$IF_GROUP_OPT9' );
    is( $IF_GROUP_WAN,   'wan',   '$IF_GROUP_WAN' );
};

subtest 'log levels' => sub {
    is( $LOG_LEVEL_NONE,   'none',   '$LOG_LEVEL_NONE' );
    is( $LOG_LEVEL_NORMAL, 'normal', '$LOG_LEVEL_NORMAL' );
    is( $LOG_LEVEL_HIGH,   'high',   '$LOG_LEVEL_HIGH' );
};

subtest 'one-to-one NAT types' => sub {
    is( $ONETOONE_BINAT, 'binat', '$ONETOONE_BINAT' );
    is( $ONETOONE_NAT,   'nat',   '$ONETOONE_NAT' );
};

subtest 'protocols' => sub {
    is( $PROTO_ANY,     'any',     '$PROTO_ANY' );
    is( $PROTO_ESP,     'ESP',     '$PROTO_ESP' );
    is( $PROTO_GRE,     'GRE',     '$PROTO_GRE' );
    is( $PROTO_ICMP,    'ICMP',    '$PROTO_ICMP' );
    is( $PROTO_OSPF,    'OSPF',    '$PROTO_OSPF' );
    is( $PROTO_PIM,     'PIM',     '$PROTO_PIM' );
    is( $PROTO_SCTP,    'SCTP',    '$PROTO_SCTP' );
    is( $PROTO_TCP,     'TCP',     '$PROTO_TCP' );
    is( $PROTO_TCP_UDP, 'TCP/UDP', '$PROTO_TCP_UDP' );
    is( $PROTO_UDP,     'UDP',     '$PROTO_UDP' );
    is( $PROTO_VRRP,    'VRRP',    '$PROTO_VRRP' );
};

subtest 'rule sequence positions' => sub {
    is( $SEQ_EARLY,    'early',    '$SEQ_EARLY' );
    is( $SEQ_FIRST,    'first',    '$SEQ_FIRST' );
    is( $SEQ_FLOATING, 'floating', '$SEQ_FLOATING' );
    is( $SEQ_LAST,     'last',     '$SEQ_LAST' );
};

subtest 'SNAT modes' => sub {
    is( $SNAT_ADVANCED,  'advanced',  '$SNAT_ADVANCED' );
    is( $SNAT_AUTOMATIC, 'automatic', '$SNAT_AUTOMATIC' );
    is( $SNAT_DISABLED,  'disabled',  '$SNAT_DISABLED' );
    is( $SNAT_HYBRID,    'hybrid',    '$SNAT_HYBRID' );
};

subtest 'state types' => sub {
    is( $STATETYPE_KEEP,     'keep',     '$STATETYPE_KEEP' );
    is( $STATETYPE_MODULATE, 'modulate', '$STATETYPE_MODULATE' );
    is( $STATETYPE_NONE,     'none',     '$STATETYPE_NONE' );
    is( $STATETYPE_SLOPPY,   'sloppy',   '$STATETYPE_SLOPPY' );
    is( $STATETYPE_SYNPROXY, 'synproxy', '$STATETYPE_SYNPROXY' );
};

subtest 'TCP flags' => sub {
    is( $TCP_FLAG_ACK, 'ack', '$TCP_FLAG_ACK' );
    is( $TCP_FLAG_CWR, 'cwr', '$TCP_FLAG_CWR' );
    is( $TCP_FLAG_ECE, 'ece', '$TCP_FLAG_ECE' );
    is( $TCP_FLAG_FIN, 'fin', '$TCP_FLAG_FIN' );
    is( $TCP_FLAG_PSH, 'psh', '$TCP_FLAG_PSH' );
    is( $TCP_FLAG_RST, 'rst', '$TCP_FLAG_RST' );
    is( $TCP_FLAG_SYN, 'syn', '$TCP_FLAG_SYN' );
    is( $TCP_FLAG_URG, 'urg', '$TCP_FLAG_URG' );
};

subtest 'TLS versions' => sub {
    is( $TLS_VERSION_1_0, '1.0', '$TLS_VERSION_1_0' );
    is( $TLS_VERSION_1_1, '1.1', '$TLS_VERSION_1_1' );
    is( $TLS_VERSION_1_2, '1.2', '$TLS_VERSION_1_2' );
    is( $TLS_VERSION_1_3, '1.3', '$TLS_VERSION_1_3' );
};

done_testing;

## use critic
