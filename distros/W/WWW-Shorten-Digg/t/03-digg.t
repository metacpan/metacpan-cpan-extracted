use strict;
use warnings;

use Test::More;

my $res = try_use('WWW::Shorten::Digg');
like($res, qr/inactive/, "Service correctly reports it is inactive.");

done_testing();

sub try_use {
    my $module = shift;
    return do {
        local $@;
        $module =~ s/::/\//g;
        eval { require "$module.pm"; };
        $@;
    };
}
