package Tie::DeepTied;
require Tie::Hash;

use strict qw(vars subs);
use vars qw(@ISA);

@ISA = qw(Tie::Hash);

sub TIEHASH {
    my ($class, $obj, $ind) = @_;
    my $this = {};
    bless $this, $class;
    $this->{'__obj'} = $obj;
    $this->{'__index'} = $ind;
    my $cell = $obj->FETCH($ind);
    $this->{'__storage'} = {%$cell};
    $this;
}

sub STORE {
    my ($this, $key, $value) = @_;
    $this->{'__last'} = time;
    $this->{'__storage'}->{$key} = $value;
    $this->{'__obj'}->STORE($this->{'__index'}, $this->{'__storage'});
    if (UNIVERSAL::isa($value, 'HASH')) {
        unless (tied(%$value)) {
            my %hash = %$value;
            tie %$value, 'Tie::StdHash', $this, $key; # Prevent infinite loop!
            %$value = %hash;
            tie %$value, 'Tie::DeepTied', $this, $key;
        }
    }
}

sub FETCH {
    my ($this, $key) = @_;
    my $value = $this->{'__storage'}->{$key};
    if (UNIVERSAL::isa($value, 'HASH')) {
        unless (tied(%$value)) {
            my %hash = %$value;
            tie %$value, 'Tie::StdHash', $this, $key; # Prevent infinite loop!
            %$value = %hash;
            tie %$value, 'Tie::DeepTied', $this, $key;
        }
    }
    $value;
}

sub DELETE {
    my ($this, $key) = @_;
    delete $this->{'__storage'}->{$key};
}

sub EXISTS {
    my ($this, $key) = @_;
    exists($this->{'__storage'}->{$key});
}

sub CLEAR {
    my $this = shift;
    $this->{'__storage'} = {};
}

sub FIRSTKEY { 
    my $this = shift;
    my $a = scalar keys %{$this->{'__storage'}}; 
    each %{$this->{'__storage'}};
}

sub NEXTKEY { 
    my $this = shift;
    each %{$this->{'__storage'}};
}

1;
