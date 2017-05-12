package NumbersTest;

use strict;
use warnings;
#use Devel::SimpleTrace;

use base 'Exporter';

use Test::More;
use Test::Exception;
use Test::TypeTiny ();

use Scalar::Util 'blessed';
use POSIX 'ceil';

use Math::BigInt;
use Math::BigFloat;

use constant {
   _BASE2_LOG     => log(2) / log(10),
   _SAFE_NUM_MIN  => Data::Integer::min_signed_natint   < Data::Float::max_integer * -1 ?
                     Data::Integer::min_signed_natint   : Data::Float::max_integer * -1,
   _SAFE_NUM_MAX  => Data::Integer::max_unsigned_natint > Data::Float::max_integer *  1 ?
                     Data::Integer::max_unsigned_natint : Data::Float::max_integer *  1,
};

our @EXPORT = qw(
   numbers_test ceil blessed _BASE2_LOG _SAFE_NUM_MIN _SAFE_NUM_MAX
   $bigtwo $bigten
                                             $nan  $pinf  $ninf
   $I1 $I0 $I_1                 $IMAX $IMIN $Inan $Ipinf $Ininf
   $F1 $F0 $F_1 $F05 $F15 $F_25 $FMAX $FMIN $Fnan $Fpinf $Fninf
);

# configure some basic big number stuff
Math::BigInt  ->config({
   round_mode => 'common',
   trap_nan   => 0,
   trap_inf   => 0,
});
Math::BigFloat->config({
   round_mode => 'common',
   trap_nan   => 0,
   trap_inf   => 0,
});

our $bigtwo = Math::BigFloat->new(2);
our $bigten = Math::BigFloat->new(10);

# Perl numbers (most are literals)
our $nan  = Data::Float::nan;
our $pinf = Data::Float::pos_infinity;
our $ninf = Data::Float::neg_infinity;

# BigInts
our $I1   = Math::BigInt->bone();
our $I0   = Math::BigInt->bzero();
our $I_1  = -$I1;   # -1

our $IMAX = Math::BigInt->new(_SAFE_NUM_MAX);
our $IMIN = Math::BigInt->new(_SAFE_NUM_MIN);

our $Inan  = Math::BigInt->bnan();
our $Ipinf = Math::BigInt->binf('+');
our $Ininf = Math::BigInt->binf('-');

# BigFloats
our $F1   = Math::BigFloat->bone();
our $F0   = Math::BigFloat->bzero();
our $F_1  = -$F1;   # -1
our $F05  = $F1 / 2;        # +0.5
our $F15  = $F1 + $F05;     # +1.5
our $F_25 = -($F15 + $F1);  # -2.5

our $FMAX = Math::BigFloat->new(_SAFE_NUM_MAX);
our $FMIN = Math::BigFloat->new(_SAFE_NUM_MIN);

our $Fnan  = Math::BigFloat->bnan();
our $Fpinf = Math::BigFloat->binf('+');
our $Fninf = Math::BigFloat->binf('-');

sub numbers_test {
   my ($val, $type, $is_pass) = @_;
   no warnings 'uninitialized';
   my $class = blessed $val;

   # turn -1 into a fail
   $is_pass = 0 if ($is_pass == -1);

   # Parameterized integer tests only: Extra check with unblessed numbers and _SAFE_NUM_MIN/MAX
   $is_pass = 0 unless (
      $type->display_name !~ /Int\[/ || !$is_pass || $class ||
      $val < _SAFE_NUM_MAX && $val > _SAFE_NUM_MIN
   );

   # TODO these tests
   local $TODO = 'Problems with Win32, INF, and looks_like_number (see RT#89423)'
      if ($^O eq 'MSWin32' && $val =~ /IN[DF]/i && Data::Float::float_is_infinite($val));

   my $num_length = $val =~ /^-?(\d+)(?:\.(\d+))?$/ ?
      join '.', length $1, (length $2 || 0) :
      0
   ;

   my $sval = "$val";
   $sval =~ s/^(-?\d{50})\d+(\d{8})/$1...$2/;

   my $msg = sprintf("%s: %s %6s%s%s",
      $type->display_name,
      ($is_pass ? 'accepts' : 'rejects'),
      $sval,
      ($class ? " ($class)" : ''),
      ($num_length >= 20 ? " [$num_length]" : ''),
   );

   my $result = $is_pass ?
      Test::TypeTiny::should_pass($val, $type, $msg) :
      Test::TypeTiny::should_fail($val, $type, $msg)
   ;

   my $error_msg;
   if ($type->can('validate_explain')) {
      my $errors = $type->validate_explain($val);
      $error_msg = join "\n", @{ $type->validate_explain($val) } if ($errors);
   }
   else {
      $error_msg = $type->validate;
   }

   diag $error_msg if ($error_msg && !$result);
   #diag $error_msg if ($error_msg);
}

1;