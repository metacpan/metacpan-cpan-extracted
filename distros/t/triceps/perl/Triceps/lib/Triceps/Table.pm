#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Perl methods for the Table class.

package Triceps::Table;

our $VERSION = 'v2.0.1';

# create a row with specified fields and find it, thus 
# making more convenient to search by key fields
sub findBy # (self, fieldName => fieldValue, ...)
{
	my $self = shift;
	my $row = $self->getRowType()->makeRowHash(@_);
	my $res = $self->find($row);
	return $res;
}

# create a row with specified fields and find it in an expicit index, thus 
# making more convenient to search by key fields
sub findIdxBy # (self, idxType, fieldName => fieldValue, ...)
{
	my $self = shift;
	my $idx = shift;
	my $row = $self->getRowType()->makeRowHash(@_);
	my $res = $self->findIdx($idx, $row);
	return $res;
}

1;
