# Bind8 DB handling
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::DB - Class implementing methods for manipulation of
a Bind records file.

=head1 NOTE

Almost all methods need a label. All records are attached to 
one. If labels are not absolute (not ending in a '.'), they 
are considered relative to the DB origin (zone name). A label of 
'' means the records are attached to the origin itself. For 
example below the origin for the db is extremix.net. So any 
records with a label of '' is attached for extremix.net. 
Alternatively it could be specified as 'extremix.net.'

When an zone record file is read up, the label attribute is
relative to the DB origin, the format it is in the zone record
file notwithstanding. Same goes for the 'rdata' attribute.

The object must have a valid SOA record, since it is mandatory
that every zone have one. If the object destructor is invoked
without a defined SOA record, the destructor blows up. It is
the responsibility of the user to ensure this.

=head1 SYNOPSIS

    use Unix::Conf::Bind8;

    my ($conf, $db, $rec, $ret);
    $conf = Unix::Conf::Bind8->new_conf (
        FILE	=> 'named.conf',
        SECURE_OPEN	=> 0
    ) or $conf->die ("couldn't get `named.conf'");

    $db = $conf->get_db ('extremix.net')
        or $db ->die ("couldn't get db for `extremix.net'");
	
    # All records have corresponding new_*, get_*, delete_*
    # methods. Only SOA doesn't have a set_* version, which
	# can be simulated by a delete_soa followed by a new_soa.

    # get a record object.
    $rec = $db->get_soa () or $rec->die ("couldn't get SOA");

    # add new A record. similarly for other record types 
    $ret = $db->new_a (
        LABEL	=> 'ns3', 
        TTL		=> '1d',
        RDATA	=> '10.0.0.10',
    ) or $ret->die ("couldn't create A record for `ns3'");

    # delete a specific NS record
    $ret = $db->delete_ns ('', 'ns1')
        or $ret->die ("couldn't delete NS record `ns1' for `extremix.net'");

    # delete all MX records for domain www.extremix.net
    $ret = $db->delete_mx ('www')
        or $ret->die ("couldn't delete MX records for `extremix.net'");

	# delete all records for a label
	$ret = $db->delete_records ('subdomain.extremix.net.')
		or $ret->die ("couldnt delete records for `subdomain'");

	# get all NS records for extremix.net
	$ret = $db->get_ns ('') 	
		or $ret->die ("couldn't get NS records for `extremix.net'");
	print ("NS records for extremix.net:\n");
	print $_->rdata (), "\n" for (@$ret);

	# get a specific record
	$rec = $db->get_a ('www', '192.168.1.1')
		or $rec->die ("couldn't get A record for www.extremix.net");
	print ("LABEL => www.extremix.net\n");
	printf ("TTL => %s\n", $ret) if ($ret = $rec->ttl ());
	printf ("CLASS => %s\n", $ret) if ($ret = $rec->class ());
	printf ("RTYPE => A\n", $ret);
	printf ("RDATA => 192.168.1.1");

	# Iterate over a list of all records.
	while (my $rec = $db->records ()) {
		# do stuff
	}

	# OR

	my @records = $db->records ();
	for (@records) {
		# do stuff
	}

=head1 DESCRIPTION

This class has interfaces for the various classes residing
beneath Unix::Conf::Bind8::DB. This is an internal class should 
not be accessed directly. Methods in this class are to be accessed
through a Unix::Conf::Bind8::DB object which is returned
by Unix::Conf::Bind8->new_db () or by invoking the get_db ()
object method in Unix::Conf::Bind8::Conf or Unix::Conf::Bind8::Conf::Zone.

=over 4

=cut

package Unix::Conf::Bind8::DB;

use strict;
use warnings;

use Unix::Conf;
use Unix::Conf::Bind8::DB::SOA;
use Unix::Conf::Bind8::DB::NS;
use Unix::Conf::Bind8::DB::MX;
use Unix::Conf::Bind8::DB::A;
use Unix::Conf::Bind8::DB::PTR;
use Unix::Conf::Bind8::DB::CNAME;
use Unix::Conf::Bind8::DB::Lib;

