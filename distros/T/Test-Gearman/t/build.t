use warnings;
use strict;

use Test::More;
use Test::Gearman;

use Gearman::XS qw(:constants);
use File::Temp qw();
use Carp qw();

my $gearmand_bin = '';
eval {
    my $tg = Test::Gearman->new({
        functions => {
            test1 => sub {},
        },
    });
    $gearmand_bin = $tg->gearmand_bin;
};

plan skip_all => 'Cannot find gearmand binary. You can set it via $ENV{GEARMAND}.' unless $gearmand_bin;

my $tg = Test::Gearman->new(
    functions => {
        test1 => sub {
            my $job = shift;
            return $job->workload;
        },
        test2 => sub {
            my $job = shift;
            my $filename = $job->workload;
            open (my $fh, '>', $filename) or Carp::croak("Cannot open $filename: $!");
            print $fh 'test pass';
            close $fh;
        },
        test3 => sub {
            die 'no work today!';
        },
    },
);

## foreground job test
my ($ret, $result) = $tg->client->do('test1', 'say this');
is $ret, GEARMAN_SUCCESS, 'Return value is success.';
is $result, 'say this', 'Return result is correct.';

## background job test
my $fh = File::Temp->new();
my $filename = $fh->filename;
$fh->close;
my ($ret2, $job_handle) = $tg->client->do_background('test2', $filename);

is $ret, GEARMAN_SUCCESS, 'Return value is success.';
ok $job_handle, 'Have job handle too.';

sleep 1; ## let the background job finish
open (my $fh2, '<', $filename) or Carp::croak("Cannot open $filename: $!");
my $line = <$fh2>;
close $fh2;

is $line, 'test pass', 'Read line from background job successfully.';

done_testing;