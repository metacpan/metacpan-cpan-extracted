package Test::Three;

=pod

=begin testing foo 1

ok( 1, 'Good test' );

=end testing

=cut

use strict;

print "Hello World!\n";

package Test::Four;

=pod

=begin testing foo

ok( 1, 'Good test' );

=end testing

=cut

use strict;

print "Hello World!\n";

1;
