package Text::vCard::Precisely::V3::Node::Tel;

use Carp;

use Moose;
use Moose::Util::TypeConstraints;

extends 'Text::vCard::Precisely::V3::Node';

has name => (is => 'ro', default => 'TEL', isa => 'Str' );

#   to validate phone numbers is too difficult for me
#subtype 'Tel'
#    => as 'Str'
#    => where { m/^(?:[+]?\d{1,2}|\d*)[\(\s\-]?\d{1,3}[\)\s\-]?[\s]?\d{1,4}[\s\-]?\d{3,4}$/s }
#    => message { "The Number you provided, $_, was not supported in Tel" };
has content => (is => 'rw', default => '', isa => 'Str' );

has preferred => (is => 'rw', default => 0, isa => 'Bool' );

subtype 'TelType'
    => as 'Str'
    => where {
        m/^(?:work|home|pref)$/is or #common
        m/^(?:text|voice|fax|cell|video|pager|textphone)$/is # for tel
    }
    => message { "The text you provided, $_, was not supported in 'TelType'" };
has types => ( is => 'rw', isa => 'ArrayRef[Maybe[TelType]]', default => sub{ [] }, );

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name || croak "Empty name";
    push @lines, 'ALTID=' . $self->altID() if $self->can('altID') and $self->altID();
    push @lines, 'PID=' . join ',', @{ $self->pid() } if $self->can('pid') and $self->pid();

    push my @types, grep{ length $_ } map{ uc $_ if defined $_ } @{$self->types()};
    push @types, 'PREF' if $self->preferred();
    my $types = 'TYPE="' . join( ',', @types ) . '"' if @types;
    push @lines, $types if $types;

    #( my $content = $self->content() ) =~ s/^ //s;  # remove top space
    #$content =~ s/(?:(?!\A)\D|\()+/ /sg;            # replace symbols to space
    #$content =~ s/^ //s;                            # remove top space again
    #my $string = join(';', @lines ) . ':' . $content;
    my $string = join(';', @lines ) . ':' . $self->content();
    return $self->fold( $string, -force => 1 );
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
