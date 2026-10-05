package Test::UnblockHTTP2;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(pump_until pump_until_idle);

sub _transfer {
    my ($from, $to) = @_;
    my $moved = 0;

    while ($from->want_write) {
        my $bytes = $from->output;
        last unless length $bytes;
        $to->input($bytes);
        $moved += length $bytes;
    }

    return $moved;
}

sub pump_until_idle {
    my ($client, $server) = @_;

    my $total = 0;
    for (1 .. 1000) {
        my $moved = 0;
        $moved += _transfer($client, $server);
        $moved += _transfer($server, $client);
        $total += $moved;
        return $total unless $moved;
    }

    die 'in-memory HTTP/2 pair did not become idle';
}

sub pump_until {
    my ($client, $server, $condition) = @_;

    die 'pump_until requires a condition coderef'
        unless ref($condition) eq 'CODE';

    for (1 .. 1000) {
        return 1 if $condition->();

        my $moved = 0;
        $moved += _transfer($client, $server);
        $moved += _transfer($server, $client);

        return 1 if $condition->();
        die 'in-memory HTTP/2 pair stalled before condition'
            unless $moved;
    }

    die 'in-memory HTTP/2 pair exceeded pump limit';
}

1;
