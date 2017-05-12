package t::UsesData;
use strict;
use warnings;

my $data;
sub get_data {
    return $data if $data;
    local $/;
    return $data = <DATA>;
}

1;
__DATA__
abc
