use v5.10;
use Math::BigInt;
use Scalar::Util 'blessed';

unless (@ARGV) {
    say "$0 number [to_warnbits]";
    say;
    say "Example usage:";
    say "$0 0x55555555555555555555555555555500               --> 1902996923607946508077714625932660180412006400";
    say "$0 1902996923607946508077714625932660180412006400 1 --> 0x55555555555555555555555555555500";
    exit;
}

my $num = Math::BigInt->new( $ARGV[0] );

# NOTE: FATAL codes also should mark the non-fatal bits, and MULTI bits should be included for all of them.

# NF -> F  (in binary)
# =======  ============
#  0 -> 0  0000 -> 0000
#  1 -> 3  0001 -> 0011
#  4 -> C  0100 -> 1100
#  5 -> F  0101 -> 1111

unless ($ARGV[1]) {
   $num = byte_reverse($num);
   $num = bit_reverse($num);
   $num = $num->blsft(32);
   say $num->bstr;
}
# Decimal pragma hash to warnbits
else {
   $num = $num->brsft(32);
   $num = bit_reverse($num);
   $num = byte_reverse($num);
   say $num->as_hex;
}

sub bit_reverse ($) {
   my $num = bare_bits($_[0]);
   $num = reverse sprintf('%0128s', $num);
   return Math::BigInt->new( '0b'.$num );
}

sub byte_reverse ($) {
   my $num = bare_bits($_[0]);

   $num = sprintf('%0128s', $num);
   $num = join('', map { scalar reverse } ($num =~ /(.{8})/g));

   return Math::BigInt->new( '0b'.$num );
}

sub bare_bits {
   my ($num) = @_;
   $num = $num->as_bin if (blessed $num);
   $num =~ s/^0b//;
   return $num;
}