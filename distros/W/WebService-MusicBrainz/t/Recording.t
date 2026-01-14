use strict;
use Test::More;

use WebService::MusicBrainz;

sub exit_if_mb_busy {
   my $res = shift;
   if(exists $res->{error} && $res->{error} =~ m/^The MusicBrainz web server is currently busy/) {
      done_testing();
      exit(0);
   }
}

my $ws = WebService::MusicBrainz->new();
ok($ws);

# JSON TESTS
my $s1_res = $ws->search(recording => { artist => 'Taylor Swift', release => '1989' });
exit_if_mb_busy($s1_res);
ok($s1_res->{count} > 70);
sleep(1);

my $s2_res = $ws->search(recording => { mbid => '1d43314e-1d7a-4aef-942e-799370be2b15' });
exit_if_mb_busy($s2_res);
ok($s2_res->{length} == 242000);
sleep(1);

my $s3_res = $ws->search(recording => { mbid => '1d43314e-1d7a-4aef-942e-799370be2b15', inc => 'artists' });
exit_if_mb_busy($s3_res);
ok($s3_res->{'artist-credit'}->[0]->{name} eq 'Taylor Swift');

done_testing();
