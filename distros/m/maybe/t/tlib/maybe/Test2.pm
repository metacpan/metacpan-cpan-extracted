package maybe::Test2;

# no $VERSION
our $is_ok = 0;

sub import {
    $is_ok = $_[1] || 1;
}

1;
