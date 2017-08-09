package Text::vCard::Precisely::V3::Node::SocialProfile;

use Carp;
use Encode;

use Moose;
use Moose::Util::TypeConstraints;

extends 'Text::vCard::Precisely::V3::Node';

has name => (is => 'ro', default => 'X-SOCIALPROFILE', isa => 'Str' );
has content => (is => 'rw', isa => 'Str', required => 1 );

subtype 'SocialProfileType'
    => as 'Str'
    => where { m/^(:?facebook|twitter|LinkedIn|flickr|myspace|sinaweibo|LINE|GitHub)$/is }
    => message { "The text you provided, $_, was not supported in 'SocialProfileType'" };
has types => ( is => 'rw', isa => 'SocialProfileType', required => 1 );

has userid => ( is => 'rw', isa => 'Str' );

subtype 'SocialProfileName'
    => as 'Str'
    => where { use utf8; decode_utf8($_) =~ m/^[\w\s]+$/s }
    => message { "The text you provided, $_, was not supported in 'SocialProfileName'" };
coerce 'SocialProfileName'
    => from 'Str'
    => via { encode_utf8($_) };
has displayname => ( is => 'rw', isa => 'SocialProfileName', coerce => 1 );

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name || croak "Empty name";
    push @lines, 'ALTID=' . $self->altID if $self->can('altID') and $self->altID;
    push @lines, 'PID=' . join ',', @{ $self->pid } if $self->can('pid') and $self->pid;
    push @lines, 'TYPE=' . $self->types || croak "Empty types";
    push @lines, 'X-USERID=' . $self->userid if defined $self->userid and $self->userid;
    push @lines, 'X-DISPLAYNAME=' . $self->displayname if defined $self->displayname and $self->displayname;

    my $string = join(';', @lines ) . ':' . $self->content;
    return $self->fold( $string, -force => 1 );
};


__PACKAGE__->meta->make_immutable;
no Moose;

1;
