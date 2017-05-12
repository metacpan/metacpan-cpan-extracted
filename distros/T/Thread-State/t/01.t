use warnings;
use strict;
use Config;

BEGIN {
    if ($Config{'useithreads'}) {
        require threads;
        threads->import;
        require Test::More;
        Test::More->import( tests => 40 );
    }
    else {
        require Test::More;
        Test::More->import(skip_all => "no useithreads");
    }
}


use_ok('Thread::State');

my $threads_version = threads->VERSION;

ok( threads->is_detached, "main thread is detached");

SKIP:
{
    skip "more than threads 1.34, can't use threads->is_running", 1
                                    if($threads_version >= 1.34);
   ok( threads->is_running , "main thread is running");
}

ok(!threads->is_finished, "main thread is not finished");

SKIP:
{
    skip "more than threads 1.34, can't use threads->is_joinable", 1
                                    if($threads_version >= 1.34);
    ok(!threads->is_joinable, "main thread is not joinable");
}


ok(!threads->is_joined  , "main thread is not joined");



my $thr = threads->new(sub{
    is(threads->tid, 1, "new thread tid 1");
    ok(!threads->is_detached, "thread 1 is not detached in itself");

    SKIP:
    {
        skip "more than threads 1.34, can't use threads->is_running", 1
                                    if($threads_version >= 1.34);
       ok( threads->is_running , "thread 1 is running in itself");
    }

    ok(!threads->is_finished, "thread 1 is not finished in itself");

    SKIP:
    {
        skip "more than threads 1.34, can't use threads->is_joinable", 1
                                    if($threads_version >= 1.34);
        ok(!threads->is_joinable, "thread 1 is not joinable in itself");
    }


    ok(!threads->is_joined,   "thread 1 is not joined in itself");
    ok( threads->is_not_joined_nor_detached(),
                              "thread 1 is not joined nor detached in itself");
});

sleep 1;

    ok(!$thr->is_detached, "thread 1 is not detached");
    ok(!$thr->is_running , "thread 1 is not running");
    ok( $thr->is_finished, "thread 1 is finished");
    ok( $thr->is_joinable, "thread 1 is joinable");
    ok(!$thr->is_joined,   "thread 1 is not joined");

$thr->join;

    ok(!$thr->is_detached,  "thread 1 is not detached");
    ok(!$thr->is_running ,  "thread 1 is not running");
    ok( $thr->is_finished,  "thread 1 is finished");

SKIP:
{
#    skip "join does not work correctly in Perl 5.8.0", 2 unless($] >= 5.008001);
    ok(!$thr->is_joinable,  "thread 1 is not joinable");
    ok( $thr->is_joined  ,  "thread 1 is joined");
}

$thr = threads->new(sub{
    is(threads->tid, 2, "new thread tid 2");
    ok(!threads->is_detached, "thread 2 is not detached in itself");

    SKIP:
    {
        skip "more than threads 1.34, can't use threads->is_running", 1
                                    if($threads_version >= 1.34);
       ok( threads->is_running , "thread 2 is running in itself");
    }

    ok(!threads->is_finished, "thread 2 is not finished in itself");

    SKIP:
    {
        skip "more than threads 1.34, can't use threads->is_joinable", 1
                                    if($threads_version >= 1.34);
        ok(!threads->is_joinable, "thread 2 is not joinable in itself");
    }

    ok(!threads->is_joined,   "thread 2 is not joined in itself");
    ok( threads->is_not_joined_nor_detached(),
                              "thread 2 is not joined nor detached in itself");
});

sleep 2;

    ok(!$thr->is_detached,  "thread 2 is not detached");
    ok(!$thr->is_running ,  "thread 2 is not running");
    ok( $thr->is_finished,  "thread 2 is finished");
    ok( $thr->is_joinable,  "thread 2 is joinable");
    ok(!$thr->is_joined  ,  "thread 2 is not joined");

$thr->detach;

    ok( $thr->is_detached,  "thread 2 is detached");
    ok(!$thr->is_running ,  "thread 2 is not running");
    ok( $thr->is_finished,  "thread 2 is finished");

    ok(!$thr->is_joinable,  "thread 2 is not joinable");
    ok(!$thr->is_joined  ,  "thread 2 is not joined");




