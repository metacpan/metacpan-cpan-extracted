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
my $s1_res = $ws->search(label => { label => 'original', country => 'US' });
exit_if_mb_busy($s1_res);
ok($s1_res->{count} > 5);
sleep(1);

foreach my $label (@{ $s1_res->{labels} }) {
    ok($label->{name} =~ m/original/i);
}

done_testing();
