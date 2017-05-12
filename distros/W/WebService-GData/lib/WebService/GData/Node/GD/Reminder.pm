package WebService::GData::Node::GD::Reminder;
use WebService::GData::Node::GD;


set_meta(
   attributes=>[qw(absoluteTime method days hours minutes)],
   is_parent=>0
);

1;
