use strict;
use warnings;
defined(my $pid = fork()) or die "Can not fork a child process!";

if (!$pid) {
    system("perl demo7_server.pl");
} else {
    sleep(1);
    system("perl demo7_client.pl");
}

