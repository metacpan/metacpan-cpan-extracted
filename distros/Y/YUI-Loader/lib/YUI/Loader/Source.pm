package YUI::Loader::Source;

use Moose;

has catalog => qw/is ro required 1 isa YUI::Loader::Catalog/;

sub uri {
    return;
}

sub file {
    return;
}

1;
