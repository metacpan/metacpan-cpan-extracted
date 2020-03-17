use strict;

package Talkers;

sub echo {
    my $sock = $_[0];
    while (read $sock, my $data, 1) {
        print $sock $data;
    }
}

sub make_writer {
    my $line = $_[0];
    return sub {
        my $s = $_[0];
        print $s $line;
    }
}

1;
