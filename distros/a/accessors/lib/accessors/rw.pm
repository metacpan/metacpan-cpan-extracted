=head1 NAME

accessors::rw - create 'classic' read/write accessor methods in caller's package.

=head1 SYNOPSIS

  package Foo;
  use accessors::rw qw( foo bar baz );

  my $obj = bless {}, 'Foo';

  # always return the current value, even on set:
  $obj->foo( 'hello ' ) if $obj->bar( 'world' ) eq 'world';

  print $obj->foo, $obj->bar, $obj->baz( "!\n" );

=cut

package accessors::rw;

use strict;
use warnings::register;
use base qw( accessors::classic );

our $VERSION  = '1.01';
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

use constant style => 'rw';

1;

__END__

=head1 DESCRIPTION

The B<accessors::rw> pragma lets you create simple I<classic> read/write
accessors at compile-time.  It is an alias for L<accessors::classic>.

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>.

=head1 SEE ALSO

L<accessors>,
L<accessors::ro>,
L<accessors::classic>,
L<accessors::chained>,
L<base>

=cut
