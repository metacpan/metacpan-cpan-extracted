
use Test;
BEGIN { plan tests => 4 };

use base 'Waft';
use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use Waft::StashAccessor;

make_stash_accessor('foo', 'bar');

my $obj = __PACKAGE__->new;

$obj->set_foo('baz');
ok( $obj->stash->{foo} eq 'baz' );
ok( $obj->get_foo eq 'baz' );

$obj->set_bar('baz');
ok( $obj->stash->{bar} eq 'baz' );
ok( $obj->get_bar eq 'baz' );
