package YATT::Lite::WebMVC0::Partial::StrictIPMatch;
sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use Socket qw(inet_pton AF_INET AF_INET6);

use YATT::Lite::Util qw(lexpand);

#
# Strict address matching for SiteApp's allow_debug_from and
# trusted_proxies. The default compile_addr_matcher in SiteApp compares
# addresses as literal strings (cheap, no parsing). This Partial parses
# them instead, so entries can be CIDR ranges (10.0.0.0/8,
# 2001:db8::/32), IPv6 spellings are normalized (::1 eq
# 0:0:0:0:0:0:0:1) and IPv4-mapped IPv6 addresses (::ffff:10.1.2.3)
# match their IPv4 entries. Unparsable entries croak at configure time.
#
#   use YATT::Lite::WebMVC0::SiteApp -as_base;
#   use YATT::Lite::WebMVC0::Partial::StrictIPMatch -as_base;
#
use YATT::Lite::Partial
  (requires => [qw/compile_addr_matcher/]);

sub compile_addr_matcher {
  (my MY $self, my ($name, $list)) = @_;
  my @ranges;
  foreach my $item (grep {defined $_ and $_ ne ''} lexpand($list)) {
    my ($addr, $bits) = $item =~ m{^([^/]+)(?:/(\d{1,3}))?\z}
      or croak "Invalid address or CIDR in $name: $item";
    my ($packed, $family) = $self->parse_ip_address($addr)
      or croak "Invalid address or CIDR in $name: $item";
    my $max = $family == AF_INET ? 32 : 128;
    $bits //= $max;
    croak "Invalid address or CIDR in $name: $item" if $bits > $max;
    push @ranges, [$family, $bits, $self->_ip_prefix($packed, $bits)];
  }
  return sub { 0 } unless @ranges;
  sub {
    my ($packed, $family) = $self->parse_ip_address($_[0])
      or return 0;
    foreach my $range (@ranges) {
      my ($fam, $bits, $prefix) = @$range;
      next unless $fam == $family;
      return 1 if $self->_ip_prefix($packed, $bits) eq $prefix;
    }
    0;
  };
}

#
# ($packed, $family) for an address string, or () when it is not one.
# IPv4-mapped IPv6 addresses are returned as IPv4.
#
sub parse_ip_address {
  (my MY $self, my $str) = @_;
  return unless defined $str and length $str;
  if ($str =~ /:/) {
    defined(my $packed = inet_pton(AF_INET6, $str)) or return;
    if (substr($packed, 0, 12) eq "\0" x 10 . "\xff\xff") {
      return (substr($packed, 12), AF_INET);
    }
    return ($packed, AF_INET6);
  } else {
    # inet_pton(AF_INET) alone accepts short forms on some platforms
    # (1.2.3 => 1.2.0.3); insist on dotted quad.
    return unless $str =~ /^(?:\d{1,3}\.){3}\d{1,3}\z/;
    defined(my $packed = inet_pton(AF_INET, $str)) or return;
    return ($packed, AF_INET);
  }
}

sub _ip_prefix {
  (my MY $self, my ($packed, $bits)) = @_;
  my $full = int($bits / 8);
  my $rest = $bits % 8;
  my $prefix = substr($packed, 0, $full);
  if ($rest) {
    $prefix .= chr(ord(substr($packed, $full, 1)) & (0xff << (8 - $rest) & 0xff));
  }
  $prefix;
}

1;
