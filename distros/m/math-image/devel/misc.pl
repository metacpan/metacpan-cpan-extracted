#!/usr/bin/perl -w

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

use 5.010;
use strict;
use warnings;
use POSIX;
use Math::BigInt;
use List::Util 'min','max','sum';

use Smart::Comments;

use lib 'devel/lib';
# use lib "$ENV{HOME}/perl/scalar-list-utils/Scalar-List-Utils-1.23_03/blib/arch";
# use lib "$ENV{HOME}/perl/scalar-list-utils/Scalar-List-Utils-1.23_03/blib/lib";
# use lib "$ENV{HOME}/perl/scalar-list-utils/Scalar-List-Utils-1.23_03/lib";

use constant DBL_INT_MAX => (FLT_RADIX**DBL_MANT_DIG - 1);


{
  require Image::Base::Text;
  require App::MathImage::Image::Base::Other;
  my $image = Image::Base::Text->new (-width => 78, -height => 30);

  my $fill = 1;
  my $w = 30;
  my $h = int($w / sqrt(3));
  App::MathImage::Image::Base::Other::hexrect($image, 10,5, 10+$w,5+$h,
                                              '*',$fill);
  # App::MathImage::Image::Base::Other::hexrect($image, 10,5+$h+1, 10+$w,5+$h+$h+1, '@');
  # $image->rectangle(10,5, 10+$w,5+$h, '*');
  # $image->rectangle(10,5+$h+1, 10+$w,5+$h+$h+1, '@');
  $image->save('/dev/stdout');
  exit 0;
}
{
  require Image::Base::Text;
  require App::MathImage::Generator;
  my $image = Image::Base::Text->new (-width => 40, -height => 11);
  # App::MathImage::Generator::_octagon($image, 0,0, 10,10, '*');
  App::MathImage::Generator::_hexagon_horizontal($image, 0,0, 19,9, '*');
  $image->save('/dev/stdout');
  exit 0;
}

{
  my $x = ~0;
  my $y = $x / 3;
  print "$y\n";
  exit 0;
}
{
  my $x = ~0;
  my $y = ~0 ^ 1;
  my $i = ~0;
  my $j = ~0 ^ 1;
  my $m = min($x,$y);
  ### $m
  say 0+($m == $i);
  say 0+($m == $j);

   $m = min($y,$x);
  ### $m
  say 0+($m == $i);
  say 0+($m == $j);
  exit 0;
}
{
  { package Foo;

    use overload
      '""' => sub { ${$_[0]} },
        '+0' => sub { ${$_[0]} },
          '>'  => sub {
            ### overload > ...
            ${$_[0]} > ${$_[1]}
          },
            fallback => 1;
    sub new {
      my $class = shift;
      my $value = shift;
      bless \$value, $class;
    }
  }

  # ~/perl/scalar-list-utils/Scalar-List-Utils-1.23_03/ListUtil.xs
  # my $big  = Math::BigInt->from_hex('FFFFFFFFFFFFFFFFFFFF7');
  # my $huge = Math::BigInt->from_hex('FFFFFFFFFFFFFFFFFFFFF');
  # my $big = Math::BigInt->new(2) ** 32768;
  # my $huge = Math::BigInt->new(2) ** 33000;
  my $big = Foo->new(3);
  my $huge = Foo->new(5);
  ### $big
  ### $huge
  my $m = min($huge,$big);
  ### $m
  ### h: $huge->numify
  say $big == $m;
  say $huge == max($big,$huge);
  say $huge == max($huge,$big);
  exit 0;
}

{
  require App::MathImage::Generator;
  my $gen = App::MathImage::Generator->new (width  => 10,
                                            height => 10,
                                            scale  => 1,
                                            path   => 'SquareSpiral',
                                            values => 'PlanePath');
  ### gen ...
  require Image::Base::Text;
  my $image = Image::Base::Text->new
    (-width  => 10,
     -height => 10,
     -cindex => { 'black' => ' ',
                  'white' => '*'});
  ### draw_Image ...
  $gen->draw_Image ($image);
  $image->save('/dev/stdout');
  exit 0;
}


{
  require App::MathImage::Generator;
  require Geometry::AffineTransform;

  my $affine = Geometry::AffineTransform->new;
  $affine->scale (10, 20);
  $affine->rotate (45+180);
  $affine->translate (100, 200);
  my $det = $affine->{m11}*$affine->{m22} - $affine->{m12}*$affine->{m21};
  ### $affine
  ### $det
  my $x = 2;
  my $y = 3;
  my ($xa, $ya) = $affine->transform ($x, $y);
  ### transform: "$xa, $ya"

  my ($xu, $yu) = $affine->App::MathImage::Generator::untransform($xa,$ya);
  ### untransform: "$xu, $yu"

  my $inv = $affine->clone;
  $inv->App::MathImage::Generator::invert;
  ### $inv
  ($xu, $yu) = $inv->transform ($xa, $ya);
  ### inverse: "$xu, $yu"

  my $concat = $affine->clone->concatenate($inv);
  ### $concat
   $concat = $inv->clone->concatenate($affine);
  ### $concat
  exit 0;
}

