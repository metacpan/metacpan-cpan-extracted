#!/usr/bin/perl -w

use strict;
use warnings;

package bare;

our $VERSION = '0.02';

my %forbidden = map { $_ => 1 } qw(
  if else elsif unless while until for foreach continue redo
  q qq tr y m s qr qw qx
  defined delete do eval exists format glob goto grep last local
  map my next no our package print printf prototype redo require
  return scalar sort split study sub undef use
  given when break
);

sub import {
  my $class = shift;
  my $caller = caller;
  my $legal_var = $utf8::hint_bits && $^H & $utf8::hint_bits
                  ? qr/^[[:alpha:]_]\w{0,250}$/
                  : qr/^[a-z_][a-z0-9_]{0,250}$/i;
  no strict 'refs';
  foreach my $bare (@_) {
    die "cannot override $bare" if $forbidden{$bare};
    die "illegal name: $bare" if $bare !~ $legal_var;
    my $scalar;
    *{"${caller}::$bare"} = \$scalar;
    *{"${caller}::$bare"} = sub():lvalue{ ${"${caller}::$bare"} };
  }
}

1;

__END__

=head1 NAME

bare.pm - scalars without sigils

=head1 SYNOPSIS

  use bare qw(foo bar);

  foo=3; bar=4;
  print foo+bar; #7

  foo=bar=3;
  print foo=5,foo+bar #58

  # Note that foo and $foo are aliased, eg:
  die unless foo==$foo;
  die unless bar==$bar;
  print "foo: $foo, bar: $bar"; #foo: 3, bar: 3

=head1 DESCRIPTION

Everyone knows that Perl looks like line noise. Not anymore!
bare.pm lets you access scalar variables without a leading
sigil.

=head1 BUGS AND LIMITATIONS

Note carefully that these are not lexical variables. You can
only have one variable C<foo>, which is aliased to the package
variable $foo. You can, however, localize such a variable like so:

  use bare 'foo';
  foo=3;
  {
    local $foo = 7;
    die unless foo==7;
  }
  die unless foo==3;

There are various other cases where you will have to use a sigil, eg:

  To interpolate a bare in a string:
    use bare 'x'; print "x=$x"

  For use on a loop variable, eg:
    use bare 'x'; for $x (0..20) { ... }

bares are implemented as subs, so sigil-less access is quite a bit
slower than "native" scalars that use sigils. For code where
performance is important, you'll have to use sigils.

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Brian Szymanski

