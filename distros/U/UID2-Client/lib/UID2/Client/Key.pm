package UID2::Client::Key;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw(id site_id created activates expires secret)],
);
use UID2::Client::Timestamp;

sub is_active {
    my ($self, $now) = @_;
    $now //= UID2::Client::Timestamp->now;
    $self->activates <= $now->get_epoch_second && $now->get_epoch_second < $self->expires;
}

1;
__END__