{
  my $i;
  sub del {
    my ($n) = @_;
    # return 2 + ($] >= 5.006 ? 3 : 999);
    return $n * (1/sqrt(2));
  }
  my %read_signal = ('has-screen' => 'screen-changed',
                     style        => 'style-set',
                     toplevel     => 'hierarchy-changed');
  sub read_signals {
    my ($self) = @_;
    my $pname = $self->{'pname'};
    return ($read_signal{$pname} || "$pname-changed")
  }

  require Math::PlanePath::MultipleRings;
  require Math::NumSeq::MathImagePrimeQuadraticHonaker;
  require B::Concise;
  # B::Concise::compile('-exec',\&Math::NumSeq::MathImagePrimeQuadraticHonaker::pred)->();
  B::Concise::compile('-exec',\&Math::PlanePath::MultipleRings::_xy_to_d)->();
  exit 0;
}


{
  require Math::BigInt;
  Math::BigInt->import (try => 'GMP');

  require Devel::TimeThis;
  my $t = Devel::TimeThis->new('x');

  my $k = 2;
  my $bits = 500000;
  my $num = Math::BigInt->new($k);
  $num->blsft ($bits);
  ### num: "$num"
  $num->blog();
  # $num->bsqrt();
  ### num: "$num"
  my $str = $num->as_bin;
  ### $str

  # $num = Math::BigInt->new(1);
  # $num->blsft (length($str)-1);
  # ### num: "$num"

  exit 0;
}





{
  my @catalan = (1);
  foreach my $i (1 .. 20) {
    my $c = 0;
    foreach my $j (0 .. $#catalan) {
      $c += $catalan[$j]*$catalan[-1-$j];
    }
    $catalan[$i] = $c;
    print "$c\n";
  }
  exit 0;
}




{
  # # use Memoize;
  # # memoize('bell_number');
  # my @bell;
  # sub bell_number {
  #   my $n = shift;
  #   if ($n < @bell) {
  #     return $bell[$n];
  #   }
  #   return undef if $n < 0;
  #   return 1     if $n == 0;
  #   my $bell = 0;
  #   for (0 .. $n - 1) {
  #     my $bin = Math::Symbolic::AuxFunctions::binomial_coeff( $n - 1, $_ );
  #     $bell += bell_number($_) * $bin;
  #     ### $bin
  #     ### $bell
  #   }
  #   ### return: $bell
  #   $bell[$n] = $bell;
  #   return $bell;
  # }

  require Math::Symbolic::AuxFunctions;
  foreach my $i (1 .. 50) {
    my $b = Math::Symbolic::AuxFunctions::bell_number($i);
    # my $b = bell_number($i);
    printf "%2d  %f\n", $i, $b;
  }
  exit 0;
}
{
  require Module::Util;
  my @modules = Module::Util::find_in_namespace
    ('Math::NumSeq');
  ### @modules
  exit 0;
}


{
  require Module::Util;
  my @modules = Module::Util::find_in_namespace('');
  print scalar(@modules),"\n";

  require Pod::Simple::Search;
  my $s = Pod::Simple::Search->new;
  $s->verbose(1);
  # $s->survey;
  print $s->find ('Math::PlanePath::SquareSpiral'),"\n";
  exit 0;
}

{
  require Gtk2;
  my $color = Gtk2::Gdk::Color->new(0x1234, 0x5678, 0x9ABC);
  print $color->to_string,"\n";

  require Gtk2::Ex::Units;
  Gtk2->init;
  print "",Gtk2::Ex::Units::width(Gtk2::Gdk::Screen->get_default,"1mm"),"\n";
  exit 0;
}


{
  sub base3 {
    my ($n) = @_;
    my $str = '';
    while ($n) {
      $str = ($n % 3) . $str;
      $n = int($n/3);
    }
    return $str;
  }
  foreach my $n (1 .. 20) {
    printf "%2d %4s\n", $n, base3($n);
  }

  require App::MathImage::Generator;
  my $gen = App::MathImage::Generator->new (fraction => '5/29',
                                            polygonal => 3);
  my $iter = $gen->values_make_ternary_without_2;
  foreach my $i (1 .. 20) {
    my $count = 0;
    my $n = $iter->();
    printf "%2d %4s\n", $n, base3($n);
  }
  exit 0;
}

