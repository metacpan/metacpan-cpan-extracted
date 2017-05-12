#!/usr/bin/perl 

use strict;
use warnings;

use Try::Tiny;
use Try::Tiny::Warnings;

{
    package Foo;

    use warnings;

    sub bar { 1 + shift }
}

Foo::bar();  # warn

try_fatal_warnings {
    Foo::bar();
}
catch {
    print "tsk, got $_";
};

try_warnings {
    Foo::bar();
    warn "some more";
}
catch {
    print "won't be printed\n";
}
catch_warnings {
    print "we warned with: $_" for @_;
};





