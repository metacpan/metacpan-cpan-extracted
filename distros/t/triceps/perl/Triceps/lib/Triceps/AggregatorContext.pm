#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Perl methods for the AggregatorContext class.

package Triceps::AggregatorContext;

our $VERSION = 'v2.0.1';

use Carp;

# A convenience wrapper that creates the Row/Rowop from
# the field name-value pairs and sends it to the output.
# Eventually should move to XS for higher efficiency.
# @param opcode - opcode for the rowop
# @param fieldName, fieldValue - pairs defining the data for the row
sub makeHashSend # (self, opcode, fieldName => fieldValue, ...)
{
	my $self = shift;
	my $opcode = shift;
	my $row = $self->resultType()->makeRowHash(@_);
	my $res = $self->send($opcode, $row);
	return $res;
}

# A convenience wrapper that creates the Row/Rowop from
# the field value array and sends it to the output.
# Eventually should move to XS for higher efficiency.
# @param opcode - opcode for the rowop
# @param fieldValue - values defining the data for the row
sub makeArraySend # (self, opcode, fieldValue, ...)
{
	my $self = shift;
	my $opcode = shift;
	my $row = $self->resultType()->makeRowArray(@_);
	my $res = $self->send($opcode, $row);
	return $res;
}

1;
