package Web3::Tiny::Util;

use strict;
use warnings;
use Exporter 'import';
use Math::BigInt;

our $VERSION   = '0.01';
our @EXPORT_OK = qw(to_wei from_wei hex_to_bigint bigint_to_hex);

my %UNITS = (
    wei    => 0,
    kwei   => 3,
    mwei   => 6,
    gwei   => 9,
    szabo  => 12,
    finney => 15,
    ether  => 18,
);

sub _unit_exp {
    my ($unit) = @_;
    $unit = lc($unit // 'ether');
    die "Web3::Tiny::Util: unknown unit '$unit'\n" unless exists $UNITS{$unit};
    return $UNITS{$unit};
}

# to_wei($amount, $unit = 'ether') -> decimal string (wei)
sub to_wei {
    my ($amount, $unit) = @_;
    my $exp = _unit_exp($unit);

    # split on a decimal point so fractional ether amounts (e.g. "1.5")
    # convert exactly, without floating-point error
    my ($sign, $int_part, $frac_part) = ($amount =~ /^(-?)(\d*)(?:\.(\d*))?$/)
        or die "Web3::Tiny::Util: bad amount '$amount'\n";
    $int_part  ||= '0';
    $frac_part ||= '';
    die "Web3::Tiny::Util: '$amount' has more precision than 1 wei\n" if length($frac_part) > $exp;
    $frac_part .= '0' x ($exp - length($frac_part));

    my $wei = Math::BigInt->new($int_part . $frac_part);
    $wei = $wei->bneg if $sign eq '-';
    return $wei->bstr;
}

# from_wei($wei, $unit = 'ether') -> decimal string, e.g. "1.5"
sub from_wei {
    my ($wei, $unit) = @_;
    my $exp = _unit_exp($unit);
    return "$wei" if $exp == 0;

    my $bi = ref($wei) && $wei->isa('Math::BigInt') ? $wei->copy : Math::BigInt->new("$wei");
    my $neg = $bi->is_neg;
    $bi->babs;

    my $str = $bi->bstr;
    $str = ('0' x ($exp + 1 - length($str))) . $str if length($str) < $exp + 1;

    my $int_part  = substr($str, 0, length($str) - $exp);
    my $frac_part = substr($str, length($str) - $exp);
    $frac_part =~ s/0+$//;

    my $out = length($frac_part) ? "$int_part.$frac_part" : $int_part;
    return $neg ? "-$out" : $out;
}

# hex_to_bigint("0x1a") -> Math::BigInt(26)
sub hex_to_bigint {
    my ($hex) = @_;
    $hex = '0x0' unless defined $hex && length($hex);
    return Math::BigInt->from_hex($hex);
}

# bigint_to_hex(26) -> "0x1a"
sub bigint_to_hex {
    my ($n) = @_;
    my $bi = ref($n) && $n->isa('Math::BigInt') ? $n : Math::BigInt->new("$n");
    my $hex = lc $bi->as_hex;
    return $hex;
}

1;

__END__

=head1 NAME

Web3::Tiny::Util - Unit conversion and hex/bigint helpers

=head1 SYNOPSIS

    use Web3::Tiny::Util qw(to_wei from_wei);

    my $wei    = to_wei('1.5', 'ether');   # "1500000000000000000"
    my $ether  = from_wei($wei, 'ether');  # "1.5"

=cut
