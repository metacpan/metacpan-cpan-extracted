use Test::More tests => 4;
use WebService::GData::Node::PointEntity;
use WebService::GData::Serialize;
my $point = new WebService::GData::Node::PointEntity( { '$t' => '0.1 0.2' } );

ok(
    ref($point) eq 'WebService::GData::Node::PointEntity',
    '$point is a WebService::GData::Node::PointEntity instance.'
);

ok(
    WebService::GData::Serialize->to_xml($point) eq
q[<georss:where><gml:Point><gml:pos>0.1 0.2</gml:pos></gml:Point></georss:where>],
    'proper xml is output'
);
ok( $point->pos eq '0.1 0.2', '$point->pos is properly set.' );
$point->pos('0.1 0.4');
ok( $point->pos eq '0.1 0.4', '$point->pos is properly set.' );
