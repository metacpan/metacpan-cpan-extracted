use v5.24;
use warnings;
use fs::Promises qw(stat_promise);
use fs::Promises::Utils qw(await);

use Errno qw(ENOENT);

use Test::More;
use Test::Exception;

use File::Temp;

subtest 'stat' => sub {
    my $does_not_exist = './does_not_exist_for_test';

    throws_ok {
        await stat_promise($does_not_exist)->catch(sub {
            my $errno = shift;
            my $e_str = "$errno";
            my $e_num = 0 + $errno;
            is($e_num, ENOENT, "we got a real errno");
            $! = ENOENT;
            is($e_str, "$!", "...and it is a dualvar with the string representation in it too");
            die "File does not exist";
        })
    } qr/File does not exist/, "stat_profile() fails on a missing file";

    my $file_to_stat = $0;

    my $stat_results;
    lives_ok { $stat_results = await stat_promise($file_to_stat) }
        "can stat an existing file";

    is(@$stat_results, 13, "...and we got a 13-element list!");
};

done_testing;

