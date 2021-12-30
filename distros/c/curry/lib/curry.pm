package curry;

our $VERSION = '2.000001';
$VERSION = eval $VERSION;

our $curry = sub {
  my ($invocant, $code) = splice @_, 0, 2;
  my @args = @_;
  sub { $invocant->$code(@args => @_) }
};

sub curry::_ { &$curry }

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

$curry::weak = sub {
  my ($invocant, $code) = splice @_, 0, 2;
  Scalar::Util::weaken($invocant) if length ref $invocant;
  my @args = @_;
  sub {
    return unless defined $invocant;
    $invocant->$code(@args => @_)
  }
};

sub curry::weak::_ { &$curry::weak }

sub AUTOLOAD {
  my $invocant = shift;
  Scalar::Util::weaken($invocant) if length ref $invocant;
  my ($method) = our $AUTOLOAD =~ /^curry::weak::(.+)$/;
  my @args = @_;
  return sub {
    return unless defined $invocant;
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

If you have a method name (or a coderef), you can call (as of version 2):

  my $code = $obj->curry::_($method => 'foo');

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

Similarly, given a method name or coderef (as of version 2):

  my $code = $obj->curry::weak::_($method => 'foo');

There are also C<$curry::curry> and C<$curry::weak> globals that work
equivalently to C<curry::_> and C<curry::weak::_> respectively - you'll
quite possibly see them in existing code because they were provided in
pre-2.0 versions but they're unlikely to be the best option for new code.

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
