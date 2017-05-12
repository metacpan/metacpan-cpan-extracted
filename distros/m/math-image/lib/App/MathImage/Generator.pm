# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


# count_outside / count_total decay progressively ...


package App::MathImage::Generator;
use 5.004;
use strict;
use Carp;
use POSIX 'floor', 'ceil';
use Math::Libm 'hypot';
use Module::Load;
use Module::Util;
use Image::Base 1.16; # 1.16 for diamond()
use Time::HiRes;
use List::Util 'min', 'max';
use List::Pairwise 'mapp';
use Locale::TextDomain 'App-MathImage';

use App::MathImage::Image::Base::Other;

use vars '$VERSION';
$VERSION = 110;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant default_options => {
                                 values       => 'Primes',
                                 path         => 'SquareSpiral',
                                 scale        => 1,
                                 width        => 10,
                                 height       => 10,
                                 foreground   => 'white',
                                 background   => 'black',
                                 filter       => 'All',
                                 figure       => 'default',

                                 # hack for prima code
                                 path_parameters => { wider => 0 },

                                 # fraction     => '5/29',
                                 # spectrum     => (sqrt(5)+1)/2,
                                 # polygonal    => 5,
                                 # parity       => 'odd',
                                 # multiplicity => 'repeated',
                                 # pairs        => 'first',
                                };

use constant filter_choices => qw(All Odd Even Primes Squares);
use constant filter_choices_display => (('No Filter'),
                                        ('Odd'),
                                        ('Even'),
                                        ('Primes'),
                                        ('Squares'));

### *DESTROY = sub { print "Generator DESTROY\n" }

sub new {
  my $class = shift;
  ### Generator new()...
  my $self = bless { %{$class->default_options()}, @_ }, $class;

  if (! defined $self->{'undrawnground'}) {
    $self->{'undrawnground'}
      = _colour_average ($self->{'foreground'},
                         $self->{'background'},
                         0.15)
        || $self->{'background'};
  }

  $self->{'path_parameters'} ||= {};
  $self->{'values_parameters'} ||= {};
  return $self;
}

sub _colour_average {
  my ($c1, $c2, $f1) = @_;
  my ($r1,$g1,$b1) = colour_to_rgb($c1) or return;
  my ($r2,$g2,$b2) = colour_to_rgb($c2) or return;
  my $f2 = 1-$f1;
  return rgb1_to_rgbstr ($r1*$f1 + $r2*$f2,
                         $g1*$f1 + $g2*$f2,
                         $b1*$f1 + $b2*$f2);
}

use constant::defer values_choices => sub {
  my %choices;
  ### @INC
  foreach my $module (Module::Util::find_in_namespace('Math::NumSeq')) {
    ### $module
    my $choice = $module;
    $choice =~ s/^Math::NumSeq:://;
    next if $choice =~ /::/; # not sub-modules
    $choice =~ s/::/-/g;
    $choices{$choice} = 1;
  }
  ### %choices
  my @choices;
  foreach my $prefer (qw(Primes
                         MobiusFunction
                         LiouvilleFunction
                         PrimeFactorCount
                         TwinPrimes
                         SophieGermainPrimes
                         SafePrimes
                         CunninghamLength
                         DeletablePrimes
                         ErdosSelfridgeClass
                         PrimeIndexOrder
                         PrimeIndexPrimes
                         LongFractionPrimes

                         AlmostPrimes
                         Emirps
                         DivisorCount
                         AllDivisors
                         GoldbachCount
                         LemoineCount
                         PythagoreanHypots

                         AllPrimeFactors

                         Totient
                         TotientCumulative
                         TotientSteps
                         TotientStepsSum
                         TotientPerfect
                         DedekindPsiCumulative
                         DedekindPsiSteps
                         Abundant
                         PolignacObstinate
                         DuffinianNumbers

                         Squares
                         Pronic
                         Triangular
                         Polygonal
                         StarNumbers
                         Cubes
                         Tetrahedral
                         Powerful
                         PowerPart
                         PowerFlip

                         Odd
                         Even
                         Modulo
                         All
                         Multiples
                         AllDigits
                         PrimesDigits
                         ConcatNumbers
                         Runs

                         Fibonacci
                         LucasNumbers
                         Fibbinary
                         FibbinaryBitCount
                         FibonacciWord
                         LucasSequenceModulo
                         PisanoPeriod
                         PisanoPeriodSteps
                         Pell
                         Perrin
                         Padovan
                         Tribonacci
                         SpiroFibonacci
                         Factorials
                         Primorials
                         Catalan
                         BalancedBinary

                         FractionDigits
                         SqrtDigits
                         SqrtEngel
                         SqrtContinued
                         SqrtContinuedPeriod
                         AlgebraicContinued
                         PiBits
                         Ln2Bits

                         Aronson
                         NumAronson
                         HofstadterFigure
                         Pell
                         ThueMorse
                         ChampernowneBinary
                         ChampernowneBinaryLsb
                         SternDiatomic

                         DigitLength
                         DigitLengthCumulative
                         SelfLengthCumulative
                         DigitSum
                         DigitSumModulo
                         DigitProduct
                         DigitProductSteps
                         DigitCount
                         DigitCountHigh
                         DigitCountLow

                         PrimeQuadraticEuler
                         PrimeQuadraticLegendre
                         PrimeQuadraticHonaker

                         Repdigits
                         RepdigitAny
                         RepdigitRadix
                         RadixWithoutDigit
                         RadixConversion
                         MaxDigitCount

                         Palindromes
                         Xenodromes
                         Beastly
                         UndulatingNumbers
                         HarshadNumbers
                         KaprekarNumbers
                         MoranNumbers
                         HappyNumbers
                         HappySteps

                         ReverseAdd
                         ReverseAddSteps
                         CollatzSteps
                         JugglerSteps
                         KaprekarRoutineSteps

                         CullenNumbers
                         WoodallNumbers
                         ProthNumbers
                         BaumSweet
                         GolayRudinShapiro
                         GolayRudinShapiroCumulative
                         HafermanCarpet
                         KlarnerRado
                         UlamSequence

                         AsciiSelf
                         Kolakoski
                         KolakoskiMajority
                         GolombSequence
                         ReRound
                         ReReplace
                         LuckyNumbers
                         MephistoWaltz

                         Expression
                         PlanePathCoord
                         PlanePathDelta
                         PlanePathTurn
                         PlanePathN

                         AlphabeticalLength
                         AlphabeticalLengthSteps
                         SevenSegments

                         OEIS
                         File
                       )) {
    if (delete $choices{$prefer}) {
      push @choices, $prefer;
    }
  }
  push @choices, sort keys %choices;  # anything not listed above
  push @choices, 'Lines';
  push @choices, 'LinesLevel';
  push @choices, 'LinesTree';

  ### @choices
  @choices
};

my %special_values_class = (Lines      => 'App::MathImage::Lines',
                            LinesLevel => 'App::MathImage::LinesLevel',
                            LinesTree  => 'App::MathImage::LinesTree');
sub values_class {
  my ($class_or_self, $values) = @_;
  my $values_class = $class_or_self->values_choice_to_class($values);
  Module::Load::load ($values_class);
  return $values_class;
}
sub values_choice_to_class {
  my ($class_or_self, $values) = @_;
  $values ||= $class_or_self->{'values'};
  $values =~ s/-/::/g;
  my $class = ($special_values_class{$values}
               || "Math::NumSeq::$values");
  if (Module::Util::find_installed ($class)) {
    return $class;
  }
  return undef;
}

# return A-number string "A000000" or undef if values not in OEIS
sub oeis_anum {
  my ($self) = @_;
  if (my $seq = $self->values_seq_maybe) {
    return $seq->oeis_anum;
  }
  return undef;
}
sub values_seq_maybe {
  my ($self) = @_;
  return eval { $self->values_seq };
}

# return a Math::NumSeq object
sub values_seq {
  my ($self) = @_;

  if (exists $self->{'values_seq'}) {
    return $self->{'values_seq'};
  }

  my $values_class = $self->values_class($self->{'values'});
  ### Generator values_seq()...
  ### $values_class
  ### values_parameters: $self->{'values_parameters'}

  if (! $values_class) {
    die "Unknown values: ",$self->{'values'};
  }

  my $values_parameters = $self->{'values_parameters'};
  my $values_seq = eval {
    $values_class->new (width => $self->{'width'},
                        height => $self->{'height'},
                        %$values_parameters,
                        (($values_parameters->{'planepath'}||'') eq 'ThisPath'
                         ? (planepath_object => $self->path_object)
                         : ()))
  };
  if (! $values_seq) {
    my $err = $@;
    ### values_seq error: $@
    die $err;
  }
  ### values_seq created: $values_seq
  return ($self->{'values_seq'} = $values_seq);
}

#------------------------------------------------------------------------------
# N string

{ package Math::PlanePath;
  use constant MathImage__n_to_radixstr => undef;
  use constant MathImage__x_to_radixstr => undef;
  use constant MathImage__y_to_radixstr => undef;
}
{ package Math::PlanePath::PythagoreanTree;
  sub MathImage__n_to_radixstr {
    my ($self, $n) = @_;
    if ($n < 1) { return undef; }
    my ($pow, $exp) = round_down_pow (2*$n-1, 3);
    $n -= ($pow+1)/2;  # offset into row
    if (is_infinite($n)) { return "$n"; }
    my @digits = digit_split_lowtohigh($n,3);
    push @digits, (0) x ($exp - scalar(@digits));  # high pad to $exp many
    return '1'.join('',reverse @digits);
  }
}
{ package Math::PlanePath::FractionsTree;
  use Math::PlanePath::Base::Generic;
  use Math::PlanePath::Base::Digits;
  sub MathImage__n_to_radixstr {
    my ($self, $n) = @_;
    if ($n < 1) { return undef; }
    if (Math::PlanePath::Base::Generic::is_infinite($n)) { return "$n"; }
    my @digits = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,2);
    return join('',reverse @digits);
  }
}
{ package Math::PlanePath::RationalsTree;
  use Math::PlanePath::Base::Digits;
  *MathImage__n_to_radixstr = \&Math::PlanePath::FractionsTree::MathImage__n_to_radixstr;
}
{ package Math::PlanePath::ChanTree;
  use Math::PlanePath::Base::Digits;
  my @digit_to_char = (0..9, 'A'..'Z');
  sub MathImage__n_to_radixstr {
    my ($self, $n) = @_;
    my $n_start = $self->{'n_start'};
    if ($n < $n_start) { return undef; }
    my $offset = $self->{'n_start'}-1;
    $n -= $offset;
    if (is_infinite($n)) { return "$n"; }
    my $k = $self->{'k'};
    my @digits = reverse
      Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,$k);
    my $str;
    if ($k <= scalar(@digit_to_char)) {
      if ($k > 10) {
        @digits = map {$digit_to_char[$_]} @digits;
      }
      $str = join('', @digits);
    } else {
      $str = join(',', @digits);
    }
    if ($offset > 0) {
      $str .= "+$offset";
    } elsif ($offset < 0) {
      $str .= $offset;  # "-123"
    }
    return $str;
  }
}
{ package Math::PlanePath::WythoffArray;
  use Math::NumSeq::Fibbinary;
  my $fibbinary = Math::NumSeq::Fibbinary->new;
  sub MathImage__n_to_radixstr {
    my ($self, $y) = @_;
    if (is_infinite($y)) { return "$y"; }
    my $zeck = $fibbinary->ith($y);
    if (! $zeck) { return undef; } # 0 or undef
    return 'zeck '
      . join ('', reverse
              Math::PlanePath::Base::Digits::digit_split_lowtohigh($zeck, 2));
  }
  *MathImage__y_to_radixstr = \&MathImage__n_to_radixstr;
}

#------------------------------------------------------------------------------
# path lattice

{ package Math::PlanePath;
  use constant MathImage__lattice_type => '';
}
{ package Math::PlanePath::TriangleSpiral;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::HexSpiral;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::HexArms;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::KochCurve;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::KochPeaks;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::KochSnowflakes;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::KochSquareflakes;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::SierpinskiTriangle;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::SierpinskiArrowhead;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::SierpinskiArrowheadCentres;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::Flowsnake;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::FlowsnakeCentres;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::GosperReplicate;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::GosperSide;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::GosperIslands;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::CubicBase;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::Hypot;
  my %lattice_type = (even => 'triangular',
                      odd => 'triangular');
  sub MathImage__lattice_type {
    my ($self) = @_;
    return $lattice_type{$self->{'points'}} || '';
  }
}
{ package Math::PlanePath::HypotOctant;
  *MathImage__lattice_type = \&Math::PlanePath::Hypot::MathImage__lattice_type;
}
{ package Math::PlanePath::TriangularHypot;
  my %lattice_type = (all => '');
  sub MathImage__lattice_type {
    my ($self) = @_;
    return $lattice_type{$self->{'points'}} || 'triangular';
  }
}
{ package Math::PlanePath::TerdragonCurve;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::TerdragonRounded;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::TerdragonMidpoint;
  use constant MathImage__lattice_type => 'triangular';
}

{ package Math::PlanePath::OneOfSixByCells;
  use constant MathImage__lattice_type => 'triangular';
}
{ package Math::PlanePath::FourReplicate;
  use constant MathImage__lattice_type => 'triangular';
}


#------------------------------------------------------------------------------
# path level range

{ package Math::PlanePath;
  use constant MathImage__level_end_offset => -1;
  sub MathImage__level_radix {
    my ($self, $level) = @_;
    my $radix = $self->{'radix'};
    if (defined $radix) { $radix *= $radix; }
    return $radix;
  }
  sub MathImage__level_n_range {
    my ($self, $level) = @_;
    if (defined (my $radix = $self->MathImage__level_radix)) {
      my $n_start = $self->n_start;
      return ($n_start,
              $n_start + $radix**$level + $self->MathImage__level_end_offset);
    }
    return;
  }
}
{ package Math::PlanePath::FlowsnakeCentres;
  use constant MathImage__level_radix => 7;
}
{ package Math::PlanePath::GosperReplicate;
  use constant MathImage__level_radix => 7;
}
{ package Math::PlanePath::HilbertCurve;
  use constant MathImage__level_radix => 4;
}
{ package Math::PlanePath::HilbertSpiral;
  use constant MathImage__level_radix => 4;
}
{ package Math::PlanePath::CornerReplicate;
  use constant MathImage__level_radix => 4;
}
{ package Math::PlanePath::SquareReplicate;
  use constant MathImage__level_radix => 9;
}
{ package Math::PlanePath::AR2W2Curve;
  use constant MathImage__level_radix => 4;
}
{ package Math::PlanePath::BetaOmega;
  use constant MathImage__level_radix => 4;
}
{ package Math::PlanePath::CincoCurve;
  use constant MathImage__level_radix => 25;
}
{ package Math::PlanePath::KochelCurve;
  use constant MathImage__level_radix => 9;
}
{ package Math::PlanePath::FibonacciWordFractal;
  sub MathImage__level_n_range {
    my ($self, $level) = @_;
    my $f0 = 1;
    my $f1 = 1;
    foreach (1 .. 3*$level) {
      ($f0,$f1) = ($f1,$f0+$f1);
    }
    return (0, $f1);
  }
}
{ package Math::PlanePath::KochCurve;
  use constant MathImage__level_radix => 4;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::KochPeaks;
  sub MathImage__level_n_range {
    my ($self, $level) = @_;
    return ($level + (2*4**$level + 1)/3,
            $level + (8*4**$level + 1)/3);
  }
}
{ package Math::PlanePath::KochSnowflakes;
  sub MathImage__level_n_range {
    my ($self, $level) = @_;
    return (4 ** $level,
            4 ** ($level+1) - 1);
  }
}
{ package Math::PlanePath::KochSquareflakes;
  sub MathImage__level_n_range {
    my ($self, $level) = @_;
    return ((4 ** ($level+1) - 1) / 3,
            (4 ** ($level+2) - 4) / 3);
  }
}
{ package Math::PlanePath::SierpinskiArrowhead;
  use constant MathImage__level_radix => 3;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::SierpinskiArrowheadCentres;
  use constant MathImage__level_radix => 3;
}
{ package Math::PlanePath::SierpinskiTriangle;
  use constant MathImage__level_radix => 3;
}
{ package Math::PlanePath::SierpinskiCurve;
  use constant MathImage__level_radix => 4;
}
{ package Math::PlanePath::SierpinskiCurveStair;
  # or 2* to triangular peak
  sub MathImage__level_n_range {
    my ($self, $level) = @_;
    return (0,
            ((6*$self->{'diagonal_length'}+4)*4**$level - 4) / 3);
  }

}
{ package Math::PlanePath::HIndexing;
  sub MathImage__level_n_range {
    my ($self, $level) = @_;
    return (0,
            2 * 4 ** $level - 1);
  }
}
{ package Math::PlanePath::QuadricCurve;
  use constant MathImage__level_radix => 8;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::QuadricIslands;
  sub MathImage__level_n_range {
    my ($self, $level) = @_;
    return ((4 * 8**$level + 3)/7,
            (32 * 8**$level - 4)/7);
  }
}
{ package Math::PlanePath::GosperIslands;
  sub MathImage__level_n_range {
    my ($self, $level) = @_;
    return (3**($level+1) - 2,
            3**($level+2) - 2 - 1);
  }
}
{ package Math::PlanePath::QuintetCurve;
  use constant MathImage__level_radix => 5;
}
{ package Math::PlanePath::QuintetCentres;
  use constant MathImage__level_radix => 5;
}
{ package Math::PlanePath::QuintetReplicate;
  use constant MathImage__level_radix => 5;
}
{ package Math::PlanePath::DragonCurve;
  use constant MathImage__level_radix => 2;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::DragonMidpoint;
  use constant MathImage__level_radix => 2;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::DragonRounded;
  use constant MathImage__level_radix => 2;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::TerdragonCurve;
  use constant MathImage__level_radix => 3;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::TerdragonMidpoint;
  use constant MathImage__level_radix => 3;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::TerdragonRounded;
  sub MathImage__level_n_range {
    my ($self, $level) = @_;
    return (0,
            2*3**$level);
  }
}
{ package Math::PlanePath::R5DragonCurve;
  use constant MathImage__level_radix => 5;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::R5DragonMidpoint;
  use constant MathImage__level_radix => 5;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::AlternatePaper;
  use constant MathImage__level_radix => 2;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::AlternatePaperMidpoint;
  use constant MathImage__level_radix => 2;
}
{ package Math::PlanePath::CCurve;
  use constant MathImage__level_radix => 2;
  use constant MathImage__level_end_offset => 0;
}
{ package Math::PlanePath::ComplexPlus;
  sub MathImage__level_radix {
    my ($self) = @_;
    return $self->{'realpart'}**2 + 1;
  }
}
{ package Math::PlanePath::ComplexMinus;
  sub MathImage__level_radix {
    my ($self) = @_;
    return $self->{'realpart'}**2 + 1;
  }
}
{ package Math::PlanePath::ComplexRevolving;
  use constant MathImage__level_radix => 2;
}
{ package Math::PlanePath::DekkingCurve;
  use constant MathImage__level_radix => 25;
}
{ package Math::PlanePath::DekkingStraight;
  use constant MathImage__level_radix => 25;
}
{ package Math::PlanePath::MooreSpiral;
  use constant MathImage__level_radix => 9;
}
{ package Math::PlanePath::PeanoHalf;
  use constant MathImage__level_radix => 9;
}

