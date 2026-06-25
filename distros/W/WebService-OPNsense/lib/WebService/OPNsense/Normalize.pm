#!/bin/false
# ABSTRACT: Normalization and validation utilities
# PODNAME: WebService::OPNsense::Normalize
use strictures 2;

package WebService::OPNsense::Normalize;
$WebService::OPNsense::Normalize::VERSION = '0.001';
use Carp            qw( croak );
use Exporter::Shiny qw( normalize_ip optional_segment validate_uuid );
use Scalar::Util    qw( blessed );
use UUID::Tiny      qw( is_uuid_string );

sub normalize_ip {
    my ($ip_obj) = @_;

    my $class = blessed $ip_obj
        or croak 'Argument must be a blessed IP object';

    if ( $class eq 'Net::CIDR::Lite' ) {
        my @list = $ip_obj->list;
        croak 'Net::CIDR::Lite must contain exactly 1 CIDR range'
            if @list != 1;
        return $list[0];
    }
    elsif ( $class eq 'Net::Netmask' ) {
        return $ip_obj->desc;
    }
    elsif ( $class eq 'NetAddr::IP' ) {
        return $ip_obj->cidr;
    }

    croak "Cannot normalize IP of class $class";
}

sub validate_uuid {
    my ($uuid) = @_;
    defined $uuid
        or croak 'UUID is required';
    is_uuid_string($uuid)
        or croak "Invalid UUID: $uuid";
    return;
}

sub optional_segment {
    my ($val) = @_;
    return defined $val ? "/$val" : q();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Normalize - Normalization and validation utilities

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WebService::OPNsense::Normalize qw( normalize_ip optional_segment validate_uuid );

    # IP normalization
    use NetAddr::IP;
    my $cidr = normalize_ip(NetAddr::IP->new('192.0.2.0/24'));
    # $cidr eq '192.0.2.0/24'

    # UUID validation
    validate_uuid('550e8400-e29b-41d4-a716-446655440000');
    validate_uuid('invalid-uuid');  # croaks

=head1 DESCRIPTION

Provides shared normalization and validation functions used across the
OPNsense API controllers.

=head1 NAME

WebService::OPNsense::Normalize - Normalization and validation utilities

=head1 FUNCTIONS

=head2 normalize_ip

    my $cidr = normalize_ip($ip_object);

Accepts a blessed IP object and returns the canonical CIDR string.

Supported classes:

=over

=item L<Net::CIDR::Lite> -- via C<< ->list >> (croaks if more than one range)

=item L<Net::Netmask> -- via C<< ->desc >>

=item L<NetAddr::IP> -- via C<< ->cidr >>

=back

=head2 validate_uuid

    validate_uuid($uuid);

Validates that C<$uuid> is a well-formed UUID string (any version).
Croaks with L<Carp> if the UUID is undefined or invalid.

=head2 optional_segment

    my $segment = optional_segment($value);

Returns C</$value> if C<$value> is defined, or an empty string otherwise.
Used to build API paths with optional trailing segments.

    my $path = "/api/endpoint/toggle/$uuid" . optional_segment($enabled);
    # $path eq "/api/endpoint/toggle/$uuid" if $enabled is undef
    # $path eq "/api/endpoint/toggle/$uuid/1" if $enabled is 1

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
