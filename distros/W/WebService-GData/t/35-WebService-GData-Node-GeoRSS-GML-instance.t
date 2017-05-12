use Test::More tests => 1;
use WebService::GData::Node::GeoRSS::Where;
use WebService::GData::Node::GML::Point;
use WebService::GData::Node::GML::Pos;
use WebService::GData::Serialize;

my $where = new WebService::GData::Node::GeoRSS::Where();
my $point = new WebService::GData::Node::GML::Point();
 $where->child($point);
 $point->child(new WebService::GData::Node::GML::Pos(text=>'0.2324322 0.2323222'));

ok(WebService::GData::Serialize->to_xml($where) eq q[<georss:where><gml:Point><gml:pos>0.2324322 0.2323222</gml:pos></gml:Point></georss:where>],'$where is properly set.');
