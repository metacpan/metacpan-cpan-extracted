package WebService::Bitly::Result::Validate;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_validate) = @_;
    my $self = $class->SUPER::new($result_validate);
}

sub is_valid {
    my $self = shift;
    return 0 if $self->is_error;
    return $self->data->{valid};
}

1;
