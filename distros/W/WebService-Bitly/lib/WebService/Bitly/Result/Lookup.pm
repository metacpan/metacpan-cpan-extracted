package WebService::Bitly::Result::Lookup;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

use WebService::Bitly::Util;

sub new {
    my ($class, $result_lookup) = @_;
    my $self = $class->SUPER::new($result_lookup);

    $self->{results}
        = WebService::Bitly::Util->make_entries($self->data->{lookup});

    return $self;
}

sub results {
    my $results = shift->{results};
    return wantarray ? @$results : $results;
}

1;