#
# Unix::Conf::Bind8::DB object
# 
# SCALARREF -> {
#                 FH
#                 ORIGIN
#                 CLASS
#                 DIRTY
#				  SOA
#				  RECORDS -> {
#							   DATA      -> {
#                                              'label' -> {
#                                                           'rtype' -> {
#                                                                        'rdata'
#                                                                      }
#                                                         }
#                                           }
#                              CHILDREN   -> {
#                                              'label' -> {
#                                                           DATA
#                                                           CHILDREN
#                                                         }
#                                            }
#                            }
#			   }
#
# Zone: 
#           example.com
# Records:
#           example.com			IN	A 	10.0.0.1
#			ns.example.com		IN  A	10.0.0.2
#			ns.sub.example.com	IN	A	10.0.0.3
#
#               RECORDS -> {
#							   DATA      -> {
#                                              '' -> {
#                                                      'A' -> {
#                                                               '10.0.0.1' -> Unix::Conf::Bind8::DB::A object
#                                                             }
#                                                    }
#                                              'ns' -> {
#                                                      'A' -> {
#                                                               '10.0.0.2' -> Unix::Conf::Bind8::DB::A object
#                                                             }
#                                                    }
#                                           }
#                              CHILDREN   -> {
#                                              'sub' -> {
#                                                         DATA -> {
#                                                                     'ns' -> {
#                                                                                'A' -> {
#                                                                                         '10.0.0.2' -> Unix::Conf::Bind8::DB::A object
#                                                                                       }
#                                                                             }
#                                                                 }
#                                                       }
#                                            }
#                          }
#
# The way this is stored, almost all the information is duplicated in both the object
# and the tree. But this seems to be the only way out if we want to come up with a
# DB object containing other record objects setup. This is done here to maintain
# uniformity with Bind8::Conf where the constituent objects in a Bind8::Conf object
# are complicated and different enough to warrant their own classes.
#

=item new ()

 Arguments
 FILE        => 'pathname',   # 
 ORIGIN      => 'value',      # origin
 CLASS       => 'class',      # ('in'|'hs'|'chaos')
 SECURE_OPEN => 0/1,          # optional (enabled (1) by default)

Class constructor
Creates a Unix::Conf::Bind8::DB object and returns it if
successful, an Err object otherwise. Direct use of this method 
is deprecated. Use Unix::Conf::Bind8::Zone::get_db (), or 
Unix::Conf::Bind8::new_db () instead.

=cut

# ARGUMENTS: hash
#	FILE
#	ORIGIN
#	CLASS
#	SECURE_OPEN
# RETURN
# 	Unix::Conf::Bind8::DB/Unix::Conf::Err object
# The object created is a ref to a scalar which contains a ref
# to a hash. This is to break the circular reference problem.
sub new
{
	my $invocant = shift ();
	my %args = @_;
	my ($new, $db, $ret);

	$args{FILE} || return (Unix::Conf->_err ('new', "DB file not specified"));	
	$args{ORIGIN} || return (Unix::Conf->_err ('new', "DB origin not specified"));
	$args{ORIGIN} .= "." unless (__is_absolute ($args{ORIGIN}));
	$args{CLASS} || return (Unix::Conf->_err ('new', "DB class not specifed"));
	$args{SECURE_OPEN} = defined ($args{SECURE_OPEN}) ?  $args{SECURE_OPEN} : 1;
	$db = Unix::Conf->_open_conf (
		NAME => $args{FILE}, SECURE_OPEN => $args{SECURE_OPEN} 
	) or return ($db);
	# we are blessing a reference to a hashref.
	$new = bless (\{ RECORDS => {}, DIRTY => 0 });
	$$new->{FH} = $db;
	$ret = $new->origin ($args{ORIGIN}) or return ($ret);
	$ret = $new->class ($args{CLASS}) or return ($ret);
	# check for any syntax probs in the classes. change parser later.
	eval { $ret = $new->__parse_db (); } or return ($@);
	return ($new);
}

sub DESTROY
{
	my $self = $_[0];

	die (
		Unix::Conf->_err (
			"DESTROY", 
			sprintf ("SOA not defined for zone `%s'", $self->origin ())
		)
	) unless ($self->get_soa ());

	if ($$self->{DIRTY}) {
		my $fh = $self->fh ();
		my $str = __render ($self);
		$fh->set_scalar ($str);
	}
	# release all contained stuff
	undef (%$$self);
}

