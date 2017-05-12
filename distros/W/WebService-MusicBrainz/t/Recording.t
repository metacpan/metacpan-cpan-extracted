use strict;
use Test::More;

use WebService::MusicBrainz;
use Data::Dumper;

my $ws = WebService::MusicBrainz->new();
ok($ws);

# JSON TESTS
my $s1_res = $ws->search(recording => { artist => 'Taylor Swift', release => '1989' });
ok($s1_res->{count} > 70);
sleep(1);

my $s2_res = $ws->search(recording => { mbid => '1d43314e-1d7a-4aef-942e-799370be2b15' });
ok($s2_res->{length} == 233000);
sleep(1);

my $s3_res = $ws->search(recording => { mbid => '1d43314e-1d7a-4aef-942e-799370be2b15', inc => 'artists' });
ok($s3_res->{'artist-credit'}->[0]->{name} eq 'Taylor Swift');

done_testing();
