package WebService::GData::Node::GD::Rating;
use WebService::GData::Node::GD;

set_meta(
   attributes=>[qw(min max numRaters average value rel)],
   is_parent=>0
);

1;
