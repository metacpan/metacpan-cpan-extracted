use Test::More;
use Test::RequiresInternet;
BEGIN { plan tests => 10 }
use WebService::UrbanDictionary;

my $ud = WebService::UrbanDictionary->new;

ok(defined $ud);

my $data = $ud->request("perl");

ok(defined $data);

ok($data->definition =~ m/pur'-el/);

my @defs = @{$data->definitions};

ok($defs[0]->defid =~ m/[0-9]*/);
ok($defs[0]->word =~ m/perl/);
ok($defs[0]->author =~ m/Snoobo/);
ok($defs[0]->permalink =~ m/http:\/\//);
ok($defs[0]->example =~ m/Whew,/);
ok($defs[0]->thumbs_up =~ m/[0-9]*/);
ok($defs[0]->thumbs_down =~ m/[0-9]*/);
