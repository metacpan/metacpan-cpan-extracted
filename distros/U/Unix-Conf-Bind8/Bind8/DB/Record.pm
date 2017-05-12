# Base class for a Bind8 zone record
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1	NAME

Unix::Conf::Bind8::DB::Record - Base class which contains 
methods which are inherited by the derived classes residing 
under Unix::Conf::Bind8::DB.

=head1 SYNOPSIS

    use Unix::Conf::Bind8;

    my ($conf, $db, $rec, $ret);

    # get a db object from a valid Unix::Conf::Bind8::Conf object
    $db = $conf->get_db ('extremix.net')
        or $die ("couldn't get db object for `extremix.net'");
	
    # create a new A record. All new_* methods are similar except 
    # for new_mx (), where an extra argument MXPREF has to be
    # provided.
    $rec = $db->new_a (
        LABEL	=> 'www',
        TTL		=> '1d',
        RDATA	=> '192.168.1.1',
    ) or $rec->die ("couldn't create A record for www.extremix.net");

    $rec = $db->get_a ('www', '192.168.1.1')
        or $rec->die ("couldn't get record object for www.extremix.net A 192.168.1.1");

    # get attribute values
    printf ("Class for record `www.extremix.net' A 192.168.1.1 is $ret\n")
        if ($ret = $rec->class ());

    # set attribute values
    $ret = $rec->ttl ('1w') 			or $ret->die ("couldn't set ttl");
    $ret = $rec->rdata ('192.168.2.1')	or $ret->die ("couldn't set rdata");

    # delete record
    $ret = $rec->delete () or $ret->die ("couldn't delete");

=over 4

=head1 METHODS

=cut

package Unix::Conf::Bind8::DB::Record;

use strict;
use warnings;
use Unix::Conf;
use Unix::Conf::Bind8::DB;
use Unix::Conf::Bind8::DB::Lib;

=item new ()

 Arguments
 LABEL		=> 'string',
 CLASS		=> 'string',	# 'IN'|'HS'|'CHAOS'
 TTL		=> 'string'|number,
 RTYPE		=> 'string',	# 'A'|'NS'|'MX'|'SOA'|'CNAME'|'PTR'
 RDATA		=> data
 PARENT		=> reference,	# to the DB object datastructure

Class constructor.
Creates a new Unix::Conf::Bind8::DB::* object and returns it
if successful, an Err object otherwise. Do not use this constructor
directly. Use the Unix::Conf::Bind8::DB::new_* equivalent instead.

=cut

# Arguments
#  LABEL
#  RTYPE
#  RDATA
#  PARENT
#  CLASS
#  TTL
sub new
{
	my $class = shift ();
	my %args = ( @_ );
	my $new = bless ({}, $class);
	my $ret;

	return (Unix::Conf->_err ('new', "LABEL not specified"))
		unless (defined ($args{LABEL}));
	return (Unix::Conf->_err ('new', "RTYPE not specified"))
		unless (defined ($args{RTYPE}));
	return (Unix::Conf->_err ('new', "RDATA not specified"))
		unless (defined ($args{RDATA}));
	return (Unix::Conf->_err ('new', "PARENT not specified"))
		unless (defined ($args{PARENT}));

	$new->_parent ($args{PARENT});
	$ret = $new->class ($args{CLASS}) or return ($ret)
		if (defined ($args{CLASS}));
	$ret = $new->ttl ($args{TTL}) or return ($ret)
		if (defined ($args{TTL}));

	$ret = $new->rtype ($args{RTYPE}) or return ($ret);
	$ret = $new->rdata ($args{RDATA}) or return ($ret);
	$ret = $new->label ($args{LABEL}) or return ($ret);

	return ($new);
}

=item label ()

 Arguments
 'label'

Object method.
Get/set the record's label. If an argument is passed, the invocant's
label is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's label is returned.

=cut

sub label
{
	my ($self, $label) = @_;
	my $ret;

	if (defined ($label)) {
		# the object is stored in a complicated datastructure keyed
		# on the label among other things. so we need to delete the 
		# old key and store the object at the new key
		if (defined ($self->{LABEL})) {
			$ret = Unix::Conf::Bind8::DB::_delete_object ($self) or return ($ret);
		}
		$self->{LABEL} = $label;
		$ret = Unix::Conf::Bind8::DB::_insert_object ($self) or return ($ret);
		$self->dirty (1);
		return (1);
	}

	return (
		defined ($self->{LABEL}) ? $self->{LABEL} :
			Unix::Conf->_err ('label', "LABEL not defined")
	);
}

