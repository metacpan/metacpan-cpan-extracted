package WebService::GData::Node::Media::Thumbnail;
use WebService::GData::Node::Media;

set_meta(
    attributes=>[qw(url height width time)],
    is_parent=>0
);

1;
