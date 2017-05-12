use Test::More tests => 4;
use WebService::GData::Node::Atom::Category;

my $category = new WebService::GData::Node::Atom::Category({
    scheme => "http://schemas.google.com/g/2005#kind",
    term   => "http://gdata.youtube.com/schemas/2007#video",
    label  => 'Shows'
});

ok(ref($category) eq 'WebService::GData::Node::Atom::Category','$category is a WebService::GData::Node::Atom::Category instance.');
ok($category->scheme eq 'http://schemas.google.com/g/2005#kind','$category->scheme is properly set.');
ok($category->term eq 'http://gdata.youtube.com/schemas/2007#video','$category->term is properly set.');
ok($category->label eq 'Shows','$category->label is properly set.');
