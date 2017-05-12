BEGIN {
    use Config;
    if (!$Config{useithreads}) {
        print ("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit 0;
    }
}
use strict;
use threads;
use warnings;
use Test::More qw(no_plan);
BEGIN { use_ok('Thread::Pool::Simple') };

my $pool = Thread::Pool::Simple->new(min => 5,
                                     load => 5,
                                     max => 10,
                                     do => [sub { return @_; }],
                                    );


for (1..300) {
    my @arg = (1, 2, 3);
    my ($id, @ret);
    $pool->add(@arg);

    ($id) = $pool->add(@arg);
    @ret = $pool->remove($id);
    ok("@ret" eq "@arg");

    ($id) = $pool->add(@arg);
    $pool->cancel($id);
    @ret = $pool->remove($id);
    ok(!@ret);

    $id = $pool->add(@arg);
    @ret = $pool->remove($id);
    ok($ret[0] == 3);
}

$pool->join();
