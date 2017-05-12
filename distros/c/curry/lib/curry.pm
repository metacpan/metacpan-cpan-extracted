package curry;

our $VERSION = '1.000000';
$VERSION = eval $VERSION;

sub AUTOLOAD {
  my $invocant = shift;
  my ($method) = our $AUTOLOAD =~ /^curry::(.+)$/;
  my @args = @_;
  return sub {
    $invocant->$method(@args => @_);
  }
}

package curry::weak;

use Scalar::Util ();

sub AUTOLOAD {
  my $invocant = shift;
  Scalar::Util::weaken($invocant) if Scalar::Util::blessed($invocant);
  my ($method) = our $AUTOLOAD =~ /^curry::weak::(.+)$/;
  my @args = @_;
  return sub {
    return unless $invocant;
    $invocant->$method(@args => @_);
  }
}

1;

=head1 NAME

curry - Create automatic curried method call closures for any class or object

=head1 SYNOPSIS

  use curry;

  my $code = $obj->curry::frobnicate('foo');

is equivalent to:

  my $code = sub { $obj->frobnicate(foo => @_) };

Additionally,

  use curry::weak;

  my $code = $obj->curry::weak::frobnicate('foo');

is equivalent to:

  my $code = do {
    Scalar::Util::weaken(my $weak_obj = $obj);
    sub {
      return unless $weak_obj; # in case it already went away
      $weak_obj->frobnicate(foo => @_)
    };
  };

=head1 RATIONALE

How many times have you written

  sub { $obj->something($some, $args, @_) }

or worse still needed to weaken it and had to check and re-check your code
to be sure you weren't closing over things the wrong way?

Right. That's why I wrote this.

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2012 the curry L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