#------------------------------------------------------------------------------
# path x,y negative

sub x_negative {
  my ($self) = @_;
  my $path_object = $self->path_object;
  if ($self->{'use_class_negative'}) {
    return $path_object->class_x_negative;
  } else {
    return $path_object->x_negative;
  }
}
sub y_negative {
  my ($self) = @_;
  my $path_object = $self->path_object;
  if ($self->{'use_class_negative'}) {
    return $path_object->class_y_negative;
  } else {
    return $path_object->y_negative;
  }
}

#------------------------------------------------------------------------------

sub path_choices {
  my ($class) = @_;
  return @{$class->path_choices_array};
}
use constant::defer path_choices_array => sub {
  my %choices;
  my $base = 'Math::PlanePath';
  foreach my $module (Module::Util::find_in_namespace($base)) {
    my $choice = $module;
    $choice =~ s/^\Q$base\E:://;
    next if $choice =~ /::/; # not sub-parts ?
    $choices{$choice} = 1;
  }
  my @choices;
  foreach my $prefer ('SquareSpiral',
                      'SacksSpiral',
                      'VogelFloret',
                      'TheodorusSpiral',
                      'ArchimedeanChords',
                      'MultipleRings',
                      'PixelRings',
                      'FilledRings',
                      'Hypot',
                      'HypotOctant',
                      'TriangularHypot',

                      'DiamondSpiral',
                      'AztecDiamondRings',
                      'PentSpiral',
                      'PentSpiralSkewed',
                      'HexSpiral',
                      'HexSpiralSkewed',
                      'HeptSpiralSkewed',
                      'AnvilSpiral',
                      'TriangleSpiral',
                      'TriangleSpiralSkewed',
                      'OctagramSpiral',
                      'KnightSpiral',
                      'CretanLabyrinth',

                      'SquareArms',
                      'DiamondArms',
                      'HexArms',
                      'GreekKeySpiral',
                      'MPeaks',

                      'PyramidRows',
                      'PyramidSides',
                      'PyramidSpiral',
                      'CellularRule',
                      'CellularRule54',
                      'CellularRule57',
                      'CellularRule190',

                      'Corner',
                      'Diagonals',
                      'DiagonalsAlternating',
                      'DiagonalsOctant',
                      'Staircase',
                      'StaircaseAlternating',
                      'Rows',
                      'Columns',

                      'PeanoCurve',
                      'HilbertCurve',
                      'HilbertMidpoint',
                      'HilbertSpiral',
                      'ZOrderCurve',
                      'GrayCode',
                      'WunderlichSerpentine',
                      'WunderlichMeander',
                      'BetaOmega',
                      'AR2W2Curve',
                      'KochelCurve',
                      'DekkingCurve',
                      'DekkingCentres',
                      'CincoCurve',

                      'ImaginaryBase',
                      'ImaginaryHalf',
                      'CubicBase',
                      'SquareReplicate',
                      'CornerReplicate',
                      'LTiling',
                      'FibonacciWordFractal',
                      'DigitGroups',

                      'Flowsnake',
                      'FlowsnakeCentres',
                      'GosperReplicate',
                      'GosperIslands',
                      'GosperSide',

                      'QuintetCurve',
                      'QuintetCentres',
                      'QuintetReplicate',

                      'KochCurve',
                      'KochPeaks',
                      'KochSnowflakes',
                      'KochSquareflakes',

                      'QuadricCurve',
                      'QuadricIslands',

                      'SierpinskiCurve',
                      'SierpinskiCurveStair',
                      'HIndexing',

                      'SierpinskiTriangle',
                      'SierpinskiArrowhead',
                      'SierpinskiArrowheadCentres',

                      'DragonCurve',
                      'DragonRounded',
                      'DragonMidpoint',
                      'TerdragonCurve',
                      'TerdragonRounded',
                      'TerdragonMidpoint',
                      'R5DragonCurve',
                      'R5DragonMidpoint',
                      'AlternatePaper',
                      'AlternatePaperMidpoint',
                      'CCurve',
                      'ComplexPlus',
                      'ComplexMinus',
                      'ComplexRevolving',

                      'CoprimeColumns',
                      'DivisibleColumns',
                      'DiagonalRationals',
                      'FactorRationals',
                      'CfracDigits',
                      'GcdRationals',
                      'RationalsTree',
                      'FractionsTree',
                      'ChanTree',
                      'PythagoreanTree',

                      'LCornerTree',
                      'LCornerReplicate',
                      'LCornerSingle',
                      'OneOfEight',

                      'ToothpickTree',
                      'ToothpickReplicate',
                      'ToothpickUpist',
                      'ToothpickSpiral',
                      'EToothpickTree', # experimental
                      'LToothpickTree', # experimental

                      'UlamWarburton',
                      'UlamWarburtonQuarter',

                      'WythoffArray',
                      'PowerArray',

                      'File',
                     ) {
    if (delete $choices{$prefer}) {
      push @choices, $prefer;
    }
  }
  ### path extras: %choices
  push @choices, sort keys %choices;  # anything not listed above
  \@choices
};

use constant figure_choices => ('default',
                                'point',
                                'square',
                                'box',
                                'circle',
                                'ring',
                                'diamond',
                                'diamunf',
                                'diamstar', # not documented
                                'plus',
                                'plus_fat', # not documented
                                'X',
                                'L',
                                'N',
                                'Z',
                                'V',
                                '/',        # not documented
                                '\\',       # not documented
                                '/EO',      # not documented
                                '/OE',      # not documented
                                'arrow',

                                # not documented
                                'hash',
                                'triangle',
                                'hexagon',
                                'hexunf',
                                'hexstar',
                                'hexagon_h',
                                'hexunf_h',
                                'hexstar_h',
                                'octagon',
                                'octunf',
                                'octstar',
                                'undiamond',
                                'unellipse',
                                'unellipunf',
                                'toothpick',
                                'toothpick_E',
                                'toothpick_L',
                                'toothpick_V',
                                'toothpick_Y',
                                );

#------------------------------------------------------------------------------
# random

# cf Data::Random

sub random_options {
  my ($self) = @_;
  my $values_parameters =
    {
     polygonal => (int(rand(20)) + 5), # skip 3=triangular, 4=squares
     pairs     => _rand_of_array(['first','second','both']),
     parity    => _rand_of_array(['odd','even']),
     # aronson
     lang         => _rand_of_array(['en','fr']),
     conjunctions => int(rand(2)),
     lying        => (rand() < .25), # less likely
    };
  my $path_parameters =
    {
    };
  my @ret = (values_parameters => $values_parameters,
             path_parameters   => $path_parameters);

  my @path_choices = $self->path_choices;
  @path_choices
    = grep {!/PythagoreanTree|RationalsTree|FractionsTree/}  # values too big for many seqs
      @path_choices;
  @path_choices = (@path_choices,
                   grep {!/KochCurve|GosperSide/} @path_choices);

  my @values_choices = $self->values_choices;
  @values_choices = grep {!/LinesLevel     # experimental
                            /x}
    @values_choices;
  #   # coord values are only permutation of integers, or coord repetitions ?
  # |PlanePath

  my @path_and_values;
  foreach my $path (@path_choices) {
    next if $path eq 'File';

    foreach my $values (@values_choices) {
      next if $values eq 'File';

      if ($values eq 'All' || $values eq 'Odd' || $values eq 'Even') {
        next unless $path eq 'SacksSpiral' || $path eq 'VogelFloret';
      }

      # too sparse?
      # next if ($values eq 'Factorials');

      # bit sparse?
      # next if $values eq 'Perrin' || $values eq 'Padovan';

      if ($values eq 'Squares') {
        next if $path eq 'Corner'; # just a line across the bottom
      }
      if ($values eq 'Pronic') {
        next if $path eq 'PyramidSides' # just a vertical
          || $path eq 'PyramidRows';    # just a vertical
      }
      if ($values eq 'Triangular') {
        next if ($path eq 'Diagonals' # just a line across the bottom
                 || $path eq 'DiamondSpiral');  # just a centre horizontal line
      }
      if ($values eq 'Lines' || $values eq 'LinesTree'
          || $values eq 'LinesLevel') {
        next if $path eq 'VogelFloret'; # too much crossover
      }

      push @path_and_values, [ $path, $values ];
    }
  }
  my ($path, $values) = @{_rand_of_array(\@path_and_values)};
  push @ret, path => $path, values => $values;

  my $path_class = $self->path_class($path);

  {
    my $radix;
    if ($values eq 'Repdigits' || $values eq 'Beastly') {
      $radix = _rand_of_array([2 .. 128,
                               (10) x 50]); # bias mostly 10
    } elsif ($values eq 'Emirps') {
      # for Emirps not too big or round up to 2^base becomes slow
      $radix = _rand_of_array([2,3,4,8,16,
                               10,10,10,10]); # bias mostly 10
    } else {
      $radix = _rand_of_array([2 .. 36]);
    }
    $values_parameters->{'radix'} = $radix;
  }


  {
    my $scale = _rand_of_array([1, 3, 5, 10, 15, 20]);
    if ($values eq 'Lines') {
      # not too small for lines to show up sensibly
      $scale = max ($scale, 5);
    }
    if ($values eq 'LinesLevel') {
      # not too small for lines to show up sensibly
      $scale = max ($scale, 2);
    }
    if ($values eq 'LinesTree') {
      # not too small for lines to show up sensibly
      $scale = max ($scale, 50);
    }
    push @ret, scale => $scale;
  }
  {
    require Math::Prime::XS;
    my @primes = Math::Prime::XS::sieve_primes(10,100);
    my $num = _rand_of_array(\@primes);
    @primes = grep {$_ != $num} @primes;
    my $den = _rand_of_array(\@primes);
    $values_parameters->{'fraction'} = "$num/$den";
  }
  {
    my @primes = Math::Prime::XS::sieve_primes(2,500);
    my $sqrt = _rand_of_array(\@primes);
    $values_parameters->{'sqrt'} = $sqrt;
  }

  {
    my $pyramid_step = 1 + int(rand(20));
    if ($pyramid_step > 12) {
      $pyramid_step = 2;  # most of the time
    }
    $path_parameters->{'step'} = $pyramid_step;
  }
  if ($path eq 'MultipleRings') {  # FIXME: go from parameter_info_array
    my $rings_step = int(rand(20));
    if ($rings_step > 15) {
      $rings_step = 6;  # more often
    }
    $path_parameters->{'step'} = $rings_step;
  }
  {
    my $path_wider = _rand_of_array([(0) x 10,   # 0 most of the time
                                     1 .. 20]);
    $path_parameters->{'wider'} = $path_wider;
  }
  {
    if (my $info = $path_class->parameter_info_hash->{'radix'}) {
      $path_parameters->{'radix'} = _rand_of_array([ ($info->{'default'}) x 3,
                                                     2 .. 7 ]);
    }
  }
  {
    if (my $info = $path_class->parameter_info_hash->{'arms'}) {
      $path_parameters->{'arms'}
        = _rand_of_array([ ($info->{'default'}) x 3,
                           $info->{'minimum'} .. $info->{'maximum'} ]);
    }
  }
  {
    $path_parameters->{'rotation_type'}
      = _rand_of_array(['phi','phi','phi','phi',
                        'sqrt2','sqrt2',
                        'sqrt3',
                        'sqrt5',
                       ]);
    # path_rotation_factor => $rotation_factor,
  }
  {
    my @figure_choices = $self->figure_choices;
    push @figure_choices, ('default') x scalar(@figure_choices);
    push @ret, figure => _rand_of_array(\@figure_choices);
  }
  {
    push @ret, foreground => _rand_of_array(['#FFFFFF',  # white
                                             '#FFFFFF',  # white
                                             '#FFFFFF',  # white
                                             '#FF0000',  # red
                                             '#00FF00',  # green
                                             '#0000FF',  # blue
                                             '#FFAA00',  # orange
                                             '#FFFF00',  # yellow
                                             '#FFB0B0',  # pink
                                             '#FF00FF',  # magenta
                                            ]);
  }

  return (@ret,
          # spectrum  => $spectrum,

          #
          # FIXME: don't want to filter out everything ... have values
          # classes declare their compositeness, parity, etc
          # filter           => _rand_of_array(['All','All','All',
          #                                     'All','All','All',
          #                                     'Odd','Even','Primes']),
         );
}

sub _rand_of_array {
  my ($aref) = @_;
  return $aref->[int(rand(scalar(@$aref)))];
}

#------------------------------------------------------------------------------
# generator names

sub description {
  my ($self) = @_;

  my $path_object = $self->path_object;
  my @path_desc = ($self->{'path'},
                   map {
                     my $pname = $_->{'name'};
                     my $value = $path_object->{$pname};
                     if (! defined $value) { $value = 'undef'; }
                     "$pname $value"
                   } @{$path_object->parameter_info_array});

  my $values_seq = $self->values_seq;
  my @values_desc = ($self->{'values'},
                     # $self->values_seq->name,  # NumSeq name method
                     map {
                       my $pname = $_->{'name'};
                       my $dispname = ($pname eq 'radix' ? 'base' : $pname);
                       my $value = $values_seq->{$pname};
                       if (! defined $value) { $value = $_->{'default'}; }
                       "$dispname $value"
                     } $values_seq->parameter_info_list);

  my $filtered;
  if (($self->{'filter'}||'') ne 'All') {
    $filtered = __x(", filtered {name}",
                    name => $self->{'filter'});
    # $self->values_class($self->{'filter'})->name); NumSeq name() method
  } else {
    $filtered = '';
  }

  return __x('{path_desc}, {values_desc}{filtered}, {width}x{height} scale {scale}',
             path_desc => join(' ',@path_desc),
             values_desc => join(' ',@values_desc),
             filtered => $filtered,
             width => $self->{'width'},
             height => $self->{'height'},
             scale => $self->{'scale'});
}

