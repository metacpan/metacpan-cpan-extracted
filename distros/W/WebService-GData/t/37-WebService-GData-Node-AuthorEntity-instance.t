use Test::More tests => 5;
use WebService::GData::Node::Atom::AuthorEntity();
use WebService::GData::Serialize;
my $author = new WebService::GData::Node::Atom::AuthorEntity({name=>{'$t'=>'doe'},uri=>{'$t'=>'http://www.youtube.com'}});
    

ok(ref($author) eq 'WebService::GData::Node::Atom::AuthorEntity','$author is a WebService::GData::Node::Atom::AuthorEntity instance.');
ok($author->name eq 'doe','$author->name is properly set.');
ok($author->uri eq 'http://www.youtube.com','$author->uri is properly set.');

$author->uri('caramba');

ok($author->uri eq 'caramba','$author->uri is properly re setted.');
ok(WebService::GData::Serialize->to_xml($author) eq '<atom:author><atom:name>doe</atom:name><atom:uri>caramba</atom:uri></atom:author>','AuthorEntity is properly serialized');

