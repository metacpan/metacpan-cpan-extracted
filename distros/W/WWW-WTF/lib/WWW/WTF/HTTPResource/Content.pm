package WWW::WTF::HTTPResource::Content;

use common::sense;

use Moose;

use File::Slurper qw(write_binary);
use Test::LongString qw//;

use overload
    '""' => 'stringify';

has 'data' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub stringify {
    return shift->data;
}

sub contains_string {
    my ($self, $str, $description) = @_;

    $description = qq{Content contains "$str"} if not defined $description;

    return Test::LongString::contains_string($self->data, $str, $description);
}

sub contains_regex {
    my ($self, $regex, $description) = @_;

    $description = qq{Content is like "$regex"} if not defined $description;

    return Test::LongString::like_string($self->data, $regex, $description);
}

sub lacks_string {
    my ($self, $str, $description) = @_;

    $description = qq{Content lacks "$str"} if not defined $description;

    return Test::LongString::lacks_string($self->data, $str, $description);
}

sub lacks_regex {
    my ($self, $regex, $description) = @_;

    $description = qq{Content is unlike "$regex"} if not defined $description;

    return Test::LongString::unlike_string($self->data, $regex, $description);
}

sub write_to {
    my ($self, $path) = @_;

    write_binary($path, $self->data);

    return;
}

1;