=item origin ()

 Arguments
 'origin',   # optional. if the argument is not absolute, i.e.
             # having a trailing '.', the existing origin, if
		     # any will be appended to the argument.

Object method.
Get/Set DB origin. If argument is passed, the method tries to set the
origin of the DB object to 'origin' and returns true on success, an Err
object otherwise. If no argument is specified, returns the name of the
zone, if defined, an Err object otherwise. 

=cut

sub origin
{
	my ($self, $origin) = @_;
	
	if (defined ($origin)) {
		$$self->{ORIGIN} = __is_absolute ($origin) ? $origin :
			(defined ($$self->{ORIGIN}) ? $origin.$$self->{ORIGIN} : $origin.'.');
		return (1);
	}
	return (
		defined ($$self->{ORIGIN}) ? $$self->{ORIGIN} : Unix::Conf->_err ('origin', "origin not defined")
	);
}

=item fh ()

Object method.
Returns the Unix::Conf::ConfIO object representing the DB file.

=cut

sub fh
{
	my $self = $_[0];
	return ($$self->{FH});
}

=item dirty ()

Object method.
Get/Set the DIRTY flag in invoking Unix::Conf::Bind8::DB object.

=cut

sub dirty
{
	my ($self, $dirty) = @_;

	if (defined ($dirty)) {
		$$self->{DIRTY} = $dirty;
		return (1);
	}
	return ($$self->{DIRTY});
}

=item class ()

 Arguments
 'class'      # ('in'|'hs'|'chaos')

Object method.
Get/Set object class. If argument is passed, the method tries to set the 
class attribute to 'class' and returns true if successful, an Err object
otherwise. If no argument is passed, returns the value of the class 
attribute if defined, an Err object otherwise.
Note:
Typically class is set in the zone statement. Each record can have a 
zone specified. But that cannot be different from the value set here.

=cut

# Typically class is set in the zone statement. Each record can have a 
# zone specified. But that cannot be different from the value set here.
sub class
{
	my ($self, $class) = @_;

	if (defined ($class)) {
		return (Unix::Conf->_err ('class', "illegal class `$class'"))
			if ($class !~ /^(in|hs|chaos)$/i);
		$$self->{CLASS} = $class;
		$$self->{DIRTY} = 1;
		return (1);
	}
	return (
		defined ($$self->{CLASS}) ? $$self->{CLASS} : Unix::Conf->_err ('class', "class not defined")
	);
}


=item delete_methods ()

 Argument
 'label'

Object method.
Deletes all records attached to a label. Returns true on success,
an Err object otherwise.

=cut

sub delete_records 
{
	my ($self, $label) = @_;
	
	$label = __make_relative ($self->origin (), $label);

	# dont' use __get_node as it is for a single record to be attached to a label
	# and does not work right for getting hold of an entire branch
	my ($leaf, $nodes) = ($label =~ /^((?:[\w-]+)?)\.?(.*)$/);
	my @nodes = split (/\./, $nodes);
	unshift (@nodes, $leaf);
	my $node = $$self->{RECORDS};
	while (@nodes) {
		$_ = pop (@nodes);
		# assume it is a branch first
		if ($node->{CHILDREN} && $node->{CHILDREN}{$_}) {
			$node  = $node->{CHILDREN}{$_} 
		}
		elsif ($node->{DATA} && $node->{DATA}{$_}) {
			$node = $node->{DATA}{$_};
		}
		else {
			return (Unix::Conf->_err ("delete_records", "no records defined for `$label'"));
		}
	}
	return (Unix::Conf->_err ("delete_records", "no records defined for `$label'"))
		unless (keys (%$node));
	# delete all keys
	undef (%$node);
	$$self->{DIRTY} = 1;
	return (1);
}

=item new_soa ()

 Arguments
 CLASS   =>
 TTL     =>
 AUTH_NS =>
 MAIL_ADDR   =>
 SERIAL  =>
 REFRESH =>
 RETRY   =>
 EXPIRE  =>
 MIN_TTL =>

Object method.
Creates and associates a new Unix::Conf::Bind8::DB::SOA object 
with the invoking Unix::Conf::Bind8::DB object and returns it
on success, an Err object otherwise.

=cut

