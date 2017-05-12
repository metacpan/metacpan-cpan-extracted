
use Test;
BEGIN { plan tests => 10 };

use base 'Waft';
use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use Waft::StashAccessor;

make_stash_accessor('foo_bar', { minlen => 1 });

my $obj = __PACKAGE__->new;

ok( do { $obj->set_foo_bar(      'baz'), 1 } );
ok( $obj->get_foo_bar eq         'baz' );
ok( do { $obj->set_foo_bar(      'ba'), 1 } );
ok( $obj->get_foo_bar eq         'ba' );
ok( do { $obj->set_foo_bar(      'b'), 1 } );
ok( $obj->get_foo_bar eq         'b' );
ok( not eval { $obj->set_foo_bar(''), 1 } );
ok( $obj->get_foo_bar eq         'b' );

$obj->stash->{foo_bar} = '';
ok( not eval { $obj->get_foo_bar, 1 } );

$obj->stash->{foo_bar} = undef;
ok( not eval { $obj->get_foo_bar, 1 } );
