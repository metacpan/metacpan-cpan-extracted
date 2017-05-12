use strict;
use warnings;

use Test::More;
use Twiggy::Prefork::Server;

{
    my $server = Twiggy::Prefork::Server->new(
        max_reqs_per_child => 100,
    );
    is $server->{max_reqs_per_child}, 100, 'passed max_reqs_per_child';
}

{
    my $server = Twiggy::Prefork::Server->new(
        max_reqs_per_child => 0
    );
    is $server->{max_reqs_per_child}, 0, 'off max_reqs_per_child';
}

{
    my $server = Twiggy::Prefork::Server->new;
    is $server->{max_reqs_per_child}, 100, 'set default value';
}

done_testing;
