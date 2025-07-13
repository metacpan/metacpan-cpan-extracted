use strict;
use warnings;
package autobox::Time::Piece;

# ABSTRACT: on-the-fly date conversion

{ our $VERSION = '0.001'; }

use base qw(autobox);

sub import {
    my $class = shift;

    $class->SUPER::import(
			  HASH => 'autobox::Time::Piece::Subs',
			  ARRAY => 'autobox::Time::Piece::Subs',
			  SCALAR => 'autobox::Time::Piece::Subs',
			 );
}

package autobox::Time::Piece::Subs;
use Time::Piece;

sub strptime {
    my ($self, $fmt) = @_;
    return $self if (ref $self eq 'Time::Piece');
    return localtime($self) unless $fmt;
    return Time::Piece->strptime($self, $fmt);
}
*parse = *strptime;
*format = *strftime;

sub convert { strptime(shift(), shift())->strftime(shift()) }

sub format { shift()->strftime(shift()) }

*Time::Piece::parse = *Time::Piece::strptime;
*Time::Piece::format = *Time::Piece::strftime;

*autobox::Time::Piece::Subs::format = *autobox::Time::Piece::Subs::strftime;

sub AUTOLOAD {
    our $AUTOLOAD;              # keep 'use strict' happy
    my $function = $AUTOLOAD =~ s/.*:://r;

    die sprintf "Time::Piece has no \"%s\" function\n", $function unless Time::Piece->can($function);

    return strptime(shift())->$function(@_);
}


1;

=head1 NAME

autobox::Time::Piece - on-the-fly date conversion

=head1 SYNOPSIS

  use autobox::Time::Piece;

  my $date = '2025-07-12';
  my $tp   = $date->strptime('%Y-%m-%d');
  my $str  = $tp->format('%A, %B %d, %Y');

  my $converted = $date->convert('%Y-%m-%d', '%d/%m/%Y');

=head1 DESCRIPTION

This module extends scalars, arrays, and hashes with methods from L<Time::Piece>. 
It allows strings and other data to behave like date objects through autoboxing.

=head1 METHODS

All methods are injected into SCALAR, ARRAY, and HASH types.

=head2 SCALAR->strptime($format)

Parses the string into a L<Time::Piece> object using the given C<strftime>-style format.
If no format is given, it falls back to C<localtime()>.
If the scalar is already a L<Time::Piece> object, it is returned unchanged.

=head2 SCALAR->parse($format)

Alias for L</strptime>.

=head2 SCALAR->format($format)

Formats a L<Time::Piece> object or a parseable string using the given format string.
Alias for L</strftime>.

=head2 SCALAR->convert($from_format, $to_format)

Parses the string using C<$from_format> and re-serializes it using C<$to_format>.

=head2 AUTOLOAD

Any method called on a scalar (or other supported type) that matches a method in
L<Time::Piece> will be dynamically delegated to it. For example:

  my $day_of_year = '2025-07-12'->strptime('%Y-%m-%d')->yday;

  # or directly:
  my $dow = '2025-07-12'->wdayname;

This mechanism ensures that common L<Time::Piece> methods like C<year>, C<mon>,
C<yday>, etc. are accessible without manual conversion.

=head1 SEE ALSO

L<autobox>, L<Time::Piece>, L<Time::Piece::strptime>

=head1 AUTHOR

Simone Cesano

This software is copyright (c) 2025 by Simone Cesano.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
