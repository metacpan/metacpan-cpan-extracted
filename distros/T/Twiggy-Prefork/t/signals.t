use strict;
use warnings;
use Test::More;
use Net::EmptyPort qw(empty_port);
use Plack::Loader;
use Test::SharedFork;
use Capture::Tiny qw(tee_stderr);

$ENV{TWIGGY_DEBUG} = 1;

my $max_workers = 2;

my $pid = fork;
!defined $pid
  and die "fork failed:$!";
if ($pid == 0) {
    my $stderr = tee_stderr {
        Plack::Loader->load(
            'Twiggy::Prefork',
            host => '127.0.0.1',
            port => empty_port(),
            max_workers => $max_workers,
        )->run(sub {});
    };
    my @lines = split /\n/, $stderr;
    my @start_lines = grep { $_ =~ /^\[\d+\] start child/ } @lines;
    my @end_lines = grep { $_ =~ /^\[\d+\] end child/ } @lines;
    my @signal_lines = grep { $_ =~ /^\[\d+\] recieved signal/ } @lines;
    is scalar @start_lines, $max_workers * 2, 'start child';
    is scalar @end_lines, $max_workers * 2, 'end child';
    is scalar @signal_lines, $max_workers * 2, 'signal child';
    exit 0;
}
# ping to child process
my $kid;
do {
    $kid = kill 0, $pid;
} while !$kid;
sleep 1; # wait app start
# send signal to child process
kill HUP => $pid;
sleep 1; # wait app start
kill TERM => $pid;
waitpid($pid, 0);

done_testing;
