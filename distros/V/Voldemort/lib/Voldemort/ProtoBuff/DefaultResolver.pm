package Voldemort::Protobuff::DefaultResolver;

use Moose;
use Voldemort::ProtoBuff::Resolver;
use Carp;

with 'Voldemort::Protobuff::Resolver';

sub resolve {
    shift;
    my $versions = shift;
    my $size     = scalar @{$versions};
    if ( $size == 0 ) {
        return;
    }
    elsif ( $size == 1 ) {
        return $$versions[0]->value;
    }
    carp "Implement your own resolver to merge vectors";
}

1;
