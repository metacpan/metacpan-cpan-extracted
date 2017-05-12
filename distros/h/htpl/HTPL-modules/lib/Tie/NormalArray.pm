package Tie::NormalArray;

use strict;

sub TIEARRAY {
    my ($class, $shadow) = @_;
    my $self = bless {'shadow' => $shadow}, $class;
    $self->size;
    $self;
}

sub FETCH {
    my ($self, $index) = @_;
    $self->{'shadow'}->FETCH($index);
}

sub STORE {
    my ($self, $index, $value) = @_;
    my $flag = $self->{'shadow'}->EXISTS($index);
    $self->{'shadow'}->STORE($index, $value);
    $self->{'size'}++ unless ($flag);
}

sub DESTROY {
    my $self = shift;
    undef $self->{'shadow'};
}

sub size {
    my $self = shift;
    my $size = 0;
    my $obj = $self->{'shadow'};
    my ($k, $v) = $obj->FIRSTKEY;
    my %hash;
    $hash{int($k)} = 1;
    while (($k, $v) = $obj->NEXTKEY) {
        $hash{int($k)} = 1;
    }
    my @keys = sort {$b <=> $a} keys %hash;
    $self->{'size'} = $keys[0] + 1;
}

sub FETCHSIZE {
    my $self = shift;
    $self->{'size'};
}

sub STORESIZE {
    my ($self, $size) = @_;
    my $current = $self->FETCHSIZE;
    while ($current < $size) {
        $self->STORE($current++, undef);
    }
    while ($current > $size) {
        $self->{'shadow'}->DELETE(--$current);
    }
    $self->{'size'} = $size;
}

1;

