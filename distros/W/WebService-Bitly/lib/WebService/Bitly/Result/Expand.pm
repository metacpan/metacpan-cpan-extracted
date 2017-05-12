package WebService::Bitly::Result::Expand;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

use WebService::Bitly::Util;

sub new {
    my ($class, $result_expand) = @_;
    my $self = $class->SUPER::new($result_expand);

    $self->{results}
        = WebService::Bitly::Util->make_entries($self->data->{expand});

    return $self;
}

sub results {
    my $results = shift->{results};
    return wantarray ? @$results : $results;
}

1;
