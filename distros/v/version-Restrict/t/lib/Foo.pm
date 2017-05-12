package Foo;

our $VERSION = 0.04;

use version::Restrict (
    "[0.0.0,0.03)" => "too old",
);
