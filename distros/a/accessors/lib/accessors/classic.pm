=head1 NAME

accessors::classic - create 'classic' read/write accessor methods in caller's package.

=head1 SYNOPSIS

  package Foo;
  use accessors::classic qw( foo bar baz );

  my $obj = bless {}, 'Foo';

  # always return the current value, even on set:
  $obj->foo( 'hello ' ) if $obj->bar( 'world' ) eq 'world';

  print $obj->foo, $obj->bar, $obj->baz( "!\n" );

=cut

package accessors::classic;

use strict;
use warnings::register;
use base qw( accessors );

our $VERSION  = '1.01';
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

use constant style => 'classic';

sub create_accessor {
    my ($class, $accessor, $property) = @_;
    # set/get is slightly faster if we eval instead of using a closure + anon
    # sub, but the difference is marginal (~5%), and this uses less memory...
    no strict 'refs';
    *{$accessor} = sub {
	(@_ > 1) ? $_[0]->{$property} = $_[1] : $_[0]->{$property};
    }
}

1;

__END__

=head1 DESCRIPTION

The B<accessors::classic> pragma lets you create simple I<classic> Perl
accessors at compile-time.

The generated methods look like this:

  sub foo {
      my $self = shift;
      $self->{foo} = shift if (@_);
      return $self->{foo};
  }

They I<always> return the current value.

Note that there is I<no> dash (C<->) prepended to the property name as there
are in L<accessors>.  This is for backwards compatability.

=head1 PERFORMANCE

There is B<little-to-no performace hit> when using generated accessors; in
fact there is B<usually a performance gain>.

=over 4

=item *

typically I<5-15% faster> than hard-coded accessors (like the above example).

=item *

typically I<1-15% slower> than I<optimized> accessors (less readable).

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
L<accessors::ro>,
L<accessors::chained>,
L<base>

=cut
