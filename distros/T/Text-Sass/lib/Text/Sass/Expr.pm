# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: Expr.pm 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/lib/Text/Sass/Expr.pm $
#
package Text::Sass::Expr;
use strict;
use warnings;
use Carp;
use Readonly;

our $VERSION = q[1.0.4];

Readonly::Scalar our $SHADE_MAX => 255;

# yes, this should be tokenised and probably use overloading

our $OPS = {
	    q[-]  => sub { my ($x, $y) = @_; return $x - $y; },
	    q[+]  => sub { my ($x, $y) = @_; return $x + $y; },
	    q[/]  => sub { my ($x, $y) = @_; return $x / $y; },
	    q[*]  => sub { my ($x, $y) = @_; return $x * $y; },
	    q[#-] => sub { my ($x, $y) = @_;
			   my ($xr, $xg, $xb) = @{$x};
			   my ($yr, $yg, $yb) = @{$y};
			   my $nr = $xr-$yr;
			   my $ng = $xg-$yg;
			   my $nb = $xb-$yb;
			   if($nr < 0) { $nr = 0; }
			   if($ng < 0) { $ng = 0; }
			   if($nb < 0) { $nb = 0; }
			   return rgb_to_hex(undef,[$nr, $ng, $nb]);
			 },
	    q[#+] => sub { my ($x, $y) = @_;
			   my ($xr, $xg, $xb) = @{$x};
			   my ($yr, $yg, $yb) = @{$y};
			   my $nr = $xr+$yr;
			   my $ng = $xg+$yg;
			   my $nb = $xb+$yb;
			   if($nr > $SHADE_MAX) { $nr = $SHADE_MAX; }
			   if($ng > $SHADE_MAX) { $ng = $SHADE_MAX; }
			   if($nb > $SHADE_MAX) { $nb = $SHADE_MAX; }
			   return rgb_to_hex(undef,[$nr, $ng, $nb]);
			 },
	   };

Readonly::Scalar our $MM2CM => 0.1;
Readonly::Scalar our $CM2MM => 10;
Readonly::Scalar our $IN2CM => 2.54;
Readonly::Scalar our $CM2IN => 1/2.54;
Readonly::Scalar our $IN2MM => 25.4;
Readonly::Scalar our $MM2IN => 1/25.4;
Readonly::Scalar our $PC2PT => 12;
Readonly::Scalar our $PT2PC => 1/12;

our $CONV = {
	     q[mm:cm] => sub { my ($v) = @_; return $v*$MM2CM; },
	     q[cm:mm] => sub { my ($v) = @_; return $v*$CM2MM; },
	     q[in:cm] => sub { my ($v) = @_; return $v*$IN2CM; },
	     q[cm:in] => sub { my ($v) = @_; return $v*$CM2IN; },
	     q[in:mm] => sub { my ($v) = @_; return $v*$IN2MM; },
	     q[mm:in] => sub { my ($v) = @_; return $v*$MM2IN; },
	     q[pc|pt] => sub { my ($v) = @_; return $v*$PC2PT; },
	     q[pt|pc] => sub { my ($v) = @_; return $v*$PT2PC; },
	    };

sub expr {
  my ($pkg, $part1, $op, $part2) = @_;

  $part1 =~ s/[#](.)(.)(.)(\b)/#${1}${1}${2}${2}${3}${3}$4/smxgi;
  $part2 =~ s/[#](.)(.)(.)(\b)/#${1}${1}${2}${2}${3}${3}$4/smxgi;

  my ($p1, $u1) = @{$pkg->units($part1)};
  my ($p2, $u2) = @{$pkg->units($part2)};
  return if(!defined $p1);

  if(!$u1) {
    $u1 = q[];
  }

  if(!$u2) {
    $u2 = q[];
  }

  if(!$u1 && $u2) {
    $u1 = $u2;
  }

  if(!$u2 && $u1) {
    $u2 = $u1;
  }

  if($u1 ne $u2 &&
     $u1 ne q[#] &&
     $u2 ne q[#]) {
    $p2 = $pkg->convert($p2, $u2, $u1);
    $u2 = $u1;
  }

  if(!exists $OPS->{$op}) {
    if ($op =~ /^\w/smx) {
      return;
    }
    elsif ($op =~ /\S{2,}/smx) {
      return;
    }
    croak qq[Cannot "$op"];
  }

  if($u1 eq q[#]) {
    my $cb = $OPS->{"#$op"};

    return sprintf q[#%s], $cb->($p1||[0,0,0], $p2||[0,0,0]);
  }

  return sprintf q[%s%s], $OPS->{$op}->($p1||0, $p2||0), $u1;
}

sub units {
  my ($pkg, $token) = @_;

  if($token =~ /^[#]/smx) {
    $token =~ s/^[#]//smx;
    return [$pkg->hex_to_rgb($token), q[#]];
  }

  my ($val, $units) = $token =~ /([\d.]+)(px|pt|pc|em|ex|mm|cm|in|%|)/smx;

  return [$val, $units];
}

sub rgb_to_hex {
  my ($pkg, $triple_ref) = @_;
  return sprintf q[%02x%02x%02x], @{$triple_ref};
}

sub hex_to_rgb {
  my ($pkg, $hex) = @_;

  my ($r, $g, $b) = unpack q[A2A2A2], $hex;
  return [hex $r, hex $g, hex $b];
}

sub convert {
  my ($pkg, $val, $from, $to) = @_;

  my $fromto = "$from:$to";
  if(!exists $CONV->{$fromto}) {
    croak qq[Cannot convert from $from to $to];
  }

  return $CONV->{$fromto}->($val);
}

1;
__END__

=encoding utf8

=head1 NAME

Text::Sass::Expr

=head1 VERSION

$LastChangedRevision: 71 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 expr

=head2 units

=head2 rgb_to_hex

=head2 hex_to_rgb

=head2 convert

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Carp

=item Readonly

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