# The only new_* method where this method adds the SOA to the
# the DB object. In other methods it is done by the corresponding
# new_* constructors.
sub new_soa
{
	my $self = shift ();
	my (%args, $new);
	return (Unix::Conf->_err ('new_soa', "SOA already defined"))
		if ($$self->{SOA});
	%args = ( @_ );
	# make sure an illegal class is not set.
	return (Unix::Conf->_err ('new_soa', "illegal class `$args{CLASS}'for SOA"))
		if ($args{CLASS} ne $$self->{CLASS});
	$new = Unix::Conf::Bind8::DB::SOA->new ( @_, RTYPE => 'SOA', PARENT => $$self ) or Unix::Conf->_err ($new);
	$$self->{DIRTY} = 1;
	return ($$self->{SOA} = $new);
}

=item get_soa ()

Object method.
Returns the Unix::Conf::Bind8::DB::SOA object associated with the invoking
Unix::Conf::Bind8::DB object if defined, an Err object otherwise.

=cut

sub get_soa
{
	my $self = $_[0];

	return (
		$$self->{SOA} ? $$self->{SOA} : Unix::Conf->_err ('get_soa', "SOA not defined")
	);
}

=item delete_soa ()

Object method.
Deletes the Unix::Conf::Bind8::DB::SOA object associated with the invoking
Unix::Conf::Bind8::DB object if defined and returns true, an Err object 
otherwise.

=cut

sub delete_soa
{
	my $self = $_[0];

	return (Unix::Conf->_err ('delete_soa', "SOA not defined"))
		unless ($$self->{SOA});
	delete ($$self->{SOA});
	$$self->{DIRTY} = 1;
	return (1);
}

=item new_ns ()

=item new_a ()

=item new_ptr ()

=item new_cname ()

 Arguments
 LABEL		=>
 CLASS		=>
 TTL		=>
 RDATA		=>

Object method.
Creates and associates a corresponding Unix::Conf::Bind8::DB::* 
object with the invoking Unix::Conf::Bind8::DB object and 
returns it, on success an Err object otherwise.

=cut

=item new_mx ()

 Arguments
 LABEL		=>
 MXPREF		=>
 CLASS		=>
 TTL		=>
 RDATA		=>

Object method.
Creates and associates a new Unix::Conf::Bind8::DB::MX object 
with the invoking Unix::Conf::Bind8::DB object and returns it,
on success an Err object otherwise.

=item get_ns ()

=item get_a ()

=item get_ptr ()

=item get_cname ()

=item get_mx ()

 Arguments
 'label',
 'rdata'			# optional

