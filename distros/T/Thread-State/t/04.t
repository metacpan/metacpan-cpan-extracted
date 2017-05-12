use warnings;
use strict;
use Config;


BEGIN {
    if ($Config{'useithreads'}) {
        require threads;
        threads->import;
        require Test::More;
        Test::More->import( tests => 3 );
    }
    else {
        require Test::More;
        Test::More->import(skip_all => "no useithreads");
    }
}


use_ok('Thread::State');

my $thr = threads->new(sub{ sleep 1; });
my $pri = $thr->priority;

like($pri, qr/\d+/, "get priority");
is($thr->priority(0), $pri, "set priority");

for (threads->list){
    $_->join;
}
