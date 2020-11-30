use strict;
use warnings;

package t::DeviceModel;
use Moose;
use Moose::Util::TypeConstraints;

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

enum 'InstancePrefix', [qw(M Q D R C X)];

my %component_terminals = (
    M => [qw(D G S B)],
    Q => [qw(emitter base collector)],
    D => [qw(anode cathode)],
    R => [qw(plus minus)],
    C => [qw(plus minus)],
);

has instance_prefix => (
    is        => 'ro',
    isa       => 'InstancePrefix|Undef',
    predicate => '_has_inst_prefix',
    required  => 1,
);

has terms => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    init_arg => 'terminals',
    writer   => '_set_terminals',
    default  => sub { [] },
    traits   => ['Array'],
    handles  => {
        terminals => 'elements',
        term      => 'get',
        term_pos  => 'first_index',
    },
);

sub is_portnet {
    my ( $self, $net ) = ( shift, shift );
    my $ind = $self->term_pos($net);
    return 0 if $ind == -1;
    return 1;
}

sub BUILD {
    my $self = shift;
    return if not $self->_has_inst_prefix;
    my $pref = $self->instance_prefix;
    $self->_set_terminals( $component_terminals{$pref} )
        if defined $pref and exists $component_terminals{$pref};
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
