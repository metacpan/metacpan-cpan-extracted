# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        bolav
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: Functions.pm 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/lib/Text/Sass/Functions.pm $
#
package Text::Sass::Functions;
use strict;
use warnings;
use Carp;
use Convert::Color;
use Text::Sass::Expr;
use POSIX qw();
use Readonly;

our $VERSION = q[1.0.4];
Readonly::Scalar my $PERC => 100;

sub _color {
  my ($self, $color) = @_;

  $color =~ s/[#](.)(.)(.)(\b)/#${1}${1}${2}${2}${3}${3}$4/smxgi;
  $color = Text::Sass::Expr->units($color);

  if ($color->[1] eq q[#]) {
    return Convert::Color->new(q[rgb8:].$color->[0]->[0].q[,].$color->[0]->[1].q[,].$color->[0]->[2]);
  }
  croak 'not a color '.$color;
}

sub _value {
  my ($self, $value) = @_;

  $value = Text::Sass::Expr->units($value);

  if ($value->[1] eq q[%]) {
    return $value->[0] / $PERC;

  } elsif ($value->[1] eq q[]) {
    return $value->[0];
  }

  croak 'Unknown unit '.$value->[1].' for value';
}

#########
# RGB Functions
#
sub rgb {
  my ($self, $r, $g, $b) = @_;

  my $cc = Convert::Color->new( "rgb8:$r,$g,$b" );

  return q[#].$cc->as_rgb8->hex;
}

# TODO: rgba

sub red {
  my ($self, $color) = @_;
  return $self->_color($color)->as_rgb8->red;
}

sub green {
  my ($self, $color) = @_;
  return $self->_color($color)->as_rgb8->green;
}

sub blue {
  my ($self, $color) = @_;
  return $self->_color($color)->as_rgb8->blue;
}

sub mix {
  my ($self, $c1, $c2, $w) = @_;

  # TODO: Weight not supported
  $w   ||= '50%';

  $c1    = $self->_color($c1);
  $c2    = $self->_color($c2);
  $w     = $self->_value($w);
  my $w2 = 1-$w;

  my $r = int(($c1->as_rgb8->red   * $w) + ($c2->as_rgb8->red   * $w2)) ;
  my $g = int(($c1->as_rgb8->green * $w) + ($c2->as_rgb8->green * $w2)) ;
  my $b = int(($c1->as_rgb8->blue  * $w) + ($c2->as_rgb8->blue  * $w2)) ;

  return q[#].Convert::Color->new("rgb8:$r,$g,$b")->hex;
}

#########
# HSL functions
#
sub hsl {
  my ($self, $h, $s, $l) = @_;

  $s = $self->_value($s);
  $l = $self->_value($l);
  my $cc = Convert::Color->new( "hsl:$h,$s,$l" );

  return q[#].$cc->as_rgb8->hex;
}

# TODO: hsla

sub hue {
  my ($self, $color) = @_;
  return $self->_color($color)->as_hsl->hue;
}

sub saturation {
  my ($self, $color) = @_;
  return $self->_color($color)->as_hsl->saturation;
}

sub lightness {
  my ($self, $color) = @_;
  return $self->_color($color)->as_hsl->lightness;
}

sub adjust_hue {
  my ($self, $color, $value) = @_;

  my $cc      = $self->_color($color);
  my $hsl     = $cc->as_hsl;
  my $new_hsl = Convert::Color->new( sprintf q[hsl:%s,%s,%s],
				     $hsl->hue+$value,
				     $hsl->saturation,
				     $hsl->lightness );

  return q[#].$new_hsl->as_rgb8->hex;
}

sub lighten {
  my ($self, $color, $value) = @_;

  $value      = $self->_value($value);
  my $cc      = $self->_color($color);
  my $hsl     = $cc->as_hsl;
  my $new_hsl = Convert::Color->new( sprintf q[hsl:%s,%s,%s],
				     $hsl->hue,
				     $hsl->saturation,
				     $hsl->lightness+$value );

  return q[#].$new_hsl->as_rgb8->hex;
}

sub darken {
  my ($self, $color, $value) = @_;

  $value      = $self->_value($value);
  my $cc      = $self->_color($color);
  my $hsl     = $cc->as_hsl;
  my $new_hsl = Convert::Color->new( sprintf q[hsl:%s,%s,%s],
				     $hsl->hue,
				     $hsl->saturation,
				     $hsl->lightness-$value );

  return q[#].$new_hsl->as_rgb8->hex;
}

sub saturate {
  my ($self, $color, $value) = @_;

  $value  = $self->_value($value);
  my $cc  = $self->_color($color);
  my $hsl = $cc->as_hsl;
  my $new_hsl = Convert::Color->new( sprintf q[hsl:%s,%s,%s],
				     $hsl->hue,
				     $hsl->saturation+$value,
				     $hsl->lightness );

  return q[#].$new_hsl->as_rgb8->hex;
}

sub desaturate {
  my ($self, $color, $value) = @_;

  $value  = $self->_value($value);
  my $cc  = $self->_color($color);
  my $hsl = $cc->as_hsl;
  my $sat = ($hsl->saturation-$value);

  if ($sat < 0) {
      $sat = 0;
  }

  my $new_hsl = Convert::Color->new( sprintf q[hsl:%s,%s,%s],
				     $hsl->hue,
				     $sat,
				     $hsl->lightness );

  return q[#].$new_hsl->as_rgb8->hex;
}

sub grayscale {
  my ($self, $color) = @_;

  return $self->desaturate($color, "$PERC%");
}

sub complement {
  my ($self, $color) = @_;

  Readonly::Scalar my $COMP_DEGREES => 180;
  return $self->adjust_hue($color, $COMP_DEGREES);
}

#########
# STRING Functions
#
sub unquote {
  my ($self, $str) = @_;

  $str =~ s/^\"(.*)\"/$1/xms;
  $str =~ s/^\'(.*)\'/$1/xms;

  return $str;
}

sub quote {
  my ($self, $str) = @_;

  if ($str =~ /^\"(.*)\"/xms) {
    return $str;
  }

  if ($str =~ /^\'(.*)\'/xms) {
    return $str;
  }

  return qq["$str"];
}

# NUMBER functions

sub percentage {
  my ($self, $num) = @_;

  return ($num * $PERC) . q[%];
}

sub round {
  my ($self, $str) = @_;

  my $num = Text::Sass::Expr->units($str);
  return sprintf q[%.0f%s], $num->[0], $num->[1];
}

sub ceil {
  my ($self, $str) = @_;

  my $num = Text::Sass::Expr->units($str);
  return POSIX::ceil($num->[0]).$num->[1];
}

sub floor {
  my ($self, $str) = @_;

  my $num = Text::Sass::Expr->units($str);
  return POSIX::floor($num->[0]).$num->[1];
}

sub abs { ## no critic (Homonym)
  my ($self, $str) = @_;
  my $num = Text::Sass::Expr->units($str);

  return POSIX::abs($num->[0]).$num->[1];
}

#########
# Introspective functions
#
sub unit {
  my ($self, $str) = @_;

  my $num = Text::Sass::Expr->units($str);
  return q["].$num->[1].q["];
}

sub unitless {
  my ($self, $str) = @_;

  my $num = Text::Sass::Expr->units($str);
  return $num->[1] ? 0 : 1;
}

1;

__END__

=encoding utf8

=head1 NAME

Text::Sass::Functions

=head1 VERSION

$LastChangedRevision: 71 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 rgb(red, green, blue)

Converts triplet into a color.

=head2 red(color)

Returns the red part of a color.

=head2 green(color)

Returns the green part of a color.

=head2 blue(color)

Returns the blue part og a color.

=head2 mix(color1, color2, weight = 50%)

Mixes two colors together.

=head2 hsl(hue, saturation, lightness)

Converts as hsl triplet into a color.

=head2 hue(color)

Returns the hue part of a color.

=head2 saturation(color)

Returns the saturation part of a color.

=head2 lightness(color)

Returns the lightness part of a color.

=head2 adjust_hue(color)

Changes the hue of a color, can be called as adjust-hue.

=head2 lighten(color, amount)

Makes a color lighter.

=head2 darken(color, amount)

Makes a color darker.

=head2 saturate(color, amount)

Makes a color more saturated.

=head2 desaturate(color, amount)

Makes a color less saturated.

=head2 grayscale(color)

Converts a color to grayscale.

=head2 complement(color)

Returns the complement of a color.

=head2 unquote(str)

Removes the quotes from a string.

=head2 quote(str)

Adds quotes to a string.

=head2 percentage(num)

Converts a unitless number to a percentage.

=head2 round(num)

Rounds a number to the nearest whole number.

=head2 ceil(num)

Rounds a number up to the nearest whole number.

=head2 floor(num)

Rounds a number down to the nearest whole number.

=head2 abs(num)

Returns the absolute value of a number.

=head2 unit(num)

Returns the unit of a value.

=head2 unitless(num)

Returns true if the number has no unit.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Carp

=item POSIX

=item Readonly

=item Convert::Color

=item Text::Sass::Expr

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Missing alpha routines rgba & hsla methods.

mix() doesn't support weight.

=head1 AUTHOR

Author: Bjørn-Olav Strand

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
