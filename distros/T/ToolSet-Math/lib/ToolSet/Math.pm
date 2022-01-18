package ToolSet::Math;
use base qw(ToolSet);

use 5.008_005;
use strict;
use warnings;

use List::Util qw(reduce);

BEGIN {
    our $VERSION = "1.002";
    $VERSION = eval $VERSION;

    our @EXPORT = qw(
      E LN2 LN10 PI PI2 PI4 PIP2 PIP4 SQRT2 SQRT5 SQRT1_2 GOLDENR
      log2 fac
    );
}

ToolSet->export(
    "List::Util" => [qw(max min sum sum0)],
    "Math::Trig" => undef,
    "Math::Complex" => undef,
    "Math::Complex" => [qw(:pi)],
    "POSIX" => [qw(
      ceil floor modf pow round
      isfinite isinf isnan
      FLT_EPSILON DBL_EPSILON nan NaN NAN
    )], # use int() for trunc()
);

use constant E => exp(1);
use constant LN2 => log(2);
use constant LN10 => log(10);

use constant PI => 4 * CORE::atan2(1, 1);
use constant PI2 => PI * 2;
use constant PI4 => PI * 4;
use constant PIP2 => PI / 2;
use constant PIP4 => PI / 4;

use constant SQRT2 => sqrt(2);
use constant SQRT5 => sqrt(5);
use constant SQRT1_2 => sqrt(1 / 2);
use constant GOLDENR => (1 + SQRT5) / 2;

sub log2 { Math::Complex::log($_[0]) / LN2 }

sub fac { !$_[0] ? 1 : reduce { $a * $b } 1 .. $_[0] }

1;
__END__

=encoding utf-8

=head1 NAME

ToolSet::Math - Bring in common math functions and constants.

=head1 SYNOPSIS

  use ToolSet::Math;

is equivalent to:

  use List::Util qw(max min sum sum0);
  use Math::Trig;
  use Math::Complex;
  use Math::Complex ":pi";
  use POSIX qw(ceil floor modf pow round isfinite isinf isnan);

Also, several constants are defined as well:

  E LN2 LN10
  PI PI2 PI4 PIP2 PIP4
  SQRT2 SQRT5 SQRT1_2 GOLDENR
  Inf nan NaN NAN
  FLT_EPSILON DBL_EPSILON

In addition, two functions are automatically exported: C<log2> for base-2 logarithm, and C<fac> for factorial.

=head1 DESCRIPTION

This module automatically exports convenience math functions and constants which are not available by default in Perl, such as C<ceil>, C<floor>, C<round>, C<log10> and trigonometric ones like C<tan>, C<asin>, C<cosec>, and C<deg2rad>. It also sets up support for complex numbers to expand Perl's math capabilities.

See C<Math::Trig> and C<Math::Complex> for details on all exported functions.

=head1 AUTHOR

Gerald Lai E<lt>glai@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2021- Gerald Lai

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
