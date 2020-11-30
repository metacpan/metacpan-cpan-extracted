
use strict;
use warnings;

package t::SpiceParser;
use t::DeviceModel;
use t::CircuitModel;

use Text::Parser::RuleSpec;
extends 'Text::Parser';

has file_stack => (
    is      => 'ro',
    isa     => 'HashRef[Num]',
    default => sub { {} },
    traits  => ['Hash'],
    handles => { file_in_stack => 'exists' }
);

applies_rule comment_char => (
    if          => 'substr($1, 0, 1) eq "*"',
    dont_record => 1,
);

applies_rule include_file => (
    if          => 'uc($1) eq ".INCLUDE"',
    do          => '$this->read_another_spice();',
    dont_record => 1,
);

sub read_another_spice {
    my $self  = shift;
    my $fpath = $self->field(1);
    die if not defined $fpath;
    $fpath =~ s/["]//g;
    die if not $fpath or not -f $fpath or not -T $fpath;
    my $inode  = ( stat($fpath) )[1];
    my $cinode = ( stat( $self->filename ) )[1];
    die if $cinode == $inode or $self->file_in_stack($inode);
    my $pars
        = t::SpiceParser->new(
        file_stack => { $cinode => $self->filename, %{ $self->file_stack } }
        );
    $pars->read($fpath);
}

has circuit_models => (
    is      => 'ro',
    isa     => 'HashRef[t::DeviceModel|t::CircuitModel]',
    default => sub {
        {   '' => t::CircuitModel->new(
                name            => '',
                instance_prefix => undef,
                terminals       => []
            )
        };
    },
    traits   => ['Hash'],
    lazy     => 1,
    init_arg => undef,
    handles  => {
        _save_model    => 'set',
        circuit_model  => 'get',
        is_known_model => 'exists',
    },
);

applies_rule create_subckt => (
    if          => 'uc($1) eq ".SUBCKT"',
    do          => '$this->create_subckt_model();',
    dont_record => 1,
);

has current_subckt => (
    is       => 'ro',
    isa      => 'Str',
    default  => '',
    lazy     => 1,
    init_arg => undef,
    writer   => '_set_current_subckt',
);

sub create_subckt_model {
    my $self = shift;
    die if $self->NF < 2;
    my $mod = t::CircuitModel->new(
        name      => $self->field(1),
        terminals => $self->_subckt_terminals
    );
    $self->_save_model( $self->field(1) => $mod );
    $self->_set_current_subckt( $self->field(1) );
}

sub _subckt_terminals {
    my $self = shift;
    my $ind  = $self->find_field_index( sub {m/.+[=].+/g} );
    my (@terms)
        = ( $ind == -1 )
        ? $self->field_range( 2, -1 )
        : $self->field_range( 2, $ind - 1 );
    return \@terms;
}

applies_rule end_subckt => (
    if          => 'uc($1) eq ".ENDS"',
    do          => '$this->_set_current_subckt("");',
    dont_record => 1,
);

applies_rule read_instance => (
    if          => 'substr($1, 0, 1) ne "."',
    do          => '$this->add_this_instance();',
    dont_record => 1,
);

sub add_this_instance {
    my $parser = shift;
    my $cmodel = $parser->circuit_model( $parser->current_subckt );
    my $name   = $parser->field(0);
    die if $cmodel->has_instance($name);
    my $model  = $parser->_find_instance_model_name;
    my $mod    = $parser->_find_model_obj( $name, $model );
    my (@nets) = $parser->_get_nets_conn_to_inst;
    my $conn   = _map_model_terms_to_nets( $mod->terms, \@nets );
    $cmodel->create_instance( $name, $mod, $conn );
}

sub _find_instance_model_name {
    my $parser = shift;
    my $ind    = $parser->find_field_index( sub {m/.+[=].+/g} );
    my $model
        = ( $ind == -1 ) ? $parser->field(-1) : $parser->field( $ind - 1 );
    return $model;
}

sub _find_model_obj {
    my ( $self, $name, $m ) = ( shift, shift, shift );
    return $self->circuit_model($m) if $self->is_known_model($m);
    my $pref = uc( substr( $name, 0, 1 ) );
    die if $pref eq 'X';
    my $mod = t::DeviceModel->new( name => $m, instance_prefix => $pref );
    $self->_save_model( $m => $mod );
    return $mod;
}

sub _get_nets_conn_to_inst {
    my $parser = shift;
    my $ind    = $parser->find_field_index( sub {m/.+[=].+/g} );
    return ( $ind == -1 )
        ? $parser->field_range( 1, -2 )
        : $parser->field_range( 1, $ind - 2 );
}

sub _map_model_terms_to_nets {
    my ( $terms, $nets ) = ( shift, shift );
    die if scalar( @{$terms} ) != scalar( @{$nets} );
    my (%conn) = ();
    for ( my $i = 0; $i < scalar( @{$terms} ); $i++ ) {
        $conn{ $terms->[$i] } = $nets->[$i];
    }
    return \%conn;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
