package Text::vCard::Precisely::V3::Node::URL;

use Carp;
use URI;

use Moose;
use Moose::Util::TypeConstraints;

extends 'Text::vCard::Precisely::V3::Node';

has name => (is => 'ro', default => 'URL', isa => 'Str' );
has types => ( is => 'rw', isa => 'ArrayRef[Str]');

subtype 'URL' => as 'Str';
coerce 'URL'
    => from 'Str'
    => via { [ URI->new($_)->as_string ] };
has content => (is => 'ro', default => '', isa => 'URL', coerce => 1 );

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name || croak "Empty name";
    push @lines, 'ALTID=' . $self->altID if $self->can('altID') and $self->altID;
    push @lines, 'PID=' . join ',', @{ $self->pid } if $self->can('pid') and $self->pid;
    push @lines, 'TYPE=' . join( ',', map { uc $_ } @{ $self->types } ) if @{ $self->types || [] } > 0;

    my $string = join(';', @lines ) . ':' . $self->content;
    return $self->fold( $string, -force => 1 );
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