{
  require App::MathImage::Generator;
  my $gen = App::MathImage::Generator->new (fraction => '5/29',
                                            polygonal => 3);
  foreach my $limit (2*2, 4*4, 8*8, 16*16) {
    my $iter = $gen->values_make_karatsuba(1,$limit);
    my $count = 0;
    while ($iter->() <= $limit) {
      $count++;
    }
    print "$limit  $count\n";
  }
  exit 0;
}

{
  require Math::Trig;
  my $x;
  foreach (my $i = 1; $i < 10000000; $i++) {
    my $multiple = $i * 7;
    my $r = 0.5/sin(Math::Trig::pi()/$multiple);
    $x //= $r-1;
    if ($r - $x < 1) {
      printf "%2d %3d %8.3f  %6.3f\n", $i, $multiple, $r, $i*$x;
      die $i;
    }
    $x = $r;
  }
  exit 0;
}

{
  require POSIX;
  require Math::Trig;
  my $r = 1;
  my $theta = 0;
  my $ang = 0;
  foreach my $n (1 .. 100) {
    printf "%2d  ang=%.3f  %.3f %.3f %.3f\n",
      $n, $ang, $r, $ang, POSIX::fmod($ang, 2*3.14159);
    $ang = Math::Trig::asin(1/$r) / (2*3.14159);
    $theta += $ang;
    $r += $ang;
  }
  exit 0;
}

{
  require String::Parity;
  require String::BitCount;
  my $i = 0xFFFF01;
  my $s = pack('N', $i);
  $s = "\x{7FF}";
  my $b = [unpack('%32b*', $s)];
  my $p = 0; #String::Parity::isOddParity($s);
  my $c = 0; # String::BitCount::BitCount($s);
  ### $i
  ### $s
  ### $b
  ### $p
  ### $c
  exit 0;
}


{
  require Image::Xpm;
  my $image = Image::Xpm->new (-width => 10,
                               -height => 10);

  require App::MathImage::Generator;
  my $gen = App::MathImage::Generator->new (width => 10,
                                            height => 10,
                                            values => 'Squares',
                                            scale => 1,
                                            foreground => 'white',
                                            background => 'black');
  $gen->draw_Image_start ($image);
  do {
    $image->save ('/dev/stdout');
  } while ($gen->draw_Image_steps (2));
  exit 0;
}

{
  require Path::Class;
  require Scalar::Util;
  my $dir = Path::Class::dir('/', 'tmp');
  ### $dir
  my $reftype = Scalar::Util::reftype($dir);
  ### $reftype
  exit 0;
}
{
  require Scalar::Util;
  @ARGV = ('--values=xyz');
  Getopt::Long::GetOptions
      ('values=s'  => sub {
         my ($name, $value) = @_;
         ### $name
         ### ref: ref($name)
         my $reftype = Scalar::Util::reftype($name);
         ### $reftype
         ### $value
         ### ref: ref($value)
       });
  exit 0;
}

{
  require Getopt::Long;
  require Scalar::Util;
  @ARGV = ('--values=xyz');
  Getopt::Long::GetOptions
      ('values=s'  => sub {
         my ($name, $value) = @_;
         ### $name
         ### ref: ref($name)
         my $reftype = Scalar::Util::reftype($name);
         ### $reftype
         ### $value
         ### ref: ref($value)
       });
  exit 0;
}

{
  my $subr = sub {
    my ($s) = @_;
    return $s*(16*$s - 56) + 50;
     return 3*$s*$s - 4*$s + 2;
    return 2*$s*$s - 2*$s + 2;
    return $s*$s + .5;
    return $s*$s - $s + 1;
    return $s*($s+1)*.5 + 0.5;
  };
  my $back = sub {
    my ($n) = @_;
    return (7 + sqrt($n - 1)) / 4;
    return (2 + sqrt(3*$n - 2)) / 3;
    return .5 + sqrt(.5*$n-.75);
    return sqrt ($n - .5);
    # return -.5 + sqrt(2*$n - .75);
    #    return int((sqrt(4*$n-1) - 1) / 2);
  };
  my $prev = 0;
  foreach (1..15) {
    my $this = $subr->($_);
    printf("%2d  %.2f  %.2f  %.2f\n", $_, $this, $this-$prev,$back->($this));
    $prev = $this;
  }
  for (my $n = 1; $n < 100; $n++) {
    printf "%.2f  %.2f\n", $n,$back->($n);
  }
  exit 0;
}
{
  my $phi = (1 + sqrt(5)) / 2;
  my $phiphi = $phi**2;
  foreach my $i (0 .. 50) {
    my $n = $i * $phiphi;
    printf "%2d  %8.4f  %s\n",
      $i, $n,
      ($n - int($n) < 0.5 ? "X" : "");
  }
  exit 0;
}