sub filename_base {
  my ($self) = @_;
  return join('-',
              (map { tr{/}{_}; $_ }
               $self->{'path'},
               do {
                 my $path_object = $self->path_object;
                 ### $path_object
                 ### info array: $path_object->parameter_info_array
                 map {
                   (defined $path_object->{$_->{'name'}}
                    && $path_object->{$_->{'name'}} ne $_->{'default'})
                     ? $path_object->{$_->{'name'}}
                       : ()
                     }
                   @{$path_object->parameter_info_array}
                 },
               $self->{'values'},
               do {
                 my $values_seq = $self->values_seq;
                 map {
                   (defined $values_seq->{$_->{'name'}}
                    && $values_seq->{$_->{'name'}} ne $_->{'default'})
                     ? $values_seq->{$_->{'name'}}
                       : ()
                     } $values_seq->parameter_info_list
                   },
               (($self->{'filter'}||'') eq 'All' ? () : $self->{'filter'}),
               $self->{'width'}.'x'.$self->{'height'},
               ($self->{'scale'} == 1 ? () : 's'.$self->{'scale'}),
               ($self->{'figure'} ne 'default' ? $self->{'figure'} : ()),
              ));
}


#------------------------------------------------------------------------------

use constant _SV_N_LIMIT => do {
  # NV might be long double, but don't trust that to things like floor(),ceil() yet
  my $uv_max = (~0);
  my $flt_radix = POSIX::FLT_RADIX();
  my $dbl_mant_dig = POSIX::DBL_MANT_DIG();
  my $dbl_max = POSIX::FLT_RADIX() ** POSIX::DBL_MANT_DIG() - 1;
  ### $uv_max
  ### $dbl_max
  ### $flt_radix
  ### $dbl_mant_dig
  my $limit = ($uv_max > $dbl_max ? $uv_max : $dbl_max);
  int ($limit / 8192)
};

sub path_choice_to_class {
  my ($self, $path) = @_;
  my $class = "Math::PlanePath::$path";
  if (Module::Util::find_installed ($class)) {
    return $class;
  }
  return undef;
}
sub path_class {
  my ($self, $path) = @_;
  unless ($path =~ /::/) {
    $path = $self->path_choice_to_class ($path)
      || croak "No module for path $path";
  }
  unless (eval { Module::Load::load ($path); 1 }) {
    my $err = $@;
    ### cannot load: $err
    croak $err;
  }
  return $path;
}

# return a Math::PlanePath object
sub path_object {
  my ($self) = @_;
  return ($self->{'path_object'} ||= do {

    my $path_class = $self->path_class ($self->{'path'});
    #### $path_class

    my $scale = $self->{'scale'} || 1;
    my %parameters = (width  => ceil(($self->{'width'}||0) / $scale),
                      height => ceil(($self->{'height'}||0) / $scale),
                      %{$self->{'path_parameters'}});
    ### %parameters

    if (($parameters{'rotation_type'}||'') eq 'custom') {
      delete $parameters{'rotation_type'};
    }
    $path_class->new (%parameters)
  });
}

sub affine_object {
  my ($self) = @_;
  return ($self->{'affine_object'} ||= do {
    my $scale = $self->{'scale'};
    my $scale_half_floor = int ($scale / 2);
    my $scale_half_ceil = int (($scale + 1) / 2);

    my $x_origin;
    if (defined $self->{'x_left'}) {
      $x_origin = - $self->{'x_left'} * $scale;
    } elsif (! $self->{'use_class_negative'}
             && (defined (my $x_minimum = $self->path_object->x_minimum))) {
      $x_origin = int(-$x_minimum*$scale + $scale - $scale_half_floor - 1);
    } elsif ($self->x_negative) {
      $x_origin = int($self->{'width'} / 2);
    } else {
      $x_origin = $scale - $scale_half_floor - 1;
    }
    if (defined (my $x_offset = $self->{'x_offset'})) {
      $x_origin += $x_offset;
    }

    my $y_origin;
    if (defined $self->{'y_bottom'}) {
      $y_origin = $self->{'y_bottom'} * $scale + $self->{'height'};
    } elsif (! $self->{'use_class_negative'}
             && (defined (my $y_minimum = $self->path_object->y_minimum))) {
      $y_origin = int(($y_minimum-1)*$scale + $scale_half_floor + $self->{'height'});
    } elsif ($self->y_negative) {
      $y_origin = int($self->{'height'} / 2);
    } else {
      $y_origin = $self->{'height'} - $scale + $scale_half_floor;
    }
    if (defined (my $y_offset = $self->{'y_offset'})) {
      $y_origin -= $y_offset;
    }

    ### x_negative: $self->x_negative
    ### y_negative: $self->y_negative
    ### $x_origin
    ### $y_origin

    require Geometry::AffineTransform;
    Geometry::AffineTransform->VERSION('1.3'); # 1.3 for invert()

    my $affine = Geometry::AffineTransform->new;
    $affine->scale ($scale, -$scale);
    if ($self->{'figure'} =~ /toothpick_[EVY]/) {
      $affine->scale (sqrt(3), 1);
    }
    $affine->translate ($x_origin, $y_origin);
  });
}

use constant 1.02; # for leading underscore
use constant _RECTANGLES_CHUNKS => 200 * 4;  # of X1,Y1,X2,Y2

sub covers_quadrants {
  my ($self) = @_;
  if ($self->{'background'} eq $self->{'undrawnground'}) {
    return 1;
  }
  if ($self->{'values'} eq 'Lines'
      || $self->{'values'} eq 'LinesLevel'
      || $self->{'values'} eq 'LinesTree') {
    # no undrawnground when drawing lines
    return 1;
  }
  my $path_object = $self->path_object;
  if (! _path_covers_quadrants ($path_object)) {
    return 0;
  }
  return 1;

  # my $affine_object = $self->affine_object;
  # my ($wx,$wy) = $affine_object->transform(-.5,-.5);
  # $wx = floor($wx+0.5);
  # $wy = floor($wy+0.5);
  # if (! $self->x_negative && $wx >= 0
  #     || ! $self->y_negative && $wy < $self->{'height'}-1) {
  #   return 0;
  # }
}
sub _path_covers_quadrants {
  my ($path_object) = @_;
  if ($path_object->isa('Math::PlanePath::ChanTree')) {
    return 0;
  }
  if ($path_object->isa('Math::PlanePath::PyramidRows')
      || ref($path_object) =~ /Octant/  # HypotOctant

      # too much contrast of undrawn points
      # || $path_object->isa('Math::PlanePath::CoprimeColumns')
     ) {
    return 0;
  }
  if ($path_object->figure eq 'circle') {
    return 1;
  }
  return 1;
}

sub figure {
  my ($self) = @_;
  if ($self->{'scale'} == 1) {
    return 'point';
  }
  my $figure = $self->{'figure'};
  if ($figure && $figure ne 'default') {
    return $figure;
  }
  if ($self->{'values'} =~ /^Lines/) {
    return 'circle';
  }
  return $self->path_object->figure;
}

sub colours_exp_shrink {
  my ($self) = @_;

  my $shrink = 0.6;
  if ($self->{'values'} eq 'Totient') {
    $shrink = .9995;
  } elsif ($self->{'values'} eq 'PlanePathCoord') {
    if ($self->values_seq->{'coordinate_type'} =~ /Squared/) {
      $shrink = 1 - 1/300;
    } elsif ($self->values_seq->{'coordinate_type'} eq 'Depth') {
      $shrink = 1 - 1/30;
    } elsif ($self->values_seq->{'coordinate_type'} eq 'ToLeaf') {
      $shrink = 1 - 1/4;
    } elsif ($self->values_seq->{'coordinate_type'} eq 'GcdDivisions') {
      $shrink = 1 - 1/3;
    } elsif ($self->values_seq->{'coordinate_type'} eq 'IntXY') {
      $shrink = 1 - 1/4;
    } elsif ($self->values_seq->{'coordinate_type'} eq 'HammingDist') {
      $shrink = 1 - 1/4;
    } else {
      $shrink = 1 - 1/50;
    }
  } elsif ($self->{'values'} eq 'DigitLength') {
    $shrink = 1 - 1/16 * 1/log(2) * log($self->values_seq->{'radix'});
  } elsif ($self->{'values'} eq 'JacobsthalFunction') {
    $shrink = 1 - 1/4;
  } elsif ($self->{'values'} eq 'PisanoPeriod') {
    $shrink = 1 - 1/100;
  } elsif ($self->{'values'} eq 'PisanoPeriodSteps') {
    if ($self->values_seq->{'values_type'} eq 'log') {
      $shrink = .8;
    }
  } elsif ($self->{'values'} eq 'PowerFlip') {
    $shrink = 1 - 1/15;
  } elsif ($self->{'values'} eq 'SqrtContinuedPeriod') {
    $shrink = 1 - 1/5;
  } elsif ($self->{'values'} eq 'AllPrimeFactors') {
    $shrink = 1 - 1/6;
  } elsif ($self->{'values'} eq 'LeastPrimitiveRoot') {
    $shrink = 1 - 1/10;
  } elsif ($self->{'values'} eq 'RepdigitRadix') {
    $shrink = 1 - 1/10;
  } elsif ($self->{'values'} eq 'RadixConversion') {
    # FIXME: scale based on how far apart the radix conversions,
    # maybe a log scale shrink too
    $shrink = 1 - 1/2000;
  } elsif ($self->{'values'} eq 'PrimeFactorExtract') {
    $shrink = 1 - 1/15;
  } elsif ($self->{'values'} eq 'FibonacciRepresentations') {
    $shrink = 1 - 1/15;
  } elsif ($self->{'values'} eq 'FibbinaryBitCount') {
    if (defined $self->values_seq->{'digit'}
        && $self->values_seq->{'digit'} eq '0') {
      $shrink = 1 - 1/8;
    } else {
      $shrink = 1 - 1/4;
    }
  } elsif ($self->{'values'} eq 'GolayRudinShapiroCumulative') {
    $shrink = 1 - 1/100;
  } elsif ($self->{'values'} eq 'GolayRudinShapiroCumulative') {
    $shrink = 1 - 1/100;
  } elsif ($self->{'values'} eq 'AlphabeticalLength') {
    $shrink = 1 - 1/20;
  } elsif ($self->{'values'} eq 'SevenSegments') {
    $shrink = 1 - 1/17;
  } elsif ($self->{'values'} eq 'CunninghamChain') {
    $shrink = 1 - 1/3;
  } elsif ($self->{'values'} eq 'CunninghamLength') {
    $shrink = 1 - 1/5;
  } elsif ($self->{'values'} eq 'TotientSteps') {
    $shrink = .88;
  } elsif ($self->{'values'} eq 'SternDiatomic') {
    $shrink = 1 - 1/30;
  } elsif ($self->{'values'} eq 'CollatzSteps') {
    if ($self->values_seq->{'step_type'} eq 'up') {
      $shrink = 1 - 1/15;
    } elsif ($self->values_seq->{'step_type'} eq 'down'
             || $self->values_seq->{'step_type'} eq 'diff') {
      $shrink = 1 - 1/40;
    } elsif ($self->values_seq->{'step_type'} eq 'both') {
      $shrink = 1 - 1/50;
    }
  } elsif ($self->{'values'} eq 'JugglerSteps') {
    if ($self->values_seq->{'step_type'} eq 'up') {
      $shrink = 1 - 1/10;
    } elsif ($self->values_seq->{'step_type'} eq 'down') {
      $shrink = 1 - 1/13;
    } elsif ($self->values_seq->{'step_type'} eq 'both') {
      $shrink = 1 - 1/20;
    }
  } elsif ($self->{'values'} eq 'GolombSequence') {
    $shrink = 1 - 1/400;
  } elsif ($self->{'values'} eq 'ErdosSelfridgeClass') {
    $shrink = 1 - 1/3;
    # if ($self->values_seq->{'using_values'} eq 'primes') {
    #   $shrink = 1 - 1/2;
    # } else {
    # }
  } elsif ($self->{'values'} eq 'MaxDigitCount') {
    if ($self->values_seq->{'values_type'} eq 'radix') {
      $shrink = 1 - 1/10;
    } else {
      $shrink = 1 - 1/5;
    }
  } elsif ($self->{'values'} eq 'LipschitzClass') {
    $shrink = 1 - 1/6;
  } elsif ($self->{'values'} eq 'HappySteps') {
    $shrink = 1 - 1/10;
  } elsif ($self->{'values'} eq 'DigitProduct') {
    $shrink = 1 - 1/100;
  } elsif ($self->{'values'} eq 'DigitSum') {
    $shrink = .95;
  } elsif ($self->{'values'} eq 'DigitSumSquares') {
    $shrink = .98;
  } elsif ($self->{'values'} eq 'DigitCount') {
    $shrink = .8;
  } elsif ($self->{'values'} eq 'ReReplace') {
    $shrink = 1 - 1/20;
  } elsif ($self->{'values'} eq 'GoldbachCount') {
    if (($self->values_seq->{'on_values'}||'') eq 'even') {
      $shrink = 1 - 1/100;
    } else {
      $shrink = 1 - 1/30;
    }
  } elsif ($self->{'values'} eq 'LemoineCount') {
    if (($self->values_seq->{'on_values'}||'') eq 'odd') {
      $shrink = 1 - 1/100;
    } else {
      $shrink = 1 - 1/50;
    }
  } elsif ($self->{'values'} eq 'Runs') {
    $shrink = .95;
  }
  return $shrink;
}

# return R,G,B in range 0 to 1.0
sub colour_to_rgb {
  my ($colour) = @_;
  my $scale;
  # ENHANCE-ME: Or demand Color::Library always, or
  # X11::Protocol::Other::hexstr_to_rgb()
  if ($colour =~ /^#([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})$/i) {
    $scale = 255;
  } elsif ($colour =~ /^#([0-9A-F]{4})([0-9A-F]{4})([0-9A-F]{4})$/i) {
    $scale = 65535;
  } elsif (eval { require Color::Library }
           && (my $c = Color::Library->color($colour))) {
    return map {$_/255} $c->rgb;
  } else {
    return;  # unrecognised colour
  }
  return (hex($1)/$scale, hex($2)/$scale, hex($3)/$scale);
}

# $factor=0 background, through $factor=1 foreground
sub colour_grey {
  my ($self, $factor) = @_;
  return $self->colour_heat($factor);

  # my @foreground = colour_to_rgb($self->{'foreground'});
  # my @background = colour_to_rgb($self->{'background'});
  # if (! @foreground) { @foreground = (1.0, 1.0, 1.0); }
  # if (! @background) { @background = (0, 0, 0); }
  # my $bg_factor = 1 - $factor;
  # return rgb1_to_rgbstr (map {
  #   ($foreground[$_]*$factor + $background[$_]*$bg_factor)
  # } 0,1,2);
}
# x=0 blue through x=1 red
sub colour_heat {
  my ($self, $x) = @_;
  ### colour_heat: $x
  return rgb1_to_rgbstr (map { ($x < $_        ? 0
                                : $x < $_+.25  ? 4*($x-$_)
                                : $x < $_+.5   ? 1
                                : $x < $_+.75  ? 4*($_+.75 - $x)
                                : 0)
                             } .375, .125, -.125);
}
sub rgb1_to_rgbstr {
  # my ($r,$g,$b) = @_;
  # return sprintf("#%04X%04X%04X",
  #                map { max (0, min (0xFFFF, int (0.5 + 0xFFFF * $_))) }
  #                @_);

  return sprintf("#%02X%02X%02X",
                 map { max (0, min (0xFF, int (0.5 + 0xFF * $_))) }
                 @_);
}

# # seven colours
# sub colours_rainbow {
#   my ($self) = @_;
#   # ROYGBIV
#   $self->{'colours'} = [ 'red', 'orange', 'yellow', 'green', 'blue', 'purple', 'violet' ];
#   ### colours: $self->{'colours'}
# }

# # ENHANCE-ME: two shades of each to make radix==6
# sub colours_rgb {
#   my ($self) = @_;
#   $self->{'colours'} = [ 'red', 'green', 'blue' ];
#   ### colours: $self->{'colours'}
# }

