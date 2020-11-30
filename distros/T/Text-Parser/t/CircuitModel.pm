use strict;
use warnings;

package t::CircuitModel;
use Moose;

extends 't::DeviceModel';

has '+instance_prefix' => ( default => 'X', );

has _subckt_params => (
    is       => 'ro',
    isa      => 'HashRef[Str]',
    lazy     => 1,
    init_arg => 'params',
    default  => sub { {} },
    handles  => {
        params      => 'keys',
        param_value => 'get',
    },
);

has _inst_models => (
    is       => 'ro',
    isa      => 'HashRef[t::DeviceModel|t::CircuitModel]',
    default  => sub { {} },
    lazy     => 1,
    init_arg => undef,
    traits   => ['Hash'],
    handles  => {
        _add_instance  => 'set',
        instance_model => 'get',
        instances      => 'keys',
        has_no_insts   => 'is_empty',
        has_instance   => 'exists',
    },
);

sub instance_model_name {
    my $self = shift;
    return $self->instance_model(shift)->name;
}

has _inst_conn => (
    is       => 'ro',
    isa      => 'HashRef[HashRef[Str]]',
    default  => sub { {} },
    lazy     => 1,
    init_arg => undef,
    traits   => ['Hash'],
    handles  => {
        _add_inst_conn       => 'set',
        instance_connections => 'get',
    }
);

after _add_inst_conn => sub {
    my $self = shift;
    my $h    = $self->_inst_conn;
    my $n    = $self->_net_insts;
    foreach my $inst ( keys %{$h} ) {
        __find_inst_conn( $h, $n, $inst, $_ ) for ( keys %{ $h->{$inst} } );
    }
    $self->_net_insts($n);
};

sub __find_inst_conn {
    my ( $h, $n, $inst, $term ) = ( shift, shift, shift, shift );
    my $net = $h->{$inst}->{$term};
    my (@conn) = ( exists $n->{$net} ) ? ( @{ $n->{$net} } ) : ();
    return if ( grep { $_->[0] eq $inst && $_->[1] eq $term } @conn );
    push @conn, [ $inst, $term ];
    $n->{$net} = \@conn;
}

sub create_instance {
    my ( $self, $name, $mod, $conn ) = ( shift, shift, shift, shift );
    $self->_add_instance( $name => $mod );
    $self->_add_inst_conn( $name => $conn );
}

has _net_insts => (
    is       => 'rw',
    isa      => 'HashRef[ArrayRef[ArrayRef[Str]]]',
    default  => sub { {} },
    lazy     => 1,
    init_arg => undef,
    traits   => ['Hash'],
    handles  => {
        net_connections => 'get',
        net_exists      => 'exists',
        nets            => 'keys',
    }
);

has _inst_props => (
    is  => 'rw',
    isa => 'HashRef[HashRef[Any]]',
);

sub flatten {
    my $self = shift;
    my $flat = t::CircuitModel->new(
        name      => $self->name,
        terminals => [ $self->terminals ]
    );
    $flat->create_instance( @{$_} ) for ( $self->_flatten_cell(@_) );
    return $flat;
}

sub _flatten_cell {
    my $h         = shift;
    my (%opt)     = _set_default_flatten_opts(@_);
    my @top_insts = ();
    foreach my $inst ( $h->instances ) {
        my $mod = $h->instance_model($inst);
        my $c   = $h->instance_connections($inst);
        if ( _stop_at_cell( $mod, @_ ) ) {
            push @top_insts,
                _prep_flat_inst( $opt{prefix}, $inst, $mod, $c,
                $opt{parent} );
        } else {
            my (%iopt)
                = _make_subcell_opt( \%opt, prefix => $inst, parent => $c );
            my (@i) = _flatten_cell( $h->instance_model($inst), %iopt );
            foreach my $i (@i) {
                push @top_insts,
                    _prep_flat_inst( $opt{prefix}, @{$i}, $opt{parent} );
            }
        }
    }
    return @top_insts;
}

sub _make_subcell_opt {
    my ( $h, %mod ) = (@_);
    my (%h) = %{$h};
    $h{$_} = $mod{$_} for ( keys %mod );
    return (%h);
}

sub _stop_at_cell {
    my $mod = shift;
    return 1 if not $mod->isa('t::CircuitModel');
    my (%opt) = @_;
    return 1 if ( grep { $_ eq $mod->name } ( @{ $opt{box} } ) );
    $mod->has_no_insts and $opt{box_empty};
}

sub _set_default_flatten_opts {
    my (%opt) = @_;
    $opt{parent} = ( exists $opt{parent} ) ? $opt{parent} : {};
    $opt{prefix} = ( exists $opt{prefix} ) ? $opt{prefix} : undef;
    $opt{box} = ( exists $opt{box} and defined $opt{box} ) ? $opt{box} : [];
    $opt{box_empty} = ( exists $opt{box_empty} ) ? $opt{box_empty}     : 1;
    return (%opt);
}

sub _prep_flat_inst {
    my ( $prefix, $iname, $mod, $c, $pc ) = (@_);
    return [ $iname, $mod, $c ] if not defined $prefix;
    my (%c) = map {
              $_ => ( exists $pc->{ $c->{$_} } )
            ? $pc->{ $c->{$_} }
            : ( $prefix . '/' . $c->{$_} )
    } ( keys %{$c} );
    return [ "$prefix/$iname", $mod, \%c ];
}

sub explicate_contents {
    my $self       = shift;
    my (@terms)    = $self->terminals;
    my $name       = $self->name;
    my (@contents) = (".SUBCKT $name @terms\n\n");
    foreach my $net ( sort $self->nets ) {
        push @contents, "*|NET $net\n";
        my $conn = $self->net_connections($net);
        my (@conn)
            = ( sort { "$a->[0]:$a->[1]" cmp "$b->[0]:$b->[1]" } @{$conn} );
        foreach my $c (@conn) {
            my $ipin = "$c->[0]:$c->[1]";
            push @contents, "*|I $ipin $c->[0] $c->[1]\n";
        }
        push @contents, "\n";
    }
    push @contents, "* Instance section\n\n";
    for my $inst ( sort $self->instances ) {
        my $mod    = $self->instance_model($inst);
        my $pref   = $mod->instance_prefix;
        my $conn   = $self->instance_connections($inst);
        my (@conn) = map { $conn->{$_} } ( $mod->terminals );
        push @contents, ( "$pref$inst @conn " . $mod->name . "\n" );
    }
    push @contents, "\n.ENDS\n";
    return @contents;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
