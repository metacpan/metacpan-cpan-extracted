use strict;
use Test::More;

use WebService::MusicBrainz;
use Data::Dumper;

my $ws = WebService::MusicBrainz->new();
ok($ws);

# JSON TESTS
my $s1_res = $ws->search(label => { label => 'original', country => 'US' });
ok($s1_res->{count} > 5);
sleep(1);

foreach my $label (@{ $s1_res->{labels} }) {
    ok($label->{name} =~ m/original/i);
}

done_testing();
