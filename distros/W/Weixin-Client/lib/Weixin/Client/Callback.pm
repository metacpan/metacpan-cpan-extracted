package Weixin::Client::Callback;
sub on_run :lvalue {
    my $self = shift;
    $self->{on_run};
}

sub on_receive_msg:lvalue {
    my $self = shift;
    $self->{on_receive_msg};
}

sub on_send_msg :lvalue {
    my $self = shift;
    $self->{on_send_msg};
}

1;
