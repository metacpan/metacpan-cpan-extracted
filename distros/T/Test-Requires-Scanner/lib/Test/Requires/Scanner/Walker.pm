package Test::Requires::Scanner::Walker;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw/
        module_name
        is_in_usedecl
        is_in_test_requires
        is_in_reglist
        is_prev_module_name
        is_in_list
        is_in_hash
        does_garbage_exist
        hash_count
        stashed_module
    /],
);

sub reset {
    my $self = shift;

    $self->module_name('');
    $self->stashed_module('');

    for my $accessor (qw/
        is_in_usedecl
        is_in_test_requires
        is_in_reglist
        is_prev_module_name
        is_in_list
        is_in_hash
        does_garbage_exist
        hash_count
    /) {
        $self->$accessor(0);
    }
}

1;
