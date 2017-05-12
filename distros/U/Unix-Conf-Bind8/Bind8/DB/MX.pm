# Bind8 MX record handling
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::DB::MX - Class representing MX records.

=head1 SYNOPSIS

Refer to the SYNOPSIS section for Unix::Conf::Bind8::DB::Record.

=head1 METHODS

Methods specified here are overridden. They might or not be differnt from
the derived ones. For other methods refer to the METHODS section for
Unix::Conf::Bind8::DB::Record.

=over 4

=cut

package Unix::Conf::Bind8::DB::MX;

use strict;
use warnings;

use Unix::Conf;
use Unix::Conf::Bind8::DB::Lib;
use Unix::Conf::Bind8::DB::Record;

our (@ISA) = qw (Unix::Conf::Bind8::DB::Record);

=item new ()

 Arguments
 LABEL		=> 'string',
 CLASS		=> 'string',	# 'IN'|'HS'|'CHAOS'
 TTL		=> 'string'|number,
 RTYPE		=> 'string',	# 'A'|'NS'|'MX'|'SOA'|'CNAME'|'PTR'
 MXPREF		=> mxpref		# number
 RDATA		=> data
 PARENT		=> reference,	# to the DB object datastructure

Class constructor.
Creates a new Unix::Conf::Bind8::DB::MX object and returns it
if successful, an Err object otherwise. Do not use this constructor
directly. Use the Unix::Conf::Bind8::DB::new_mx () equivalent instead.

=cut

# Override class constructor in base class. The difference is here we check
# to see argument MXPREF is defined and assign it.

sub new 
{
	my $class = shift ();
	my %args = ( @_ );
	my $new = bless ({}, $class);
	my $ret;

	return (Unix::Conf->_err ('new', "MXPREF not specified"))
		unless (defined ($args{MXPREF}));
	return (Unix::Conf->_err ('new', "LABEL not specified"))
		unless (defined ($args{LABEL}));
	return (Unix::Conf->_err ('new', "RTYPE not specified"))
		unless (defined ($args{RTYPE}));
	return (Unix::Conf->_err ('new', "RDATA not specified"))
		unless (defined ($args{RDATA}));
	return (Unix::Conf->_err ('new', "PARENT not specified"))
		unless (defined ($args{PARENT}));

	$ret = $new->_parent ($args{PARENT}) or return ($ret);
	$ret = $new->class ($args{CLASS}) or return ($ret)
		if (defined ($args{CLASS}));
	$ret = $new->ttl ($args{TTL}) or return ($ret)
		if (defined ($args{TTL}));

	$ret = $new->rtype ('MX') or return ($ret);
	$ret = $new->mxpref ($args{MXPREF}) or return ($ret);
	$ret = $new->rdata ($args{RDATA}) or return ($ret);
	$ret = $new->label ($args{LABEL}) or return ($ret);

	return ($new);
}

=item mxpref ()

 Arguments
 mxpref	# number

Object method.
Get/set the record's mxpref. If an argument is passed, the invocant's
mxpref is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's mxpref is returned.

=cut

# Object method. Get/Set MXPREF
sub mxpref
{
	my ($self, $mxpref) = @_;

	if (defined ($mxpref)) {
		return (Unix::Conf->_err ('mxpref', "illegal MXPREF value `$mxpref'"))
			if ($mxpref !~ /^\d+$/);
		$self->{MXPREF} = $mxpref;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{MXPREF}) ? $self->{MXPREF} :
			Unix::Conf->_err ('mxpref', "MXPREF not defined")
	);
}

1;
