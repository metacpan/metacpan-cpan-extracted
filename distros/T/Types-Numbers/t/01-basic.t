use strict;
use warnings;

use Test::More;
use Test::TypeTiny 'ok_subtype';
use Types::Numbers ':all';

use lib 't/lib';
use NumbersTest;

my @types = (
   NumLike, NumRange, IntLike, PerlNum, BlessedNum, NaN, Inf, RealNum,
   PerlSafeInt, BlessedInt, SignedInt, UnsignedInt,
   BlessedFloat, FloatSafeNum, RealSafeNum, FloatBinary, FloatDecimal, FixedBinary, FixedDecimal,
);

my $pass_types = {
   NumLike       => [qw( perl bint bfloat   uint sint float nan inf )],
   NumRange      => [qw( perl bint bfloat   uint sint float nan inf )],
   IntLike       => [qw( perl bint bfloat   uint sint               )],
   PerlNum       => [qw( perl               uint sint float nan inf )],
   BlessedNum    => [qw(      bint bfloat   uint sint float nan inf )],
   NaN           => [qw( perl bint bfloat                   nan     )],
   Inf           => [qw( perl bint bfloat                       inf )],
   RealNum       => [qw( perl bint bfloat   uint sint float         )],

   PerlSafeInt   => [qw( perl               uint sint               )],
   PerlSafeFloat => [qw( perl      bfloat   uint sint float nan inf )],
   BlessedInt    => [qw(      bint bfloat   uint sint               )],
   SignedInt     => [qw( perl bint bfloat   uint sint               )],
   UnsignedInt   => [qw( perl bint bfloat   uint                    )],

   BlessedFloat  => [qw(           bfloat   uint sint float nan inf )],
   FloatSafeNum  => [qw( perl      bfloat   uint sint float nan inf )],
   RealSafeNum   => [qw( perl      bfloat   uint sint float         )],
   FloatBinary   => [qw( perl      bfloat   uint sint float nan inf )],
   FloatDecimal  => [qw( perl      bfloat   uint sint float nan inf )],
   FixedBinary   => [qw( perl      bfloat   uint sint float         )],
   FixedDecimal  => [qw( perl      bfloat   uint sint float         )],
};

my $supertypes = {
   NumLike      => [Types::Standard::Item, Types::Standard::Defined],
};
$supertypes = {
   %$supertypes,
   NumRange     => [@{$supertypes->{'NumLike'}}, NumLike],
};
$supertypes = {
   %$supertypes,
   IntLike      => $supertypes->{'NumRange'},
   PerlNum      => $supertypes->{'NumRange'},
   BlessedNum   => $supertypes->{'NumRange'},
   NaN          => $supertypes->{'NumRange'},
   Inf          => $supertypes->{'NumRange'},
   FloatSafeNum => $supertypes->{'NumRange'},
   RealNum      => $supertypes->{'NumRange'},
};
$supertypes = {
   %$supertypes,
   SignedInt     => [@{$supertypes->{'IntLike'}}, IntLike],
   UnsignedInt   => [@{$supertypes->{'IntLike'}}, IntLike],
   PerlSafeInt   => [@{$supertypes->{'PerlNum'}}, PerlNum],
   PerlSafeFloat => [@{$supertypes->{'PerlNum'}}, PerlNum],

   BlessedInt    => [@{$supertypes->{'BlessedNum'}}, BlessedNum],
   BlessedFloat  => [@{$supertypes->{'BlessedNum'}}, BlessedNum],

   FloatBinary   => [@{$supertypes->{'FloatSafeNum'}}, FloatSafeNum],
   FloatDecimal  => [@{$supertypes->{'FloatSafeNum'}}, FloatSafeNum],

   RealSafeNum   => [@{$supertypes->{'RealNum'}}, RealNum],
   FixedBinary   => [@{$supertypes->{'RealNum'}}, RealNum, RealSafeNum],
   FixedDecimal  => [@{$supertypes->{'RealNum'}}, RealNum, RealSafeNum],
};

#  Item (T:S)
#     Defined (T:S)
#        NumLike
#           NumRange
#           IntLike
#              SignedInt[`b]
#              UnsignedInt[`b]
#           PerlNum
#              PerlSafeFloat
#              PerlSafeInt
#           BlessedNum[`d]
#              BlessedInt[`d]
#              BlessedFloat[`d]
#           NaN
#           Inf
#           FloatSafeNum
#              FloatBinary[`b, `e]
#              FloatDecimal[`d, `e]
#           RealNum
#              RealSafeNum
#                 FixedBinary[`b, `s]
#                 FixedDecimal[`d, `s]

