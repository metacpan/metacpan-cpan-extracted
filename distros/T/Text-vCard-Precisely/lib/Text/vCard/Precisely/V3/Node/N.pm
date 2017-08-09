package Text::vCard::Precisely::V3::Node::N;

use Carp;
use Moose;
use Moose::Util::TypeConstraints;

extends 'Text::vCard::Precisely::V3::Node';

my @order = qw( family given additional prefixes suffixes );

has name => (is => 'ro', default => 'N', isa => 'Str' );
has \@order => ( is => 'rw', isa => 'Str|Undef', default => undef );

subtype 'Values' => as 'HashRef[Maybe[Str]]';
coerce 'Values'
    => from 'ArrayRef[Maybe[Str]]'
    => via {
        my @values = @$_; $values[4] ||= ''; my $hash = {};
        map { $hash->{$order[$_]} = $values[$_] } 0..4;
        return $hash;
    };
coerce 'Values'
    => from 'Str'
    => via {
        my @values = split( /(?<!\\);/, $_ ); $values[4] ||= ''; my $hash = {};
        map { $hash->{$order[$_]} = $values[$_] } 0..4;
        return $hash;
    };
has content => ( is => 'rw', isa => 'Values', coerce => 1 );

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name || croak "Empty name";
    push @lines, 'LANGUAGE=' . $self->language if $self->language;

    my @values = map{ $self->_escape($_) } map{ $self->$_ or  $self->content && $self->content()->{$_} } @order;

    my $string = join(';', @lines ) . ':' . join( ';', @values );
    return $self->fold( $string, -force => 1 );
};

__PACKAGE__->meta->make_immutable;
no Moose;

#Alias
sub family_name {
    family(@_);
}

sub surname {
    family(@_);
}

sub given_name {
    given(@_);
}

sub additional_name {
    additional(@_);
}

sub honorific_prefixes {
    prefixes(@_);
}

sub honorific_suffixes {
    suffixes(@_);
}

1;
