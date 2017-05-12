use warnings;
use strict;
use Test::Most 0.34;
use Test::Moose 2.1805;
use Moose 2.1805;    # required to provide instrospection to Moo

my $class = 'Test::Health::Email';

require_ok($class);
can_ok( $class, qw(get_host get_to get_from send_email _create_transport) );
dies_ok { $class->new( {} ) } 'require attributes during object creation';
dies_ok { $class->new( { to => [], from => 'ihioh' } ) }
'exception with invalid value for "to" attribute';
dies_ok { $class->new( { to => 'yugyugyug', from => undef } ) }
'exception with invalid value for "from" attribute';
my $instance =
  $class->new( { to => 'john@foo.bar', from => 'lenny@foob.bar' } );
isa_ok( $instance, $class );
foreach my $attrib (qw(to from host)) {
    has_attribute_ok( $instance, $attrib );
}
is( $instance->get_host, 'localhost', 'instance host attribute defaults to' );

done_testing;
