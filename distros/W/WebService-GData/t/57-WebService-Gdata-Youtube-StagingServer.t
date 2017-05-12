use Test::More tests => 5;


use WebService::GData::YouTube::StagingServer;
use WebService::GData::YouTube;
use WebService::GData::YouTube::Feed::Comment;
use WebService::GData::YouTube::Feed::PlaylistLink;
use WebService::GData::YouTube::Feed::Video;

my $yt = new WebService::GData::YouTube(); 

ok($yt->base_uri()=~m/stage./,'youtube base uri is set to the staging server');
ok($WebService::GData::YouTube::Feed::Comment::WRITE_BASE_URI=~m/stage\./,'comment url is set to staging server');
ok($WebService::GData::YouTube::Feed::Video::UPLOAD_BASE_URI =~m/stage\./,'video upload bae uri is set to staging server');
ok($WebService::GData::YouTube::Feed::Video::BASE_URI        =~m/stage\./,'video base uri  is set to staging server');  
ok($WebService::GData::YouTube::Feed::Video::API_DOMAIN_URI  =~m/stage\./,'video api domain uri url is set to staging server');