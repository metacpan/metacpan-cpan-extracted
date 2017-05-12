package WebService::Bitly::Result::HTTPError;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_error) = @_;
    my $self = $class->SUPER::new($result_error);
}

sub is_error {
    return 1;
}

1;
