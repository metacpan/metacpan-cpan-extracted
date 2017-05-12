use Test::More tests => 1;
use WebService::GData::YouTube::YT::AboutMe;
use WebService::GData::Serialize;
my $aboutme = new WebService::GData::YouTube::YT::AboutMe();
    
   $aboutme->text('I am very funny.');

ok(WebService::GData::Serialize->to_xml($aboutme) eq q[<yt:aboutMe>I am very funny.</yt:aboutMe>],'AboutMe is properly set.');


