package Tie::Parent;

use strict;

sub TIESCALAR {
    my $class = shift;
    my ($obj, $field) = @_;
    my $this = {'obj' => $obj, 'field' => $field};
    bless $this, $class;
}

sub FETCH {
    my $this = shift;
    return $this->{'obj'}->{$this->{'field'}} ||
             $this->{'obj'}->{uc($this->{'field'})} ||
             $this->{'obj'}->{lc($this->{'field'})};
}

sub STORE {
    my ($this, $value) = @_;
    $this->{'obj'}->{$this->{'field'}} = $value;
}

1;