# # ($x,$y, $x,$y, ...) = $aff->untransform($x,$y, $x,$y, ...)
# sub untransform {
#   my $self = shift;
#   my @result;
#   my $det = $self->{m11}*$self->{m22} - $self->{m12}*$self->{m21};
#   while (@_) {
#     my $x = shift() - $self->{tx};
#     my $y = shift() - $self->{ty};
#     push @result,
#       ($self->{m22} * $x - $self->{m21} * $y) / $det,
#         ($self->{m11} * $y - $self->{m12} * $x) / $det;
#   }
#   return @result;
# }
#
# # $aff = $aff->invert
# sub invert {
#   my ($self) = @_;
#   my $det = $self->{m11}*$self->{m22} - $self->{m12}*$self->{m21};
#   return $self->set_matrix_2x3
#     ($self->{m22} / $det,     # 11
#      - $self->{m12} / $det,   # 12
#      - $self->{m21} / $det,   # 21
#      $self->{m11} / $det,     # 22
#      $self->App::MathImage::Generator::untransform(0,0));
#
#   # tx,ty as full expressions instead of untransform(), if preferred
#   # ($self->{m21} * $self->{ty} - $self->{m22} * $self->{tx}) / $det,
#   # ($self->{m12} * $self->{tx} - $self->{m11} * $self->{ty}) / $det);
# }

my %figure_is_circular = (circle   => 1,
                          ring     => 1,
                          point    => 1,
                          diamond  => 1,
                          plus     => 1,
                          plus_fat => 1,
                         );
my %figure_fill = (square      => 1,
                   circle      => 1,
                   diamond     => 1,
                   unellipse   => 1,
                   hexagon     => 1,
                   hexagon_h   => 1,
                   octagon     => 1,
                   plus_fat    => 1,
                   toothpick_E => 1,
                   toothpick_L => 1,
                   toothpick_V => 1,
                   toothpick_Y => 1,
                  );
my %figure_image_method
  = (square      => 'rectangle',
     box         => 'rectangle',
     circle      => 'ellipse',
     ring        => 'ellipse',
     diamond     => 'diamond',
     diamunf     => 'diamond',
     diamstar    => \&_diamstar,
     plus        => \&App::MathImage::Image::Base::Other::plus,
     plus_fat    => \&App::MathImage::Image::Base::Other::plus_fat,
     X           => \&App::MathImage::Image::Base::Other::draw_X,
     L           => \&App::MathImage::Image::Base::Other::draw_L,
     V           => \&App::MathImage::Image::Base::Other::draw_V,
     Z           => \&App::MathImage::Image::Base::Other::draw_Z,
     N           => \&App::MathImage::Image::Base::Other::draw_N,
     '/'         => \&App::MathImage::Image::Base::Other::draw_slash,
     '\\'        => \&App::MathImage::Image::Base::Other::draw_backslash,
     hash        => \&App::MathImage::Image::Base::Other::draw_hash,
     unellipse   => \&App::MathImage::Image::Base::Other::unellipse,
     unellipunf  => \&App::MathImage::Image::Base::Other::unellipse,
     undiamond   => \&undiamond,
     triangle    => \&_triangle,
     hexagon     => \&_hexagon_vertical,
     hexunf      => \&_hexagon_vertical,
     hexstar     => \&_hexstar_vertical,
     hexagon_h   => \&_hexagon_horizontal,
     hexunf_h    => \&_hexagon_horizontal,
     hexstar_h   => \&_hexstar_horizontal,
     octagon     => \&_octagon,
     octunf      => \&_octagon,
     octstar     => \&_octstar,
     toothpick_E => 'ellipse',
     toothpick_L => 'ellipse',
     toothpick_V => 'ellipse',
     toothpick_Y => 'ellipse',
    );

my $colours_text_plus_or_minus = [ '-', ' ', '+' ];
my $colours_text = [ 0 .. 9, 'A'..'Z', 'a'..'z' ];

sub draw_Image_start {
  my ($self, $image) = @_;
  ### draw_Image_start()...
  ### values: $self->{'values'}

  $self->{'image'} = $image;
  my $width  = $self->{'width'}  = $image->get('-width');
  my $height = $self->{'height'} = $image->get('-height');
  my $scale = $self->{'scale'};
  ### $width
  ### $height

  my $path_object = $self->path_object;
  my $foreground    = $self->{'foreground'};
  my $background    = $self->{'background'};
  my $undrawnground = $self->{'undrawnground'};
  my $figure = $self->figure;
  my $covers = $self->covers_quadrants;
  my $affine = $self->affine_object;
  my @colours = ($foreground);
  my $values_seq = $self->values_seq;
  my $lines_type = $values_seq->{'lines_type'} || 'integer';
  ### $figure
  ### $undrawnground

  # clear undrawn quadrants
  {
    $image->add_colours ($background, $undrawnground);
    my @undrawn_rects;
    if ($covers) {
      $image->rectangle (0,0, $width-1,$height-1, $background, 1);
      if (defined (my $x_minimum = $path_object->x_minimum)) {
        my ($wx, $wy) = $self->transform_xy($x_minimum-.51, 0);
        if ($wx > 0) {
          push @undrawn_rects, 0,0, $wx-1,$height-1;
        }
      }
      if (defined (my $x_maximum = $path_object->x_maximum)) {
        my ($wx, $wy) = $self->transform_xy($x_maximum-.51, 0);
        if ($wx < $width) {
          push @undrawn_rects, $wx+1,0, $width-1,$height-1;
        }
      }
      if (defined (my $y_minimum = $path_object->y_minimum)) {
        my ($wx, $wy) = $self->transform_xy(0, $y_minimum-.51);
        if ($wy < $height) {
          push @undrawn_rects, 0,$wy+1, $width-1,$height-1;
        }
      }
      if (defined (my $y_maximum = $path_object->y_maximum)) {
        my ($wx, $wy) = $self->transform_xy(0, $y_maximum-.51);
        if ($wy > 0) {
          push @undrawn_rects, 0,0, $width-1,$wy-1;
        }
      }

      #    
      #                            sum
      #    /\                       /\
      #   /  \                     *  \
      #  /    \                   /    \
      #  \    /                   \    /
      #   \  *  minimum            \  /  maximum
      #    \/                       \/
      #    
      if (defined (my $diffxy_minimum = $path_object->diffxy_minimum)) {
        my ($wx, $wy) = $self->transform_xy($diffxy_minimum-.51, .51);
        my $size = 2*max($width,$height);
        my $sum = $wx + $wy - 1;
        if ($sum > 0) {
          $image->diamond (-$sum,-$sum, $sum,$sum, $undrawnground, 1);
        }
      }
      if (defined (my $diffxy_maximum = $path_object->diffxy_maximum)) {
        my ($wx, $wy) = $self->transform_xy($diffxy_maximum+.51, -.51);
        my $sum = $wx + $wy + 1;
        my $extra = max($width,$height) - $sum;
        ### diffxy_maximum: "diffxy=$diffxy_maximum is wx=$wx wy=$wy sum=$sum"
        if ($sum < $width+$height) {
          $image->diamond (-$extra,-$extra, 2*$sum+3*$extra,2*$sum+3*$extra, $undrawnground, 1);
        }
      }

      #    diff
      #    /\                     /\
      #   /  *                   /  \
      #  /    \                 /    \
      #  \    /                 \    /
      #   \  /  minimum          *  /  maximum
      #    \/                     \/
      if (defined (my $sumxy_minimum = $path_object->sumxy_minimum)) {
        my ($wx, $wy) = $self->transform_xy($sumxy_minimum-.51, -.51);
        my $diff = $wx - $wy - 1;
        my $size = 2*max($width,$height);
        my $extra = $diff;
        $image->diamond ($diff-$size-3*$extra,-$extra,
                         $diff+$size+$extra,2*$size+3*$extra,
                         $undrawnground, 1);
      }
      # if (defined (my $sumxy_maximum = $path_object->sumxy_maximum)) {
      #   my ($wx, $wy) = $self->transform_xy($sumxy_maximum+.51, .51);
      #   my $diff = $wx - $wy + 1;
      #   if ($diff > 0) {
      #     $image->diamond ($diff,$diff, $diff+$width,$diff+$height, $undrawnground, 1);
      #   }
      # }
    } else {
      push @undrawn_rects, 0,0, $width-1,$height-1;
    }
    # $image->add_colours ($background, (@undrawn_rects ? $undrawnground : ()));
    App::MathImage::Image::Base::Other::rectangles
        ($image, $undrawnground, 1, @undrawn_rects);
  }

  my ($n_lo, $n_hi);
  my $rectangle_area = 1;
  if ($self->{'values'} eq 'LinesLevel') {
    my $level = ($self->{'values_parameters'}->{'level'} ||= 2);
    ($n_lo,$n_hi) = $path_object->MathImage__level_n_range ($level);
    if (! defined $n_hi) {
      $n_lo = $path_object->n_start;
      $n_hi = $n_lo + $level*$level;
    }
    ### $level

    my $yfactor = 1;
    my $n_angle;
    my $xmargin = .05;
    if ($path_object->isa ('Math::PlanePath::Flowsnake')
        || $path_object->isa ('Math::PlanePath::FlowsnakeCentres')
        || $path_object->isa ('Math::PlanePath::GosperReplicate')) {
      $yfactor = sqrt(3);
      $n_angle = 6;
      foreach (2 .. $level) {
        $n_angle = (7 * $n_angle + 0);
      }

    } elsif ($path_object->isa ('Math::PlanePath::GosperIslands')) {
      # FIXME: x,y range ...
    } elsif ($path_object->isa ('Math::PlanePath::QuadricIslandsIslands')) {
      # FIXME: x,y range ...

    } elsif ($path_object->isa ('Math::PlanePath::KochCurve')) {
      $yfactor = sqrt(3)*2;
    } elsif ($path_object->isa ('Math::PlanePath::KochPeaks')) {
      # FIXME: x,y range
      $yfactor = sqrt(3)*2;
    } elsif ($path_object->isa ('Math::PlanePath::KochSnowflakes')) {
      # FIXME: x,y range
      $yfactor = sqrt(3)*2;
    } elsif ($path_object->isa ('Math::PlanePath::KochSquareflakes')) {
      # FIXME: x,y range
      $yfactor = sqrt(3)*2;
    } elsif ($path_object->isa ('Math::PlanePath::SierpinskiArrowhead')
             || $path_object->isa ('Math::PlanePath::SierpinskiArrowheadCentres')
             || $path_object->isa ('Math::PlanePath::SierpinskiTriangle')) {
      $n_angle = 2 * 3**($level-1);
      $yfactor = sqrt(3);
    } elsif ($path_object->isa ('Math::PlanePath::SierpinskiCurve')
             || $path_object->isa ('Math::PlanePath::SierpinskiCurveStair')) {
      $yfactor = 2;
    }
    $n_angle ||= $n_hi;

    ### $level
    ### $n_lo
    ### $n_hi
    ### $n_angle
    ### $yfactor

    $affine = Geometry::AffineTransform->new;
    $affine->scale (1, $yfactor);

    my ($xlo, $ylo) = $path_object->n_to_xy ($n_lo);
    my ($xang, $yang) = $path_object->n_to_xy ($n_angle);
    my $theta = - atan2 ($yang*$yfactor, $xang);
    my $r = hypot ($xlo-$xang,($ylo-$yang)*$yfactor) || 1;
    ### lo raw: "$xlo, $ylo"
    ### ang raw: "$xang, $yang"
    ### hi raw: $path_object->n_to_xy($n_hi)
    ### $theta
    ### $r

    ### origin: $self->{'width'} * .15, $self->{'height'} * .5
    $affine->rotate ($theta / 3.14159 * 180);
    my $rot = $affine->clone;
    $affine->scale ($self->{'width'} * (1-2*$xmargin) / $r,
                    - $self->{'width'} * .7 / $r * .3);
    $affine->translate ($self->{'width'} * $xmargin,
                        $self->{'height'} * .5);

    ### width: $self->{'width'}
    ### scale x: $self->{'width'} * (1-2*$xmargin) / $r
    ### transform lo: join(',',$affine->transform($xlo,$ylo))
    ### transform ang: join(',',$affine->transform($xang,$yang))

    # FIXME: wrong when rotated ... ??
    if (defined $self->{'x_left'}) {
      ### x_left: $self->{'x_left'}
      $affine->translate (- $self->{'x_left'} * $self->{'scale'},
                          0);
    }
    if (defined $self->{'y_bottom'}) {
      ### y_bottom: $self->{'y_bottom'}
      $affine->translate (0,
                          $self->{'y_bottom'} * $self->{'scale'});
    }

    my ($x,$y) = $path_object->n_to_xy ($n_lo);
    ### start raw: "$x, $y"
    ($x,$y) = $affine->transform ($x, $y);
    $x = floor ($x + 0.5);
    $y = floor ($y + 0.5);

    $self->{'xprev'} = $x;
    $self->{'yprev'} = $y;
    $self->{'affine_object'} = $affine;
    ### prev: "$x,$y"
    ### theta degrees: $theta*180/3.14159
    ### start: "$self->{'xprev'}, $self->{'yprev'}"

  } else {
    my $affine_inv = $affine->clone->invert;
    my ($x1, $y1) = $affine_inv->transform (-$scale, -$scale);
    my ($x2, $y2) = $affine_inv->transform ($self->{'width'} + $scale,
                                            $self->{'height'} + $scale);
    $rectangle_area = (abs($x2-$x1)+2) * (abs($y2-$y1)+2);
    ### limits around:
    ### $x1
    ### $x2
    ### $y1
    ### $y2

    ($n_lo, $n_hi) = $path_object->rect_to_n_range ($x1,$y1, $x2,$y2);
    # if ($n_hi > _SV_N_LIMIT) {
    #   ### n_hi: "$n_hi"
    #   ### bigint n range ...
    #   ($n_lo, $n_hi) = $path_object->rect_to_n_range (_bigint()->new(floor($x1)),$y1, $x2,$y2);
    # }
  }

  ### n_lo: "$n_lo"
  ### n_hi: "$n_hi"

  $self->{'n_list'} = [];
  $self->{'n_prev'} = $n_lo - 1;
  $self->{'upto_n'} = $n_lo;
  $self->{'n_hi'}   = $n_hi;
  $self->{'count_total'} = 0;
  $self->{'count_outside'} = 0;
  $self->{'figure_image_fill'} = $figure_fill{$figure};

  # dot at origin
  if ($scale >= 3 && $self->figure ne 'point') {
    my ($wx,$wy) = $self->transform_xy(0,0);
    if ($wx >= 0 && $wy >= 0 && $wx < $width && $wy < $height) {
      $image->xy ($wx, $wy, $foreground);
    }
  }

  {
    my $xpscale = $scale;
    my $ypscale = $scale;
    if ($figure =~ /toothpick/i) {
      # FIXME: Identify ToothpickTree and ToothpickReplicate lattice.
      if ($self->{'path'} =~ /^Toothpick/i) {
        $xpscale = $ypscale = $scale * 1.8;
      } else {
        $xpscale = $ypscale = $scale * .35;
      }
    } elsif ($self->{'values'} =~ /^Lines/) {
      # smaller figures for lines 'midpoint' and 'rounded'
      $xpscale = $ypscale = $scale * ($lines_type eq 'integer' ? .4
                                      : .2);
    } elsif ($figure eq 'arrow') {
      $xpscale *= .7;
      $ypscale *= .7;
    } elsif ($path_object->MathImage__lattice_type eq 'triangular'
             && ($figure eq 'diamond' || $figure eq 'diamunf')) {
      $xpscale *= 2;
      $ypscale *= 2;
    } elsif ($path_object->MathImage__lattice_type eq 'triangular'
             && $figure eq 'triangle') {
      $xpscale *= 2;
      $ypscale *= 1;
    } elsif ($path_object->MathImage__lattice_type eq 'triangular'
             && ($figure =~ /^hex/)) {
      $xpscale *= 2;
      unless ($figure =~ /h$/) {
        $ypscale *= 4/3;
      }
      unless ($self->{'figure_image_fill'}) {
        $xpscale *= .98;
        $ypscale *= .98;
      }
    } elsif ($path_object->MathImage__lattice_type eq 'triangular'
             && ($figure eq 'octagon' || $figure eq 'octunf')) {
      $xpscale *= sqrt(2);
      $ypscale *= sqrt(2);
      unless ($self->{'figure_image_fill'}) {
        $xpscale *= .98;
        $ypscale *= .98;
      }
    } elsif ($path_object->MathImage__lattice_type eq 'triangular'
             && $figure eq 'diamstar') {
      $xpscale *= 2;
      $ypscale *= 2;
    } elsif ($path_object->MathImage__lattice_type eq 'triangular'
             && $figure_is_circular{$figure}) {
      $xpscale *= sqrt(2);
      $ypscale *= sqrt(2);
    } elsif ($path_object->figure eq 'circle'
             && ! $figure_is_circular{$figure}) {
      $xpscale *= sqrt(1/2);
      $ypscale *= sqrt(1/2);
    }
    ### $xpscale
    ### $ypscale

    $xpscale = max (1, floor ($xpscale));
    $ypscale = max (1, floor ($ypscale));
    ### $xpscale
    ### $ypscale

    if ($xpscale == 1 && $ypscale == 1) {
      $figure = 'point';
    }

    #   +----+----+----+       scale=3  lo=int((3-2)/2)=1
    #   |    |    |    | -1
    #   +----+----+----+      +----+----+   scale=2
    #   |    |  x |    |      |    |    |
    #   +----+----+----+      +----+----+   xlo=int((2-1)/2)=1
    #   |    |    |    | +1   |  x |    |   ylo=int((2-1)/2)=0
    #   +----+----+----+      +----+----+

    $self->{'xscale_lo'} = int (($xpscale-1) / 2);
    $self->{'xscale_hi'} = $xpscale-1 - $self->{'xscale_lo'};

    $self->{'yscale_lo'} = int ($ypscale / 2);
    $self->{'yscale_hi'} = $ypscale-1 - $self->{'yscale_lo'};
  }

  {
    $self->{'figure_image_method'} ||= $figure_image_method{$figure};
    my $draw_figure_method = "draw_figure_$figure";
    $draw_figure_method =~ s{\+}{slash};
    $draw_figure_method =~ s{/}{slash};
    $draw_figure_method =~ s{\\}{backslash};
    $draw_figure_method = $self->can($draw_figure_method);
    if (! $draw_figure_method) {
      $draw_figure_method = 'draw_figure_using_image_method';
      $self->{'figure_image_method'}
        || croak 'Unrecognised figure: ',$figure;
    }
    $self->{'draw_figure_method'} = $draw_figure_method;
  }

  if ($self->{'values'} eq 'LinesTree') {
    $self->{'lines_figure_method'} = $self->{'draw_figure_method'};
    $self->{'draw_figure_method'} = 'draw_figure_linestree';
  }

  if ($self->{'values'} eq 'Lines') {
    ### $values_seq
    ### lines_type: $values_seq->{'lines_type'}
    ### midpoint_offset: $values_seq->{'midpoint_offset'}
    ### increment: $values_seq->{'increment'}

    $self->{'lines_figure_method'} = $self->{'draw_figure_method'};
    $self->{'draw_figure_method'} = 'draw_figure_lines';

    my $arms_count = $path_object->arms_count;

    my $midpoint_offset = 0;
    if ($lines_type eq 'integer') {
      $midpoint_offset = 0;
    } elsif ($lines_type eq 'midpoint') {
      $midpoint_offset = $values_seq->{'midpoint_offset'};
      if (! defined $midpoint_offset) { $midpoint_offset = 0.5; }
    } elsif ($lines_type eq 'rounded') {
      $midpoint_offset = $values_seq->{'midpoint_offset'};
      if (! defined $midpoint_offset) { $midpoint_offset = 0.5; }
      $midpoint_offset /= 2;
    }
    ### $midpoint_offset

    my @n_offset_list;
    my @n_figure_list;
    if ($lines_type eq 'rounded') {
      @n_offset_list = (-.5 - $arms_count + 1,
                        -$midpoint_offset - $arms_count + 1,
                        min($midpoint_offset,0.499),
                        .499);
      @n_figure_list = (0,1,1,0);
    } else {
      my $increment = $values_seq->{'increment'} || $arms_count;
      my $n_offset_from = -$increment;
      my $n_offset_to = $increment;

      # draw point n+midoff
      # discont start at n-disc
      # diff n+moff-(n-disc) = moff+disc, negative
      my $n_discontinuity = $path_object->n_frac_discontinuity;
      if ($increment == 1 && defined $n_discontinuity) {
        $n_offset_from = -($midpoint_offset+$n_discontinuity);
        if ($n_offset_from <= -1) {
          $n_offset_from++;
        }
        $n_offset_to = $n_offset_from + .9999;
      }
      ### $n_offset_from
      ### $n_offset_to

      if ($n_offset_from) {
        push @n_offset_list, $n_offset_from+$midpoint_offset;
        push @n_figure_list, 0+$midpoint_offset;
      }
      push @n_offset_list,
        $midpoint_offset,
          $n_offset_to+$midpoint_offset;
      push @n_figure_list, 1;
    }
    $self->{'n_offset_list'} = \@n_offset_list;
    $self->{'n_figure_list'} = \@n_figure_list;
    ### @n_offset_list
    ### @n_figure_list
  }

  my $filter = $self->{'filter'} || 'All';
  $self->{'filter_obj'} =
    $self->values_class($filter)->new;
  # (lo => $n_lo,
  #  hi => $n_hi);

  ### $rectangle_area
  ### $n_hi
  ### $n_lo

  my $i_estimate = $n_hi;
  if ($self->use_colours) {
    if ($values_seq->can('seek_to_value')) {
      $values_seq->seek_to_value($n_lo);
      $i_estimate -= $values_seq->tell_i;
      ### less tell_i(): $values_seq->tell_i
    }
  } else {
    if ($values_seq->can('value_to_i_estimate')) {
      $i_estimate = $values_seq->value_to_i_estimate($n_hi);
      ### value_to_i_estimate(): "n_hi=$n_hi  i_est=$i_estimate"
    }
    if ($values_seq->can('seek_to_value')) {
      $values_seq->seek_to_value($n_lo);
      $i_estimate -= $values_seq->tell_i;
      ### less tell_i(): $values_seq->tell_i
    }
  }
  ### $i_estimate

  if ($i_estimate > $rectangle_area * 4
      && $self->can_use_xy) {
    ### use_xy initially due to big i steps: $i_estimate
    $self->use_xy($image);
  }

  # ### force use_xy for testing ...
  # $self->use_xy($image);
}

