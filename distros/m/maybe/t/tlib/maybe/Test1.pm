package maybe::Test1;

our $VERSION = 123;
our $is_ok = 0;

sub import {
    $is_ok = $_[1] || 1;
}

1;