Object method.
Returns the corresponding Unix::Conf::Bind8::DB::* object 
associated with the invoking Unix::Conf::Bind8::DB object, 
with label 'label' and rdata 'rdata'. If the rdata argument 
is not passed, then all `rdata' record objects attached to label 
'label' are returned in an anonymous array. On failure an 
Err object is returned.

=cut

=item set_ns ()

=item set_a ()

=item set_ptr ()

=item set_cname ()

 Arguments
 'label',
 [
 	{ CLASS => 'class', TTL => 'ttl', RDATA => 'rdata',  },
 	{ CLASS => 'class', TTL => 'ttl', RDATA => 'rdata',  },
 	....
 ],

Object method.
Creates and associates corresponding Unix::Conf::Bind8::DB::* 
objects with the relevant attributes with the invoking 
Unix::Conf::Bind8::DB object. Returns true on success, an 
Err object otherwise. The existing 
Unix::Conf::Bind8::DB::* objects attached to this label are
deleted.

=cut

=item set_mx ()

 Arguments
 'label',
 [
 	{ CLASS => 'class', TTL => 'ttl', MXPREF => pref, RDATA => 'rdata',  },
 	{ CLASS => 'class', TTL => 'ttl', MXPREF => pref, RDATA => 'rdata',  },
 	....
 ],

Object method.
Creates and associates Unix::Conf::Bind8::DB::MX objects with the 
relevant attributes with the invoking Unix::Conf::Bind8::DB object.
Returns true on success, an Err object otherwise. The existing
Unix::Conf::Bind8::DB::MX objects attached to this label are
deleted.

=cut

=item delete_ns ()

=item delete_a ()

=item delete_ptr ()

=item delete_cname ()

=item delete_mx ()

 Arguments
 'label',
 'rdata',

Object method.
Deletes the corresponding Unix::Conf::Bind8::DB::* object with 
label 'label' and rdata 'rdata', associated with the invoking 
Unix::Conf::Bind8::DB object if defined and returns true, an 
Err object. If the rdata argument is not passed, then all 
corresponding records attached to label 'label' are deleted.

=cut

for my $rtype qw (NS A MX PTR CNAME) 
{
	no strict 'refs';
	# new_*
	my $meth = lc ($rtype);
	my $newmeth = "new_$meth";
	my $delmeth = "delete_$meth";
	*$newmeth = sub {
		my $self = shift ();
		return ("Unix::Conf::Bind8::DB::$rtype"->new ( @_, RTYPE => $rtype, PARENT => $$self ));
	};

	*{"get_$meth"} = sub {
		my ($self, $label, $rdata) = @_;
		return (Unix::Conf->_err ("get_$meth", "label not specified"))
			unless (defined ($label));
		my $node = __get_node ($$self, $label);
		return (Unix::Conf->_err ("get_$meth", "$rtype record for `$label' not defined"))
			unless ($node->{$rtype});
		# get a record with value of $rdata for $label
		if (defined ($rdata)) {
			return (Unix::Conf->_err ("get_$meth", "$rtype record for `$label' with rdata of `$rdata' not defined"))
				unless ($node->{$rtype}{$rdata});
			return ($node->{$rtype}{$rdata});
		}
		# else return all records for of that particular RTYPE for $label
		return ( [ values (%{$node->{$rtype}}) ] );
	};

	*{"set_$meth"} = sub {
		my ($self, $label, $arg) = @_;
		my ($rdata, $ret);
		return (Unix::Conf->_err ("set_$meth", "label not passed"))
			unless (defined ($label));
		return (Unix::Conf->_err ("set_$meth", "RDATA not passed"))
			unless ($arg);
		if (ref ($arg)) {
			if (UNIVERSAL::isa ($arg, 'HASH')) {
				$rdata = [ $arg ];
			}
			elsif (UNIVERSAL::isa ($arg, 'ARRAY')) {
				$rdata = $arg;
			}
			else {
				Unix::Conf->_err ("set_$meth", "RDATA type is either a hash ref or an array ref");
			}
		}
		else {
			Unix::Conf->_err ("set_$meth", "RDATA type is either a hash ref or an array ref");
		}
		# first delete all old values for that label
		$ret = $delmeth->($self, $label) or return ($ret);
		for (@$rdata) {
			$_->{LABEL} = $label;
			$ret = $newmeth->($self, %{$_}) or return ($ret);
		}
		return (1);
	}; 

	*$delmeth = sub {
		my ($self, $label, $rdata) = @_;
		return (Unix::Conf->_err ("delete_$meth", "label not specified"))
			unless (defined ($label));
		my $node = __get_node ($$self, $label);
		return (Unix::Conf->_err ("delete_$meth", "$rtype record for `$label' not defined"))
			unless ($node->{$rtype});

		# delete the $rtype record with value $rdata for $label
		if (defined ($rdata)) {
			$rdata = __make_relative ($$self->{ORIGIN}, $rdata);
			return (Unix::Conf->_err ("delete_$meth", "$rtype record for `$label' with rdata of `$rdata' not defined"))
				unless ($node->{$rtype}{$rdata});
			delete ($node->{$rtype}{$rdata});
			# delete rtype if there are no types left.
			delete ($node->{$rtype})
				unless (keys (%{$node->{$rtype}}));
			$self->dirty (1);
			return (1);
		}

		# else delete all $rtype records for $label
		delete ($node->{$rtype});
		$self->dirty (1);
		return (1);
	};
}

=item records ()

