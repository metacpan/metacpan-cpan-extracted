package Text::vCard::Precisely::V4::Node::Member;

use Carp;
use Moose;
use Moose::Util::TypeConstraints;

extends 'Text::vCard::Precisely::V4::Node';

has name    => ( is => 'ro', default => 'MEMBER', isa => 'Str' );
has content => ( is => 'ro', default => '',       isa => 'Str' );

subtype 'MemberType' => as 'Str' => where {
    m/^(?:contact|acquaintance|friend|met|co-worker|colleague|co-resident|neighbor|child|parent|sibling|spouse|kin|muse|crush|date|sweetheart|me|agent|emergency)$/is;

    # it needs tests
} => message {"The text you provided, $_, was not supported in 'MemberType'"};
has types => ( is => 'rw', isa => 'ArrayRef[MemberType]', default => sub { [] } );

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name() || croak "Empty name";
    push @lines, 'ALTID=' . $self->altID() if $self->altID();
    push @lines, 'PID=' . join ',', @{ $self->pid() } if $self->pid();
    push @lines, 'TYPE="' . join( ',', map {uc} @{ $self->types() } ) . '"'
        if ref $self->types() eq 'ARRAY' and $self->types()->[0];
    push @lines, 'PREF=' . $self->pref() if $self->pref();

    my $string = join( ';', @lines ) . ':' . $self->_escape( $self->content() );
    return $self->fold($string);
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
