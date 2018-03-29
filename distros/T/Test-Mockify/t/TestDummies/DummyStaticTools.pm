package t::TestDummies::DummyStaticTools;
use strict;
use warnings;

sub Tripler ($){
    my ($Value) = @_;
    return $Value * 3;
}
1;