Object method.
Returns records defined in the zone. When called in a list context, 
returns all defined records. Iterates over defined records, when 
called in a scalar method. Returns `undef' at the end of one 
iteration, and starts over if called again.

=cut

{
	sub __traverse ($$;$);
	sub records 
	{
		my ($self, $label) = @_;
		my $travarg;
		# create a list of records only it iterator is at start
		unless ($$self->{ITR}) {
			undef (@{$$self->{RECARRAY}});
			push (@{$$self->{RECARRAY}}, $$self->{SOA}) unless (defined ($label));
			my $node = $$self->{RECORDS};
			if ($label) {
				my ($leaf, $nodes) = ($label =~ /^((?:[\w-]+)?)\.?(.*)$/);
				my @nodes = split (/\./, $nodes);
				unshift (@nodes, $leaf);
				while (@nodes) {
					$_ = pop (@nodes);
					# assume it is a branch first
					if ($node->{CHILDREN} && $node->{CHILDREN}{$_}) {
						$node  = $node->{CHILDREN}{$_} 
					}
					elsif ($node->{DATA} && $node->{DATA}{$_}) {
						# if there is a valid value for $_ under DATA
						# there @nodes should be empty. Sanity check.
						return (Unix::Conf->_err ("records", "internal consistency error"))
							if (@nodes);
						# force __traverse to iterate only through all records for
						# $_ under $node->{DATA} instead of all records under all labels 
						# under $node->{DATA}
						$travarg = $_; 
						last;
					}
					else {
						return (Unix::Conf->_err ("records", "no records defined for `$label'"));
					}
				}
			}
			__traverse ($$self->{RECARRAY}, $node, $travarg);
		}

		if (wantarray ()) {
			# reset iterator before returning
			$$self->{ITR} = 0;
			return (@{$$self->{RECARRAY}}) 
		}
		# return undef on completion of one iteration
		return () if ($$self->{ITR} && !($$self->{ITR} %= scalar (@{$$self->{RECARRAY}})));
		return (${$$self->{RECARRAY}}[$$self->{ITR}++]);
	}

	sub __traverse ($$;$)
	{
		my ($arrref, $node, $label) = @_;
		my @labels = defined ($label) ? ($label) : sort (keys (%{$node->{DATA}}));

		for my $_label (@labels) {
			for my $rectype (sort (keys (%{$node->{DATA}{$_label}}))) {
				for my $rec (sort (keys (%{$node->{DATA}{$_label}{$rectype}}))) {
					push (@$arrref, $node->{DATA}{$_label}{$rectype}{$rec});
				}
			}
		}

		# if $label is defined, there will be no CHILDREN, or at least there 
		# ought not to be.
		unless (defined ($label)) {
			for my $child (sort (keys (%{$node->{CHILDREN}}))) {
				__traverse ($arrref, $node->{CHILDREN}{$child});
			}
		}
	}
}

# Utility functions used to insert/delete objects from the database tree
# ARGUMENT: Unix::Conf::Bind8::DB::Record or derived object. 
#
# NOTE: If the label is relative, it is assumed to be relative to
# the zone origin.
#
sub _insert_object
{
	my $object = $_[0];

	return (Unix::Conf->_err ('_insert_object', "Record object not specified"))
		unless ($object);
	return (Unix::Conf->_err ('_insert_object', "Record object not a child class of type Unix::Conf::Bind8::DB::Record"))
		unless ($object->isa ('Unix::Conf::Bind8::DB::Record'));
	my $root = $object->_parent ();

	my ($label, $rtype, $rdata);
	defined ($label = $object->label ()) or return ($label);
	$rtype = $object->rtype () or return ($rtype);
	$rdata = $object->rdata () or return ($rdata);
	$rdata = __make_relative ($root->{ORIGIN}, $rdata)
		if ($rtype ne 'A');

	my $node = __get_node ($root, $label);
	return (Unix::Conf->_err ('_insert_object', "Record with label `$label' of type `$rtype' with data `$rdata' already defined"))
		if ($node->{$rtype}{$rdata});
	return ($node->{$rtype}{$rdata} = $object);
}

