package YUI::Loader::IncludeExclude;

use strict;
use warnings;

use Moose;

has manifest => qw/is ro required 1 weak_ref 1/, handles => [qw/include exclude/];
has do_include => qw/is ro required 1/;

# TODO Urgh, ...
for my $name (YUI::Loader::Catalog->name_list) {
    my $method = $name;
    $method =~ s/-/_/g;
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        my $on = @_ ? shift : $self->do_include;
        if ($on) {
            $self->manifest->collection->{$name} = 1;
            $self->manifest->dirty(1);
        }
        else {
            delete $self->manifest->collection->{$name};
            $self->manifest->dirty(1);
        }
        return $self;
    };
}

sub then {
    my $self = shift;
    my $manifest = $self->manifest;
    return $manifest->loader || $manifest;
}

1;
