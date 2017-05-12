#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Perl methods for the Label class.

package Triceps::Label;

use Carp;

our $VERSION = 'v2.0.1';

# A convenience wrapper that creates the Rowop from
# the field name-value pairs, handling the look-up of the
# row type.
# Eventually should move to XS for higher efficiency.
# @param opcode - opcode for the rowop
# @param fieldName, fieldValue - pairs defining the data for the row
sub makeRowopHash # (self, opcode, fieldName => fieldValue, ...)
{
	my $self = shift;
	my $opcode = shift;
	my $row = $self->getType()->makeRowHash(@_);
	my $rop = $self->makeRowop($opcode, $row);
	return $rop;
}

# A convenience wrapper that creates the Rowop from
# the field value array, handling the look-up of the
# row type.
# Eventually should move to XS for higher efficiency.
# @param opcode - opcode for the rowop
# @param fieldValue - values defining the data for the row
sub makeRowopArray # (self, opcode, fieldValue, ...)
{
	my $self = shift;
	my $opcode = shift;
	my $row = $self->getType()->makeRowArray(@_);
	my $rop = $self->makeRowop($opcode, $row);
	return $rop;
}

# Make a label chained from this one.
# Automatically picks up the row type and unit from this label.
# The arguments are the same as for makeLabel() except that the
# row type gets skipped.
# Confesses on any error.
# @param name - name of the new label
# @param clear - the clear function
# @param exec - the label execution function
# @param args - arguments for the clear and exec functions
# @return - the newly created chained label
sub makeChained # ($self, $name, &$clear, &$exec, @args)
{
	confess "Use: Label::makeChained(self, name, clear, exec, ...)"
		unless ($#_ >= 3);
	my $self = shift;
	my $name = shift;
	my $clear = shift;
	my $exec = shift;
	my $rt = $self->getRowType();
	my $unit = $self->getUnit();
	my $lb = $unit->makeLabel($rt, $name, $clear, $exec, @_);
	$self->chain($lb);
	return $lb;
}

1;
