package HTML::HTPL::Table;

use HTML::HTPL::Lib;
use strict;

sub new {
    my $self = {};
    bless $self, shift;
    $self->{'rows'} = [];
    $self->set(@_);
    $self;
}

sub set {
    my $self = shift;
    my %hash = @_;
    foreach (keys %hash) {
        $self->{lc($_)} = $hash{$_};
    }
}

sub add {
    my $self = shift;
    my @cells = @_;
    @cells=@{$cells[0]} if ($#cells == 0 && UNIVERSAL::isa($cells[0], 'ARRAY'));
    push(@{$self->{'rows'}}, \@cells);
}

sub load {
    my ($self, @ary) = @_;
    foreach (@ary) {
        $self->add(@$_);
    }
}

sub push {
    my ($self, @cells) = @_;
    $self->{'curr'} = [] unless ($self->{'curr'});
    my $curr = $self->{'curr'};
    my $cols = $self->{'cols'};
    my $rows = $self->{'rows'};
    foreach (@cells) {
        push(@$rows, []) unless (@{$rows->[-1]} % $cols);
        push(@{$rows->[-1]}, $_);
    }
}

sub flush {
    my $self = shift;
    my $row = $self->{'rows'}->[-1];
    my $cols = $self->{'cols'};
    while (@$row < $cols) {
        push(@$row, undef);
    }
}

sub serialize {
    my $self = shift;
    my $cols = $self->{'cols'};
    my $row;
    my @a;
    foreach $row (@{$self->{'rows'}}) {
        my $i;
        foreach $i ((1 .. $cols)) {
            push(@a, $row->[$i - 1]);
        }
    }
    @a;
}

sub ashtml {
    my $self = shift;
    my $cols = $self->{'cols'};
    my @a = $self->serialize;
    my %copy = %$self;
    delete $copy{'cols'};
    delete $copy{'rows'};
    my $tag = join(' ', (map { uc($_) . '="' . $copy{$_} . '"' } keys %copy));
    &html_table_rows('cols' => $cols, 'tattr' => \%copy, 'noout' => 1,
            'items' => \@a);
}

sub setcell {
    my ($self, $row, $cell, $data) = @_;
    $self->{'rows'}->[$row] = [] unless ($self->{'rows'}->[$row]);
    $self->{'rows'}->[$row]->[$cell] = $data;
}

sub rows {
    my $self = shift;
    scalar(@{$self->{'rows'}});
}

1;
