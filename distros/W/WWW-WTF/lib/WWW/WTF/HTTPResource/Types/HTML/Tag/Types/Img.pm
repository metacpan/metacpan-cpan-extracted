package WWW::WTF::HTTPResource::Types::HTML::Tag::Types::Img;

use common::sense;

use Moose::Role;

has 'src' => (
    is      => 'ro',
    isa     => 'URI',
    lazy    => 1,
    default => sub {
        my $self = shift;

        return URI->new($self->attribute('src')->content);
    },
);

1;
