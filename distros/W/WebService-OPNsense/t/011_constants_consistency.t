#!perl
use v5.24;
use strictures 2;

use Test2::V1 qw( is isnt ok diag done_testing );

use WebService::OPNsense::Constants;

# Group constants by prefix for structural consistency checks.
# Each group's values should be unique within that group.
my %groups = (

    ACTION => [
        qw(
            $ACTION_BLOCK $ACTION_PASS $ACTION_REJECT
        )
    ],

    AF => [
        qw(
            $AF_INET $AF_INET6 $AF_INET46
        )
    ],

    ALIAS => [
        qw(
            $ALIAS_ASN $ALIAS_AUTHGROUP $ALIAS_DYNIPV6HOST $ALIAS_EXTERNAL
            $ALIAS_GEOIP $ALIAS_HOST $ALIAS_INTERNAL $ALIAS_MAC
            $ALIAS_NETWORK $ALIAS_NETWORK_GROUP $ALIAS_PORT $ALIAS_URL
            $ALIAS_URL_JSON $ALIAS_URL_TABLE
        )
    ],

    DIRECTION => [
        qw(
            $DIRECTION_ANY $DIRECTION_IN $DIRECTION_OUT
        )
    ],

    INTERFACE => [
        qw(
            $INTERFACE_DMZ $INTERFACE_GUEST $INTERFACE_LAN $INTERFACE_LOOPBACK
            $INTERFACE_OPT1 $INTERFACE_OPT2 $INTERFACE_OPT3 $INTERFACE_OPT4
            $INTERFACE_OPT5 $INTERFACE_OPT6 $INTERFACE_OPT7 $INTERFACE_OPT8
            $INTERFACE_OPT9 $INTERFACE_WAN $INTERFACE_WAN2 $INTERFACE_WAN_DHCP
            $INTERFACE_WAN_PPPOE
        )
    ],

    IF_GROUP => [
        qw(
            $IF_GROUP_DMZ $IF_GROUP_GUEST $IF_GROUP_LAN
            $IF_GROUP_OPT1 $IF_GROUP_OPT2 $IF_GROUP_OPT3 $IF_GROUP_OPT4
            $IF_GROUP_OPT5 $IF_GROUP_OPT6 $IF_GROUP_OPT7 $IF_GROUP_OPT8
            $IF_GROUP_OPT9 $IF_GROUP_WAN
        )
    ],

    LOG_LEVEL => [
        qw(
            $LOG_LEVEL_NONE $LOG_LEVEL_NORMAL $LOG_LEVEL_HIGH
        )
    ],

    ONETOONE => [
        qw(
            $ONETOONE_BINAT $ONETOONE_NAT
        )
    ],

    PROTO => [
        qw(
            $PROTO_ANY $PROTO_ESP $PROTO_GRE $PROTO_ICMP $PROTO_OSPF $PROTO_PIM
            $PROTO_SCTP $PROTO_TCP $PROTO_TCP_UDP $PROTO_UDP $PROTO_VRRP
        )
    ],

    SEQ => [
        qw(
            $SEQ_EARLY $SEQ_FIRST $SEQ_FLOATING $SEQ_LAST
        )
    ],

    SNAT => [
        qw(
            $SNAT_ADVANCED $SNAT_AUTOMATIC $SNAT_DISABLED $SNAT_HYBRID
        )
    ],

    STATETYPE => [
        qw(
            $STATETYPE_KEEP $STATETYPE_MODULATE $STATETYPE_NONE $STATETYPE_SLOPPY
            $STATETYPE_SYNPROXY
        )
    ],

    TCP_FLAG => [
        qw(
            $TCP_FLAG_ACK $TCP_FLAG_CWR $TCP_FLAG_ECE $TCP_FLAG_FIN
            $TCP_FLAG_PSH $TCP_FLAG_RST $TCP_FLAG_SYN $TCP_FLAG_URG
        )
    ],

    TLS_VERSION => [
        qw(
            $TLS_VERSION_1_0 $TLS_VERSION_1_1 $TLS_VERSION_1_2 $TLS_VERSION_1_3
        )
    ],

);

# Standalone constants not in a named group
my @standalone = qw( $ENABLED $DISABLED $GATEWAY_DEFAULT );
my @all        = ( @standalone, map { @{$_} } values %groups );

