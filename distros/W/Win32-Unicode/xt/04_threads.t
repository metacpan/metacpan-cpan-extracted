use strict;
use warnings;
use Test::More;
use threads;
use Win32::Unicode::Native;

plan skip_all => 'TODO';

my @threads;
for (1..20) {
    push @threads, threads->create(sub{
        note "spawned thread : " . threads->tid;
        my $tid = threads->tid;
        find +{
            wanted => sub {
                note sprintf 'spawned thread : %02d ( file: %s )', $tid, $_[0]->{path};
            },
            no_chdir => 1,
        }, 'lib';
    });
}

for my $thr (@threads) {
    note "joining thread : " . $thr->tid;
    $thr->join;
}

ok 1;

done_testing;
