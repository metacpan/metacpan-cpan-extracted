#!/usr/bin/env perl
# XML::Axk::Object::TinyDefaults - Object::Tiny::XS, but with default values.
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

package XML::Axk::Object::TinyDefaults;

use 5.004;
use strict 'vars', 'subs';
use warnings;
use Data::Dumper;
use Import::Into;

our $ObjTiny;
our $VERSION = '0.001008';

BEGIN {
    require parent;

    # Use Object::Tiny::XS or Object::Tiny
    eval { require Object::Tiny::XS; };
    $ObjTiny = 'Object::Tiny::XS' unless $@;
    eval { require Object::Tiny; } unless $ObjTiny;
    $ObjTiny = 'Object::Tiny' unless $@ || $ObjTiny;

    die 'Cannot find Object::Tiny or Object::Tiny::XS' unless $ObjTiny;
    #print "Using $ObjTiny\n";
} # BEGIN

my %defaults;

# Import: If the first parameter is a hashref, it contains the defaults.
# Any remaining parameters are other fields to create.  Field names in the
# defaults do not also have to be specified in the list.
sub import {
    my $class = shift;
    return unless $class eq __PACKAGE__;
        # Without this, it also gets imported into XML::Axk::L1 and
        # axk_script_*, trashing symbols and preventing execution.
    my $pkg   = caller;
    #print "Import into $pkg: (", join(', ', @_), ")\n";

    # Stash defaults for new()
    $defaults{$pkg} = { (ref $_[0] eq 'HASH') ? %{+shift} : () };
        # Keep our own shallow copy of the defaults
    #print "Defaults for $pkg are ", Dumper($defaults{$pkg}), "\n";

    parent->import::into(1, $class);    # Caller is now a child of us
    #print "Caller is now ", join(', ', @{$pkg . '::ISA'}), "\n";

    my %vars = %{$defaults{$pkg}};      # All the fields, without duplicates
    $vars{$_} = 1 for @_;

    #print 'Fields are (', join(', ', keys %vars), ")\n";
    $ObjTiny->import::into(1, keys %vars);
        # Caller now has all the accessors, and is still a child of us because
        # Object::Tiny doesn't overwrite an existing @ISA.

    #print "Done importing into $pkg\n";
    return 1;
} #import()

# new: Create a new instance.  Constructor parameters are key=>value
# assignments that override the defaults.
sub new {
    #print 'New: (', join(', ', @_), ")\n";
    my $class = shift;

    my $hrOpts = $defaults{$class} // {};       # Grab defaults
    my %self = %{$hrOpts};

    my $hrArgs = { @_ };                          # Params override defaults
    @self{keys %$hrArgs} = values %$hrArgs;

    return bless(\%self, $class);
} #new()

1;

__END__

=pod

=head1 NAME

XML::Axk::Object::TinyDefaults - Object::Tiny[::XS] wrapper that adds default values

=head1 SYNOPSIS

    package MyClass;
    use XML::Axk::Object::TinyDefaults { foo => 42 } qw(bar bat);

    package main;
    my $inst = MyClass->new(bar=>1);

Now MyClass has accessors C<foo()>, C<bar()>, and C<bat()>, and values
C<foo=42> and C<bar=1>.

Requires L<Object::Tiny> or L<Object::Tiny::XS>.  XS will be used if available.

TODO replace this with L<Class::Tiny>!

=head1 COPYRIGHT

Copyright (c) 2018 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). Details are in the LICENSE
file accompanying this distribution.

=cut
# vi: set ts=4 sts=4 sw=4 et ai: #
