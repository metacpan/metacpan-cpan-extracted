use strict;
use warnings;
use Test::More;
use UniEvent::HTTP;

plan skip_all => 'set WITH_LEAKS=1 to enable leaks test' unless $ENV{WITH_LEAKS};
plan skip_all => 'BSD::Resource required to test for leaks' unless eval {require BSD::Resource; 1};

my $measure = 200;
my $leak = 0;

my @a = 1..100;
undef @a;

for (my $i = 0; $i < 30000; $i++) {
    for (1..10) { my $pool = UE::HTTP::Pool->new; }
    UE::Loop->default_loop->run_nowait;
    
    {
        my $loop = UE::Loop->new;
        for (1..3) { my $pool = UE::HTTP::Pool->new($loop); }
    }
    
    $measure = BSD::Resource::getrusage()->{"maxrss"} if $i == 10000;
}

$leak = BSD::Resource::getrusage()->{"maxrss"} - $measure;
my $leak_ok = $leak < 100;
warn("LEAK DETECTED: ${leak}Kb") unless $leak_ok;
ok($leak_ok);

done_testing();
