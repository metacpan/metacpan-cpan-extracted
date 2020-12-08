package WWW::WTF::HTTPResource::Types::HTML::Tag::Types::A;

use common::sense;

use Moose::Role;

has 'uri' => (
    is      => 'ro',
    isa     => 'Maybe[URI]',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $href = $self->attribute('href');

        return unless $href;

        return URI->new($href->content);
    },
);

1;
