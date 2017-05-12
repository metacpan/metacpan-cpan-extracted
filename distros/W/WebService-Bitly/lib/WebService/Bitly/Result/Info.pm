package WebService::Bitly::Result::Info;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

use WebService::Bitly::Util;

sub new {
    my ($class, $result_info) = @_;
    my $self = $class->SUPER::new($result_info);

    $self->{results}
        = WebService::Bitly::Util->make_entries($self->data->{info});

    return $self;
}

sub results {
    my $results = shift->{results};
    return wantarray ? @$results : $results;
}

1;
