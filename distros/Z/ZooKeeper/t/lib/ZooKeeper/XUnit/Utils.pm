package ZooKeeper::XUnit::Utils;
use Try::Tiny;
use parent 'Exporter';
our @EXPORT_OK = qw(timeout);

sub timeout {
    my ($time, $code) = @_;
    my $timeout = "TIMEOUT\n";

    my $timedout = try {
        local $SIG{ALRM} = sub { die $timeout };
        alarm($time);
        $code->();
        alarm(0);
    } catch {
        die $_ unless $_ eq $timeout;
    };
    alarm(0);
}

1;
