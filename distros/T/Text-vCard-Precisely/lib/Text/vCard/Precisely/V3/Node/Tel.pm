package Text::vCard::Precisely::V3::Node::Tel;

use Carp;

use Moose;
use Moose::Util::TypeConstraints;

extends 'Text::vCard::Precisely::V3::Node';

has name => (is => 'ro', default => 'TEL', isa => 'Str' );

subtype 'Tel'
    => as 'Str'
    => where { m/^(:?[+]?\d{1,2}|\d*)[\(\s\-]?\d{1,3}[\)\s\-]?[\s]?\d{1,3}[\s\-]?\d{3,4}$/s }
    => message { "The Number you provided, $_, was not supported in Tel" };
has content => (is => 'ro', default => '', isa => 'Tel' );

subtype 'TelType'
    => as 'Str'
    => where {
        m/^(:?work|home)$/is or #common
        m/^(:?text|voice|fax|cell|video|pager|textphone)$/is # for tel
    }
    => message { "The text you provided, $_, was not supported in 'TelType'" };
has types => ( is => 'rw', isa => 'ArrayRef[Maybe[TelType]]');

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name || croak "Empty name";
    push @lines, 'ALTID=' . $self->altID if $self->can('altID') and $self->altID;
    push @lines, 'PID=' . join ',', @{ $self->pid } if $self->can('pid') and $self->pid;
    push @lines, 'TYPE=' . join( ',', map { uc $_ } @{ $self->types } ) if @{ $self->types || [] } > 0;

    ( my $content = $self->content ) =~ s/[-+()\s]+/ /sg;
    $content =~ s/^ //s;
    my $string = join(';', @lines ) . ':' . $content;
    return $self->fold( $string, -force => 1 );
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