sub use_colours {
  my ($self) = @_;
  if (exists $self->{'use_colours'}) {
    return $self->{'use_colours'};
  }

  ### use_colours() ...

  if ($self->{'values'} eq 'Lines') {

  } elsif ($self->{'values'} eq 'LinesTree') {

  } else {
    my $values_seq = $self->values_seq;

    my $values_min = $values_seq->values_min;
    my $values_max = $values_seq->values_max;
    my $is_count = $values_seq->characteristic('count');
    my $is_smaller = $values_seq->characteristic('smaller');

    ### $values_min
    ### $values_max
    ### characteristic(count): $is_count
    ### characteristic(smaller): $is_smaller

    if (defined $values_max && ! defined $values_min) {
      ($values_min,$values_max) = ($values_max,$values_min);
    }

    my $colours_base = $values_min || 0;
    if ($colours_base >= 1 && $values_seq->characteristic('integer')) {
      $colours_base -= 1;
    }

    my $colours_max = $self->{'colours_max'} = $values_max;
    my $image = $self->{'image'};

    if (defined $values_min
        && defined $values_max
        && $values_seq->characteristic('integer')
        && $values_max - $values_min == 1
       #  && $self->covers_quadrants
       ) {
      ### binary two values ...
      if ($image && $image->isa('Image::Base::Text')) {
        $self->{'colours_array'} = [ ' ', '*' ];
      } else {
        $self->{'colours_array'} = [ $self->{'background'},
                                     $self->{'foreground'} ];
      }
      $colours_base = $values_min;

    } elsif (defined $values_min
             && defined $values_max
             && $values_seq->characteristic('integer')
             && $values_max == 1 && $values_min == -1
             && $image && $image->isa('Image::Base::Text')) {
      # +/-1 in text
      $self->{'colours_array'} = $colours_text_plus_or_minus;

    } elsif (defined $values_min
             && defined $values_max
             && $values_seq->characteristic('integer')
             && $values_max == 1 && $values_min == -1) {
      # +/-1 in graphics
      $self->{'colours_array'} = [ _colour_average ($self->{'foreground'},
                                                    $self->{'background'},
                                                    0.5),
                                   $self->{'background'},
                                   $self->{'foreground'} ];

    } elsif (defined $image && $image->isa('Image::Base::Text')) {
      $self->{'colours_array'} = $colours_text;
    }

    if (defined $values_max) {
      unless (defined $is_smaller && ! $is_smaller) {
        $self->{'use_colours'} = 1;
      }
    }

    $self->{'colours_base'} = $colours_base;
    $self->{'colours_shrink'} = $self->colours_exp_shrink;
    $self->{'colours_shrink_log'} = log($self->{'colours_shrink'});

    # "count" doesn't really meant it's small ...
    if ($is_smaller || ($is_count && ! defined $is_smaller)) {
      $self->{'use_colours'} = 1;

      # if ($image->isa('Image::Base::Text')) {
      #   $self->{'colours'} = [ 0 .. 9 ];
      # } else {
      #   $self->colours_grey_exp ($self);
      # }
    }

    ### use_colours: $self->{'use_colours'}
    ### colours_base: $self->{'colours_base'}
    ### cf values_min: $values_seq->values_min
  }
  return $self->{'use_colours'};
}

sub transform_xy {
  my ($self, $x,$y) = @_;
  # BigInt no good for $affine->transform multiply
  if (ref $x) { $x = $x->numify; }
  if (ref $y) { $y = $y->numify; }
  my ($wx, $wy) = $self->{'affine_object'}->transform ($x, $y);
  return (floor ($wx + 0.5),
          floor ($wy + 0.5));
}

sub draw_figure_point {
  my ($self, $colour) = @_;
  $self->{'image'}->xy ($self->{'wx'},$self->{'wy'}, $colour);
}
sub draw_figure_square {
  my ($self, $colour) = @_;
  $self->{'image'}->rectangle ($self->{'wx'} - $self->{'xscale_lo'},
                               $self->{'wy'} - $self->{'yscale_lo'},
                               $self->{'wx'} + $self->{'xscale_hi'},
                               $self->{'wy'} + $self->{'yscale_hi'},
                               $colour,
                               1);  # fill
}
sub draw_figure_using_image_method {
  my ($self, $colour) = @_;
  my $figure_image_method = $self->{'figure_image_method'};
  $self->{'image'}->$figure_image_method ($self->{'wx'} - $self->{'xscale_lo'},
                                          $self->{'wy'} - $self->{'yscale_lo'},
                                          $self->{'wx'} + $self->{'xscale_hi'},
                                          $self->{'wy'} + $self->{'yscale_hi'},
                                          $colour,
                                          $self->{'figure_image_fill'});
}

sub draw_figure_slashEO {
  my ($self, $colour) = @_;
  my $coderef = (($self->{'x'}+$self->{'y'}) % 2
                 ? \&App::MathImage::Image::Base::Other::draw_backslash # odd
                 : \&App::MathImage::Image::Base::Other::draw_slash);   # even
  &$coderef($self->{'image'},
            $self->{'wx'} - $self->{'xscale_lo'},
            $self->{'wy'} - $self->{'yscale_lo'},
            $self->{'wx'} + $self->{'xscale_hi'},
            $self->{'wy'} + $self->{'yscale_hi'},
            $colour,
            $self->{'figure_image_fill'});
}
sub draw_figure_slashOE {
  my ($self, $colour) = @_;
  my $coderef = (($self->{'x'}+$self->{'y'}) % 2
                 ? \&App::MathImage::Image::Base::Other::draw_slash       # odd
                 : \&App::MathImage::Image::Base::Other::draw_backslash); # even
  &$coderef($self->{'image'},
            $self->{'wx'} - $self->{'xscale_lo'},
            $self->{'wy'} - $self->{'yscale_lo'},
            $self->{'wx'} + $self->{'xscale_hi'},
            $self->{'wy'} + $self->{'yscale_hi'},
            $colour,
            $self->{'figure_image_fill'});
}

