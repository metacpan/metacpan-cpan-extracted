=head1 NAME

accessors::chained - create method chaining accessors in caller's package.

=head1 SYNOPSIS

  package Foo;
  use accessors::chained qw( foo bar baz );

  my $obj = bless {}, 'Foo';

  # generates chaining accessors:
  $obj->foo( 'hello ' )
      ->bar( 'world' )
      ->baz( "!\n" );

  print $obj->foo, $obj->bar, $obj->baz;

=cut

package accessors::chained;

use strict;
use warnings::register;
use base qw( accessors );

our $VERSION  = '1.01';
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

# inherit everything for now.

1;

__END__

=head1 DESCRIPTION

The B<accessors::chained> pragma lets you create simple method-chaining
accessors at compile-time.

This module exists for future backwards-compatability - if the default style
of accessor ever changes, method-chaining accessors will still be available
through this pragma.

See L<accessors> for documentation.

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>

=head1 SEE ALSO

L<accessors>, L<accessors::classic>, L<base>

=cut
