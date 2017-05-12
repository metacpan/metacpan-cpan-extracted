package WebService::GData::Node::Atom::Feed;
use WebService::GData::Node::Atom;
use WebService::GData::Node::GD();

set_meta(
    attributes=>['gd:etag'],
    extra_namespaces=>{WebService::GData::Node::GD->namespace_prefix=>WebService::GData::Node::GD->namespace_uri}
);

1;
