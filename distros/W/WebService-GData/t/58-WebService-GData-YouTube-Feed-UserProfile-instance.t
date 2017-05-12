use Test::More tests => 24;
use WebService::GData::YouTube::Feed::UserProfile;
use t::UserProfileFeedResponse;
use JSON;

my $profile = new WebService::GData::YouTube::Feed::UserProfile(
    from_json($UserProfileFeedResponse::CONTENTS)->{entry});
    


ok($profile->etag eq "W/\"CUMMRn47eCp7ImA9WhZRFE8.\"",'etag properly set');
ok($profile->updated eq "2011-04-10T01:18:07.000-07:00",'updated properly set');
ok($profile->published eq "2010-04-24T06:09:01.000-07:00",'published properly set');
ok($profile->id eq "tag:youtube.com,2008:user:testing",'id properly set');
ok($profile->category->[1]->term eq "Musician",'term properly set');
ok($profile->title eq "testing Channel",'title properly set');
ok($profile->link->rel('related')->[0]->href eq "http://www.myurl.com",'link properly set');
ok($profile->author->[0]->name eq "withnovo",'name properly set');
ok($profile->author->[0]->uri eq "http://gdata.youtube.com/feeds/api/users/testing",'uri properly set');
ok($profile->feed_links->rel('favorites')->[0]->href eq "http://gdata.youtube.com/feeds/api/users/testing/favorites",'feed_links properly set');
ok($profile->about_me eq "you will learn all about me",'about_me properly set');
ok($profile->first_name eq 'testing','first_name properly set');
ok($profile->last_name eq 'last name','last_name properly set');
ok($profile->age eq '31','age properly set');
ok($profile->username eq 'test','username properly set'); 
ok($profile->gender eq 'm' ,'gender properly set');
ok($profile->hometown eq '“Œ‹ž' ,'hometown properly set');
ok($profile->location eq "“Œ‹ž, JP" ,'location properly set');
ok($profile->thumbnail eq "http://i4.ytimg.com/i/c6H9RSpd0rg/1.jpg",'thumbnail properly set');
ok($profile->statistics->last_web_access eq "2011-04-10T01:12:59.000-07:00",'last_web_access properly set');
ok($profile->statistics->view_count ==657,'view_count properly set');
ok($profile->statistics->subscriber_count==2,'subscriber_count properly set');
ok($profile->statistics->video_watch_count==0,'video_watch_count properly set');
ok($profile->statistics->total_upload_views==1435,'total_upload_views properly set');

=pod
ok($profile->books ,'books properly set');
ok($profile->company ,'company properly set');
ok($profile->hobbies ,'hobbies properly set');
ok($profile->movies,'movies properly set');
ok($profile->music ,'music properly set');
ok($profile->relationship ,'relationship properly set');
ok($profile->occupation ),'occupation properly set';
ok($profile->school,'school properly set');
=cut




