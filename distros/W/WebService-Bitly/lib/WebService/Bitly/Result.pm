package WebService::Bitly::Result;

use warnings;
use strict;
use Carp;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
    data
    status_code
    status_txt
));

sub new {
    my ($class, $result) = @_;
    my $self = $class->SUPER::new($result);
}

sub is_error {
    my $self = shift;

    return $self->status_code >= 400;
}

1;
