use warnings;
use strict;
use Config;


BEGIN {
    if ($Config{'useithreads'}) {
        require threads;
        threads->import;
        require Test::More;
        Test::More->import( tests => 10 );
    }
    else {
        require Test::More;
        Test::More->import(skip_all => "no useithreads");
    }
}


use_ok('Thread::State');

my $thr = threads->new(sub{ 1; });

ok(defined $thr->in_context);
ok(defined $thr->wantarray);
ok(! $thr->in_context);

($thr) = threads->new(sub{ 1,2,3; });

ok(defined $thr->in_context);
ok(defined $thr->wantarray);
ok($thr->in_context);
ok($thr->wantarray);

threads->new(sub{ });

ok(!defined threads->object(3)->in_context);
ok(!defined threads->object(3)->wantarray);

for (threads->list){
    $_->join;
}
