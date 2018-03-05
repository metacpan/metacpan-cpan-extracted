package WWW::FCM::HTTP::Response::Result;

use strict;
use warnings;

sub new {
    my ($class, $result) = @_;
    bless $result, $class;
}

sub is_success {
    shift->error ? 0 : 1;
}

sub has_canonical_id {
    shift->registration_id ? 1 : 0;
}

sub message_id {
    shift->{message_id};
}

sub error {
    shift->{error};
}

sub registration_id {
    shift->{registration_id};
}

sub sent_reg_id {
    shift->{_sent_reg_id};
}

1;
