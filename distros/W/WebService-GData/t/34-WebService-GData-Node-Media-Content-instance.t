use Test::More tests => 1;
use WebService::GData::Node::Media::Content;
use WebService::GData::Serialize;

my $category = new WebService::GData::Node::Media::Content(
    url         => 'http://www.youtube.com',
    type        => "application/x-shockwave-flash",
    medium      => 'video',
    isDefault   => 'true',
    expression  => 'full',
    duration    => '0:43'
);

$category->text('I am very funny.');
$category->is_default('false');

ok(
    WebService::GData::Serialize->to_xml($category) eq
q[<media:content url="http://www.youtube.com" type="application/x-shockwave-flash" medium="video" isDefault="false" expression="full" duration="0:43"/>],
    'category object is properly output'
);

