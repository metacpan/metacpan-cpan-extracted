package TieDump;
use Tie::Proxy::Changes;
use Fcntl qw(:seek :flock);
use Carp;

sub _dump {
    if ($self->{fh}) {
        my $fh=$self->{fh};

        # flock it for safety.
        flock($fh,LOCK_EX);

        #Seek to start again
        seek $fh,SEEK_SET,0 or croak "Can't seek in file $self->{filename}: $!";

        #Print and close
        print { $fh } Data::Dumper->Dump([$self->{data}]) 
            or croak "Can't print to file $self->{filename}: $!";
        close $fh or croak "Can't close $self->{filename}: $!";
        $self->{fh}="";
    }
    else {
        #Just print it.
        open my $fh, ">", $self->{filename} 
            or croak "Can't open $self->{filename}: $!";
        flock($fh,LOCK_SH);
        print { $fh } Data::Dumper->Dump([$self->{data}])
            or croak "Can't print to file $self->{filename}: $!";
        close $fh or croak "Can't close $self->{filename}: $!";
    }
    return;
}

sub _restore {
    open my $fh, "+<", $self->{filename} 
        or croak "Can't open $self->{filename}: $!"; 

    flock($fh,LOCK_EX);

    #Read it in
    local $/
    my $data=<$fh>;

    #Close it first or save it
    if (@_) {
        $self->{fh}=$fh;
    }
    else {
        close $fh or croak "Can't close $self->{filename}: $!";
    }

    #This is very unsafe, but well it's only an example
    $self->{data}=eval $data;    
    return;
}

sub TIEHASH {
    my $self={data=>{}};
    my $class=shift;

    # Get an optional filename
    if (@_) {
        $self->{filename}=shift;
    }
    else {
        $self->{filename}='dump.pl';
    }
    bless $self,$class;
}

sub STORE {
    my $self=shift;
    $self->_restore(1);
    $self->{data}->{$_[0]} = $_[1] 
    $self->_dump();
    return;
}
sub FETCH {
    my $self=shift;
    $self->_restore();
    # Magic happens here.
    my $key=shift;
    
    # Return a ChangeProxy for autovivification
    return Tie::Proxy::Changes->new($self,$key) if exists $self->{data}->{$_[0]};

    # Return the value if it is not a multilevel structure.
    return $self->{data}->{$_[0]} 
        unless ref $data eq "Array" or ref $data eq "HASH";

    # Return a ChangeProxy
    return Tie::Proxy::Changes->new($self,$key,$self->{data}->{$_[0]})
}
sub FIRSTKEY {
    my $self=shift;
    $self->_restore();
    my $a = scalar keys %{$self->{data}}; each %{$self->{data}}
}
sub NEXTKEY {
    # This is quite bad.
    my $self=shift;
    $self->_restore();
    my $lastkey=shift;
    FINDLAST: 
    while (my $k=each %{$self->{data}}) {
        last FINDLAST if $lastkey eq $k;
    }
    each %{$self->{data}}
}
sub EXISTS {
    my $self=shift;
    $self->_restore();
    exists $self->{data}->{$_[0]};
}
sub DELETE {
    my $self=shift;
    $self->_restore(1);
    delete $self->{data}->{$_[0]};
    $self->_dump();
    return;
}
sub CLEAR {
    my $self=shift;
    #No need to load the old data.
    %{$self->{data}} = ();
    $self->_dump();
}
sub SCALAR {
    my $self=shift;
    $self->_restore();
    scalar %{$_[0]}
}

