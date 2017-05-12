#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Perl methods for the Row class.

package Triceps::Row;

our $VERSION = 'v2.0.1';

# convert a row to a printable string, with name-value pairs
# (printP stands for "print in Perl")
sub printP # ($self)
{
	my $self = shift;
	my @data = $self->toHash();
	my ($k, $v);
	my $res = '';
	while ($#data >= 0) {
		$k = shift @data;
		$v = shift @data;
		next if !defined $v;
		if (ref $v) {
			# it's an array value
			$res .= "$k=[" . join(", ", map { $_ =~ s/\\/\\\\/g; $_ =~ s/"/\\"/g; "\"$_\"" } @$v) . "] ";
		} else {
			$v =~ s/\\/\\\\/g;
			$v =~ s/"/\\"/g;
			$res .= "$k=\"$v\" "
		}
	}
	return $res;
}
1;
