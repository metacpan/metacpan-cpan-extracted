package maybe::Test6;

our $VERSION = 0;
our $is_ok = 0;

sub import {
    $is_ok = $_[1] || 1;
}

1;
