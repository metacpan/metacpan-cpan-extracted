=head1 NAME

accessors::ro - create 'classic' read-only accessor methods in caller's package.

=head1 SYNOPSIS

  package Foo;
  use accessors::ro qw( foo bar baz );

  my $obj = bless { foo => 'read only? ' }, 'Foo';

  # values are read-only, so set is disabled:
  print "oh my!\n" if $obj->foo( "set?" ) eq 'read only? ';

  # if you really need to change the vars,
  # you must use direct-variable-access:
  $obj->{bar} = 'i need a drink ';
  $obj->{baz} = 'now';

  # always returns the current value:
  print $obj->foo, $obj->bar, $obj->baz, "!\n";

=cut

package accessors::ro;

use strict;
use warnings::register;
use base qw( accessors );

our $VERSION  = '1.01';
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

use constant style => 'ro';

sub create_accessor {
    my ($class, $accessor, $property) = @_;
    # get is slightly faster if we eval instead of using a closure + anon
    # sub, but the difference is marginal (~5%), and this uses less memory...
    no strict 'refs';
    *{$accessor} = sub { return $_[0]->{$property} };
}

1;

__END__

=head1 DESCRIPTION

The B<accessors::ro> pragma lets you create simple I<classic> read-only
accessors at compile-time.

The generated methods look like this:

  sub foo {
      my $self = shift;
      return $self->{foo};
  }

They I<always> return the current value, just like L<accessors::ro>.

=head1 PERFORMANCE

There is B<little-to-no performace hit> when using generated accessors; in
fact there is B<usually a performance gain>.

=over 4

=item *

typically I<5-15% faster> than hard-coded accessors (like the above example).

=item *

typically I<0-15% slower> than I<optimized> accessors (less readable).

=item *

typically a I<small> performance hit at startup (accessors are created at
compile-time).

=item *

uses the same anonymous sub to reduce memory consumption (sometimes by 80%).

=back

See the benchmark tests included with this distribution for more details.

=head1 CAVEATS

Classes using blessed scalarrefs, arrayrefs, etc. are not supported for sake
of simplicity.  Only hashrefs are supported.

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>

=head1 SEE ALSO

L<accessors>,
L<accessors::rw>,
L<accessors::classic>,
L<accessors::chained>,
L<base>

=cut
