package WebService::GData::YouTube::YT::Statistics;
use WebService::GData::YouTube::YT;

set_meta(
  attributes=>[qw(viewCount videoWatchCount subscriberCount lastWebAccess favoriteCount totalUploadViews)],
  is_parent =>0
);


1;