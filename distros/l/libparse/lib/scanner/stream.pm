package Scanner::Stream;

# $Revision:   1.1  $

=head1 NAME 

Stream - provide basic behavior for scanner streams

=cut

require 5.001;

sub new {
    # Buffer, index, length, linenum, charpos, INPUT (used by derived),
    # CODE ref to GetLine method of derived, input is still valid
    my $self = [ undef, 0, 0, 0, undef, $_[1] ];
    bless $self;
    return $self;
}

sub next {
    my $self = $_[0];
    $self->[0] = &{$self->[5]}($self);
    $self->[3]++;
    $self->[2] = length($self->[0]);
    $self->[1] = 0;
}

sub Match {
    if (substr($_[0][0], $_[0][1]) =~ /^$_[1]/) {
        ${_[0]}->Skip(length $&);
        ${$_[2]} = $&;
        return 1;
    }
    return 0;
}

sub GetChar {
    my $c = substr($_[0][0], $_[0][1], 1);
    ${_[0]}->Skip(1);
    return $c;
}

sub Skip {
    my $self = $_[0];
    $self->[1] += $_[1];
    if ($self->[1] == $self->[2]) {
        $self->next();
    }
    elsif ($self->[1] > $self->[2]) {
        die "Length of input exceeded";
    }
}

sub Backup {
    my $self = $_[0];
    $self->[1] -= $_[1];
    if ($self->[1] < 0) {
        die "Can't backup before beginning of line";
    }
}

sub Valid {
    return ${_[0]}->[2];
}

sub Line {
    return ${_[0]}->[3];
}

sub Charpos {
    return ${_[0]}->[1];
}

sub Context {
    my $self = $_[0];
    my $line;
    if ($self->[1] > 2) {
        $line = (" " x ($self->[1] - 3)) . "--^";
    } else {
        $line = (" " x ($self->[1] - 1)) . "^--";
    }
    return $self->[0] . $line . "\n";
}

1;
