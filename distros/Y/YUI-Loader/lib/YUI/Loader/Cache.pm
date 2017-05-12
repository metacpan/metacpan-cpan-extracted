package YUI::Loader::Cache;

use Moose;
use YUI::Loader::Carp;
has catalog => qw/is ro required 1 isa YUI::Loader::Catalog lazy 1/, default => sub { shift->source->catalog };
has source => qw/is ro required 1 isa YUI::Loader::Source/;

sub uri {
    return;
}

sub file {
    return;
}

1;

