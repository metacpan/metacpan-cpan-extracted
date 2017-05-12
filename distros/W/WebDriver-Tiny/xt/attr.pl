use strict;
use utf8;
use warnings;

my $number = re qr/^[\d.]+$/;

sub {
    my $elem = shift->('h1');

    cmp_deeply $elem->location, { 'x', $number, 'y', $number }, 'location';

    cmp_deeply $elem->location_in_view, { 'x', $number, 'y', $number },
        'location_in_view';
}
