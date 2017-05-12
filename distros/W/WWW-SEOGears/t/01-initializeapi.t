use Test::More;
use FindBin;
use lib $FindBin::Bin;
use CommonSubs;

BEGIN { use_ok ( 'WWW::SEOGears' ); }
require_ok ( 'WWW::SEOGears' );

my $api = CommonSubs::initiate_api();
my $brandname = $ENV{'SEOGEARS_BRANDNAME'} || 'mybrandname';
my $brandkey  = $ENV{'SEOGEARS_BRANDKEY'}  || 'mybrandkey';

ok ( defined ($api) && ref $api eq 'WWW::SEOGears', "API object creation" );
ok ( $api->get_brandname eq $brandname,  "Brandname value");
ok ( $api->get_brandkey eq $brandkey, "Brandkey value");

done_testing();