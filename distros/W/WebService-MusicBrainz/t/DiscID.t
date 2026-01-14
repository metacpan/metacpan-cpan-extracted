use strict;
use Test::More;

use WebService::MusicBrainz;
use Data::Dumper;

my $ws = WebService::MusicBrainz->new();
ok($ws);

my $s1_res = $ws->search(discid => { discid => 'NmFqfPXBZfk05ZpbTcL.IvmEtQY-' });
ok($s1_res->{'offset-count'} eq 16);
ok(@{$s1_res->{offsets}} eq 16);
ok($s1_res->{offsets}->[0] eq 150);
ok($s1_res->{offsets}->[1] eq 20822);
ok($s1_res->{offsets}->[2] eq 39976);
ok($s1_res->{offsets}->[3] eq 57651);
ok($s1_res->{offsets}->[4] eq 82691);
ok($s1_res->{offsets}->[5] eq 97773);
ok($s1_res->{offsets}->[6] eq 116625);
ok($s1_res->{offsets}->[7] eq 140670);
ok($s1_res->{offsets}->[8] eq 160155);
ok($s1_res->{offsets}->[9] eq 183516);
ok($s1_res->{offsets}->[10] eq 194429);
ok($s1_res->{offsets}->[11] eq 210901);
ok($s1_res->{offsets}->[12] eq 228250);
ok($s1_res->{offsets}->[13] eq 246216);
ok($s1_res->{offsets}->[14] eq 272031);
ok($s1_res->{offsets}->[15] eq 285133);
ok($s1_res->{id} eq 'NmFqfPXBZfk05ZpbTcL.IvmEtQY-');
ok($s1_res->{sectors} eq 308410);
ok(@{$s1_res->{releases}} > 0);
ok(not defined @{$s1_res->{releases}}[0]->{'artist-credit'});
sleep(1);

my $s2_res = $ws->search(discid => { discid => 'NmFqfPXBZfk05ZpbTcL.IvmEtQY-', inc => 'artists' });
ok(@{$s2_res->{releases}} > 0);
ok(defined @{$s2_res->{releases}}[0]->{'artist-credit'});
ok(defined @{$s2_res->{releases}}[0]->{'artist-credit'}->[0]->{artist});
ok(@{$s2_res->{releases}}[0]->{'artist-credit'}->[0]->{artist}->{'sort-name'} eq 'Adams, Ryan');

my $s3_res = $ws->search(discid => { discid => 'bfpR1_IguRzV1SbnhoCxyQUkgkM-', inc => ['artist-credits','recordings'] });
ok(@{$s3_res->{releases}} > 0);
ok($s3_res->{releases}[0]->{'artist-credit'} != undef);
ok(@{$s3_res->{releases}[0]->{'media'}} > 0);
ok(@{$s3_res->{releases}[0]->{'media'}[0]->{'tracks'}} > 0);
ok(defined $s3_res->{releases}[0]->{'media'}[0]->{'tracks'}[0]->{'recording'});

done_testing();