sub draw_figure_toothpick {
  my ($self, $colour) = @_;

  if (($self->{'x'}+$self->{'y'}) % 2) {
    # horizontal
    $self->{'image'}->line ($self->{'wx'} - $self->{'xscale_lo'}, $self->{'wy'},
                            $self->{'wx'} + $self->{'xscale_hi'}, $self->{'wy'},
                            $colour);
  } else {
    # vertical
    $self->{'image'}->line ($self->{'wx'}, $self->{'wy'} - $self->{'yscale_lo'},
                            $self->{'wx'}, $self->{'wy'} + $self->{'yscale_hi'},
                            $colour);
  }
}
sub draw_figure_toothpick_E {
  my ($self, $colour) = @_;
  my $image = $self->{'image'};
  my $path_object = $self->{'path_object'};
  my $x = $self->{'x'};
  my $y = $self->{'y'};
  my $wx = $self->{'wx'};
  my $wy = $self->{'wy'};
  foreach my $n (@{$self->{'n_list'}}) {
    my $n_parent = $path_object->tree_n_parent($n);
    next if ! defined $n_parent;
    my ($px,$py) = $path_object->n_to_xy($n_parent);
    my $dx = ($x - $px);
    my $dy = ($y - $py);
    {
      my $dx = .8*$dx;
      my $dy = .8*$dy;
      $image->line ($wx,$wy,
                    $self->transform_xy($x+$dx, $y+$dy),
                    $colour);
    }
    {
      my ($dx,$dy) = (($dx+$dy)/2,
                      ($dy-3*$dx)/2);
      $dx = .8*$dx;
      $dy = .8*$dy;
      $image->line ($wx,$wy,
                    $self->transform_xy($x + $dx, $y + $dy),
                    $colour);
    }
    {
      my ($dx,$dy) = (($dx-$dy)/2,
                      ($dy+3*$dx)/2);
      $dx = .8*$dx;
      $dy = .8*$dy;
      $image->line ($wx,$wy,
                    $self->transform_xy($x + $dx, $y + $dy),
                    $colour);
    }
  }


  if (my $n_to_level = $path_object->{'n_to_level'}) {
    if (my $level = $n_to_level->[$self->{'n'}]) {
      if ($level == 0) {
        $colour = 'green';
      }
      if ($level == 7) {
        $colour = 'red';
      }
    }
  }
  $self->draw_figure_using_image_method($colour);
}
sub draw_figure_toothpick_L {
  my ($self, $colour) = @_;
  my $image = $self->{'image'};
  my $path_object = $self->{'path_object'};
  my $x = $self->{'x'};
  my $y = $self->{'y'};
  my $wx = $self->{'wx'};
  my $wy = $self->{'wy'};
  foreach my $n (@{$self->{'n_list'}}) {
    my $n_parent = $path_object->tree_n_parent($n);
    next if ! defined $n_parent;
    my ($px,$py) = $path_object->n_to_xy($n_parent);
    my $dx = ($x - $px);
    my $dy = ($y - $py);
    {
      my ($dx,$dy) = ($dx+$dy, $dy-$dx);
      if (($dx % 2) == 0) { $dx /= 2; }
      if (($dy % 2) == 0) { $dy /= 2; }
      $dx = .6*$dx;
      $dy = .6*$dy;
      $image->line ($wx,$wy,
                    $self->transform_xy($x + $dx, $y + $dy),
                    $colour);
    }
    {
      my ($dx,$dy) = ($dx-$dy, $dy+$dx);
      if (($dx % 2) == 0) { $dx /= 2; }
      if (($dy % 2) == 0) { $dy /= 2; }
      $dx = .6*$dx;
      $dy = .6*$dy;
      $image->line ($wx,$wy,
                    $self->transform_xy($x + $dx, $y + $dy),
                    $colour);
    }
  }

  $self->draw_figure_using_image_method($colour);
}
sub draw_figure_toothpick_V {
  my ($self, $colour) = @_;
  my $image = $self->{'image'};
  my $path_object = $self->{'path_object'};
  my $x = $self->{'x'};
  my $y = $self->{'y'};
  my $wx = $self->{'wx'};
  my $wy = $self->{'wy'};
  foreach my $n (@{$self->{'n_list'}}) {
    my $n_parent = $path_object->tree_n_parent($n);
    next if ! defined $n_parent;
    my ($px,$py) = $path_object->n_to_xy($n_parent);
    my $dx = ($x - $px);
    my $dy = ($y - $py);
    {
      my ($dx,$dy) = (($dx+$dy)/2,
                      ($dy-3*$dx)/2);
      $dx = .8*$dx;
      $dy = .8*$dy;
      $image->line ($wx,$wy,
                    $self->transform_xy($x + $dx, $y + $dy),
                    $colour);
    }
    {
      my ($dx,$dy) = (($dx-$dy)/2,
                      ($dy+3*$dx)/2);
      $dx = .8*$dx;
      $dy = .8*$dy;
      $image->line ($wx,$wy,
                    $self->transform_xy($x + $dx, $y + $dy),
                    $colour);
    }
  }
  $self->draw_figure_using_image_method('red'); # $colour
}
sub draw_figure_toothpick_Y {
  my ($self, $colour) = @_;
  my $image = $self->{'image'};
  my $path_object = $self->{'path_object'};
  my $x = $self->{'x'};
  my $y = $self->{'y'};
  my $wx = $self->{'wx'};
  my $wy = $self->{'wy'};
  foreach my $n (@{$self->{'n_list'}}) {
    my $n_parent = $path_object->tree_n_parent($n);
    next if ! defined $n_parent;
    my ($px,$py) = $path_object->n_to_xy($n_parent);
    my $dx = ($x - $px);
    my $dy = ($y - $py);
    {
      my $dx = .8*$dx;
      my $dy = .8*$dy;
      $image->line ($wx,$wy,
                    $self->transform_xy($x+$dx, $y+$dy),
                    $colour);
    }
    {
      my ($dx,$dy) = (($dy-$dx)/2,
                      -($dy+3*$dx)/2);
      $dx = .8*$dx;
      $dy = .8*$dy;
      $image->line ($wx,$wy,
                    $self->transform_xy($x + $dx, $y + $dy),
                    $colour);
    }
    {
      my ($dx,$dy) = (($dx+$dy)/-2,
                      (3*$dx-$dy)/2);
      $dx = .8*$dx;
      $dy = .8*$dy;
      $image->line ($wx,$wy,
                    $self->transform_xy($x + $dx, $y + $dy),
                    $colour);
    }
  }
  if ($self->{'n'} > 37) {
    $self->draw_figure_using_image_method('green'); # $colour
  } else {
    $self->draw_figure_using_image_method('red'); # $colour
  }
}
sub draw_figure_arrow {
  my ($self, $colour) = @_;
  my $wx = $self->{'wx'};
  my $wy = $self->{'wy'};
  my $image = $self->{'image'};
  my $path_object = $self->{'path_object'};

  my $x = $self->{'x'};
  my $y = $self->{'y'};
  if (ref $x) { $x = $x->numify; }
  if (ref $y) { $y = $y->numify; }

  my $frac = ($self->{'values'} eq 'LinesTree' ? 0.6
              : 0.6);

  foreach my $n (@{$self->{'n_list'}}) {
    mapp {
      my $dx = $a;
      my $dy = $b;
      ### dxdy: "$dx,$dy"

      if (ref $dx) { $dx = $dx->numify; }
      if (ref $dy) { $dy = $dy->numify; }
      my $h = hypot($dx,$dy);
      if ($h) {
        if ($frac) {
          my $f = $frac / $h;
          $dx *= $f;
          $dy *= $f;
          ### scaled dxdy: "$dx,$dy"
        }
        ### draw line(): $wx,$wy, $self->transform_xy($x+$dx, $y+$dy),
        _image_arrow ($image,
                      $wx,$wy,
                      $self->transform_xy($x+$dx, $y+$dy),
                      $colour);
      } else {
        $image->xy ($self->{'wx'},$self->{'wy'}, $colour);
      }
    }
      ($self->{'values'} eq 'LinesTree'
       ? (map {my ($cx,$cy) = $path_object->n_to_xy($_); ($cx-$x, $cy-$y)}
          $path_object->tree_n_children($n))
       : $path_object->n_to_dxdy($n));
  }
}
# rotate +45  X-Y,X+Y
# rotate -45  X+Y,X-Y
sub _image_arrow {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  ### _image_arrow(): "$x1,$y1 to $x2,$y2"
  $image->line ($x1,$y1, $x2,$y2, $colour);
  my $dx = ($x2-$x1)/3;
  my $dy = ($y2-$y1)/3;
  my $sum = int($dx+$dy);
  my $diff = int($dx-$dy);
  if ($sum || $diff) {
    $image->line ($x2-$diff,$y2-$sum,  $x2,$y2, $colour);
    $image->line ($x2-$sum, $y2+$diff, $x2,$y2, $colour);
  }
}

sub draw_figure_lines {
  my ($self, $colour) = @_;
  ### draw_figure_lines() ...

  my $orig_wx = $self->{'wx'};
  my $orig_wy = $self->{'wy'};
  my $path_object = $self->{'path_object'};

  my $lines_figure_method = $self->{'lines_figure_method'};
  my $image = $self->{'image'};
  my $n_offset_list = $self->{'n_offset_list'};
  my $n_figure_list = $self->{'n_figure_list'};

  foreach my $n (@{$self->{'n_list'}}) {
    ### $n
    my ($wx,$wy);
    foreach my $i (0 .. $#$n_offset_list) {
      ### n with offset: $n+$n_offset_list->[$i]
      my ($x2, $y2) = $path_object->n_to_xy($n+$n_offset_list->[$i]);
      my ($wx2, $wy2);

      if (defined $x2) {
        $self->{'x'} = $x2;
        $self->{'y'} = $y2;

        ($wx2, $wy2) = $self->transform_xy($x2, $y2);
        ### frag: "to x2,y2 = $x2,$y2"
        ### affined to x2,y2: "$wx2, $wy2"

        if ($n_figure_list->[$i]) {
          $self->{'x'} = $x2;
          $self->{'y'} = $y2;
          $self->{'wx'} = $wx2;
          $self->{'wy'} = $wy2;
          $self->$lines_figure_method($colour);
        }

        if (defined $wx) {
          # next if ($wy2 <= $wy) ^ ($wx2 <= $wx);  # no backslope lines

          my $drawn = _image_line_clipped ($image, $wx,$wy, $wx2,$wy2,
                                           $self->{'width'},$self->{'height'},
                                           $colour);
          # $count_total++;
          # $count_outside += !$drawn;
          # $count_figures += $drawn;
        }
      }
      $wx = $wx2;
      $wy = $wy2;
    }
  }
}

sub draw_figure_linestree {
  my ($self, $colour) = @_;
  ### draw_figure_linestree(): "$colour N=".join(',',@{$self->{'n_list'}})

  my $path_object = $self->{'path_object'};
  ### path_object: "$path_object"
  my $x = $self->{'x'};
  my $y = $self->{'y'};
  if (ref $x) { $x = $x->numify; }
  if (ref $y) { $y = $y->numify; }

  my @n_children;
  foreach my $n (@{$self->{'n_list'}}) {
    if (my $branches = $self->{'branches'}) {
      push @n_children,
        tree_n_children_for_branches ($path_object, $n, $branches);
    } else {
      my @this_n_children;
      @this_n_children = $path_object->tree_n_children($n);
      ### this_n_children: "n=$n children=".join(',',@this_n_children) 
      # or @this_n_children = $path_object->MathImage__tree_n_children($n);
      push @n_children, @this_n_children;
    }
  }
  ### @n_children

  my $wx = $self->{'wx'};
  my $wy = $self->{'wy'};
  my $image = $self->{'image'};

  # draw line to each of @n_children
  foreach my $n_dest (@n_children) {
    my ($x_dest, $y_dest) = $path_object->n_to_xy ($n_dest)
      or next;
    my $drawn = _image_line_clipped ($image,
                                     $wx,$wy,
                                     $self->transform_xy ($x_dest, $y_dest),
                                     $self->{'width'},$self->{'height'},
                                     $colour);
    # $count_figures++;
    # $count_total++;
    # $count_outside += !$drawn;
  }

  # if ($self->{'n'} == 0) {
  #   $colour = 'lightgreen';
  # }
  # if (my $depth = $self->{'path_object'}->tree_n_to_depth($self->{'n'})) {
  #   if ($depth == 8) {
  #     $colour = 'red';
  #   }
  # }

  my $lines_figure_method = $self->{'lines_figure_method'};
  $self->$lines_figure_method($colour);
}

