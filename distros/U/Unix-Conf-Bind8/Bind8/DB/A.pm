# Bind8 A record handling
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::DB::A - Class representing A records.

=head1 SYNOPSIS

Refer to the SYNOPSIS section for Unix::Conf::Bind8::DB::Record.

=head1 METHODS

Methods specified here are overridden. They might or not be differnt from
the derived ones. For other methods refer to the METHODS section for
Unix::Conf::Bind8::DB::Record.

=over 4

=cut

package Unix::Conf::Bind8::DB::A;

use strict;
use warnings;

use Unix::Conf;
use Unix::Conf::Bind8::Conf::Lib;
use Unix::Conf::Bind8::DB::Record;

our (@ISA) = qw (Unix::Conf::Bind8::DB::Record);

=item rdata ()

 Arguments
 data

Object method.
Get/set the record's rdata. If an argument is passed, the invocant's
rdata is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's rdata is returned.

=cut

# Override base class (Unix::Conf::Bind8::DB::Record) method. The only
# difference is the validation of the IP address.
sub rdata
{
	my ($self, $rdata) = @_;

	if (defined ($rdata)) {
		return (Unix::Conf->_err ('rdata', "`$rdata' not a valid IP"))
			unless (__valid_ipaddress ($rdata));
		if (defined ($self->{RDATA})) {
			my $ret;
			$ret = Unix::Conf::Bind8::DB::_delete_object ($self) 
				or return ($ret);
			# change rdata now before storing in new location as it is
			# depenedant on the rdata.
			$self->{RDATA} = $rdata;
			$self->dirty (1);
			return (Unix::Conf::Bind8::DB::_insert_object ($self));
		}
		$self->{RDATA} = $rdata;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{RDATA}) ? $self->{RDATA} :
			Unix::Conf->_err ('rdata', "RDATA not defined")
	);
}

1;
