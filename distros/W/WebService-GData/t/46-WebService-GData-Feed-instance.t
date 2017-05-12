use Test::More tests => 31;
use WebService::GData::Feed;
use t::JSONResponse;
use JSON;


my $feed = new WebService::GData::Feed( from_json($JSONResponse::CONTENTS) );

ok($feed->title eq "YouTube Videos",'feed title properly set.');

ok($feed->id eq "tag:youtube.com,2008:videos",'feed id properly set.');

ok($feed->updated eq "2010-10-11T06:03:31.584Z",'feed updated properly set.');

ok($feed->etag eq "W/\"DUcFQHszfCp7ImA9Wx5VF0o.\"",'feed etag properly set.');

ok($feed->total_items == 1000000,'feed total_items properly set.');

ok($feed->total_results == 1000000,'feed total_results properly set.');

ok($feed->start_index == 1,'feed start_index properly set.');

ok($feed->items_per_page == 1,'feed items_per_page properly set.');

ok($feed->category->[0]->scheme eq "http://schemas.google.com/g/2005#kind",'feed category scheme properly set.');

ok($feed->category->[0]->term eq "http://gdata.youtube.com/schemas/2007#video",'feed category term properly set.');

ok($feed->author->[0]->name eq "YouTube",'feed author name properly set.');

ok($feed->author->[0]->uri eq "http://www.youtube.com/",'feed author uri properly set.');

ok(@{$feed->links} ==6,'feed link properly set.');

ok($feed->next_link eq "http://gdata.youtube.com/feeds/api/videos?alt=json&start-index=2&max-results=1&client=ytapi-google-jsdemo",'next_link properly set.');

ok(!$feed->previous_link,'previous_link properly set.');

my $entries = $feed->entry('WebService::GData::Feed::Entry'); 
ok(@{$entries}==1,'entries properly set.');

my $entry = $entries->[0];


ok($entry->isa('WebService::GData::Feed::Entry'),'Entry has been set to the defined class.');

ok($entry->title eq "Young Turks Episode 10-07-09",'$entry title properly set.');

ok($entry->id eq "tag:youtube.com,2008:video:qWAY3YvHqLE",'$entry id properly set.');

ok($entry->updated eq "2010-08-27T14:29:38.000Z",'$entry updated properly set.');

ok($entry->published eq "2009-10-08T04:39:24.000Z",'$entry published properly set.');

ok($entry->etag eq "W/\"A0QDSX47eCp7ImA9Wx5RGUw.\"",'$entry etag properly set.');




ok($entry->author->[0]->name eq "TheYoungTurks",'entry author name properly set.');

ok($entry->author->[0]->uri eq "http://gdata.youtube.com/feeds/api/users/theyoungturks",'entry author uri properly set.');

ok(@{$entry->links} ==6,'entry link properly set.');

ok(@{$entry->category} ==30,'entry category properly set.');

ok($entry->category->[3]->term eq 'young','entry category third element properly set.');

ok($entry->content({})->src eq "http://www.youtube.com/v/qWAY3YvHqLE?f=videos&c=ytapi-google-jsdemo&app=youtube_gdata",'entry content src properly set.');

ok($entry->content({})->type eq "application/x-shockwave-flash",'entry content type properly set.');

ok($entry->content_source eq "http://www.youtube.com/v/qWAY3YvHqLE?f=videos&c=ytapi-google-jsdemo&app=youtube_gdata",'entry content_source properly set.');

ok($entry->content_type eq "application/x-shockwave-flash",'entry content_type properly set.');