# ARGUMENT: Unix::Conf::Bind8::DB::Record or derived object. 
sub _delete_object
{
	my $object = $_[0];

	return (Unix::Conf->_err ('_delete_object', "Record object not specified"))
		unless ($object);
	return (Unix::Conf->_err ('_delete_object', "Record object not a child class of type Unix::Conf::Bind8::DB::Record"))
		unless ($object->isa ('Unix::Conf::Bind8::DB::Record'));
	my $root = $object->_parent ();
	my ($label, $rtype, $rdata);
	defined ($label = $object->label ()) or return ($label);
	$rtype = $object->rtype () or return ($rtype);
	$rdata = $object->rdata () or return ($rdata);
	$rdata = __make_relative ($root->{ORIGIN}, $rdata)
		if ($rtype ne 'A');

	my $node = __get_node ($root, $label);
	return (Unix::Conf->_err ('_delete_object', "Record with label `$label' of type `$rtype' with data `$rdata' not defined"))
		unless ($node->{$rtype}{$rdata});
	delete ($node->{$rtype}{$rdata});
	delete ($node->{$rtype})
		unless (keys (%{$node->{$rtype}}));
	return (1);
}

#sub _get_object
#{
#	my ($root, $label, $rtype, $rdata) = @_;
#
#	return (Unix::Conf->_err ('_get_object', "label not specified"))
#		unless (defined ($label));
#	return (Unix::Conf->_err ('_get_object', "rtype not specified"))
#		unless (defined ($rtype));
#	return (Unix::Conf->_err ('_get_object', "rdata not specified"))
#		unless (defined ($rdata));
#
#	my $node = __get_node ($root, $label);
#	return (Unix::Conf->_err ('_get_object', "Record with label `$label' of type `$rtype' with data `$rdata' not defined"))
#		unless ($node->{$rtype}{$rdata});
#	return ($node->{$rtype}{$rdata});
#}

sub __get_node
{
	my ($root, $olabel) = @_;
	my $label;
	return (Unix::Conf->_err ('__get_node', "`$olabel' lies outside `$root->{ORIGIN}'"))
		unless (defined ($label = __make_relative ($root->{ORIGIN}, $olabel)));

	my $ptr = $root->{RECORDS};
	# use regex to pull out a pattern so that the $leaf will be '', not undef
	# in case of $label being ''
	my ($leaf, $nodes) = ($label =~ /^((?:[\w-]+)?)\.?(.*)$/);
	my @nodes = split (/\./, $nodes);
	unshift (@nodes, $leaf);

TRAVERSE:
	# traverse the tree
	while (@nodes) {
		$_ = pop (@nodes);

		# if @nodes has exactly one element left, then we will
		# need to create another branch, by attaching an anon hash
		# to $ptr->{CHILDREN}{$_}. The element left in @node, will
		# be attached to $ptr->{CHILDREN}{$_}{DATA}{element}. Now
		# if we find that {DATA} is already defined for $_, we
		# need to move it to under $ptr->{CHILDREN}{$_}{DATA}{''}.
		# The result of this is, if no branch exists, the leaf node
		# will be the leftmost part (with '.' as separators).  But 
		# if a branch exists, the leaf will be a '', and the leftmost
		# part shifted as another branch.
		# Thus, assuming an origin of extremix.net, an A record for 
		# www will be attached to $root->{RECORDS}{DATA}{www}{A}{rdata}. 
		# Similarly for a NS record for sub. But, if then a record like www.sub is
		# encountered, then when sub is in $_ and www is still in @nodes,
		# the code below finds out that sub is going to be a branch.
		# So it will move $root->{RECORDS}{DATA}{sub} to 
		# $root->{RECORDS}{CHILDREN}{sub}{DATA}{''}.
		# So while, the www A record will be written out as
		# www	IN	A	rdata
		# the sub NS record (after encountering www.sub record), will be 
		# written out as
		# $ORIGIN sub.extremix.net.
		# 		IN	NS		rdata
		# www	IN	RTYPE	rdata
		if (@nodes == 1 && $ptr->{DATA}{$_}) {
			$ptr->{CHILDREN}{$_}{DATA}{''} = $ptr->{DATA}{$_};
			delete ($ptr->{DATA}{$_});
		}

		# this is to ensure that if CHILDREN 'foo' already exist, the correct
		# node for a label 'foo' is not under $ptr->{DATA}{foo}, but under
		# $ptr->{CHILDREN}{foo}{DATA}{''}. If no children the former course is
		# adopted. If later branch is created at foo, data attached to 
		# $ptr->{DATA}{foo} will be shifted down by the previous block of code.
		# as @nodes now has something, it will not enter the unless (@nodes) 
		# below and loop again travelling down the tree and will be attached
		# with a label of ''.
		push (@nodes, '')
			if (!@nodes && $ptr->{CHILDREN} && $ptr->{CHILDREN}{$_});

		unless (@nodes) {
			$ptr->{DATA}{$_} = {}	unless ($ptr->{DATA}{$_});
			$ptr = $ptr->{DATA}{$_};
			last TRAVERSE;
		}

		# if this part of the tree doesn't exist create it.
		$ptr->{CHILDREN}{$_} = {} unless (defined ($ptr->{CHILDREN}{$_}));
		$ptr = $ptr->{CHILDREN}{$_}
	}
	return ($ptr);
}