# --- Structural checks ---

# Helper: dereference a constant by name (strip leading $ from string)
sub _val {
    my $name = shift;
    $name =~ s/^\$//;
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    return ${$name};
}

# Every constant is defined and is a plain scalar
for my $name (@all) {
    my $value = _val($name);
    ok( defined $value, "$name is defined" );
    ok( !ref $value,    "$name is a plain scalar, not a reference" ) if defined $value;
}

# No leading or trailing whitespace in any string value
for my $name (@all) {
    my $value = _val($name);
    next unless defined $value && !ref $value && $value !~ m/^-?[0-9]+(\.[0-9]+)?$/;
    my $trimmed = $value;
    $trimmed =~ s/^\s+|\s+$//g;
    is( $value, $trimmed, "$name value has no leading/trailing whitespace" );
}

# No duplicate values within each group
while ( my ( $group, $constants ) = each %groups ) {
    my %seen;
    GROUP:
    for my $name ( @{$constants} ) {
        my $value = _val($name);
        next GROUP unless defined $value;
        ok(
            !exists $seen{$value},
            "no duplicate value '$value' in $group group"
        ) or diag "conflict between $name and $seen{$value}";
        $seen{$value} = $name;
    }
}

# Type consistency: integer-valued constants are indeed integers
{
    is( $ENABLED,  1, '$ENABLED is 1' );
    is( $DISABLED, 0, '$DISABLED is 0' );
    ok( $ENABLED == 1,  '$ENABLED is numeric 1' );
    ok( $DISABLED == 0, '$DISABLED is numeric 0' );
}

# Map each constant to its group for cross-group collision checks
my %constant_to_group;
for my $g ( keys %groups ) {
    for my $cname ( @{ $groups{$g} } ) {
        $constant_to_group{$cname} = $g;
    }
}

# Cross-group collisions that exist by design:
#   INTERFACE <-> IF_GROUP  (interface name = group name for same interface)
#   DIRECTION <-> PROTO     ('any' is both a direction and a wildcard protocol)
#   STATETYPE <-> LOG_LEVEL ('none' means "no state tracking" and "no logging")
my %intentional_cross;
for my $pair (
    [qw( wan    INTERFACE IF_GROUP )],
    [qw( lan    INTERFACE IF_GROUP )],
    [qw( dmz    INTERFACE IF_GROUP )],
    [qw( guest  INTERFACE IF_GROUP )],
    [qw( opt1   INTERFACE IF_GROUP )],
    [qw( opt2   INTERFACE IF_GROUP )],
    [qw( opt3   INTERFACE IF_GROUP )],
    [qw( opt4   INTERFACE IF_GROUP )],
    [qw( opt5   INTERFACE IF_GROUP )],
    [qw( opt6   INTERFACE IF_GROUP )],
    [qw( opt7   INTERFACE IF_GROUP )],
    [qw( opt8   INTERFACE IF_GROUP )],
    [qw( opt9   INTERFACE IF_GROUP )],
    [qw( any    DIRECTION PROTO    )],
    [qw( none   STATETYPE LOG_LEVEL )],
) {
    my ( $val, $g1, $g2 ) = @{$pair};
    $intentional_cross{$val}{$g1} = 1;
    $intentional_cross{$val}{$g2} = 1;
}

# No accidental cross-group collisions (INTERFACE/IF_GROUP overlap is intentional)
{
    my %all_values;
    my $found_unexpected = 0;
    for my $name (@all) {
        next if $name eq '$ENABLED' || $name eq '$DISABLED' || $name eq '$GATEWAY_DEFAULT';
        my $value = _val($name);
        next unless defined $value;
        if ( exists $all_values{$value} ) {
            my $prev_name  = $all_values{$value};
            my $cur_group  = $constant_to_group{$name}      // q{};
            my $prev_group = $constant_to_group{$prev_name} // q{};
            if (   $intentional_cross{$value}
                && $intentional_cross{$value}{$cur_group}
                && $intentional_cross{$value}{$prev_group} ) {
                next;
            }
            $found_unexpected = 1;
            diag
"Unexpected cross-group collision: ${prev_group}::$prev_name and ${cur_group}::$name both equal '$value'";
        }
        $all_values{$value} = $name;
    }
    ok( !$found_unexpected, 'no accidental cross-group collisions' );
}

done_testing;
