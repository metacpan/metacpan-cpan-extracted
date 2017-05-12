use warnings;
use strict;
use Config;


BEGIN {
    if ($Config{'useithreads'}) {
        require threads;
        threads->import;
        require Test::More;
        Test::More->import( tests => 2 );
    }
    else {
        require Test::More;
        Test::More->import(skip_all => "no useithreads");
    }
}


use_ok('Thread::State');

my $thr = threads->new(sub{ sleep 2; return 10; });

is(ref($thr->coderef), "CODE");


for (threads->list){
    $_->join;
}
