use Test::More;
use FindBin;
use lib $FindBin::Bin;
use CommonSubs;

BEGIN { use_ok ( 'WWW::Weebly' ); }
require_ok ( 'WWW::Weebly' );

my $api = CommonSubs::initiate_api();
my $secret = $ENV{'WEEBLY_SECRET'} || 'mysecretkey';
my $url    = $ENV{'WEEBLY_URL'}    || 'http://testing-weebly.not.real.com';

ok ( defined ($api) && ref $api eq 'WWW::Weebly', "API object creation" );
ok ( $api->get_weebly_secret() eq $secret,  "Weebly Secret");
ok ( $api->get_weebly_url() eq $url, "Weebly Query URL");

done_testing();
