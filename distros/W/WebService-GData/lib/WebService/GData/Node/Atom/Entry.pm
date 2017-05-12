package WebService::GData::Node::Atom::Entry;
use WebService::GData::Node::Atom;
use WebService::GData::Node::GD();

set_meta(
    attributes=>['gd:etag'],
    extra_namespaces=>{WebService::GData::Node::GD->namespace_prefix=>WebService::GData::Node::GD->namespace_uri}
);


"The earth is blue like an orange.";
