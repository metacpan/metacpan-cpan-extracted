use Test::More tests => 1;
use WebService::GData::YouTube::YT::AccessControl;
use WebService::GData::Serialize;
my $accessControl = new WebService::GData::YouTube::YT::AccessControl();
    
   $accessControl->action('comment');
   $accessControl->permission('allowed');

ok(WebService::GData::Serialize->as_xml($accessControl) eq q[<yt:accessControl action="comment" permission="allowed"/>],'$accessControl is properly set.');