sub undiamond {
  my ($image, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  my $width = $x2 - $x1 + 1;
  my $height = $y2 - $y1 + 1;
  my $halfheight = int($height/2);
  my $xoff = int($width/2);
  for (my $yoff = 0; $yoff <= $halfheight; $yoff++) {
    foreach my $y ($y1 + $yoff, $y2-$yoff) {
      $image->line ($x1,$y,       $x1+$xoff,$y, $colour);
      $image->line ($x2-$xoff,$y, $x2,$y,       $colour);
    }
    $xoff--;
  }
}

sub _triangle {
  my ($image, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  my $xc = int (($x1+$x2)/2);  # top centre
  $image->line ($xc,$y1, $x1,$y2, $colour);
  $image->line ($xc,$y1, $x2,$y2, $colour);
  $image->line ($x1,$y2, $x2,$y2, $colour);
}
# sub _triangle {
#   my ($image, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
#   triangle ($image,
#             int (($x1+$x2)/2), $y1,   # top vertex
#             $x1,$y2,
#             $x2,$y2,
#             $colour,
#             $fill);
# }

#    +----+      --+
#   /      \       | sqrt(1/2) so diagonal length 1
#  /        \      |
# +          +   --+
# |          |     |
# |          |     | 1
# |          |     |
# +          +   --+
#  \        /
#   \      /
#    +----+
# total 2*sqrt(1/2)+1 = sqrt(2)+1
# 1/(sqrt(2)+1) = sqrt(2)-1
# straight sqrt(2)-1
# angle sqrt(1/2)*(sqrt(2)-1)
#     = sqrt(1/2)*sqrt(2)-sqrt(1/2)
#     = 1-sqrt(1/2) = 0.2928
#
sub _octagon {
  my ($image, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### _octagon: "$x1,$y1, $x2,$y2, $colour"

  my $w = $x2 - $x1;
  my $h = $y2 - $y1;
  if ($w < 2 || $h < 2) {
    $image->rectangle ($x1,$y1, $x2,$y2, $colour, 1);
    return;
  }

  if ($fill) {
    $w = int ($w / 4);
    $h = int ($h / 4);

    my $x = $w;  # middle
    my $y = 0;   # top

    my $draw;
    if ($fill) {
      $draw = sub {
        ### draw across: "$x,$y"
        $image->line ($x1+$x,$y1+$y, $x2-$x,$y1+$y, $colour); # upper
        $image->line ($x1+$x,$y2-$y, $x2-$x,$y2-$y, $colour); # lower
      };
    } else {
      $draw = sub {
        ### draw: "$x,$y"
        $image->xy ($x1+$x,$y1+$y, $colour); # upper left
        $image->xy ($x2-$x,$y1+$y, $colour); # upper right

        $image->xy ($x1+$x,$y2-$y, $colour); # lower left
        $image->xy ($x2-$x,$y2-$y, $colour); # lower right
      };
    }

    if ($w > $h) {
      ### shallow ...

      my $rem = int($w/2) - $w;
      ### $rem

      while ($x > 0) {
        ### at: "x=$x  rem=$rem"

        if (($rem += $h) >= 0) {
          &$draw();
          $y++;
          $rem -= $w;
          $x--;
        } else {
          if (! $fill) { &$draw() }
          $x--;
        }
      }

    } else {
      ### steep ...

      # when $h is odd bias towards pointier at the narrower top/bottom ends
      my $rem = int(($h-1)/2) - $h;
      ### $rem

      while ($y < $h) {
        ### $rem
        &$draw();

        if (($rem += $w) >= 0) {
          $rem -= $h;
          $x--;
          ### x inc to: "x=$x  rem $rem"
        }
        $y++;
      }
    }

    ### final: "$x,$y"

    # middle rectangle
    if ($fill) {
      $image->rectangle ($x1,$y1+$h, $x2,$y2-$h, $colour, 1);
    }

  } else {
    my $yc = int (($y1+$y2)/2);  # side centre
    my $xoffset = int(($x2-$x1+1) * (1-sqrt(1/2)));
    my $yoffset = int(($y2-$y1+1) * (1-sqrt(1/2)));

    my @x = ($x2-$xoffset,
             $x2,
             $x2,
             $x2-$xoffset,
             $x1+$xoffset,
             $x1,
             $x1,
             $x1+$xoffset);
    my @y = ($y1,
             $y1+$yoffset,
             $y2-$yoffset,
             $y2,
             $y2,
             $y2-$yoffset,
             $y1+$yoffset,
             $y1);
    my $x = $x[-1];
    my $y = $y[-1];
    while (@x) {
      my $x2 = shift @x;
      my $y2 = shift @y;
      $image->line ($x,$y, $x2,$y2, $colour);
      $x = $x2;
      $y = $y2;
    }
  }
}


sub _hexstar_vertical {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  {
    my $hq = int(($y2 - $y1 + 1)/4);
    $image->line ($x1,$y1+$hq, $x2,$y2-$hq, $colour); # diagonal
    $image->line ($x2,$y1+$hq, $x1,$y2-$hq, $colour); # diagonal
  }
  {
    my $xc = int(($x1 + $x2)/2);
    my $yc = int(($y1 + $y2)/2);
    $image->line ($xc,$y1, $xc,$y2, $colour); # vertical
  }
}

#  .5    1    .5
#     +-----+
#    /      /\
#   /      /  \
#  /      /    \
# +      *------+
#  \           /
#   \         /
#    \       /
#     +-----+
sub _hexstar_horizontal {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  {
    my $wq = int(($x2 - $x1 + 1)/4);
    $image->line ($x1+$wq,$y1, $x2-$wq,$y2, $colour); # diagonal
    $image->line ($x2-$wq,$y1, $x1+$wq,$y2, $colour); # diagonal
  }
  {
    my $xc = int(($x1 + $x2)/2);
    my $yc = int(($y1 + $y2)/2);
    $image->line ($x1,$yc, $x2,$yc, $colour); # horizontal
  }
}

sub _octstar {
  my ($image, $x1,$y1, $x2,$y2, $colour, $fill) = @_;

  $image->line ($x1,$y1, $x2,$y2, $colour); # diagonal
  $image->line ($x2,$y1, $x1,$y2, $colour); # diagonal

  my $xc = int(($x1 + $x2)/2);
  my $yc = int(($y1 + $y2)/2);
  $image->line ($x1,$yc, $x2,$yc, $colour); # horizontal
  $image->line ($xc,$y1, $xc,$y2, $colour); # vertical
}
sub _diamstar {
  my ($image, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  {
    my $wq = int(($x2 - $x1 + 1)/4);
    my $hq = int(($y2 - $y1 + 1)/4);
    $image->line ($x1+$wq,$y1+$hq, $x2-$wq,$y2-$hq, $colour); # diagonal
    $image->line ($x2-$wq,$y1+$hq, $x1+$wq,$y2-$hq, $colour); # diagonal
  }
  {
    my $xc = int(($x1 + $x2)/2);
    my $yc = int(($y1 + $y2)/2);
    $image->line ($x1,$yc, $x2,$yc, $colour); # horizontal
    $image->line ($xc,$y1, $xc,$y2, $colour); # vertical
  }
}


#  .5   1    .5
#     +----+
#    /|    |\
#   / |    | \
#  +  |    |  +
#   \ |    | /
#    \|    |/
#     +----+
# height 2*sqrt(3/4) = sqrt(3)

#
sub _hexagon_horizontal {
  my ($image, $x1,$y1, $x2,$y2, $colour, $fill) = @_;

  my $w = $x2 - $x1;
  my $h = $y2 - $y1;
  if ($w < 2 || $h < 2) {
    $image->rectangle ($x1,$y1, $x2,$y2, $colour, 1);
    return;
  }

  my $xoffset = int(($x2-$x1+1) * .25);
  my $yc = int (($y1+$y2)/2);  # side centre
  my $yc_ceil = int (($y1+$y2+1)/2);  # side centre
  ### $xoffset

  if ($fill) {
    $w = int ($w / 4);
    $h = int ($h / 2);

    my $x = $w;  # middle
    my $y = 0;   # top

    my $draw;
    if ($fill) {
      $draw = sub {
        ### draw across: "$x,$y"
        $image->line ($x1+$x,$y1+$y, $x2-$x,$y1+$y, $colour); # upper
        $image->line ($x1+$x,$y2-$y, $x2-$x,$y2-$y, $colour); # lower
      };
    } else {
      $draw = sub {
        ### draw: "$x,$y"
        $image->xy ($x1+$x,$y1+$y, $colour); # upper left
        $image->xy ($x2-$x,$y1+$y, $colour); # upper right

        $image->xy ($x1+$x,$y2-$y, $colour); # lower left
        $image->xy ($x2-$x,$y2-$y, $colour); # lower right
      };
    }

    if ($w > $h) {
      ### shallow ...

      my $rem = int($w/2) - $w;
      ### $rem

      while ($x > 0) {
        ### at: "x=$x  rem=$rem"

        if (($rem += $h) >= 0) {
          &$draw();
          $y++;
          $rem -= $w;
          $x--;
        } else {
          if (! $fill) { &$draw() }
          $x--;
        }
      }

    } else {
      ### steep ...

      # when $h is odd bias towards pointier at the narrower top/bottom ends
      my $rem = int(($h-1)/2) - $h;
      ### $rem

      while ($y < $h) {
        ### $rem
        &$draw();

        if (($rem += $w) >= 0) {
          $rem -= $h;
          $x--;
          ### x inc to: "x=$x  rem $rem"
        }
        $y++;
      }
    }


    ### final: "$x,$y"

    # middle rectangle
    if ($fill) {
      $image->rectangle ($x1,$y1+$h, $x2,$y2-$h, $colour, 1);
    }

  } else {
    $image->line ($x1,$yc, $x1+$xoffset,$y1, $colour);
    $image->line ($x1,$yc_ceil, $x1+$xoffset,$y2, $colour);

    $image->line ($x1+$xoffset,$y1, $x2-$xoffset,$y1, $colour);
    $image->line ($x1+$xoffset,$y2, $x2-$xoffset,$y2, $colour);

    $image->line ($x2-$xoffset,$y1, $x2,$yc, $colour);
    $image->line ($x2-$xoffset,$y2, $x2,$yc_ceil, $colour);
  }
}

#    +      --+
#   / \       | cos(Pi/3) = 1/2
#  /   \      |
# +     +   --+
# |     |     | 1
# |     |     |
# +     +   --+
#  \   /
#   \ /
#    +
# total 2
#
sub _hexagon_vertical {
  my ($image, $x1,$y1, $x2,$y2, $colour, $fill) = @_;

  ### assert: $x2 >= $x1
  ### assert: $y2 >= $y1

  my $w = $x2 - $x1;
  my $h = $y2 - $y1;
  if ($w < 2 || $h < 2) {
    $image->rectangle ($x1,$y1, $x2,$y2, $colour, 1);
    return;
  }

  if ($fill) {
    $w = int ($w / 2);
    $h = int ($h / 4);

    my $x = $w;  # middle
    my $y = 0;   # top

    ### $w
    ### $h
    ### x1+x: $x1+$w
    ### x2-x: $x2-$w
    ### y1+y: $y1+$h
    ### y2-y: $y2-$h


    my $draw;
    if ($fill) {
      $draw = sub {
        ### draw across: "$x,$y"
        $image->line ($x1+$x,$y1+$y, $x2-$x,$y1+$y, $colour); # upper
        $image->line ($x1+$x,$y2-$y, $x2-$x,$y2-$y, $colour); # lower
      };
    } else {
      $draw = sub {
        ### draw: "$x,$y"
        $image->xy ($x1+$x,$y1+$y, $colour); # upper left
        $image->xy ($x2-$x,$y1+$y, $colour); # upper right

        $image->xy ($x1+$x,$y2-$y, $colour); # lower left
        $image->xy ($x2-$x,$y2-$y, $colour); # lower right
      };
    }

    if ($w > $h) {
      ### shallow ...

      my $rem = int($w/2) - $w;
      ### $rem

      while ($x > 0) {
        ### at: "x=$x  rem=$rem"

        if (($rem += $h) >= 0) {
          &$draw();
          $y++;
          $rem -= $w;
          $x--;
        } else {
          if (! $fill) { &$draw() }
          $x--;
        }
      }

    } else {
      ### steep ...

      # when $h is odd bias towards pointier at the narrower top/bottom ends
      my $rem = int(($h-1)/2) - $h;
      ### $rem

      while ($y < $h) {
        ### $rem
        &$draw();

        if (($rem += $w) >= 0) {
          $rem -= $h;
          $x--;
          ### x inc to: "x=$x  rem $rem"
        }
        $y++;
      }
    }


    ### final: "$x,$y"

    # middle rectangle
    if ($fill) {
      $image->rectangle ($x1,$y1+$h, $x2,$y2-$h, $colour, 1);
    }

  } else {
    # unfilled
    my $xc = int (($x1+$x2)/2);  # side centre
    my $xc_ceil = int (($x1+$x2+1)/2);  # side centre
    my $yoffset = int(($y2-$y1+1) * .25);

    $image->line ($xc,$y1, $x1,$y1+$yoffset, $colour);         # top left
    $image->line ($xc_ceil,$y1, $x2,$y1+$yoffset, $colour);    # top right

    $image->line ($x1,$y1+$yoffset, $x1,$y2-$yoffset, $colour); # left
    $image->line ($x2,$y1+$yoffset, $x2,$y2-$yoffset, $colour); # right

    $image->line ($x1,$y2-$yoffset, $xc,$y2, $colour);
    $image->line ($x2,$y2-$yoffset, $xc_ceil,$y2, $colour);
  }
}

sub draw_Image_steps {
  my ($self) = @_;
  #### draw_Image_steps() ...
  my $steps = 0;
  
  my $path_object = $self->path_object;
  my $step_figures = $self->{'step_figures'} || 2;
  my $step_time = $self->{'step_time'};
  my $count_figures = 0;
  my ($time_lo, $time_hi);
  my $more = 0;
  ### $step_figures
  ### $step_time

  my $cont = sub {
    if (defined $step_figures) {
      if ($count_figures >= $step_figures) {
        $more = 1;
        return 0; # don't continue
      }
    }
    if (defined $step_time) {
      if (defined $time_lo) {
        my $time = _gettime();
        if ($time < $time_lo  # oops, time gone backwards
            || $time > $time_hi) {
          $more = 1;
          return 0; # don't continue
        }
      } else {
        $time_lo = _gettime();
        $time_hi = $time_lo + $step_time;
        # at least one iteration no matter how long the initializers take
      }
    }
    return 1; # continue
  };
  
  my $image  = $self->{'image'};
  my $width  = $self->{'width'};
  my $height = $self->{'height'};
  my $foreground = $self->{'foreground'};
  my $background = $self->{'background'};
  my $undrawnground = $self->{'undrawnground'};
  my $scale = $self->{'scale'};
  ### $scale
  
  my $covers = $self->covers_quadrants;
  my $affine = $self->affine_object;
  my $values_seq = $self->values_seq;
  my $filter_obj = $self->{'filter_obj'};
  my $draw_figure_method = $self->{'draw_figure_method'};
  my $n_list = $self->{'n_list'};
  
  my $lines_type = $values_seq->{'lines_type'} || 'integer';
  my $figure = $self->figure;
  
  my $figure_fill = $figure_fill{$figure};
  ### $figure
  
  my %rectangles_by_colour;
  my $flush = sub {
    ### flush rectangles: scalar(%rectangles_by_colour)
    foreach my $colour (keys %rectangles_by_colour) {
      my $aref = delete $rectangles_by_colour{$colour};
      App::MathImage::Image::Base::Other::rectangles
          ($image, $colour, 1, @$aref);
    }
  };
  
  my $count_total = $self->{'count_total'};
  my $count_outside = $self->{'count_outside'};
  my $n_hi = $self->{'n_hi'};
  
  if ($self->{'values'} eq 'LinesLevel') {
    ### LinesLevel step...
    
    my $n = $self->{'upto_n'};
    my $wxprev = $self->{'wxprev'};
    my $wyprev = $self->{'wyprev'};
    
    ### upto_n: $n
    ### $wxprev
    ### $wyprev
    
    for ( ; $n <= $n_hi; $n++) {
      &$cont() or last;
      
      my ($x,$y) = $path_object->n_to_xy($n)
        or last; # no more
      ### n: "$n"
      ### xy raw: "$x,$y"
      
      $self->{'x'} = $x;
      $self->{'y'} = $y;
      my ($wx,$wy) = $self->transform_xy ($x, $y);
      $self->{'wx'} = $wx;
      $self->{'wy'} = $wy;
      $self->$draw_figure_method($foreground);
      
      if (defined $wxprev) {
        _image_line_clipped ($image, $wxprev,$wyprev, $wx,$wy,
                             $width,$height, $foreground);
        $count_figures++;
      }
      
      $wxprev = $wx;
      $wyprev = $wy;
    }
    $self->{'upto_n'} = $n;
    $self->{'wxprev'} = $wxprev;
    $self->{'wyprev'} = $wyprev;
    return $more;
  }
  
  my $background_fill_proc = sub {};
  
  # my $offset = ($figure eq 'point' ? 0 : int(($xpscale+1)/2));
  # if (! $covers && $figure eq 'point') {
  #   $background_fill_proc = sub {
  #     my ($n_to) = @_;
  #     ### background fill for point...
  #     foreach my $n ($n_prev+1 .. $n_to) {
  #       $steps++;
  #       $count_total++;
  #       my ($x, $y) = $path_object->n_to_xy($n) or do {
  #         $count_outside++;
  #         next;
  #       };
  #       ($x, $y) = $affine->transform($x, $y);
  #       $x = floor ($x - $offset + 0.5);
  #       $y = floor ($y - $offset + 0.5);
  #       ### back_point: $n
  #       ### $x
  #       ### $y
  #       next if ($x < 0 || $y < 0 || $x >= $width || $y >= $height);
  #     }
  #   };
  # } elsif (! $covers && $figure eq 'square') {
  #   $background_fill_proc = sub {
  #     my ($n_to) = @_;
  #     ### background fill for rectangle...
  #     foreach my $n ($n_prev+1 .. $n_to) {
  #       $steps++;
  #       my ($x, $y) = $path_object->n_to_xy($n) or next;
  #       ($x, $y) = $affine->transform($x, $y);
  #       ### back_rectangle: "$n   $x,$y"
  #       $x = floor ($x - $offset + 0.5);
  #       $y = floor ($y - $offset + 0.5);
  #       $count_total++;
  #       my @rect = rect_clipper ($x, $y, $x+$xpscale, $y+$ypscale,
  #                                $width,$height)
  #         or do {
  #           $count_outside++;
  #           next;
  #         };
  #       push @{$rectangles_by_colour{$background}}, @rect;
  #       if (@{$rectangles_by_colour{$background}} >= _RECTANGLES_CHUNKS) {
  #         $flush->();
  #       }
  #     }
  #   };
  # } else {
  #   ### background_fill_proc is noop...
  #   $background_fill_proc = \&_noop;
  # }
  
  my $colour = $foreground;
  my $use_colours = $self->use_colours;
  my $values_non_decreasing_from_i = $values_seq->characteristic('non_decreasing_from_i');
  my $n;

  ### $use_colours
  ### $values_non_decreasing_from_i
  ### n_decrease_count: $self->{'n_decrease_count'}
  ### use_xy: $self->{'use_xy'}
  
  for (;;) {
    &$cont() or last;
    $count_total++;
    my ($n, $x,$y, $value);
    
    if ($self->{'use_xy'}) {
      ### by XY ...
      ($x, $y) = $self->{'rectbyxy'}->next
        or last;
      @$n_list = $path_object->xy_to_n_list
        (($self->{'bignum_xy'} ? _bigint()->new($x) : $x),
         ($self->{'bignum_xy'} ? _bigint()->new($y) : $y))
          or do {
            ### no N for this X,Y ...
            next;
          };
      #### use_xy path: "$x,$y  n_list=".join(',',@$n_list)
      
      if ($n_list->[-1] < $self->{'n_prev'}) {
        ### below already drawn "by N" ...
        next;
      }
      
      $n = $n_list->[0];
      if ($use_colours) {
        $value = $values_seq->ith($n);
      } else {
        $value = $values_seq->pred($n);
        if (defined $value && ! $value) {
          ### pred false, background ...
          next;
        }
      }
      ### $value
      if (! defined $value) {
        ### ith() or pred() undef, unknown at this X,Y, undrawnground ...
        $self->{'x'} = $x;
        $self->{'y'} = $y;
        ($self->{'wx'},$self->{'wy'}) = $self->transform_xy($x,$y);
        $self->draw_figure_square($undrawnground);
        next;
      }
      
    } else {
      (my $i, $value) = $values_seq->next;
      ### by N ...
      ### $i
      ### value: $value
      ### n_prev: "$self->{'n_prev'}"
      
      if ($use_colours) {
        $n = $i;
        if (! defined $n || $n > $n_hi) {
          ### seq i undef or past n_hi, stop ...
          last;
        }
      } else {
        $n = $value;
        if (! defined $n) {
          if (++$self->{'n_outside'} > 10) {
            ### n_outside >= 10, stop ...
            last;
          }
          next;
        }
        if ($n <= $self->{'n_prev'}) {
          ### n not increasing, count: $self->{'n_decrease_count'}
          if (++$self->{'n_decrease_count'} > 50) {
            ### stop for n<=n_prev too many times ...
            last;
          }
        } else {
          $self->{'n_decrease_count'} = 0;
          $self->{'n_prev'} = $n;
          
          if ($n > $n_hi) {
            if ((defined $values_non_decreasing_from_i
                 && $i >= $values_non_decreasing_from_i)
                || ++$self->{'n_outside'} > 10) {
              ### stop for n>n_hi ...
              last;
            }
            ### skip n>n_hi ...
            next;
          }
        }
      }
      ($x, $y) = $path_object->n_to_xy($n)
        or do {
          ### no xy at this n ...
          next;
        };
      @$n_list = ($n);
    }

    if ($use_colours) {
      if (! defined $value) {
        ### value undef, undrawnground ...
        $self->{'x'} = $x;
        $self->{'y'} = $y;
        ($self->{'wx'},$self->{'wy'}) = $self->transform_xy($x,$y);
        $self->draw_figure_square($undrawnground);
        next;
      }
      $colour = $self->value_to_colour($value);
      #### $colour
    }

    $self->{'n'} = $n;
    $self->{'x'} = $x;
    $self->{'y'} = $y;
    ### at: "n=$n  path xy=$x,$y"

    my ($wx, $wy) = $self->transform_xy($x,$y);
    if ($wx < -$scale || $wy < -$scale || $wx >= $width+$scale || $wy >= $height+$scale) {
      ### skip, outside width,height...
      $count_outside++;
      next;
    }

    $self->{'wx'} = $wx;
    $self->{'wy'} = $wy;

    if (! $filter_obj->pred($n)) {
      if (! $covers) {
        $self->draw_figure_square($undrawnground);
      }
      next;
    }

    $count_figures++;
    if ($use_colours) {
      $colour = $self->value_to_colour($value);
    }
    $self->$draw_figure_method($colour);
  }

  $flush->();
  ### $more
  return $more;
}

# sub xy_to_dir4_list {
#   my ($path, $x,$y) = @_;
#   return map {dxdy_to_dir4(n_to_dxdy($path,$_))} $path->xy_to_n_list($x,$y);
# }
# sub dxdy_to_dir4 {
#   my ($dx,$dy) = @_;
#   return map {n_to_dxdy($path,$_)} $path->xy_to_n_list($x,$y);
# }
sub path_xy_to_dxdy_list {
  my ($path, $x,$y) = @_;
  return map {$path->n_to_dxdy($_)} $path->xy_to_n_list($x,$y);
}

sub tree_n_children_for_branches {
  my ($path, $n, $branches) = @_;
  my $n_start = $path->n_start;
  $n = $branches*($n-$n_start) + $n_start;
  return map {$n+$_} 1 .. $branches;
}
# n_start=7
# N=8,9,10
# 8-(7+1)=0
# 9-(7+1)=1
# 10-(7+1)=2
sub tree_n_parent_for_branches {
  my ($path, $n, $branches) = @_;
  my $n_start = $path->n_start;
  $n -= $n_start + 1;
  if ($n < 0) {
    return undef;
  } else {
    return int($n/$branches) + $n_start;
  }
}

sub maybe_use_xy {
  my ($self) = @_;

  ### maybe_use_xy() ...
  ### count_total: $self->{'count_total'}
  ### count_outside: $self->{'count_outside'}

  my ($count_total, $values_seq);
  if (($count_total = $self->{'count_total'}) > 1000
      && $self->{'count_outside'} > .5 * $count_total
      && $self->can_use_xy ) {
    ### use_xy from now on...
    $self->use_xy($self->{'image'});
  }
}

sub can_use_xy {
  my ($self) = @_;
  my $values_seq;
  return ($self->path_object->figure eq 'square'
          && (! ($values_seq = $self->values_seq)  # Lines can use xy
              || $values_seq->can($self->use_colours ? 'ith' : 'pred')));

  # $pathname_square_grid{$self->{'path'}}
  # $values_seq->can('pred')
  #         && $values_seq->can('ith')) {
}

sub value_to_colour {
  my ($self, $value) = @_;
  ### value_to_colour(): $value

  my $base = $self->{'colours_base'};
  if (my $aref = $self->{'colours_array'}) {
    ### colour from array at: "base=$base, adjusted value=".abs($value - $base)
    $value = abs($value - $base);
    return $aref->[min ($#$aref, $value)];
  }
  if (defined (my $max = $self->{'colours_max'})) {
    ### linear ...
    $value = abs($value - $base);
    $value *= 65536.0;
    $value = int ($value / (($max - $base) || 1));
    $value = "$value" + 0.0; # numize bigint
    $value /= 65536.0;  # range 0 to 1
    return $self->colour_grey ($value)
  }
  ### exponential ...
  $value = abs($value - $base);
  # if ($value <= 0) { return $self->{'background'}; }
  $value = "$value" + 0.0; # numize bigint
  $value = exp($value * $self->{'colours_shrink_log'});
  # $value = log(1 + ($value - $base)) / (1- $self->{'colours_shrink'});
  return $self->colour_grey ($value)
}

# cf Math::NumSeq::_bigint()
use constant::defer _bigint => sub {
  # Crib note: don't change the back-end if already loaded
  unless (Math::BigInt->can('new')) {
    require Math::BigInt;
    eval { Math::BigInt->import (try => 'GMP') };
  }
  return 'Math::BigInt';
};

sub use_xy {
  my ($self, $image) = @_;
  # print "use_xy from now on\n";
  $self->{'use_xy'} = 1;

  my $affine = $self->affine_object;
  my $affine_inv = $affine->clone->invert;
  my $width  = $image->get('-width');
  my $height = $image->get('-height');

  my ($x_lo, $y_hi) = $affine_inv->transform (0,0);
  my ($x_hi, $y_lo) = $affine_inv->transform ($width,$height);

  $x_lo = floor($x_lo);
  $y_lo = floor($y_lo);
  $x_hi = ceil($x_hi);
  $y_hi = ceil($y_hi);

  if (! $self->x_negative) {
    $x_lo = max (0, $x_lo);
    $x_hi = max (0, $x_hi);
  }
  if (! $self->y_negative) {
    $y_lo = max (0, $y_lo);
    $y_hi = max (0, $y_hi);
  }
  $self->{'x_lo'} = $x_lo;
  $self->{'y_lo'} = $y_lo;
  $self->{'x_hi'} = $x_hi;
  $self->{'y_hi'} = $y_hi;

  require App::MathImage::RectByXY;
  $self->{'rectbyxy'} = App::MathImage::RectByXY->new (x_min => $x_lo,
                                                       x_max => $x_hi,
                                                       y_min => $y_lo,
                                                       y_max => $y_hi);

  $self->{'x'} = $x_lo - 1;
 $self->{'y'} = $y_lo;
  ### x range: "$x_lo to $x_hi start $self->{'x'}"
  ### y range: "$y_lo to $y_hi start $self->{'y'}"
  ### n_hi: "$self->{'n_hi'}   cf _SV_N_LIMIT "._SV_N_LIMIT()

  $self->{'bignum_xy'} = ($self->{'n_hi'} > _SV_N_LIMIT);

  my $x_width = $self->{'x_width'} = $x_hi - $x_lo + 1;
  $self->{'xy_total'} = ($y_hi - $y_lo + 1) * $x_width;
}


sub draw_progress_fraction {
  my ($self) = @_;
  if ($self->{'use_xy'}) {
    return (($self->{'x'} - $self->{'x_lo'})
            + ($self->{'y'} - $self->{'y_lo'}) * $self->{'x_width'})
      / $self->{'xy_total'};
  } else {
    return $self->{'n_prev'} / $self->{'n_hi'};
  }
}

sub draw_Image {
  my ($self, $image) = @_;
  local $self->{'step_time'} = undef;
  local $self->{'step_figures'} = undef;
  $self->draw_Image_start ($image);
  while ($self->draw_Image_steps) {
    # more
  }
}

# draw $image->line() but clipped to width x height
sub _image_line_clipped {
  my ($image, $x1,$y1, $x2,$y2, $width,$height, $colour) = @_;
  ### _image_line_clipped(): "$x1,$y1 $x2,$y2  ${width}x${height}"
  if (($x1,$y1, $x2,$y2) = line_clipper ($x1,$y1, $x2,$y2, $width,$height)) {
    ### clipped draw: "$x1,$y1 $x2,$y2"
    $image->line ($x1,$y1, $x2,$y2, $colour);
    return 1;
  } else {
    return 0;
  }
}

# clipping establishes $count_outside
sub ellipse_clipper {
  my ($x1,$y1, $x2,$y2, $width, $height) = @_;

  #  return ($x1,$y1, $x2,$y2);

  ### ellipse_clipper() ...
  # FIXME: Image::Xpm and Xbm have trouble partially off-screen
  # return if ($x1 < 0 || $x1 >= $width
  #            || $x2 < 0 || $x2 >= $width
  #            || $y1 < 0 || $y1 >= $height
  #            || $y2 < 0 || $y2 >= $height);

  return if ($x1 < 0 && $x2 < 0)
    || ($x1 >= $width && $x2 >= $width)
      || ($y1 < 0 && $y2 < 0)
        || ($y1 >= $height && $y2 >= $height);
  return ($x1,$y1, $x2,$y2);
}

# clipping establishes $count_outside
sub rect_clipper {
  my ($x1,$y1, $x2,$y2, $width,$height) = @_;
  ### rect_clipper(): "$x1,$y1, $x2,$y2"

  # if ($x1 < 0 && $x2 < 0) {
  #   my $m1 = $x1 & 0x7FFF;
  #   my $m2 = $x2 & 0x7FFF;
  #   if ($m1 < 1000) {
  #     print "$x1 .. $x2    $m1 .. $m2\n";
  #   }
  # }
  # #  return if ($x1 < 0 && $x2 < 0);
  #
  # # return if ($y2 < 0);
  # return ($x1,$y1, $x2,$y2);

  return if ($x1 < 0 && $x2 < 0)
    || ($x1 >= $width && $x2 >= $width)
      || ($y1 < 0 && $y2 < 0)
        || ($y1 >= $height && $y2 >= $height);

  return (max($x1,0),
          max($y1,0),
          min($x2,$width-1),
          min($y2,$height-1));
}

sub line_clipper {
  my ($x1,$y1, $x2,$y2, $width, $height) = @_;

  return if ($x1 < 0 && $x2 < 0)
    || ($x1 >= $width && $x2 >= $width)
      || ($y1 < 0 && $y2 < 0)
        || ($y1 >= $height && $y2 >= $height);

  my $x1new = $x1;
  my $y1new = $y1;
  my $x2new = $x2;
  my $y2new = $y2;
  my $xlen = ($x1 - $x2);
  my $ylen = ($y1 - $y2);

  if ($x1new < 0) {
    $x1new = 0;
    $y1new = floor (0.5 + ($y1*(-$x2) + $y2*($x1)) / $xlen);
    ### x1 neg: "y1new to $x1new,$y1new"
  } elsif ($x1new >= $width) {
    $x1new = $width-1;
    $y1new = floor (0.5 + ($y1*($x1new-$x2) + $y2*($x1-$x1new)) / $xlen);
    ### x1 big: "y1new to $x1new,$y1new"
  }
  if ($y1new < 0) {
    $y1new = 0;
    $x1new = floor (0.5 + ($x1*(-$y2) + $x2*($y1)) / $ylen);
    ### y1 neg: "x1new to $x1new,$y1new   left ".($y1new-$y2)." right ".($y1-$y1new)
    ### x1new to: $x1new
  } elsif ($y1new >= $height) {
    $y1new = $height-1;
    $x1new = floor (0.5 + ($x1*($y1new-$y2) + $x2*($y1-$y1new)) / $ylen);
    ### y1 big: "x1new to $x1new,$y1new   left ".($y1new-$y2)." right ".($y1-$y1new)
  }
  if ($x1new < 0 || $x1new >= $width) {
    ### x1new outside ...
    return;
  }

  if ($x2new < 0) {
    $x2new = 0;
    $y2new = floor (0.5 + ($y2*($x1) + $y1*(-$x2)) / $xlen);
    ### x2 neg: "y2new to $x2new,$y2new"
  } elsif ($x2new >= $width) {
    $x2new = $width-1;
    $y2new = floor (0.5 + ($y2*($x1-$x2new) + $y1*($x2new-$x2)) / $xlen);
    ### x2 big: "y2new to $x2new,$y2new"
  }
  if ($y2new < 0) {
    $y2new = 0;
    $x2new = floor (0.5 + ($x2*($y1) + $x1*(-$y2)) / $ylen);
    ### y2 neg: "x2new to $x2new,$y2new"
  } elsif ($y2new >= $height) {
    $y2new = $height-1;
    $x2new = floor (0.5 + ($x2*($y1-$y2new) + $x1*($y2new-$y2)) / $ylen);
    ### y2 big: "x2new $x2new,$y2new"
  }
  if ($x2new < 0 || $x2new >= $width) {
    ### x2new outside ...
    return;
  }

  return ($x1new,$y1new, $x2new,$y2new);
}


#------------------------------------------------------------------------------

# return a message string or undef
sub xy_message {
  my ($self, $x,$y) = @_;
  ### xy_message() ...
  ### $x
  ### $y

  unless (defined $x && defined $y) {
    return undef;
  }

  my $affine = $self->affine_object;
  my $affine_inv = $affine->clone->invert;
  ($x,$y) = $affine_inv->transform($x,$y);
  ### unaffine to: "$x,$y"

  my $path_object = $self->path_object;
  my @n_list = $path_object->xy_to_n_list($x,$y);
  ### @n_list

  # FIXME: ask $path_object whether there's any fractional X,Y and round for
  # display if not, or something
  if ($path_object->figure eq 'square') {
    $x = POSIX::floor ($x + 0.5);
    $y = POSIX::floor ($y + 0.5);
  }
  ### figure centre to: "$x,$y"

  my $message = sprintf("x=%.*f", (int($x)==$x ? 0 : 2), $x);
  if (defined (my $str = $path_object->MathImage__x_to_radixstr($y))) {
    $message .= "=[$str]";
  }
  $message .= sprintf(", y=%.*f", (int($y)==$y ? 0 : 2), $y);
  if (defined (my $str = $path_object->MathImage__y_to_radixstr($y))) {
    $message .= "=[$str]";
  }

  if (! @n_list) {
    return $message;
  }

  my $values_seq = $self->values_seq;
  my $join = '   ';
  foreach my $n (@n_list) {
    $message .= $join;
    $join = ' and ';

    $message .= "N=$n";
    if (defined (my $str = $path_object->MathImage__n_to_radixstr($n))) {
      $message .= "=[$str]";
    }

    # only when path is a tree
    if (defined (my $depth = $path_object->tree_n_to_depth($n))) {
      $message .= " depth=$depth";
    }

    if (! $values_seq) {
      ### no values_seq ...
      next;
    }

    ### use_colours: $self->use_colours
    ### can ith(): $values_seq->can('ith')
    my $vstr = '';
    my $radix;
    if ($self->use_colours) {
      if ($values_seq->can('ith')) {
        ### show value: $values_seq->ith($n)
        if (defined (my $value = $values_seq->ith($n))) {
          $vstr = " value=$value";
          ### $vstr
          if ($value >= 2 && $values_seq->characteristic('value_is_radix')) {
            $radix = $value;
          }
        }
      } else {
        $message .= "  (no ith() to get value)";
      }
    }

    $radix ||= $values_seq->characteristic('digits');
    my $values_parameters;
    if (! $radix
        && ! $values_seq->isa('Math::NumSeq::Emirps')
        && ($values_parameters = $self->{'values_parameters'})
        && $self->values_class->parameter_info_hash->{'radix'}) {
      $radix = $values_parameters->{'radix'}
    }
    if ($n != 0 && $radix && $radix != 10) {
      my $str = _my_cnv($n,$radix);
      $message .= " (N=$str in base $radix)";
    }
    $message .= $vstr;
  }
  return $message;
}
sub _my_cnv {
  my ($n, $radix) = @_;
  if ($radix <= 36) {
    require Math::BaseCnv;
    return Math::BaseCnv::cnv($n,10,$radix);
  } else {
    my $ret = '';
    do {
      $ret = sprintf('[%d]', $n % $radix) . $ret;
    } while ($n = int($n/$radix));
    return $ret;
  }
}

#------------------------------------------------------------------------------
# diagnostics

sub diagnostic_str {
  my ($self) = @_;
  my $str = '';

  $str .= "Generator $self->{'width'}x$self->{'height'}\n";
  {
    my $values_seq = $self->{'values_seq'};
    $str .= "Values " . (defined $values_seq ? ref $values_seq : '[undef]')
      . "\n";
  }
  {
    my $path_object = $self->{'path_object'};
    $str .= "Path   " . (defined $path_object ? ref $path_object : '[undef]')
      . "\n";
  }
  {
    $str .= "Draw by " . ($self->{'use_xy'} ? "X,Y" : "N")
      . ($self->{'bignum_xy'} ? ' bignumXY' : '')
      . "  upto_n $self->{'upto_n'} "
      . "  count $self->{'count_outside'} outside, $self->{'count_total'} total"
      . "\n";
    $str .= "N high $self->{'n_hi'}"
      . "\n";
  }
}

#------------------------------------------------------------------------------
# generic

use constant TRUE => 1;

# _gettime() returns a floating point count of seconds since some fixed but
# unspecified origin time.
#
# clock_gettime(CLOCK_REALTIME) is preferred.  clock_gettime() always
# exists, but it croaks if there's no such C library func.  In that case
# fall back on the hires time(), which is whatever best thing Time::HiRes
# can do, probably gettimeofday() normally.
#
# Maybe it'd be worth checking clock_getres() to see it's a decent
# resolution.  It's conceivable some old implementations might do
# CLOCK_REALTIME just from the CLK_TCK times() counter, giving only 10
# millisecond resolution.  That's enough for _IDLE_TIME_SLICE of 250 ms
# though.
#
sub _gettime {
  return Time::HiRes::clock_gettime (Time::HiRes::CLOCK_REALTIME());
}
BEGIN {
  unless (eval { _gettime(); 1 }) {
    ### _gettime() no clock_gettime(): $@
    local $^W = undef; # no warnings;
    *_gettime = \&Time::HiRes::time;
  }
}

sub _noop {}


sub NOTWORKING__Aztec_xy_next_in_rect {
  my ($x, $y, $x1,$y1, $x2,$y2) = @_;
  ($x1,$x1) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y1) = ($y2,$y1) if $y1 > $y2;
  for (;;) {
    if ($y >= 0) {
      if ($x >= 0) {
        # first quad
        $x -= 1;
        $y += 1;
        if ($x >= $x1 && $y <= $y2) {
          return ($x,$y)
        }
        $y = $x+$y;
        $x = -1;
      } else {
        # second quad
        $x -= 1;
        $y -= 1;
        if ($x >= $x1 && $y >= $y1) {
          return ($x,$y)
        }
        $x = $x-$y;
        $y = -1;
      }
    } else {
      if ($x < 0) {
        # third quad
        $x += 1;
        $y -= 1;
        if ($x <= $x2 && $y >= $y1) {
          return ($x,$y)
        }
        $y = $x-$y+1;
        $x = 0;
      } else {
        # fourth quad
        $x += 1;
        $y += 1;
        if ($x <= $x2 && $y <= $y2) {
          return ($x,$y)
        }
        $x = $x-$y;
        $y = 0;
      }
    }
  }
}

1;
__END__
