package Text::vCard::Precisely::V4::Node::Address;

use Carp;
use Moose;

extends qw|Text::vCard::Precisely::V3::Node::Address Text::vCard::Precisely::V4::Node|;

has name => (is => 'ro', default => 'ADR', isa => 'Str' );
has content => (is => 'ro', default => '', isa => 'Str' );

has label => ( is => 'rw', isa => 'Str' );
has geo => ( is => 'rw', isa => 'Str' );

my @order = @Text::vCard::Precisely::V3::Node::Address::order;

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name || croak "Empty name";
    push @lines, 'ALTID=' . $self->altID if $self->can('altID') and $self->altID;
    push @lines, 'PID=' . join ',', @{ $self->pid } if $self->can('pid') and $self->pid;
    push @lines, 'TYPE=' . join( ',', map { uc $_ } @{ $self->types } ) if @{ $self->types || [] } > 0;
    push @lines, 'PREF=' . $self->pref if $self->pref;
    push @lines, 'LANGUAGE=' . $self->language if $self->language;
    push @lines, 'LABEL="' . $self->label . '"' if $self->label;
    push @lines, 'GEO="' . $self->geo . '"' if $self->geo;

    my @values = ();
    map{ push @values, $self->_escape( $self->$_ ) } @order;
    my $string = join(';', @lines ) . ':' . join ';', @values;
    return $self->fold($string);

};

__PACKAGE__->meta->make_immutable;
no Moose;
    
1;
