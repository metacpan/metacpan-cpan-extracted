package MyVal::Plugin::Glade;

sub new {

    my ($self, $proto) = @_;

    $proto->stash(smell  => \&smell);
    $proto->stash(squirt => \&squirt);
    $proto->set_method(squash => sub {'abc'});

    return bless {}, $self;

}

sub smell  {'Good'}
sub squirt {1}

1;
