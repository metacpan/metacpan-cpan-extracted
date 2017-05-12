package ZooKeeper::Test::Utils;
use strict; use warnings;
use Time::HiRes qw(alarm);
use Try::Tiny;
use parent 'Exporter';
our @EXPORT = qw(test_hosts timeout);
our @EXPORT_OK = @EXPORT;

sub test_hosts {
    $ENV{ZOOKEEPER_TEST_HOSTS} // 'localhost:2181';
}

sub timeout (&;$) {
    my ($code, $time) = @_;
    my $timeout = "TIMEOUT\n";

    my $timedout;
    try {
        local $SIG{ALRM} = sub { die $timeout };
        alarm($time // 1);
        $code->();
        alarm(0);
    } catch {
        die $_ unless /^$timeout/;
        $timedout++;
    };
    alarm(0);

    return !!$timedout;
}

1;
