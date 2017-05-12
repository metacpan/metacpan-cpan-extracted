#!/usr/bin/perl -c

package tlib;

use Symbol::Util ':all';


sub import {
    my ($package, @names) = @_;
    my $caller = caller();
    return export_package($caller, $package, {
        EXPORT => [ qw( list_subroutines is_code is_constant ) ],
    }, @names);
};


sub list_subroutines {
    my ($name) = @_;
    return [ sort grep { is_code("${name}::$_") }
                  keys %{ stash($name) } ];
};


sub is_code {
    my ($name) = @_;
    no strict 'refs';
    return defined fetch_glob($name, 'CODE');
};


1;
