#!/usr/bin/perl

use lib 'lib', '../lib';

package My::MouseClass;

use Mouse;

use namespace::functions -except => 'meta';

sub my_method {
    my ($self, $arg) = @_;
    return blessed $self;
};

no namespace::functions;

# The My::MouseClass now provides "my_method" and "meta" only.


package main;

use Class::Inspector;
use YAML;

print Dump ( {
    functions => [Class::Inspector->functions('My::MouseClass')],
    methods   => [Class::Inspector->methods('My::MouseClass')],
} );
