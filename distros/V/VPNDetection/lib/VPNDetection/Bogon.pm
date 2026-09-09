package VPNDetection::Bogon;

use strict;
use warnings;

use Socket qw(AF_INET AF_INET6 inet_pton);

use VPNDetection::Bogons;
use VPNDetection::Result;

our $VERSION = '1.4.0';

# Whether an address is private, loopback, link-local, documentation, multicast
# or otherwise not routable on the public internet, including the IPv6
# equivalents and the 6to4 and Teredo ranges that wrap them.
#
# These can never be VPN or proxy infrastructure, so the client answers them
# itself and they never cost a request.
sub is_bogon {
    my ($ip) = @_;
    return 0 unless defined $ip && length $ip;

    my $v6 = index($ip, ':') >= 0;
    my $addr = _pton($v6 ? AF_INET6 : AF_INET, $ip);
    return 0 unless defined $addr;

    for my $range (@{ $v6 ? _v6() : _v4() }) {
        return 1 if ($addr & $range->[1]) eq $range->[0];
    }
    return 0;
}

# The answer a bogon gets, in the full shape the API serves at its widest plan:
# every flag present and false, every detail object present and empty.
sub bogon_result {
    my ($ip) = @_;
    my %answer = (ip => $ip, is_bogon => 1);
    $answer{$_} = 0 for @VPNDetection::Result::FLAGS;
    $answer{$_} = {} for @VPNDetection::Result::DETAILS;
    return VPNDetection::Result->_new(\%answer, {});
}

# Parsed on first use rather than at load: a program that never looks an address
# up should not pay for the table.
my ($v4, $v6);

sub _v4 {
    $v4 ||= [map { _range(AF_INET, $_, 4) } @VPNDetection::Bogons::V4];
    return $v4;
}

sub _v6 {
    $v6 ||= [map { _range(AF_INET6, $_, 16) } @VPNDetection::Bogons::V6];
    return $v6;
}

# A range is [masked network bytes, mask bytes], both packed strings, so
# membership is one bitwise string AND and one string comparison. Perl has no
# 128 bit integer, and it does not need one: `&` on two byte strings is a
# per-byte AND, so a /36 IPv6 mask is just a 16 byte string.
#
# That behavior is why no file in this distribution says `use v5.28` or later:
# those enable the `bitwise` feature, under which `&` becomes numeric-only, both
# operands numify to 0, and EVERY address would match EVERY range. The 46 case
# isBogon corpus is what catches it.
sub _range {
    my ($family, $cidr, $width) = @_;
    my ($net, $bits) = split m{/}, $cidr, 2;
    my $mask = _mask($bits, $width);
    return [inet_pton($family, $net) & $mask, $mask];
}

sub _mask {
    my ($bits, $width) = @_;
    my $mask = "\xff" x int($bits / 8);
    my $partial = $bits % 8;
    $mask .= chr((0xff << (8 - $partial)) & 0xff) if $partial;
    return $mask . "\x00" x ($width - length $mask);
}

# inet_pton is strict: it rejects a prefix, a shortened dotted quad and junk, so
# no separate validation is needed. It dies rather than returning undef on some
# platforms, hence the eval.
sub _pton {
    my ($family, $ip) = @_;
    my $packed = eval { inet_pton($family, $ip) };
    return undef unless defined $packed;
    return $packed;
}

1;

__END__

=head1 NAME

VPNDetection::Bogon - the local bogon check behind C<< $client->is_bogon >>

=head1 DESCRIPTION

Implementation detail. Use L<VPNDetection/is_bogon>, which is exported on
request and is also a method on the client.

=cut
