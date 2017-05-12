# Acl.pm
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Acl - Class for handling Bind8 configuration
directive `acl'.

=head1 SYNOPSIS

	use Unix::Conf::Bind8;

	my ($conf, $acl, $zone, $tmpacl, $ret);
	$conf = Unix::Conf::Bind8->new_conf (
		FILE        => '/etc/named.conf',
		SECURE_OPEN => 1,
	) or $conf->die ("couldn't open `named.conf'");

	#
	# Ways to get an acl object.
	#

	$zone = $conf->get_zone ('extremix.net')
		or $zone->die ("couldn't get zone `extremix.net'");

	# create a new acl to be defined before the zone directive
	# 'extremix.net'.
	$acl = $conf->new_acl (
		NAME     => 'extremix.com-slaves', 
		ELEMENTS => [ qw (element1 element2) ],
		WHERE	 => 'BEFORE',
		WARG	 => $zone,
	) or $acl->die ("couldn't create `extremix.com-slaves'");

	# OR

	# get an existing acl named 'extremix.com-slaves'
	$acl = $conf->get_acl ('extremix.com-slaves')
		or $acl->die ("couldn't get ACL `extremix.com-slaves');

	#
	# Operations that can be performed on an Acl object.
	#

	# create an unnamed acl
	$tmpacl = $conf->new_acl (
		ELEMENTS => [ 'key key1', 'localhost' ]
	) or $tmpacl->die ("couldn't create unnamed acl");

	# Following operations can be performed on an Acl object.
	# NOTE: Legal Acl elements, are IP addresses, defined Acl 
	# names ('any','none','localhost','localnets') defined keys, 
	# and unnamed Acl objects

	# set the elements of the ACL. old values are deleted
	$ret = $acl->elements (qw (10.0.0.1 10.0.0.2))
		or $ret->die ("couldn't set elements on ACL `extremix.net-slaves'");

	# add elements
	$ret = $acl->add_elements ('10.0.0.3', '10.0.0.4', $tmpacl)
		or $ret->die ("couldn't add elements to ACL `extremix.net-slaves'");
    
	# delete elements. This will delete the acl if no elements are
	# left and the object is a named acl.
	$ret = $acl->delete_elements (qw (10.0.0.5 10.0.0.6))
		or $ret->die ("couldn't delete elements from ACL `extremix.net-slaves'")

	# delete an existing acl named 'extremix.com-slaves'
	$ret = $acl->delete () 
		or $ret->die ('couldn't delete ACL `extremix.com-slaves');

	# OR 

	$ret = $conf->delete_acl ('extremix.com-slaves')
		or $ret->die ("couldn't delete ACL `extremix.com-slaves');

=head1 METHODS

=cut

package Unix::Conf::Bind8::Conf::Acl;

use strict;
use warnings;

use Unix::Conf;
use Unix::Conf::Bind8::Conf::Directive;
our @ISA = qw (Unix::Conf::Bind8::Conf::Directive);

use Unix::Conf::Bind8::Conf::Lib;

=over 4

=item new ()

 Arguments
 NAME       => 'ACL-NAME',
 ELEMENTS   => [ qw (element1 element2) ],
 WHERE  => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG   => Unix::Conf::Bind8::Conf::Directive subclass object
                        # WARG is to be provided only in case WHERE eq 'BEFORE 
                        # or WHERE eq 'AFTER'
 PARENT	=> reference,   # to the Conf object datastructure.

Class constructor.
Creates a new Unix::Conf::Bind8::Conf::Acl object and returns it if successful,
an Err object otherwise.
Direct use of this method is deprecated. Use Unix::Conf::Bind8::Conf::new_acl ()
instead.

=cut
sub new
{
	my $class = shift ();
	my $new = bless ({});
	my %args = @_;
	my $ret;

	$args{PARENT} || return (Unix::Conf->_err ("new", "PARENT not defined"));
	$ret = $new->_parent ($args{PARENT}) or return ($ret);
	if ($args{NAME}) {
		$ret = $new->name ($args{NAME}) or return ($ret);
		$args{WHERE} = 'LAST' unless ($args{WHERE});
		$ret = Unix::Conf::Bind8::Conf::_insert_in_list ($new, $args{WHERE}, $args{WARG})
			or return ($ret);
	}
	$ret = $new->elements ($args{ELEMENTS} || []) or return ($ret);
	return ($new);
}

=item name ()

 Arguments
 'ACL-NAME'     # optional

Object method.
Get/set the object's name attribute. If an argument is passed, the method tries 
to set the name attribute to 'ACL-NAME' and returns true if successful, an 
Err object otherwise. If no argument passed, it returns the name.

=cut

sub name
{
	my ($self, $name) = @_;

	if (defined ($name)) {
		my $ret;

		__valid_string ($name);
		# already defined. changing name
		if ($self->{name}) {
			$ret = Unix::Conf::Bind8::Conf::_del_acl ($self) or return ($ret);
		}
		$self->{name} = $name;
		$ret = Unix::Conf::Bind8::Conf::_add_acl ($self) or return ($ret);
		$self->dirty (1);
		return (1);
	}
	return ($self->{name});
}

=item elements ()

 Arguments
 LIST OF ELEMENTS
 or 
 [ LIST OF ELEMENTS ]

Object method.
Get/set the object's elements attribute. If argument(s) is passed
the method tries to set the elements attribute. It returns true on 
success, an Err object otherwise. If no argument is passed, 
returns an array reference consisting of the elements of the object
(including Acl objects contained therein), if defined, an Err object 
otherwise.

=cut

sub __add_elements ($$);

sub elements
{
	my $self = shift ();
	my $elements;
	my (@obj, @ele);

	if (@_) {
		my $ret;
		if (ref ($_[0]) && !UNIVERSAL::isa ($_[0], 'Unix::Conf::Bind8::Conf::Acl')) {
			return (Unix::Conf->_err ("elements", "expected arguments are a list or an array ref"))
				unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
			$elements = $_[0];
		}
		else {
			# got a list
			$elements = [ @_ ];
		}
		for (@$elements) {
			if (ref ($_)) {
				push (@obj, $_);
			}
			else {
				# (\S.+) because there could be whitespace as in
				# '  !key  sample-key '. We want $2 to match 
				# 'key  sample-key', which will be converted to
				# 'key sample-key' in the next s//.
				s/^\s*(!?)\s*(\S.+?)\s*$/$1$2/;
				s/^(!?)key\s+(\S+)\s*$/$1key $2/;
				push (@ele, $_);
			}
			return ($ret) unless ($ret = __valid_element ($self->_parent (), $_));
			# if element is an Acl object, set its aclparent attribute to
			# us so that if and when all its elements are deleted, it can
			# delete itself by invoking its parent's delete_elements method.
			$_->{aclparent} = $self
				if (ref ($_) && UNIVERSAL::isa ($_, 'Unix::Conf::Bind8::Conf::Acl'));
		}
		# reinit values
		$self->{allelements} = {};
		$self->{elements} = {};
		$self->{objects} = {};
		__add_elements ($self, $elements);
		# set elements defined for this acl to 'elements'. weed out
		# acl objects. they are attached to 'objects'.
		@{$self->{elements}}{@ele} = 1 x @ele;
		# remember the reference will be stringified as the key. cannot
		# use. that need to use the values. that is why values not set to 1
		@{$self->{objects}}{@obj} = (@obj);
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{elements}) ? [  keys (%{$self->{allelements}}) ] :
			Unix::Conf->_err ('elements', "elements not set for this acl")
	);
}

# helper routine for elements and add_elements
# if the element is an Acl object, recursively call 
# ourself.
# 'allelements' key of an Acl object will contain all elements an Acl, including
# those of embedded elements. 'objects', will contain stringified references of the
# objects, including those contained inside the argument. The value is the same
# as the key for 'objects'.
sub __add_elements ($$)
{
	my ($self, $elements) = @_;

	for (@$elements) {
		if (ref ($_) && UNIVERSAL::isa ($_, 'Unix::Conf::Bind8::Conf::Acl')) {
			# accessing the embedded object's internals directly.
			@{$self->{allelements}}{keys (%{$_->{allelements}})} = values (%{$_->{allelements}});
			# now overwrite those values which are contained directly in $_ with the reference $_
			my @tmp = keys (%{$_->{elements}});
			@{$self->{allelements}}{@tmp} = ($_) x @tmp;
		}
		else {
			$self->{allelements}{$_} = 1;
		}
	}
}

=item add_elements ()

 Arguments
 LIST OF ELEMENTS
 or 
 [ LIST OF ELEMENTS ]

Object method.
Adds the argument to the elements of the invocant object. Returns true 
on success, an Err object otherwise.

=cut

sub add_elements
{
	my $self = shift ();
	my $elements;
	my (@obj, @ele);

	if (@_) {
		my $ret;

		if (ref ($_[0]) && !UNIVERSAL::isa ($_[0], 'Unix::Conf::Bind8::Conf::Acl')) {
			return (Unix::Conf->_err ("add_elements", "expected arguments are a list or an array ref"))
				unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
			$elements = $_[0];
		}
		else {
			# got a list
			$elements = [ @_ ];
		}
		for (@$elements) {
			if (ref ($_)) {
				return (Unix::Conf->_err ('add_elements', "object `$_' already defined"))
					if ($self->{objects}{$_});
				push (@obj, $_);
			}
			else {
				# (\S.+) because there could be whitespace as in
				# '  !key  sample-key '. We want $2 to match 
				# 'key  sample-key', which will be converted to
				# 'key sample-key' in the next s//.
				s/^\s*(!?)\s*(\S.+?)\s*$/$1$2/;
				s/^(!?)key\s+(\S+)\s*$/$1key $2/;
				return (Unix::Conf->_err ('add_elements', "element `$_' already defined"))
					if ($self->{allelements}{$_});
				push (@ele, $_);
			}
			return ($ret) unless ($ret = __valid_element ($self->_parent (), $_));
			# if element is an Acl object, set its aclparent attribute to
			# us so that if and when all its elements are deleted, it can
			# delete itself by invoking its parent's delete_elements method.
			$_->{aclparent} = $self
				if (ref ($_) && UNIVERSAL::isa ($_, 'Unix::Conf::Bind8::Conf::Acl'));
		}
		__add_elements ($self, $elements);
		# set elements defined for this acl to 'elements'. weed out
		# acl objects. they are attached to 'objects'.
		@{$self->{elements}}{@ele} = 1 x @ele;
		# remember the reference will be stringified as the key. cannot
		# use. that need to use the values. that is why values not set to 1
		@{$self->{objects}}{@obj} = (@obj);
		$self->dirty (1);
		return (1);
	}
	return (Unix::Conf->_err ('add_element', "elements to be added not specified"));
}

=cut delete_elements ()

 Arguments
 LIST OF ELEMENTS
 or 
 [ LIST OF ELEMENTS ]

Object method.
Deletes the argument from the elements of the invocant object and returns
true on success, an Err object otherwise.

=cut

sub delete_elements 
{
	my $self = shift ();
	my ($elements, $ret);

	return (Unix::Conf->_err ('delete_elements', "elements to be deleted not specified"))
		unless (@_);

	if (ref ($_[0]) && !UNIVERSAL::isa ($_[0], 'Unix::Conf::Bind8::Conf::Acl')) {
		return (Unix::Conf->_err ("delete_elements", "expected arguments are a list or an array ref"))
			unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
		$elements = $_[0];
	}
	else {
		# got a list
		$elements = [ @_ ];
	}
	for (@$elements) {
		if (ref ($_)) {
			return (Unix::Conf->_err ('delete_elements', "object `$_' not defined"))
				unless ($self->{objects}{$_});
			next;
		}
		s/^\s*(!?)\s*(\S.+?)\s*$/$1$2/;
		s/^(!?)key\s+(\S+)\s*$/$1key $2/;
		return (Unix::Conf->_err ('delete_elements', "element `$_' not defined"))
			unless ($self->{allelements}{$_});
	}
	my $obj;
	# lookup the allelements map to see if any of the elements to 
	# be deleted is contained in an embedded object. if so delete
	# from that object.
	for (@$elements) {
		# if the element is an Acl object delete elements contained
		# in it and embedded objects from our hash keyed on 'allelements'.
		# also delete object keyed in 'objects'
		if (ref($_)) {
			my @tmp = keys (%{$self->{objects}{$_}{allelements}});
			delete (@{$self->{allelements}}{@tmp});
			delete ($self->{objects}{$_});
		}
		else {
			# if the element has a value of Acl object, it is in
			# the contained Acl object.
			$obj->delete_elements ($_)
				if (ref ($obj = $self->{allelements}{$_}));
			delete ($self->{allelements}{$_});
			delete ($self->{elements}{$_});
		}
	}
	# if we are an embedded object and empty delete ourself from 
	# our parent.
	$ret = $self->{aclparent}->delete_elements ($self) or return ($ret)
		if ($self->{aclparent} && (keys (%{$self->{allelements}}) == 0));

	# delete the acl object if it is empty only if a named one
	$self->delete ()
		if (!keys (%{$self->{allelements}}) && $self->name ());

	$self->dirty (1);
	return (1);
}

sub defined
{
	my ($self, $element) = @_;

	return (1) if ($self->{allelements}{$element});
	return (1) if ($self->{objects}{$element});
	return (0);
}

my ($Name, $TabLevel);

sub ___render ($);
# helper routine for __render. arguments and calling
# format same as __render
sub ___render ($)
{
	my $string;
	$TabLevel++;
	$string .= ("\t" x $TabLevel) . "$_;\n" for (keys (%{$_[0]->{elements}}));
	$string .= ("\t" x $TabLevel) . "{\n" . ___render ($_) . "\n" for (values (%{$_[0]->{objects}}));

	$string .= "\t" x ($TabLevel - 1) unless ($TabLevel);
	$TabLevel--;
	return ($string . "\t" x $TabLevel . "};");
}

# Instance method
# Arguments: NONE
sub __render
{
	my $self = shift ();
	my ($name, $rendered);
	
	$rendered = "acl $Name "
		if ($Name = $self->name ());
	$rendered .= "{\n";
	$TabLevel = shift ();
	$TabLevel = 0 unless (defined ($TabLevel));
	$rendered .= ___render ($self);
	return ($self->_rstring (\$rendered));
}

1;
__END__

=head1 TODO

o	Add new methods to access elements defined only in that Acl object
	instead of all the elements, to access contained objects only etc.
o	Change elements, add_elements, delete_elements, __render to use them.
o	 Enforce that an Acl object passed as an element be unnamed.
