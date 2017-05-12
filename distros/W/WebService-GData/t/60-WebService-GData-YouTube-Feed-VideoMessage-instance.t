use Test::More tests => 3;
use WebService::GData::YouTube::Feed::VideoMessage;


my $message = new WebService::GData::YouTube::Feed::VideoMessage({});
$message->summary('test');
$message->id('video_id');  

ok($message->summary eq "test",'summary properly set');
ok($message->id eq "video_id",'video_id properly set');


my $expected =q[<entry xmlns="http://www.w3.org/2005/Atom"><summary>test</summary><id>video_id</id></entry>];

ok($message->serialize eq $expected,'serialization properly done');