#        Value (T:S)
#           Str (T:S)
#              Char[`b]

plan tests => scalar(@types);

foreach my $type (@types) {
   my $name = $type->name;
   my $is_pass;

   my $should_pass = {
      (map { $_ => 0 } @{ $pass_types->{'NumLike'} }),
      (map { $_ => 1 } @{ $pass_types->{$name}     })
   };

   subtest $name => sub {
      plan tests => scalar(@{$supertypes->{$name}}) + 32;
      note explain {
         name => $name,
         inline => $type->inline_check('$num'),
      };

      foreach my $supertype (@{$supertypes->{$name}}) {
         local $TODO = 'Union/Intersection parent issues' if (
            $supertype->name eq 'BlessedNum' && $type->name eq 'BlessedInt'   or
            $supertype->name eq 'IntLike'    && $type->name eq 'SignedInt'    or
            $supertype->name eq 'RealNum'    && $type->name eq 'RealSafeNum'  or
            $supertype->name eq 'RealNum'    && $type->name eq 'FixedBinary'  or
            $supertype->name eq 'RealNum'    && $type->name eq 'FixedDecimal'
         );

         ok_subtype($supertype, $type) ||
            diag join(', ', map { $_->name.($_->name eq $_->display_name ? '' : ' ('.$_->display_name.')') } ($type, $type->parents));
      }

      numbers_test(undef, $type, 0);
      numbers_test('ABC', $type, 0);

      # Perl numbers
      $is_pass = $should_pass->{perl} && $should_pass->{uint};
      numbers_test(    0, $type, $is_pass);
      numbers_test(    1, $type, $is_pass);
      numbers_test(_SAFE_NUM_MAX-1, $type, $is_pass);
      numbers_test(_SAFE_NUM_MAX+1, $type, $name =~ /Int(?!Like)|Float|Fixed|RealSafe/ ? 0 : $is_pass);

      $is_pass = $should_pass->{perl} && $should_pass->{sint};
      numbers_test(   -1, $type, $is_pass);
      numbers_test(_SAFE_NUM_MIN+1, $type, $is_pass);
      numbers_test(_SAFE_NUM_MIN-1, $type, $name =~ /Int(?!Like)|Float|Fixed|RealSafe/ ? 0 : $is_pass);

      $is_pass = $should_pass->{perl} && $should_pass->{float};
      numbers_test(  0.5, $type, $is_pass);
      numbers_test( -2.5, $type, $is_pass);

      $is_pass = $should_pass->{perl} && $should_pass->{nan};
      numbers_test( $nan, $type, $is_pass);

      $is_pass = $should_pass->{perl} && $should_pass->{inf};
      numbers_test($pinf, $type, $is_pass);
      numbers_test($ninf, $type, $is_pass);

      # BigInts
      $is_pass = $should_pass->{bint} && $should_pass->{uint};
      numbers_test(  $I0, $type, $is_pass);
      numbers_test(  $I1, $type, $is_pass);
      numbers_test($IMAX, $type, $is_pass);

      $is_pass = $should_pass->{bint} && $should_pass->{sint};
      numbers_test( $I_1, $type, $is_pass);
      numbers_test($IMIN, $type, $is_pass);

      $is_pass = $should_pass->{bint} && $should_pass->{nan};
      numbers_test($Inan, $type, $is_pass);

      $is_pass = $should_pass->{bint} && $should_pass->{inf};
      numbers_test($Ipinf, $type, $is_pass);
      numbers_test($Ininf, $type, $is_pass);

      # BigFloats
      $is_pass = $should_pass->{bfloat} && $should_pass->{uint};
      numbers_test(  $F0, $type, $is_pass);
      numbers_test(  $F1, $type, $is_pass);
      numbers_test($FMAX, $type, $is_pass);

      $is_pass = $should_pass->{bfloat} && $should_pass->{sint};
      numbers_test( $F_1, $type, $is_pass);
      numbers_test($FMIN, $type, $is_pass);

      $is_pass = $should_pass->{bfloat} && $should_pass->{float};
      numbers_test( $F05, $type, $is_pass);
      numbers_test($F_25, $type, $is_pass);

      $is_pass = $should_pass->{bfloat} && $should_pass->{nan};
      numbers_test($Fnan, $type, $is_pass);

      $is_pass = $should_pass->{bfloat} && $should_pass->{inf};
      numbers_test($Fpinf, $type, $is_pass);
      numbers_test($Fninf, $type, $is_pass);
   } or diag explain {
      name => $name,
      inline => $type->inline_check('$num'),
   };
}

done_testing;
