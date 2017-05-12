package Text::Handlebars::Symbol;
our $AUTHORITY = 'cpan:DOY';
$Text::Handlebars::Symbol::VERSION = '0.05';
use Mouse;

extends 'Text::Xslate::Symbol';

has is_helper => (
    is  => 'rw',
    isa => 'Bool',
);

has is_block_helper => (
    is  => 'rw',
    isa => 'Bool',
);

__PACKAGE__->meta->make_immutable;
no Mouse;

=for Pod::Coverage

=cut

1;
