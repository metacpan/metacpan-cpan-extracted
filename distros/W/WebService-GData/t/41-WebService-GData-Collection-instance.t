use Test::More tests => 4;
use WebService::GData::Collection;
use WebService::GData::Node::Atom::Id;
use WebService::GData::Node::Media::GroupEntity;

my $gr = new WebService::GData::Node::Media::GroupEntity({
	'media$category'=>[
	   {'$t'=>'hi'}
	]	
});

ok(ref $gr->category->[0] eq 'WebService::GData::Node::Media::Category','data is properly inflated');

my $collection = new WebService::GData::Collection(
[
  {'$t'=>'hi'},
  {'$t'=>'good bye'}
],undef,
sub { 
	my $val = shift;
	$val= new WebService::GData::Node::Atom::Id($val) if ref $val ne 'WebService::GData::Node::Atom::Id';
	return $val;
}
);

for(my $i=0;$i<scalar(@$collection);$i++){
	ok(ref $collection->[$i] eq 'WebService::GData::Node::Atom::Id');
}

$collection->[0]=new WebService::GData::Node::Atom::Id({'$t'=>'salut'});

ok($collection->[0]->text eq 'salut','properly set');
