package TestClass;

sub new {
    my $class = shift;
    #print "$class constructor called\n";
    return bless { }, $class;
}

sub foo {
    my $self = shift;
    #print "$self->foo called\n";
    my $old = $self->{foo};
    $self->{foo} = shift if @_;
    $old;
}

sub newhash {
    my $self = shift;
    return { @_ };
}

sub hash_deref {
    my $self = shift;
    my $hash = shift;
    my $key  = shift;
    #print "$self->hash_deref($hash, '$key')\n";
    $hash->{$key};
}

sub callback {
    my $self = shift;
    my $obj  = shift;
    my $meth = shift;

    $obj->$meth(@_);
}

sub localtime { CORE::localtime; }

sub error {
    my $self = shift;
    die "Failed: " . shift;
}

sub dump {
    my $self = shift;
    require Data::Dumper;
    print Dumper ($self), "\n";
}

1;
