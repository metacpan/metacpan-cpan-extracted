# $Id: DefClass.pm,v 1.2 1997/04/30 21:58:23 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

# This module provides a simple class/accessor creation
# syntax. Because it happens at runtime, however, procedures don't
# have the right names in the debugger, and you must assign the glob
# to override a procedure. Not ready for prime time but handy for
# perlrpcgen.

package perlrpcgen::DefClass;

use Exporter;

@perlrpcgen::DefClass::ISA = qw(Exporter);

@EXPORT = qw(defclass);

sub defclass ($$@) {
    my ($name, $super, @fields) = @_;

    *{$name . "::new"} = \&new;

    if (ref($super) ne 'ARRAY') {
	$super = [ $super ];
    }
    *{$name . "::ISA"} = $super;

    my $i = 0;
    foreach $f (@fields) {
	*{$name . "::" . $f} = &get_getter($i);
	*{$name . "::set_" . $f} = &get_setter($i);
	$i++;
    }
}

sub new {
    my ($class, @fields) = @_;
    return bless \@fields, $class;
}

sub make_getter {
    my ($index) = @_;

    return sub {
	my ($self) = @_;
	return $self->[$index];
    }
}

sub get_getter {
    my ($index) = @_;
    if (!$getters[$index]) {
	$getters[$index] = &make_getter($index);
    }
    return $getters[$index];
}

sub make_setter {
    my ($index) = @_;

    return sub {
	my ($self, $val) = @_;
	$self->[$index] = $val;
    }
}

sub get_setter {
    my ($index) = @_;
    if (!$setters[$index]) {
	$setters[$index] = &make_setter($index);
    }
    return $setters[$index];
}

1;
