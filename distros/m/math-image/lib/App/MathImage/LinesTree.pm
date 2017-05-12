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

package App::MathImage::LinesTree;
use 5.004;
use strict;
use Locale::TextDomain 'App-MathImage';

# uncomment this to run the ### lines
#use Smart::Comments;


use vars '$VERSION','@ISA';
$VERSION = 110;
use Math::NumSeq::All;
@ISA = ('Math::NumSeq::All');

use constant name => __('Lines by Tree');
use constant description => __('No numbers, instead lines showing the path taken.');
use constant oeis_anum => undef;

use constant parameter_info_array => [ { name    => 'branches',
                                         display => __('Branches'),
                                         type    => 'integer',
                                         default => 0,
                                         minimum => 0,
                                         width   => 3,
                                         # description => __('...'),
                                       },
                                     ];

#------------------------------------------------------------------------------
# tree_n
#
# row=0  0
# row=1  1       to b                  is b many
# row=2  b+1     to b + b*b            is b*b many
# row=3  b*b+b+1 to b + b*b + b*b*b    is b*b*b many
# row start at
# Nlevel = b^(k-1)+...+b+1 = (b^k - 1)/(b-1)
# b^k - 1 = N*(b-1)
# b^k = N*(b-1)+1
#
#      0
#   1  2    3
# 456 789 10,11,12           4=11
# 13,14,15                  13=111      3*parent+1,2,3
#
# n_start=1 is [ 3*(N-1)+1,2,3 ] + 1
#           =  [ 3*N + 1-3+1,2-3+1,3-3+1 ]
#           =  [ 3*N + -1,0,1 ]
# n_start=s is [ b*(N-s)+1,2,3 ] + s
#           =  b*(N-s) + s+1..s+k
#           =  b*(N-s)+s + 1..k
#
# parent n_start=0 (N-1)/b
# parent n_start=k (N-1-k)/b+k
#                  = (N-1+b*k)/b

