package Text::vCard::Precisely::V3::Node::Address;

use Carp;
use Moose;

extends 'Text::vCard::Precisely::V3::Node';

has name    => ( is => 'ro', default => 'ADR', isa => 'Str' );
has content => ( is => 'ro', default => '',    isa => 'Str' );

our @order = qw( pobox extended street city region post_code country );
has \@order => ( is => 'rw', isa => 'Str' );

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name() || croak "Empty name";
    push @lines, 'TYPE=' . join( ',', map {uc} @{ $self->types() } )
        if ref $self->types() eq 'ARRAY' and $self->types()->[0];
    push @lines, 'PREF=' . $self->pref()         if $self->pref();
    push @lines, 'LANGUAGE=' . $self->language() if $self->language();

    my $string = join( ';', @lines ) . ':' . join ';', map { $self->_escape( $self->$_ ) } @order;
    return $self->fold($string);
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
