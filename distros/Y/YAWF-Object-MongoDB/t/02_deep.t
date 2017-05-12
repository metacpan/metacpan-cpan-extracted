use Test::More tests => 20;

use_ok('YAWF::Object::MongoDB');
use_ok('t::lib::Car');

# $YAWF::Object::MongoDB::DEBUG = 1;

my $first = t::lib::Car->new;    # Create a new car
is( ref($first),              't::lib::Car', 'Check first object type' );
is( $first->color('red'),     'red',         'Set first color' );
is($first->{document},undef,'Check for new document');
is($first->{_changes}->{color},'red','Check first _changes value');
ok( $first->flush, 'Flush first object to database' );
ok($first->{_document},'First object has _document');
ok($first->{_document}->{_id},'First object has id '.($first->{_document}->{_id} || ''));
is($first->{_document}->{_id},$first->id,'First object internal vs. ->id check');

my $fetched = t::lib::Car->new($first->id);
ok($fetched,'Fetch document');
isnt($fetched,$first,'Is fresh');
is($fetched->id,$first->id,'Fetched id');
is($fetched->{_document}->{_id},$first->id,'Fetched internal id');
is($fetched->color,'red','Fetched color');

$found = t::lib::Car->new(color => 'red');
ok($found,'Found document');
is(ref($found),'t::lib::Car','Class');
is($found->id,$first->id,'Found id');
is($found->{_document}->{_id},$first->id,'Found internal id');
is($found->color,'red','Found color');

END {
    t::lib::Car->_collection->drop;
}