=item class ()

 Arguments
 'class'

Object method.
Get/set the record's class. If an argument is passed, the invocant's
class is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's class is returned, if defined,
an Err object otherwise.

=cut

sub class 
{
	my ($self, $class) = @_;

	if (defined ($class)) {
		return (Unix::Conf->_err ('class', "illegal class `$class'"))
			if ($class !~ /^(in|hs|chaos)$/i);
		return (Unix::Conf->_err ('class', "class `$class' not the same as DB class `$self->{PARENT}{CLASS}'"))
			if ($class ne $self->{PARENT}{CLASS});
		$self->{CLASS} = $class;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{CLASS}) ? $self->{CLASS} : 	
			Unix::Conf->_err ('class', "class not defined")
	)
}

=item rtype ()

 Arguments
 'rtype'

Object method.
Get/set the record's rtype. If an argument is passed, the invocant's
rtype is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's rtype is returned.

=cut

# Do not allow change in RTYPE once defined
sub rtype
{
	my ($self, $rtype) = @_;

	if (defined ($rtype)) {
		return (Unix::Conf->_err ('rtype', "RTYPE already defined"))
			if (defined ($self->{RTYPE}));
		$self->{RTYPE} = $rtype;
		return (1);
	}
	return ($self->{RTYPE});
}

=item ttl ()

 Arguments
 ttl

Object method.
Get/set the record's ttl. If an argument is passed, the invocant's
ttl is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's ttl is returned, if defined,
an Err object otherwise.

=cut

sub ttl 
{
	my ($self, $ttl) = @_;

	if (defined ($ttl)) {
		return (Unix::Conf->_err ('ttl', "illegal ttl `$ttl'"))
			unless (__is_validttl ($ttl));
		$self->{TTL} = $ttl;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{TTL}) ? $self->{TTL} : 
			Unix::Conf->_err ('ttl', "TTL not defined")
	)
}

=item rdata ()

 Arguments
 data

Object method.
Get/set the record's rdata. If an argument is passed, the invocant's
rdata is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's rdata is returned.

=cut

sub rdata
{
	my ($self, $rdata) = @_;

	if (defined ($rdata)) {
		# the object is stored in a complicated datastructure keyed
		# on the rdata among other things. so we need to delete the 
		# old key and store the object at the new key
		if (defined ($self->{RDATA})) {
			my $ret;
			$ret = Unix::Conf::Bind8::DB::_delete_object ($self) 
				or return ($ret);
			# change rdata now before storing in new location as it is
			# depenedant on the rdata.
			$self->{RDATA} = $rdata;
			return (Unix::Conf::Bind8::DB::_insert_object ($self));
			$self->dirty (1);
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

=item dirty ()

 Arguments
 dirty	# numeric

Object method.
Get/set the dirty attribute. If an argument is passed, sets it
as the value of the dirty attribute, and returns true on success,
an Err object otherwise. If no argument is passed, returns the
value of the attribute.

=cut

# we set the dirty flag in the containing object using the PARENT member.
sub dirty
{
	my ($self, $dirty) = @_;

	if (defined ($dirty)) {
		$self->{PARENT}{DIRTY} = $dirty;
		return (1);
	}
	return ($self->{PARENT}{DIRTY});
}

=item delete ()

Object method.
Deletes the invocant record and returns true on success,
an Err object otherwise.

=cut

sub delete
{
	return (Unix::Conf::Bind8::DB::_delete_object ($_[0]));
	$_[0]->dirty (1);
}

# this is used to set the memeber PARENT which points to the hash in
# which we are contained. This helps us set the dirty flag in case
# we are modified.
sub _parent
{
	my ($self, $parent) = @_;

	if (defined ($parent)) {
		# Don't allow changing value once defined.
		return (Unix::Conf->_err ('parent', "PARENT already defined"))
			if (defined ($self->{PARENT})); 
		$self->{PARENT} = $parent;
		return (1);
	}
	return (
		defined ($self->{PARENT}) ? $self->{PARENT} :
			Unix::Conf->_err ('parent', "PARENT not defined")
	);
}

1;
__END__
