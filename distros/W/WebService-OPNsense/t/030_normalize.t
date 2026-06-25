#!perl
use v5.24;
use strictures 2;

use Test2::V1               qw( is ok done_testing );
use Test2::Tools::Exception qw( dies lives );

use WebService::OPNsense::Normalize qw( normalize_ip validate_uuid );

# --- normalize_ip ---

# NetAddr::IP
{
    use NetAddr::IP;
    my $ip = NetAddr::IP->new('192.0.2.0/24');
    is( normalize_ip($ip), '192.0.2.0/24', 'NetAddr::IP' );
}

# Net::Netmask
{
    use Net::Netmask;
    my $ip = Net::Netmask->new('10.0.0.0/8');
    is( normalize_ip($ip), '10.0.0.0/8', 'Net::Netmask' );
}

# Net::CIDR::Lite (single range)
{
    use Net::CIDR::Lite;
    my $lite = Net::CIDR::Lite->new;
    $lite->add('172.16.0.0/12');
    is( normalize_ip($lite), '172.16.0.0/12', 'Net::CIDR::Lite single' );
}

# Net::CIDR::Lite (multi-range — should die)
{
    use Net::CIDR::Lite;
    my $lite = Net::CIDR::Lite->new;
    $lite->add('10.0.0.0/8');
    $lite->add('192.0.2.0/24');
    ok( dies { normalize_ip($lite) }, 'Net::CIDR::Lite multi dies' );
}

# Net::CIDR::Lite (empty — should die)
{
    use Net::CIDR::Lite;
    my $lite = Net::CIDR::Lite->new;
    ok( dies { normalize_ip($lite) }, 'Net::CIDR::Lite empty dies' );
}

# Unsupported class
{
    my $fake = bless {}, 'Unknown::Class';
    ok( dies { normalize_ip($fake) }, 'Unknown class dies' );
}

# Undef
{
    ok( dies { normalize_ip(undef) }, 'undef dies' );
}

# Non-blessed scalar
{
    ok( dies { normalize_ip('plain string') }, 'non-blessed scalar dies' );
}

# Non-blessed reference
{
    ok( dies { normalize_ip( {} ) }, 'non-blessed hashref dies' );
}

# IPv6 via NetAddr::IP
{
    use NetAddr::IP;
    my $ip = NetAddr::IP->new('2001:db8:1::/48');

    # NetAddr::IP expands to full form
    is( normalize_ip($ip), '2001:DB8:1:0:0:0:0:0/48', 'NetAddr::IP IPv6' );
}

# --- validate_uuid ---

# Valid UUID v4 with dashes
{
    ok(
        lives { validate_uuid('550e8400-e29b-41d4-a716-446655440000') },
        'valid UUID v4 with dashes'
    );
}

# Valid UUID v4 with dashes (alt)
{
    ok(
        lives { validate_uuid('f47ac10b-58cc-4372-a567-0e02b2c3d479') },
        'valid UUID v4 with dashes (alt)'
    );
}

# Valid UUID v1 with dashes
{
    ok(
        lives { validate_uuid('c1e7a4b0-bf1c-11e9-8f0b-362b9e155667') },
        'valid UUID v1 with dashes'
    );
}

# Path traversal
{
    ok(
        dies { validate_uuid('/../etc/passwd') },
        'path traversal dies'
    );
}

# Non-UUID string
{
    ok(
        dies { validate_uuid('hello') },
        'non-UUID string dies'
    );
}

# UUID-like but wrong length
{
    ok(
        dies { validate_uuid('550e8400-e29b-41d4-a716-44665544000Z') },
        'UUID with non-hex char dies'
    );
}

# Empty string
{
    ok(
        dies { validate_uuid('') },
        'empty string dies'
    );
}

# Undef
{
    ok(
        dies { validate_uuid(undef) },
        'undef dies'
    );
}

# Whitespace-only string
{
    ok(
        dies { validate_uuid('  ') },
        'whitespace-only string dies'
    );
}

done_testing;