{
  my $xs = 'x' x 100_000;
  sub noop {}
  require Devel::TimeThis;
  {
    my $str = $xs;
    my $time = Devel::TimeThis->new('ord1');
    foreach my $i (0 .. length($str)-1) {
      noop (ord(substr($str,$i,1)));
    }
  }
  {
    my $str = $xs;
    my $time = Devel::TimeThis->new('ord all');
    foreach my $i (0 .. length($str)-1) {
      noop (ord(substr($str,$i)));
    }
  }
  {
    my $str = $xs;
    my $time = Devel::TimeThis->new('substr1');
    while ($str) {
      $str = substr ($str, 1);
      noop(ord($str));
    }
    print "$str\n";
  }
  {
    my $str = $xs;
    my $time = Devel::TimeThis->new('4-arg');
    while ($str) {
      substr ($str, 0,1, '');
      noop(ord($str));
    }
    print "$str\n";
  }

  exit 0;
}
{
  require Math::Libm;
  my $pi = Math::Libm::M_PI();
  $pi *= 2**30;
  print $pi,"\n";
  printf ("%b", $pi);
  exit 0;
}


{
  require Math::Libm;
  require Math::PlanePath::VogelFloret;
  my $pathobj = Math::PlanePath::VogelFloret->new;
  my @ns = (1, 4);
  my @points = map { [$pathobj->n_to_xy($_)] } @ns;
  my $min_d = 999;
  my ($min_i, $min_j);
  foreach my $i (0 .. $#points-1) {
    foreach my $j ($i+1 .. $#points) {
      my $d = Math::Libm::hypot ($points[$i]->[0] - $points[$j]->[0],
                                 $points[$i]->[1] - $points[$j]->[1]);
      if ($d < 2) {
        print "$i $j  $d\n";
      }
      if ($d < $min_d) {
        $min_d = $d;
        $min_i = $i;
        $min_j = $j;
      }
    }
  }
  ### @points

  print "i=$min_i  ni=$ns[$min_i],nj=$ns[$min_j]  min_d=$min_d\n";
  print "x $points[$min_i]->[0]  $points[$min_j]->[0],  diff ",
    $points[$min_i]->[0] - $points[$min_j]->[0],"\n";
  print "y $points[$min_i]->[1]  $points[$min_j]->[1],  diff ",
    $points[$min_i]->[1] - $points[$min_j]->[1],"\n";

  #   print "1 to 4   $points[0]->[0],$points[0]->[1]   $points[3]->[0],$points[3]->[1]\n";
  #   print $points[0]->[0] - $points[3]->[0],"\n";
  #   print $points[0]->[1] - $points[3]->[1],"\n";
  exit 0;
}

{
  require Math::Prime::TiedArray;
  tie my @primes, 'Math::Prime::TiedArray';
  local $, = "\n";
  print @primes[0..5000];
  exit 0;
}

{
  require Image::Base;
  require Image::Xbm;
  my $image = Image::Xbm->new (-width => 100,
                               -height => 100);
  $image->ellipse(50,50, 150,150, 1);
  $image->save('/tmp/x.xbm');
  exit 0;
}
{
  require Image::Base;
  require Image::Xpm;
  my $image = Image::Xpm->new (-width => 10,
                               -height => 10);
  $image->ellipse(5,5, 15,15, 'white');
  $image->save('/dev/stdout');
  exit 0;
}

{
  require Math::PlanePath::SacksSpiral;
  foreach my $i (0 .. 40) {
    my $n;
    $n = $i*$i + $i;
    $n = $i*$i;
    my ($x, $y) = Math::PlanePath::SacksSpiral->n_to_xy($n);
    printf "%d  %d, %d\n", $i, $x, $y;
  }
  exit 0;
}

{
  require GD;
  require App::MathImage::Generator;
  my $gen = App::MathImage::Generator->new (scale => 20);
  my $gd = GD::Image->new (100,100);
  $gen->draw_GD ($gd);
  require File::Slurp;
  File::Slurp::write_file ('/tmp/x.png', $gd->png);
  system ('xzgv /tmp/x.png');
  exit 0;
}



# miss 1928099
{
  require Math::Prime::XS;
  my @array = Math::Prime::XS::sieve_primes (1, 2000000);
  $,="\n";
#  print @array;
  exit 0;
}
{
  require App::MathImage::Generator;
  my $gen = App::MathImage::Generator->new;
  my $values_class;
  $values_class = $gen->values_class('SophieGermainPrimes');
  my $seq = $values_class->new (lo => 1,
                                       hi => 19391363);
  # for (my $i = 0; $i < 10000; $i++) {
  #   my $n = $seq->{'array'}->[$i];
  #   print "$i $n\n";
  # }
  exit 0;
}



