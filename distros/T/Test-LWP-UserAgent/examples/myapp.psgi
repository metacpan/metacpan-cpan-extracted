use strict;
use warnings;

sub {
    my $env = shift;

    return [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [ 'You sent me the path ' . $env->{PATH_INFO} . '.' ],
    ];
}