{ package Math::PlanePath;
  use constant MathImage__tree_constant_branches => undef;
  sub MathImage__tree_n_parent {
    my ($self, $n) = @_;
    ### MathImage__tree_n_parent() generic: $n
    if (my $branches = $self->MathImage__tree_constant_branches) {
      my $n_start = $self->n_start;
      if ($n > $n_start) {
        return int(($n - $n_start - 1)/$branches) + $n_start;
      }
    }
    return undef;
  }
  sub MathImage__tree_n_children {
    my ($self, $n) = @_;
    ### MathImage__tree_n_children() generic: ref $self, $n
    ### branches: $self->MathImage__tree_constant_branches
    if (my $branches = $self->MathImage__tree_constant_branches) {
      my $n_start = $self->n_start;
      $n = $branches*($n-$n_start) + $n_start;
      return map {$n+$_} 1 .. $branches;
    } else {
      return;
    }
  }
}
# { package Math::PlanePath::SquareSpiral;
# }
# { package Math::PlanePath::PyramidSpiral;
# }
# { package Math::PlanePath::TriangleSpiralSkewed;
# }
# { package Math::PlanePath::DiamondSpiral;
# }
# { package Math::PlanePath::AztecDiamondRings;
# }
# { package Math::PlanePath::PentSpiralSkewed;
# }
# { package Math::PlanePath::HexSpiral;
# }
# { package Math::PlanePath::HexSpiralSkewed;
# }
# { package Math::PlanePath::HexArms;
# }
# { package Math::PlanePath::HeptSpiralSkewed;
# }
# { package Math::PlanePath::AnvilSpiral;
# }
# { package Math::PlanePath::OctagramSpiral;
# }
# { package Math::PlanePath::KnightSpiral;
# }
# { package Math::PlanePath::CretanLabyrinth;
# }
# { package Math::PlanePath::SquareArms;
# }
# { package Math::PlanePath::DiamondArms;
# }
# { package Math::PlanePath::GreekKeySpiral;
# }
# { package Math::PlanePath::SacksSpiral;
# }
# { package Math::PlanePath::VogelFloret;
# }
# { package Math::PlanePath::TheodorusSpiral;
# }
# { package Math::PlanePath::ArchimedeanChords;
# }
# { package Math::PlanePath::MultipleRings;
# }
# { package Math::PlanePath::PixelRings;
# }
# { package Math::PlanePath::FilledRings;
# }
# { package Math::PlanePath::Hypot;
# }
# { package Math::PlanePath::HypotOctant;
# }
# { package Math::PlanePath::TriangularHypot;
# }
{ package Math::PlanePath::PeanoCurve;
  sub MathImage__tree_constant_branches {
    my ($self) = @_;
    return $self->{'radix'} ** 2;
  }
}
{ package Math::PlanePath::WunderlichMeander;
  use constant MathImage__tree_constant_branches => 9;
}
{ package Math::PlanePath::WunderlichSerpentine;
  sub MathImage__tree_constant_branches {
    my ($self) = @_;
    return $self->{'radix'} ** 2;
  }
}
{ package Math::PlanePath::HilbertCurve;
  use constant MathImage__tree_constant_branches => 4;
}
{ package Math::PlanePath::HilbertSpiral;
  use constant MathImage__tree_constant_branches => 4;
}
{ package Math::PlanePath::ZOrderCurve;
  sub MathImage__tree_constant_branches {
    my ($self) = @_;
    return $self->{'radix'} ** 2;
  }
}
{ package Math::PlanePath::GrayCode;
  sub MathImage__tree_constant_branches {
    my ($self) = @_;
    return $self->{'radix'} ** 2;
  }
}
{ package Math::PlanePath::ImaginaryBase;
  sub MathImage__tree_constant_branches {
    my ($self) = @_;
    return $self->{'radix'} ** 2;
  }
}
{ package Math::PlanePath::ImaginaryHalf;
  sub MathImage__tree_constant_branches {
    my ($self) = @_;
    return $self->{'radix'} ** 2;
  }
}
{ package Math::PlanePath::CubicBase;
  sub MathImage__tree_constant_branches {
    my ($self) = @_;
    return $self->{'radix'} ** 2;
  }
}
# { package Math::PlanePath::Flowsnake;
#   # inherit from Math::PlanePath::FlowsnakeCentres
# }
{ package Math::PlanePath::FlowsnakeCentres;
  use constant MathImage__tree_constant_branches => 7;
}
{ package Math::PlanePath::GosperReplicate;
  use constant MathImage__tree_constant_branches => 7;
}
{ package Math::PlanePath::GosperSide;
  use constant MathImage__tree_constant_branches => 3;
}
{ package Math::PlanePath::GosperIslands;
  use constant MathImage__tree_constant_branches => 3;
  # Nstart = 3^(level+1) - 2
  # N = 3^(level+1) - 2 + offset
  # children 3^(level+2) - 2  + 3*offset  + 0,1,2
  #        = 3*(3^(level+2)-2) +3*2 - 2  + 3*offset  + 0,1,2
  #        = 3*(3^(level+2)-2 + offset) + 4 + 0,1,2
  #        = 3*(3^(level+2)-2 + offset) + 4,5,6
  #        = 3*N + 4,5,6
  sub MathImage__tree_n_parent {
    my ($self, $n) = @_;
    if ($n >= 7) {
      return int(($n-4)/3);
    } else {
      return undef;
    }
  }
  sub MathImage__tree_n_children {
    my ($self, $n) = @_;
    $n *= 3;
    return ($n+4, $n+5, $n+6);
  }
}
{ package Math::PlanePath::KochCurve;
  use constant MathImage__tree_constant_branches => 4;
}
{ package Math::PlanePath::KochPeaks;
  # Nstart = level + (2*4^level + 1)/3
  # N = Nstart(level) + offset
  # children = Nstart(level+1) + 3*offset + 0,1,2
  sub MathImage__tree_n_parent {
    my ($self, $n) = @_;
    if ($n < 4) {
      return undef;
    }
    my ($side, $level) = _round_down_pow((3*$n-1)/2, 4);
    my $base = $level + (2*$side + 1)/3;
    if (2*$n+1 < 2*$base) {
      $level--;
      $side /= 4;
      $base = $level + (2*$side + 1)/3;
    }
    my $rem = $n - $base;
    my $prevstart = $level-1 + ($side/2 + 1)/3;
    if ($rem <= $side) {
      return $prevstart + int($rem/4);
    } else {
      return $prevstart + int(($rem+3)/4);
    }
  }
  sub MathImage__tree_n_children {
    my ($self, $n) = @_;
    my ($side, $level) = _round_down_pow((3*$n-1)/2, 4);
    my $base = $level + (2*$side + 1)/3;
    if (2*$n+1 < 2*$base) {
      $level--;
      $side /= 4;
      $base = $level + (2*$side + 1)/3;
    }
    my $next = $level+1 + (8*$side + 1)/3;
    my $rem = $n - $base;
    $n = $next + 4*$rem;
    if ($rem < $side) {
      return $n,$n+1,$n+2,$n+3;
    } elsif ($rem == $side) {
      return $n;
    } else {
      return $n-3,$n-2,$n-1,$n;
    }
  }
}
{ package Math::PlanePath::KochSnowflakes;
  # Nstart = 4^level
  # N = 4^level + offset
  # children 4^(level+1) + 4*offset + 0,1,2,3
  #        = 4*(4^level) + 4*offset + 0,1,2,3
  #        = 4*(4^level + offset) + 0,1,2,3
  #        = 4*N + 0,1,2,3
  sub MathImage__tree_n_parent {
    my ($self, $n) = @_;
    if ($n < 4) { return undef; }
    return int($n/4);
  }
  sub MathImage__tree_n_children {
    my ($self, $n) = @_;
    $n *= 4;
    return ($n, $n+1, $n+2, $n+3);
  }
}
{ package Math::PlanePath::KochSquareflakes;
  # Nstart(level) = (4^(level+1) - 1)/3
  # N = Nstart(level) + offset
  # children = Nstart(level+1) + 4*offset + 0,1,2,3
  #          = (4^(level+2) - 1)/3 + 4*offset + 0,1,2,3
  #          = (4*4^(level+1) - 1)/3 + 4*offset + 0,1,2,3
  #          = (4*4^(level+1) -4  +4 - 1)/3 + 4*offset + 0,1,2,3
  #          = 4*Nstart(level)  + (4 - 1)/3 + 0,1,2,3
  #          = 4*Nstart(level)  + 1 + 0,1,2,3
  sub MathImage__tree_n_parent {
    my ($self, $n) = @_;
    if ($n < 5) { return undef; }
    return int(($n-1)/4);
  }
  sub MathImage__tree_n_children {
    my ($self, $n) = @_;
    $n *= 4;
    return ($n+1, $n+2, $n+3, $n+4);
  }
}
{ package Math::PlanePath::QuadricCurve;
  use constant MathImage__tree_constant_branches => 8;
}
{ package Math::PlanePath::QuadricIslands;
  # Nstart = (4*8^level + 3)/7
  # N = Nstart + offset
  # children Nstart(level+1) + 8*offset + 0..7
  #        = (4*8^(level+1) + 3)/7 + 8*offset + 0..7
  #        = 4/7*8*8^level + 3/7 + 8*offset + 0..7
  #        = 8*(4/7*8^level + offset) + 3/7 + 0..7
  #        = 8*((4/7*8^level+3/7) + offset  -3/7) + 3/7 + 0..7
  #        = 8*(Nstart(level) + offset)  -8*3/7 + 3/7 + 0..7
  #        = 8*(Nstart(level) + offset) + (-8*3 + 3)/7 + 0..7
  #        = 8*(Nstart(level) + offset) - 3 + 0..7
  sub MathImage__tree_n_parent {
    my ($self, $n) = @_;
    if ($n >= 5) {
      return int(($n+3)/8);
    } else {
      return undef;
    }
  }
  sub MathImage__tree_n_children {
    my ($self, $n) = @_;
    $n *= 8;
    return ($n-3,$n-2,$n-1,$n,$n+1,$n+2,$n+3,$n+4);
  }
}
{ package Math::PlanePath::SierpinskiTriangle;
}
# { package Math::PlanePath::SierpinskiArrowhead;
# }
# { package Math::PlanePath::SierpinskiArrowheadCentres;
# }
{ package Math::PlanePath::SierpinskiCurve;
  use constant MathImage__tree_constant_branches => 4;
}
# { package Math::PlanePath::SierpinskiCurveStair;
#   # sub MathImage__tree_constant_branches {
#   #   my ($self) = @_;
#   #   return 2*$self->{'diagonal_length'} + 1;
#   # }
# }
{ package Math::PlanePath::HIndexing;
  use constant MathImage__tree_constant_branches => 4;
}
{ package Math::PlanePath::DragonCurve;
  use constant MathImage__tree_constant_branches => 2;
}
{ package Math::PlanePath::DragonRounded;
  # OR: first of each seg descends to first of each replication
  # 0 -> 2,3
  # 1 -> 4,5
  # 2 -> 6,7
  # 3 -> 8,9
  sub MathImage__tree_n_parent {
    my ($self, $n) = @_;
    if ($n < 2) {
      return undef;
    }
    return int($n/2)-1;
  }
  sub MathImage__tree_n_children {
    my ($self, $n) = @_;
    $n *= 2;
    return map {$n+$_} 2 .. 3;
  }
}
{ package Math::PlanePath::DragonMidpoint;
  use constant MathImage__tree_constant_branches => 2;
}
{ package Math::PlanePath::AlternatePaper;
  use constant MathImage__tree_constant_branches => 2;
}
{ package Math::PlanePath::TerdragonCurve;
  use constant MathImage__tree_constant_branches => 3;
}
{ package Math::PlanePath::TerdragonRounded;
  use constant MathImage__tree_constant_branches => 2;
  # 0 -> 2,3
  # 1 -> 4,5
  # 2 -> 6,7
  # 3 -> 8,9
  # sub MathImage__tree_n_parent {
  #   my ($self, $n) = @_;
  #   if ($n < 2) {
  #     return undef;
  #   }
  #   return int($n/2)-1;
  # }
  # sub MathImage__tree_n_children {
  #   my ($self, $n) = @_;
  #   $n *= 2;
  #   return map {$n+$_} 2 .. 3;
  # }
}
{ package Math::PlanePath::TerdragonMidpoint;
  use constant MathImage__tree_constant_branches => 3;
}
{ package Math::PlanePath::R5DragonCurve;
  use constant MathImage__tree_constant_branches => 5;
}
{ package Math::PlanePath::R5DragonMidpoint;
  use constant MathImage__tree_constant_branches => 5;
}
{ package Math::PlanePath::CCurve;
  use constant MathImage__tree_constant_branches => 2;
}
{ package Math::PlanePath::ComplexPlus;
  sub MathImage__tree_constant_branches {
    my ($self) = @_;
    return $self->{'realpart'} ** 2 + 1;
  }
}
{ package Math::PlanePath::ComplexMinus;
  sub MathImage__tree_constant_branches {
    my ($self) = @_;
    return $self->{'realpart'} ** 2 + 1;
  }
}
{ package Math::PlanePath::ComplexRevolving;
  use constant MathImage__tree_constant_branches => 2; # per base i+1
}
{ package Math::PlanePath::Rows;
  sub MathImage__tree_n_parent {
    my ($self, $n) = @_;
    $n -= $self->{'width'};
    return ($n >= 0 ? $n : undef);
  }
  sub MathImage__tree_n_children {
    my ($self, $n) = @_;
    return $n + $self->{'width'};
  }
}
{ package Math::PlanePath::Columns;
  sub MathImage__tree_n_parent {
    my ($self, $n) = @_;
    $n -= $self->{'height'};
    return ($n >= 0 ? $n : undef);
  }
  sub MathImage__tree_n_children {
    my ($self, $n) = @_;
    return $n + $self->{'height'};
  }
}
# { package Math::PlanePath::Diagonals;
# }
# { package Math::PlanePath::DiagonalsAlternating;
# }
# { package Math::PlanePath::DiagonalsOctant;
# }
# { package Math::PlanePath::MPeaks;
# }
# { package Math::PlanePath::Staircase;
# }
# { package Math::PlanePath::StaircaseAlternating;
# }
{ package Math::PlanePath::Corner;
  # StartN(d) = d^2 + 1
  # d = floor(sqrt(N - 1))
  # top N = StartN(d)+offset
  # child = StartN(d+1)+offset
  #       = (d+1)^2 + offset
  #       = d^2+offset + 2d+1
  sub MathImage__tree_n_parent {
    my ($self, $n) = @_;
    if ($n < 2) {
      return undef;
    }
    my $d = int(sqrt($n-1));
    my $rem = $n - ($d*$d+1);
    $n -= 2*$d-1;
    if ($rem < $d) {
      return $n;
    } elsif ($rem == $d) {
      return $n - 1;
    } else {
      return $n - 2;
    }
  }
  sub MathImage__tree_n_children {
    my ($self, $n) = @_;
    if ($n >= 1) {
      my $d = int(sqrt($n-1));
      my $rem = $n - ($d*$d+1);
      $n += 2*$d+1;
      if ($rem < $d) {
        return $n;
      } elsif ($rem > $d) {
        return $n + 2;
      } else {
        return ($n, $n+1, $n+2);
      }
    } else {
      return;
    }
  }
}
# { package Math::PlanePath::PyramidRows;
# }
# { package Math::PlanePath::PyramidSides;
# }
# { package Math::PlanePath::CellularRule;
# }
# { package Math::PlanePath::CellularRule::Line;
# }
# { package Math::PlanePath::CellularRule::OddSolid;
# }
# { package Math::PlanePath::CellularRule::LeftSolid;
# }
# { package Math::PlanePath::CellularRule54;
# }
# { package Math::PlanePath::CellularRule57;
# }
# { package Math::PlanePath::CellularRule190;
# }
# { package Math::PlanePath::DiagonalRationals;
# }
# { package Math::PlanePath::FactorRationals;
# }
# { package Math::PlanePath::GcdRationals;
# }
# { package Math::PlanePath::CoprimeColumns;
# }
# { package Math::PlanePath::DivisibleColumns;
# }
# { package Math::PlanePath::File;
# }
# { package Math::PlanePath::QuintetCurve;
#   # inherit from QuintetCentres
# }
{ package Math::PlanePath::QuintetCentres;
  use constant MathImage__tree_constant_branches => 5;
}
{ package Math::PlanePath::QuintetReplicate;
  use constant MathImage__tree_constant_branches => 5;
}
{ package Math::PlanePath::QuintetSide;
  use constant MathImage__tree_constant_branches => 5;
}
{ package Math::PlanePath::AR2W2Curve;
  use constant MathImage__tree_constant_branches => 4;
}
{ package Math::PlanePath::BetaOmega;
  use constant MathImage__tree_constant_branches => 4;
}
{ package Math::PlanePath::KochelCurve;
  use constant MathImage__tree_constant_branches => 9;
}
{ package Math::PlanePath::CincoCurve;
  use constant MathImage__tree_constant_branches => 25;
}
{ package Math::PlanePath::SquareReplicate;
  use constant MathImage__tree_constant_branches => 9;
}
{ package Math::PlanePath::CornerReplicate;
  use constant MathImage__tree_constant_branches => 4;
}
# { package Math::PlanePath::DigitGroups;
# }
# { package Math::PlanePath::FibonacciWordFractal;
# }
{ package Math::PlanePath::LTiling;
  use constant MathImage__tree_constant_branches => 3; # FIXME: divide by points
}

1;
__END__

=for stopwords Ryde MathImage

=head1 NAME

App::MathImage::LinesTree -- tree line drawing

=head1 DESCRIPTION

This is a special kind of "values" which draws lines between the points of
the path in a tree structure.

This suits things like L<Math::PlanePath::PythagoreanTree>, but may be a big
mess for non-tree related paths.

=head1 SEE ALSO

L<App::MathImage::Lines>,
L<App::MathImage::LinesLevel>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-image/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013 Kevin Ryde

Math-Image is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-Image is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Image.  If not, see <http://www.gnu.org/licenses/>.

=cut
