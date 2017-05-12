use Test::More tests => 3;
use WebService::GData::Node::Atom::Content;

my $content = new WebService::GData::Node::Atom::Content({
    src => "http://www.youtube.com/v/qW...YvHqLE",
    type   => "application/x-shockwave-flash"
});
    

ok(ref($content) eq 'WebService::GData::Node::Atom::Content','$content is a WebService::GData::Node::Atom::Content instance.');
ok($content->src eq 'http://www.youtube.com/v/qW...YvHqLE','$content->src is properly set.');
ok($content->type eq 'application/x-shockwave-flash','$content->type is properly set.');

