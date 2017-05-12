#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Perl methods for the Rowop class.

package Triceps::Rowop;

our $VERSION = 'v2.0.1';

# convert a rowop to a printable string, with name-value pairs
# (printP stands for "print in Perl")
package  Triceps::Rowop;

# @param name - override for the name of the label
sub printP # ($self, [$name])
{
	my $self = shift;
	my $name = shift;
	$name = $self->getLabel()->getName() unless ($name);
	return $name . " " . Triceps::opcodeString($self->getOpcode()) . " " . $self->getRow()->printP();
}

1;
