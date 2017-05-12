package WebService::Bitly::Util;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Entry;

sub make_entries {
    my ($class, $entries) = @_;
    my $results;

    for my $entry (@$entries) {
        push @$results, WebService::Bitly::Entry->new($entry);
    }

    return $results;
}

1;
