package Text::vCard::Precisely::V3::Node::MultiContent;

use Carp;
use Moose;
use Moose::Util::TypeConstraints;

use overload( '""' => \&as_string );

extends 'Text::vCard::Precisely::V3::Node';

has name => ( is => 'ro', default => 'ADR', isa => 'Str' );

subtype 'MultiContent' => as 'ArrayRef[Str]';
coerce 'MultiContent'  => from 'Str' => via { [$_] };
has content            => ( is => 'rw', required => 1, isa => 'MultiContent', coerce => 1 );

sub as_string {
    my ($self) = @_;
    my $string = ( $self->name() || croak "Empty name" ) . ':' . join ',', @{ $self->content() };
    return $self->fold($string);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
