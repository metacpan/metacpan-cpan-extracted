package Unblock::HTTP3::_Native;

use strict;
use warnings;

use Unblock::HTTP3 ();

our $VERSION = '0.01';

sub nghttp3_version {
    return _nghttp3_version();
}

sub parse_priority {
    my ($class, $value) = @_;
    return _parse_priority($value);
}

sub client {
    my (
        $class,
        $max_field_section_size,
        $qpack_max_table_capacity,
        $qpack_blocked_streams,
        $enable_connect_protocol,
        $h3_datagram,
    ) = @_;

    $max_field_section_size = 65_536
        unless defined $max_field_section_size;
    $qpack_max_table_capacity = 4_096
        unless defined $qpack_max_table_capacity;
    $qpack_blocked_streams = 100
        unless defined $qpack_blocked_streams;
    $enable_connect_protocol = 0
        unless defined $enable_connect_protocol;
    $h3_datagram = 0
        unless defined $h3_datagram;

    return _new_client(
        $max_field_section_size,
        $qpack_max_table_capacity,
        $qpack_blocked_streams,
        $enable_connect_protocol ? 1 : 0,
        $h3_datagram ? 1 : 0,
    );
}

sub server {
    my (
        $class,
        $max_field_section_size,
        $qpack_max_table_capacity,
        $qpack_blocked_streams,
        $enable_connect_protocol,
        $h3_datagram,
    ) = @_;

    $max_field_section_size = 65_536
        unless defined $max_field_section_size;
    $qpack_max_table_capacity = 4_096
        unless defined $qpack_max_table_capacity;
    $qpack_blocked_streams = 100
        unless defined $qpack_blocked_streams;
    $enable_connect_protocol = 0
        unless defined $enable_connect_protocol;
    $h3_datagram = 0
        unless defined $h3_datagram;

    return _new_server(
        $max_field_section_size,
        $qpack_max_table_capacity,
        $qpack_blocked_streams,
        $enable_connect_protocol ? 1 : 0,
        $h3_datagram ? 1 : 0,
    );
}

1;