# shared amongst __render_tree and __render
my ($Rendered, $Class, $DB_Origin);

# forward declaration
sub __render_tree ($$$$);
sub __render
{
	my $self = $_[0];
	$DB_Origin = $$self->{ORIGIN};
	$Class = $self->class ();

	# render SOA for the zone
	$Rendered = "\$ORIGIN $DB_Origin\n@\t";
	$Rendered .= "$$self->{SOA}{TTL}\t" if (defined ($$self->{SOA}{TTL}));
	my $auth_ns = __make_absolute ($DB_Origin, $$self->{SOA}{AUTH_NS});
	my $mail_addr = __make_absolute ($DB_Origin, $$self->{SOA}{MAIL_ADDR});
	$Rendered .= "$Class\tSOA\t$auth_ns\t$mail_addr (\n\t\t$$self->{SOA}{SERIAL}\n\t\t$$self->{SOA}{REFRESH}\n\t\t$$self->{SOA}{RETRY}\n\t\t$$self->{SOA}{EXPIRE}\n\t\t$$self->{SOA}{MIN_TTL})\n";

	__render_tree ($$self->{RECORDS}, $DB_Origin, 1, 1);
	return (\$Rendered);
}

sub __render_tree ($$$$)
{
	my ($node, $origin, $origin_printed, $at_printed) = @_;
	# print ORIGIN
	my $start = "\n";
	$start .= "\$ORIGIN $origin\n" unless ($origin_printed);

	# print all nodes in this level
	# sorting the keys will ensure that records with empty
	# labels '', will be printed first. it will be a serious
	# error if this is not so, as label is carried forward from
	# the previous record, in case of records with empty labels.
	for my $label (sort (keys (%{$node->{DATA}}))) {
		# do not do anything here as it is possible that 
		# there is a hash attached to $label, but with no records
		# defined as they have all been deleted.
		for my $rectype (sort (keys (%{$node->{DATA}{$label}}))) {
			# print '@' if the label is empty right after
			# ORIGIN is printed.
			if (!$at_printed && !$label) {
				$start .= '@';
			}
			else {
				$start .= "$label";
			}
			# once the first label is printed, whether it is a '@'
			# or an actual label, we don't need to print @ for 
			# empty labels.
			$at_printed = 1;
			for my $rec (sort (keys (%{$node->{DATA}{$label}{$rectype}}))) {
				my ($obj, $tmp);
				# print this only if there are records
				if ($start) { $Rendered .= $start; undef ($start); }
				#else 		{ $Rendered .= "\t"; }
				$Rendered .= "\t";
				$obj = $node->{DATA}{$label}{$rectype}{$rec};
				$Rendered .= "$tmp\t"
					if ($tmp = $obj->ttl ());
				$Rendered .= "$Class\t\U$rectype\E\t";
				$Rendered .= "$tmp\t"
					if ($rectype eq 'MX' && ($tmp = $obj->mxpref ()));
				# any relative labels are relative to DB_Origin. so make it abs
				# then relative to last printed origin before printing
				if ($rectype ne 'A') {
					$Rendered .= sprintf ("%s\n", __make_relative ($origin, __make_absolute ($DB_Origin, $rec)));
				}
				else {
					$Rendered .= "$rec\n";
				}
			}
		}
	}
	for my $child (sort (keys (%{$node->{CHILDREN}}))) {
		__render_tree ($node->{CHILDREN}{$child}, "$child.$origin", 0, 0);
	}
}

#################################  PARSER  #####################################
#                                                                              #
require 'Unix/Conf/Bind8/DB/Parser.pm';
#                                   END                                        #
#################################  PARSER  #####################################

1;

=head1 TODO

1. Finalise on the interface. Remove superfluous ones.
