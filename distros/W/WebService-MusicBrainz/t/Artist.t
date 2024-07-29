use strict;
use Test::More;
use Data::Dumper;

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
my $s1_res = $ws->search(artist => { mbid => '070d193a-845c-479f-980e-bef15710653e' });
exit_if_mb_busy($s1_res);

ok($s1_res->{type} eq 'Person');
ok($s1_res->{'sort-name'} eq 'Prince');
ok($s1_res->{name} eq 'Prince');
ok($s1_res->{country} eq 'US');
ok($s1_res->{gender} eq 'Male');
sleep(1);

my $s2_res = $ws->search(artist => { mbid => '070d193a-845c-479f-980e-bef15710653e', inc => 'releases' });
exit_if_mb_busy($s2_res);

ok($s2_res->{type} eq 'Person');
ok(exists $s2_res->{releases});
ok($s2_res->{name} eq 'Prince');
sleep(1);

my $s3_res = $ws->search(artist => { mbid => '070d193a-845c-479f-980e-bef15710653e', inc => ['releases','aliases'] });
exit_if_mb_busy($s3_res);
ok(exists $s3_res->{releases});
ok(exists $s3_res->{aliases});
sleep(1);

eval {
    my $s4_res = $ws->search(artist => { mbid => '070d193a-845c-479f-980e-bef15710653e', inc => 'nothing-here' });
    exit_if_mb_busy($s4_res);
};
like($@, qr/not a valid.*inc.*subquery/i);
sleep(1);

my $s5_res = $ws->search(artist => { artist => 'Coldplay' });
exit_if_mb_busy($s5_res);
ok($s5_res->{artists});
ok($s5_res->{artists}->[0]->{name} eq 'Coldplay');
ok($s5_res->{artists}->[0]->{score} eq '100');
sleep(1);

my $s6_res = $ws->search(artist => { artist => 'Van Halen', type => 'group' });
exit_if_mb_busy($s6_res);
ok($s6_res->{count} >= 1);
ok($s6_res->{artists}->[0]->{type} eq 'Group');
ok($s6_res->{artists}->[0]->{id} eq 'b665b768-0d83-4363-950c-31ed39317c15');
sleep(1);

my $s7_res = $ws->search(artist => { artist => 'Ryan Adams', type => 'person' });
exit_if_mb_busy($s7_res);
ok($s7_res->{artists}->[0]->{'sort-name'} eq 'Adams, Ryan');
sleep(1);

my $s8_res = $ws->search(artist => { artist => 'red' });
exit_if_mb_busy($s8_res);
ok($s8_res->{count} >= 1700);
ok($s8_res->{offset} == 0);
sleep(1);

my $s9_res = $ws->search(artist => { artist => 'red', offset => 30 });
exit_if_mb_busy($s9_res);
ok($s9_res->{count} >= 1700);
ok($s9_res->{offset} == 30);
sleep(1);

# XML TESTS
my $s1_dom = $ws->search(artist => { mbid => '070d193a-845c-479f-980e-bef15710653e', fmt => 'xml' });
exit_if_mb_busy($s1_dom);
ok($s1_dom->at('sort-name')->text eq 'Prince');
sleep(1);

my $s2_dom = $ws->search(artist => { artist => 'Ryan Adams', type => 'person', fmt => 'xml' });
exit_if_mb_busy($s2_dom);
ok($s2_dom->at('country')->text eq 'US');

done_testing();
