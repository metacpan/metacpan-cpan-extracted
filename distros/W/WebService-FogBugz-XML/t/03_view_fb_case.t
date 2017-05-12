use v5.10;

use lib './lib';

use WebService::FogBugz::XML;
my $fb = WebService::FogBugz::XML->new();

use Test::More;
if ($ENV{AUTOMATED_TESTING} && !-e $fb->config_filename){
    plan skip_all => "No fogbugz config file, and no user to provide config";
}
else {
    plan tests => 3;
}

# Lots of groundwork done! This probably needs a lot of abstracting...
# Now let's get the actual testing done...
my $case = $fb->get_case(1);
ok($case, 'Got valid case');
isa_ok($case, 'WebService::FogBugz::XML::Case');
ok($case->title => "Got a title: ".$case->title);
