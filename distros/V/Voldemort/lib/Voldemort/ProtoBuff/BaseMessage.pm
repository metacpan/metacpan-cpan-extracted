package Voldemort::ProtoBuff::BaseMessage;

use Moose;
use IO::Select;
use Carp;
use Scalar::Util qw(reftype);

use Voldemort::Message;
use Voldemort::ProtoBuff::Spec2;

with 'Voldemort::Message';

sub write {
    carp "Implement write";
    return;
}

sub _get_entries {
    shift;
    my $node  = shift;
    my @nodes = ($node);
    my $ref   = reftype $node;

    @nodes = @$node if ( defined $ref and $ref eq 'ARRAY' );

    my $time = time();
    my @result;
    foreach my $node (@nodes) {
        push(
            @result,
            Voldemort::ProtoBuff::Spec2::ClockEntry->new(
                {
                    node_id => $node,
                    version => time()
                }
            )
        );
    }
    return \@result;
}

sub read {
    carp "Implement write";
    return;
}
1;

