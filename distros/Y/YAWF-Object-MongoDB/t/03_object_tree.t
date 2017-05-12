use Test::More tests => 13;

use_ok('YAWF::Object::MongoDB');
use_ok('t::lib::Tree');

my $first = t::lib::Tree->new;    # Create a new tree
is( ref($first),              't::lib::Tree', 'Check first object type' );
ok( !ref($first->color),              , 'Check first object color type' );
ok( ref($first->root),              , 'Check first object root type' );

is($first->color('green'),'green','Set color');
is($first->color,'green','Get color');

is($first->root->branch('brown'),'brown','Set root->branch');
is($first->root->branch,'brown','Get root->branch');
ok(defined($first->{_changes}->{root}),'root changed');
is(ref($first->{_changes}->{root}),'HASH','changed root is ref');
is($first->{_changes}->{root}->{branch},'brown','changed root->branch value');

my $root = $first->root;
is($first->root,$root,'Check if same object is returned on multiple calls');

END {
    t::lib::Tree->_collection->drop;
}
