package Text::PageLayout::Page;

use 5.010;
use utf8;
use strict;
use warnings;

use overload q[""] => \&Str;

use Moo;

with 'Text::PageLayout::PageElements';

has page_number => (
    is          => 'ro',
    required    => 1,
);

has total_pages => (
    is          => 'rw',
);

has bottom_filler => (
    is          => 'ro',
    default     => sub { '' },
);

sub Str {
    my $self = shift;

    return join '',
           $self->_apply('header'),
           join($self->separator, @{ $self->paragraphs }),
           $self->bottom_filler,
           $self->_apply('footer'),
           ;
}
sub as_string {
    my $self = shift;
    $self->Str;
}

sub _apply {
    my ($self, $elem) = @_;
    my $e = $self->$elem;
    return $self->process_template->(
        template    => $e,
        element     => $elem,
        page_number => $self->page_number,
        total_pages => $self->total_pages,
    );
}


1;
