use Test::More tests => 5;
use WebService::GData::YouTube::Feed::Complaint;


my $complaint = new WebService::GData::YouTube::Feed::Complaint({});
$complaint->summary('test');
$complaint->video_id('video_id');  

ok($complaint->summary eq "test",'summary properly set');
ok($complaint->video_id eq "video_id",'video_id properly set');

ok($complaint->reason eq "SPAM",'reason properly set by default');

$complaint->reason('VIOLENCE');
ok($complaint->reason eq "VIOLENCE",'reason properly set');

my $expected =q[<entry xmlns="http://www.w3.org/2005/Atom"><summary>test</summary><category scheme="http://gdata.youtube.com/schemas/2007/complaint-reasons.cat" term="VIOLENCE"/></entry>];

ok($complaint->serialize eq $expected,'serialization properly done');


