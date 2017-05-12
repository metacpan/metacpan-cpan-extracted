package cPanel::FakeLogger;

# Mock version of a Logger class to be used in testing the logging policy code
# for StateFile and TaskQueue.

sub new {
    my ($class) = @_;

    return bless { msgs => [] }, $class;
}

sub reset_msgs {
    my ($self) = @_;
    $self->{msgs} = [];
    return;
}

sub get_msgs {
    my ($self) = @_;
    return @{$self->{msgs}};
}


sub throw {
    my $self = shift;
    push @{$self->{msgs}}, "throw: @_";
    die @_;
}

sub warn {
    my $self = shift;
    push @{$self->{msgs}}, "warn: @_";
    return;
}

sub info {
    my $self = shift;
    push @{$self->{msgs}}, "info: @_";
    return;
}

sub notify {
    my $self = shift;
    my $subj = shift;
    push @{$self->{msgs}}, "notify: [$subj] @_";
}

1;
