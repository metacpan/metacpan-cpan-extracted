package Text::vCard::Precisely::V4::Node::Related;

use Carp;
use URI;

use Moose;
use Moose::Util::TypeConstraints;

extends 'Text::vCard::Precisely::V4::Node';

has name => ( is => 'ro', default => 'RELATED', isa => 'Str' );

subtype 'RelatedType' => as 'Str' => where {
    m/^(?:contact|acquaintance|friend|met|co-worker|colleague|co-resident|neighbor|child|parent|sibling|spouse|kin|muse|crush|date|sweetheart|me|agent|emergency)$/is;

    # it needs tests
} => message {"The text you provided, $_, was not supported in 'RelatedType'"};

subtype 'RelatedTypes' => as 'ArrayRef[RelatedType]';
coerce 'RelatedTypes'  => from 'RelatedType' => via { [$_] };
has types =>
    ( is => 'rw', isa => 'RelatedTypes', default => sub { [] }, required => 1, coerce => 1 );

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name() || croak "Empty name";
    push @lines, 'ALTID=' . $self->altID() if $self->altID();
    push @lines, 'PID=' . join ',', @{ $self->pid() } if $self->pid();
    push @lines, 'TYPE="' . join( ',', map { uc $_ } @{ $self->types() } ) . '"'
        if ref $self->types() eq 'ARRAY' and $self->types()->[0];
    push @lines, "MEDIATYPE=" . $self->media_type() if defined $self->media_type();

    my $string = join( ';', @lines ) . ':' . $self->content();
    return $self->fold( $string, -force => 1 );
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
