package WWW::WTF::HTTPResource::Types::HTML::Tag;

use common::sense;

use Moose;

use List::Util qw(first);
use Test::LongString qw//;

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'content' => (
    is  => 'ro',
    isa => 'Str',
);

has 'tag_types' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    default  => sub {
        {
            'a'   => 'A',
            'img' => 'Img',
        }
    },
);

has 'attributes' => (
    is  => 'ro',
    isa => 'ArrayRef[WWW::WTF::HTTPResource::Types::HTML::Tag::Attribute]',
);

sub BUILD {
    my $self = shift;

    my $tag_name = lc($self->name);

    if (exists $self->tag_types->{$tag_name}) {
        Moose::Util::apply_all_roles($self, 'WWW::WTF::HTTPResource::Types::HTML::Tag::Types::' . $self->tag_types->{$tag_name});
    }
}

sub attribute {
    my ($self, $name) = @_;

    return first { $_->name eq $name } @{ $self->attributes };
}

sub contains_string {
    my ($self, $str, $description) = @_;

    $description = qq{Tag contains "$str"} if not defined $description;

    return Test::LongString::contains_string($self->content, $str, $description);
}

1;
