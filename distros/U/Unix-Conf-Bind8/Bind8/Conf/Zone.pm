# Bind8 Zone handling
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Zone - Class for representing the Bind8 zone 
directive

=head1 SYNOPSIS

    use Unix::Conf::Bind8;

    my ($conf, $zone, $acl, $db, $ret);
    $conf = Unix::Conf::Bind8->new_conf (
        FILE        => '/etc/named.conf',
        SECURE_OPEN => 1,
    ) or $conf->die ("couldn't open `named.conf'");

    #
    # Ways to get a Zone object.
    #
	
    $zone = $conf->new_zone (
        NAME	=> 'extremix.net',
        TYPE	=> 'master',
        FILE	=> 'db.extremix.net',
    ) or $zone->die ("couldn't create zone");

    # OR

    $zone = $conf->get_zone ('extremix.net')
        or $zone->die ("couldn't get zone");
		
	#
	# Operations that can be performed on a Zone object.
	#

    $ret = $zone->type ('slave') $ret->die ("couldn't change type");
    $ret = $zone->masters (qw (192.168.1.1 192.168.1.2))
        or $ret->die ("couldn't set masters");

    # create a new acl to be defined before the zone directive
    # 'extremix.net'.
    $acl = $conf->new_acl (
        NAME     => 'extremix.com-slaves', 
        ELEMENTS => [ qw (element1 element2) ],
        WHERE	 => 'BEFORE',
        WARG	 => $zone,
    ) or $acl->die ("couldn't create `extremix.com-slaves'");

    $ret = $zone->allow_transfer ('extremix.com-slaves')
        or $ret->die ("couldn't set `allow-transfer'");
	
    $ret = $zone->delete_allow_update ()
        or $ret->die ("couldn't delete `allow-update'");

    $db = $zone->get_db () or $db->die ("couldn't get db");
    # Refer to documentation for Unix::Conf::Bind8::DB
    # for manipulating the DB file.

    # delete 
	$ret = $zone->delete () or $ret->die ("couldn't delete");

    # OR

	$ret = $conf->delete_zone ('extremix.net')
		or $ret->die ("couldn't delete zone `extremix.net'");

=head1 METHODS

=cut

package Unix::Conf::Bind8::Conf::Zone;

use strict;
use warnings;
use Unix::Conf;

use Unix::Conf::Bind8::Conf::Directive;
our @ISA = qw (Unix::Conf::Bind8::Conf::Directive);

use Unix::Conf::Bind8::Conf;
use Unix::Conf::Bind8::Conf::Lib;
use Unix::Conf::Bind8::Conf::Acl;

# dont become too restrictive. i am putting in validations offhand.
# recheck with Bind behaviour.
# Arguments: zone class
# INCOMPLETE
sub validate ($)
{
	my ($zone) = @_;
	my $errmsg = "";

	($zone->type () eq 'master') && do {
		$errmsg .= sprintf ("no records file defined for master zone `%s'\n", $zone->name ())
			if (! $zone->file ());
		$errmsg .= sprintf ("masters defined for master zone `%s'\n", $zone->name ()) 
			if ($zone->masters ()); 
	};
	($zone->type () eq 'slave') && do {
		$errmsg .= sprintf ("masters not defined for slave zone `%s'\n", $zone->name ())
			if (! $zone->masters ());
	};
	($zone->type () eq 'forward') && do {
		$errmsg .= sprintf ("masters defined for forward zone `%s'\n", $zone->name ()) 
			if ($zone->masters ()); 
		$errmsg .= sprintf ("forward not defined for forward zone `%s'\n", $zone->name ()) 
			if (! $zone->forward ());
		$errmsg .= sprintf ("forwarders not defined for forward zone `%s'\n", $zone->name ()) 
			if (! $zone->forwarders ());
	};

	return ($errmsg) if ($errmsg);
	return ();
}

# change to access the hash members directly instead of thro the methods.
# that should speed up things a bit
sub __render
{
	my $self = $_[0];
	my ($rendered, $tmp);

	# name class { type
	if ($self->__defined_class ()) {
		$rendered = sprintf (qq (zone "%s" %s {\n\ttype %s;\n), $self->name (), $self->class (), $self->type ());
	}	
	else {
		$rendered = sprintf (qq (zone "%s" {\n\ttype %s;\n), $self->name (), $self->type ());
	}

	$rendered .= qq (\tfile "$tmp";\n)
		if (($tmp = $self->file ()));
	if (($tmp = $self->masters ())) {
		local $" = "; ";
		$rendered .= sprintf (qq (\tmasters %s{\n\t\t@{$tmp->[1]};\n\t};\n), 
			defined ($tmp->[0]) ? "port $tmp->[0] " : "");
	}

	$rendered .= qq (\tforward $tmp;\n)
		if (($tmp = $self->forward ()));
	# list can be empty.
	if (($tmp = $self->forwarders ())) {
		local $" = "; ";
		$rendered .= qq (\tforwarders {);
		# the array might be empty. print `{};' in such cases
		$rendered .= qq (\n\t\t@{$tmp};\n\t) if (@$tmp);
		$rendered .= qq (};\n);
	}

	$rendered .= qq (\tcheck-names $tmp;\n)
		if (($tmp = $self->check_names ()));

	$rendered .= qq (\tnotify $tmp;\n)
		if (($tmp = $self->notify ()));
	# list can be empty
	if (($tmp = $self->also_notify ())) {
		local $" = "; ";
		$rendered .= qq (\talso-notify {);
		$rendered .= qq (\n\t\t@{$tmp};\n\t) if (@$tmp);
		$rendered .= qq (};\n);
	}

	# The values are represented by an ACL. Get the elements, stringify it
	# and set the ACL to clean, so that the destructors do not write it to file
	{
		$rendered .= "\tallow-update " . ${$tmp->_rstring (undef, 1)} . "\n"
			if (($tmp = $self->allow_update ())); 
		$rendered .= "\tallow-query " . ${$tmp->_rstring (undef, 1)} . "\n"
			if (($tmp = $self->allow_query ()));
		$rendered .= "\tallow-transfer " . ${$tmp->_rstring (undef, 1)} . "\n"
			if (($tmp = $self->allow_transfer ()));
	}
	#local $" = " ";
	$rendered .= qq/\tpubkey @{$tmp}[0..2] "$tmp->[3]";\n/
		if ($tmp = $self->pubkey ());

	$rendered .= "};";
	return ($self->_rstring (\$rendered));
}


my %ZoneDirectives = (
	'forward'			=> \&__valid_yesno,
	'notify'			=> \&__valid_yesno,
	'dialup'			=> \&__valid_yesno,
	'check-names'		=> \&__valid_checknames,
	'transfer-source'	=> \&__valid_ipaddress,
	'max-transfer-time-in'
						=> \&__valid_number,

	'also-notify'		=> 'IPLIST',
	'forwarders'		=> 'IPLIST',


	'allow-transfer'	=> 'acl',
	'allow-query'		=> 'acl',
	'allow-update'		=> 'acl',

	# can't delete the 'name' attribute
	'name'				=> 0,
	'file'				=> 1,
	'class'				=> 1,
	'type'				=> 1,
	'masters'			=> 1,
	'pubkey'			=> 1,
);


=over 4

=item new ()

 Arguments
 NAME             => 'name',
 TYPE             => 'type',            # 'master'|'slave'|'forward'|'stub'|'hint'
 CLASS            => 'class',           # 'in'|'hs'|'hesiod'|'chaos'
 FILE             => 'pathname',
 MASTERS          => { 					# only if TYPE =~  /'slave'|'stub'/
 						PORT => 'port'	# optional
						ADDRESS => [ qw (ip1 ip2) ],
					 },	
 FORWARD          => 'yes_no',
 FORWARDERS       => [ qw (ip1 ip2) ],
 CHECK-NAMES      => 'value',           # 'warn'|'fail'|'ignore'
 ALLOW-UPDATE     => [ qw (host1 host2) ],
 ALLOW-QUERY      => [ qw (host1 host2) ],
 ALLOW-TRANSFER   => [ qw (host1 host2) ],
 DIALUP           => 'yes_no',
 NOTIFY           => 'yes_no',
 ALSO-NOTIFY      => [ qw (ip1 ip2) ],
 WHERE  => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG   => Unix::Conf::Bind8::Conf::Directive subclass object
                        # WARG is to be provided only in case WHERE eq 'BEFORE 
                        # or WHERE eq 'AFTER'
 PARENT	=> reference,   # to the Conf object datastructure.

Class constructor
Creates a new Unix::Conf::Bind8::Conf::Zone object and returns 
it if successful, an Err object otherwise. Do not use this constructor
directly. Use Unix::Conf::Bind8::Conf::new_zone () instead.

=cut

sub new
{
	shift ();
	my $new = bless ({});
	my %args = @_;
	my ($ret, $acl);
	
	$args{NAME} || return (Unix::Conf->_err ('new', "zone name not defined"));
	$args{PARENT} || return (Unix::Conf->_err ('new', "PARENT not defined"));
	my $where = $args{WHERE} ? $args{WHERE} : 'LAST';
	my $warg = $args{WARG};
	$ret = $new->_parent ($args{PARENT}) or return ($ret);
	$ret = $new->name ($args{NAME}) or return ($ret);
	delete (@args{'NAME','PARENT','WHERE','WARG'});

	# now what is left in %args are zone attributes.
	for (keys (%args)) {
		my $meth = $_;
		$meth =~ tr/A-Z/a-z/;
		return (Unix::Conf->_err ("new", "attribute `$meth' not supported"))
			unless (defined ($ZoneDirectives{$meth}));
		$meth =~ tr/-/_/;
		($_ eq 'MASTERS')	&& do {
			$ret = $new->$meth (%{$args{$_}}) or return ($ret);
			next;
		};
		$ret = $new->$meth ($args{$_}) or return ($ret);
	}
	$ret = Unix::Conf::Bind8::Conf::_insert_in_list ($new, $where, $warg)
		or return ($ret);
	return ($new);
}

=item name ()

 Arguments
 'zone',    # optional

Object method.
Get/Set object's name attribute. If argument is passed, the method tries to 
set the name attribute to 'zone', and returns true if successful, an Err 
object otherwise. If no argument is passed, returns the name of the zone, 
if defined, an Err object otherwise.

=cut

sub name
{
	my ($self, $name) = @_;

	if (defined ($name)) {
		my $ret;
		# strip the double quotes if any
		$name =~ s/^"(.+)"$/$1/;
		# already defined. changing name
		if ($self->{name}) {
			$ret = Unix::Conf::Bind8::Conf::_del_zone ($self) or return ($ret);
		}
		$self->{name} = $name;
		$ret = Unix::Conf::Bind8::Conf::_add_zone ($self) or return ($ret);
		$self->dirty (1);
		return (1);
	}
	return ($self->{name});
}

=item class ()

 Arguments
 'class',     # optional

Object method.
Get/Set object's class attribute. If argument is passed, the method tries 
to set the class attribute to 'class', and returns true if successful, an 
Err object otherwise. If no argument is passed, returns the class of 
the zone, if defined, an Err object otherwise.

=cut

sub class
{
	my ($self, $class) = @_;

	if (defined ($class)) {
		return (Unix::Conf->_err ('class', "illegal class `$class'"))
			if ($class !~ /^(in|hs|hesoid|chaos)$/i);
		$self->{class} = lc ($class);
		return (1);
	}
	return ( defined ($self->{class}) ? $self->{class} : "IN" );
}

sub __defined_class { return ( defined ($_[0]->{class}) ); }

=item file ()

 Arguments
 'file',    # optional

Object method.
Get/Set the object's file attribute. If argument is passed, the method tries 
to set the file attribute to 'file', and returns true if successful, and 
Err object otherwise. If no argument is passed, returns the file of the zone, if 
defined, an Err object otherwise.

=cut

sub file
{
	my ($self, $file) = @_;

	if (defined ($file)) {
		# strip the double quotes if any
		$file =~ s/^"(.+)"$/$1/;
		$self->{file} = $file;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{file}) ? $self->{file} : Unix::Conf->_err ('file', "file not defined")
	);
}

=item type ()

 Arguments
 'type',    # optional

Object method.
Get/Set the object's type attribute. If argument is passed, the method 
tries to set the type attribute to 'type', and returns true if successful, 
an Err object otherwise. If no argument is passed, returns the type of the 
zone, if defined, an Err object otherwise.

=cut

sub type
{
	my ($self, $type) = @_;

	if (defined ($type)) {
		return (Unix::Conf->_err ('type', "illegal type `$type'"))
			if ($type !~ /^(hint|master|slave|stub|forward)$/); 
		$self->{type} = $type;
		$self->dirty (1);
		return (1);
	}
	return ($self->{type});
}

=item forward ()

=item notify ()

=item dialup ()

 Arguments
 SCALAR,		# 'yes'|'no'|0|1

Object method
Get/set corresponding attribute in the invocant. If argument is passed,
the method tries to set it as the value and returns true if successful,
an Err object otherwise. If no argument is passed the value of that
attribute is returned if defined, an Err object otherwise.

=cut

=item check_names ()

 Arguments
 string,		# 'warn'|'fail'|'ignore'

Object method
Get/set corresponding attribute in the invocant. If argument is passed,
the method tries to set it as the value and returns true if successful,
an Err object otherwise. If no argument is passed the value of that
attribute is returned if defined, an Err object otherwise.

=cut

=item transfer_source ()

 Arguments
 string,		# IPv4 address in dotted quad notation

Object method
Get/set corresponding attribute in the invocant. If argument is passed,
the method tries to set it as the value and returns true if successful,
an Err object otherwise. If no argument is passed the value of that
attribute is returned if defined, an Err object otherwise.

=cut

=item max_transfer_time_in ()

 Arguments
 number,		

Object method
Get/set corresponding attribute in the invocant. If argument is passed,
the method tries to set it as the value and returns true if successful,
an Err object otherwise. If no argument is passed the value of that
attribute is returned if defined, an Err object otherwise.

=cut

=item also_notify ()

=item forwarders ()

 Arguments
 LIST			# List of IPv4 addresses in 
 or 			# dotted quad notation
 [ LIST ]

Object method.
Get/set the corresponding attribute in the invoking object. If argument(s)
is/are passed, the method tries to set the attribute and returns true
on success, an Err object otherwise. If no arguments are passed then
the method tries to return an array reference if the attribute is defined,
an Err object otherwise.

=cut

=item add_to_also_notify ()

=item add_to_forwarders ()

=item add_to_masters ()

 Arguments
 LIST			# List of IPv4 addresses in
 or				# dotted quad notation.
 [ LIST ]

Object method.
Add the elements of the list to the corresponding attribute. Return
true on success, an Err object otherwise.

=cut

=item delete_from_also_notify ()

=item delete_from_forwarders ()

=item delete_from_masters ()

 Arguments
 LIST			# List of IPv4 addresses in
 or				# dotted quad notation.
 [ LIST ]

Object method.
Delete elements of the list from the corresponding attribute. Return
true on success, an Err object otherwise.

=cut

=item allow_transfer ()

=item allow_query ()

=item allow_update ()

 Arguments
 Acl object,
 or
 LIST
 or 
 [ LIST ]

Object method.
If argument(s) is/are passed, tries to set the elements of the corresponding
attribute and returns true on success, an Err object otherwise. If no
arguments are passed, tries to return the elements defined for that attribute
as an anonymous array, if defined, an Err object otherwise.

=cut

=item add_to_allow_transfer ()

=item add_to_allow_query ()

=item add_to_allow_update ()

=item delete_from_allow_transfer ()

=item delete_from_allow_query ()

=item delete_from_allow_update ()

 Arguments
 LIST
 [ LIST ]

Object method.
Add to/delete from elements defined for the corresponding attributes.
Returns true on success, an Err object otherwise.

=cut

=item delete_forward ()

=item delete_notify ()

=item delete_dialup ()

=item delete_check_names ()

=item delete_transfer_source ()

=item delete_max_transfer_time_in ()

=item delete_also_notify ()

=item delete_forwarders ()

=item delete_allow_transfer ()

=item delete_allow_query ()

=item delete_allow_update ()

=item delete_file ()

=item delete_class ()

=item delete_type ()

=item delete_masters ()

=item delete_also_notify ()

=item delete_forwarders ()

=item delete_pubkey ()

Object method.
Deletes the corresponding attribute, if defined and returns true,
an Err object otherwise.

=cut

for my $dir (keys (%ZoneDirectives)) {
	no strict 'refs';

	my $meth;
	($meth = $dir) =~ tr/-/_/;

	($ZoneDirectives{$dir} eq 'IPLIST')	&& do {
		*$meth = sub {
			my $self = shift ();
			my $addresses;

			if (@_) {
				if (ref ($_[0])) {
					return (
						Unix::Conf->_err (
							"$meth", 
							"expected arguments are a list or an array reference"
						)
					) unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
					$addresses = $_[0];
				}
				else {
					$addresses = \@_;
				}
				for (@$addresses) {
					return (Unix::Conf->_err ("$meth", "illegal IP address `$_'"))
						if (! __valid_ipaddress ($_));
				}
				# reinit
				$self->{$dir} = undef;
				@{$self->{$dir}}{@$addresses} = (1) x @$addresses;
				$self->dirty (1);
				return (1);
			}

			return (
				defined ($self->{$dir}) ? [ keys (%{$self->{$dir}}) ] :
					Unix::Conf->_err ("$meth", "zone directive `$dir' not defined")
			)
		};

		*{"add_to_$meth"} = sub {
			my $self = shift ();
			my $addresses;

			if (@_) {
				if (ref ($_[0])) {
					return (
						Unix::Conf->_err (
							"add_to_$meth", 
							"expected arguments are a list or an array reference"
						)
					) unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
					$addresses = $_[0];
				}
				else {
					$addresses = \@_;
				}
				for (@$addresses) {
					return (Unix::Conf->_err ("add_to_$meth", "illegal IP address `$_'"))
						if (! __valid_ipaddress ($_));
					return (
						Unix::Conf->_err ( "add_to_$meth", "address `$_' already defined" )
					) if ($self->{$dir}{$_});
				}
				@{$self->{$dir}}{@$addresses} = (1) x @$addresses;
				$self->dirty (1);
				return (1);
			}
			return (Unix::Conf->_err ("add_to_$meth", "addresses to be added not passed"));
		};

		*{"delete_from_$meth"} = sub {
			my $self = shift ();
			my $addresses;

			if (@_) {
				if (ref ($_[0])) {
					return (
						Unix::Conf->_err (
							"delete_from_$meth", 
							"expected arguments are a list or an array reference"
						)
					) unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
					$addresses = $_[0];
				}
				else {
					$addresses = \@_;
				}
				for (@$addresses) {
					return (Unix::Conf->_err ("delete_from_$meth", "illegal IP address `$_'"))
						if (! __valid_ipaddress ($_));
					return (
						Unix::Conf->_err ( "delete_from_$meth", "address `$_' not defined" )
					) unless ($self->{$dir}{$_});
				}
				delete (@{$self->{$dir}}{@$addresses});
				# if no keys left delete the zone directive itself
				delete ($self->{$dir})
					unless (keys (%{$self->{$dir}}));
				$self->dirty (1);
				return (1);
			}
			return (Unix::Conf->_err ("delete_from_$meth", "addresses to be deleted not passed"));
		};
		goto CREATE_DELETE;
	};

	# zone directives taking Acl as arguments.
	($ZoneDirectives{$dir} eq 'acl')	&& do {
		*$meth = sub {
			my $self = shift ();
			my $elements;

			if (@_) {
				if (ref ($_[0])) {
					if (UNIVERSAL::isa ($_[0], 'Unix::Conf::Bind8::Conf::Acl')) {
						# Acl object passed
						$self->{$dir} = $_[0];
						$self->dirty (1);
						return (1);
					}
					elsif (UNIVERSAL::isa ($_[0], 'ARRAY')) {
						# array ref was passed
						return (Unix::Conf->_err ("$meth", "array passed by reference empty"))
							unless (@{$_[0]});
						$elements = $_[0];
					}
					else {
						return (	
							Unix::Conf->_err (
								"$meth", 
								"expected arguments are a list, an Unix::Conf::Bind8::Conf::Acl object or an array ref"
							)
						);
					}
				}
				else {
					# assume a list of elements to be set was passed.
					$elements = \@_;
				}

				my $acl;
				$acl = Unix::Conf::Bind8::Conf::Acl->new (
					PARENT => $self->_parent (), ELEMENTS => $elements,
				) or return ($acl);
				$self->{$dir} = $acl;
				$self->dirty (1);
				return (1);
			}
			return (
				defined ($self->{$dir}) ? 
					$self->{$dir} : 
					Unix::Conf->_err ("$meth", "zone directive `$dir' not defined")
			);
		};

		# add_to_* counterpart for options taking ACL elements as arguments
		*{"add_to_$meth"} = sub {
			my $self = shift ();
			my ($elements, $ret);

			return (Unix::Conf->_err ("add_to_$meth", "elements to be added not passed"))
				unless (@_);

			if (ref ($_[0])) {
				return (
					Unix::Conf->_err (
						"add_to_$meth", 
						"expected arguments are either a list of elements or an array ref")
				) unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
				return (Unix::Conf->_err ("add_to_$meth", "array passed by reference empty"))
					unless (@{$_[0]});
				$elements = $_[0];
			}
			else {
				$elements = [ @_ ];
			}
			$self->{$dir} = Unix::Conf::Bind8::Conf::Acl->new (
				PARENT => $self->_parent ()
			) unless (defined ($self->{$dir}));
			$ret = $self->{$dir}->add_elements ($elements) or return ($ret);
			$self->dirty (1);
			return (1);
		};

		# delete_from_* counterpart for options taking ACL elements as arguments
		*{"delete_from_$meth"} = sub {
			my $self = shift ();
			my ($elements, $ret);

			return (Unix::Conf->_err ("delete_from_$meth", "elements to be added not passed"))
				unless (@_);

			if (ref ($_[0])) {
				return (
					Unix::Conf->_err (
						"delete_from_$meth", 
						"expected arguments are either a list of elements or an array ref")
				) unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
				return (Unix::Conf->_err ("delete_from_$meth", "array passed by reference empty"))
					unless (@{$_[0]});
				$elements = $_[0];
			}
			else {
				$elements = [ @_ ];
			}

			return (Unix::Conf::->_err ("delete_from_$meth", "zone directive `$dir' not defined"))
				unless (defined ($self->{$dir}));
			$ret = $self->{$dir}->delete_elements ($elements) or return ($ret);
			# if all elements have been deleted, delete the option itself.
			delete ($self->{$dir})
				unless (@{$self->{$dir}->elements ()});
			$self->dirty (1);
			return (1);
		};
		# *_elements
		*{"${meth}_elements"} = sub {
			return (
				defined ($_[0]->{$dir}) ? $_[0]->{$dir}->elements () : 
					Unix::Conf->_err ("{$meth}_elements", "zone directive $dir not defined")
			);
		};
		goto CREATE_DELETE;
	};

	("$ZoneDirectives{$dir}" =~ /^CODE/)	&& do {
		*$meth = sub {
				my ($self, $arg) = @_;
				
				if (defined ($arg)) {
					return (Unix::Conf->_err ("$meth", "invalid argument $arg"))
						unless (&{$ZoneDirectives{$dir}}($arg));
					$self->{$dir} = $arg;
					$self->dirty (1);
					return (1);
				}
				return (
					defined ($self->{$dir}) ? 
					$self->{$dir} : 
					Unix::Conf->_err ("$meth", "zone directive `$dir' not defined")
				);
		};
	};
CREATE_DELETE:
	# delete_* to be created only for directives which have true value.
	# will not be created for name.
	($ZoneDirectives{$dir})					&& do {
		*{"delete_$meth"} = sub {
			return (Unix::Conf->_err ("delete_$meth", "zone directive `$dir' not defined"))
				unless (defined ($_[0]->{$dir}));
			delete ($_[0]->{$dir});
			$_[0]->dirty (1);
			return (1);
		};
	};
}

=item masters ()

 Arguments
 PORT		=> port,	# optional
 ADDRESS	=> [ LIST ],

Object method.
Get/sets the 'masters' attribute. If argument is passed, the
attribute is set to the argument and returns true on success, 
an Err object otherwise. If not the attribute value is returned 
in the form of an anonymous array 
([ PORT, [ LIST OF ADDRESSES ] ]), if defined, an Err object 
otherwise.

=cut

sub masters
{
	my $self = shift ();
	
	if (@_) {
		my %args = ( @_ );
		
		$self->{masters} = undef;
		if (defined ($args{PORT})) {
			return (Unix::Conf->_err ("masters", "illegal PORT `$args{PORT}'"))
				unless (__valid_port ($args{PORT}));
			$self->{masters}[0] = $args{PORT};
		}
		for (@{$args{ADDRESS}}) {
			return (Unix::Conf->_err ("masters", "illegal IP address `$_'"))
				if (! __valid_ipaddress ($_));
		}
		# reinit
		@{$self->{masters}[1]}{@{$args{ADDRESS}}} = (1) x @{$args{ADDRESS}};
		$self->dirty (1);
	}

	return (Unix::Conf->_err ("masters", "zone directive `masters' not defined"))
		unless ($self->{masters});
	return ([ $self->{masters}[0], [ keys (%{$self->{masters}[1]}) ] ]);
}

sub add_to_masters
{
	my $self = shift ();
	my $addresses;

	if (@_) {
		if (ref ($_[0])) {
			return (
				Unix::Conf->_err (
					"add_to_masters", 
					"expected arguments are a list or an array reference"
				)
			) unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
			$addresses = $_[0];
		}
		else {
			$addresses = \@_;
		}
		for (@$addresses) {
			return (Unix::Conf->_err ("add_to_masters", "illegal IP address `$_'"))
				if (! __valid_ipaddress ($_));
			return (
				Unix::Conf->_err ( "add_to_masters", "address `$_' already defined")
			) if ($self->{masters}[1]{$_});
		}
		@{$self->{masters}[1]}{@$addresses} = (1) x @$addresses;
		$self->dirty (1);
		return (1);
	}
	return (Unix::Conf->_err ("add_to_masters", "addresses to be added not passed"));
}

sub delete_from_masters
{
	my $self = shift ();
	my $addresses;

	if (@_) {
		if (ref ($_[0])) {
			return (
				Unix::Conf->_err (
					"delete_from_masters", 
					"expected arguments are a list or an array reference"
				)
			) unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
			$addresses = $_[0];
		}
		else {
			$addresses = \@_;
		}
		for (@$addresses) {
			return (Unix::Conf->_err ("delete_from_masters", "illegal IP address `$_'"))
				if (! __valid_ipaddress ($_));
			return (
				Unix::Conf->_err ( "delete_from_masters", "address `$_' not defined" )
			) unless ($self->{masters}[1]{$_});
		}
		delete (@{$self->{masters}[1]}{@$addresses});
		# if no keys left delete the zone directive itself
		delete ($self->{masters})
			unless (keys (%{$self->{masters}[1]}));
		$self->dirty (1);
		return (1);
	}
	return (Unix::Conf->_err ("delete_from_masters", "addresses to be deleted not passed"));
}

=item masters_port ()

 Arguments
 'port',     # optional

Object method.
Get/Set the object's masters port attribute. If argument is passed, the 
method tries to set the masters port attribute to 'port', and returns true if 
successful, an Err object otherwise. If no argument is passed, returns the 
masters port, if defined, an Err object otherwise.

=cut

sub masters_port
{
	my ($self, $port) = @_;

	if (defined ($port)) {
		return (Unix::Conf->_err ("masters", "illegal PORT `$port'"))
			unless (__valid_port ($port));
		$self->{masters}[0] = $port;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{masters}[0]) ? $self->{masters}[0] : 
			Unix::Conf->_err ('masters_port', "masters port not defined")
	);
}

=item pubkey ()

 Arguments
 LIST			# flags, protocol, algorithm, string
 or 
 [ LIST ]		# same structure

=cut

sub pubkey 
{
	my $self = shift ();
	my $args;

	return (
		defined ($self->{pubkey}) ? [ @{$self->{pubkey}} ] :
			Unix::Conf->_err ('pubkey', "zone directive `pubkey' not defined")
	) unless (@_);

	if (ref ($_[0])) {
		return (Unix::Conf->_err ('pubkey', ""))
			unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
		 $args = [ @{$_[0]} ];
	}
	elsif (@_ == 4) {
		$args = [ @_ ];
	}
	else {
		return (
			Unix::Conf->_err (
				'pubkey', "expected arguments are LIST (flags, protocol, algorithm, key) or [ LIST ]"
			)
		);
	}
	# strip quotes if any.
	$args->[3] =~ s/^"(.+)"$/$1/;
	$self->{pubkey} = $args;
	$self->dirty (1);
	return (1);
}

=item delete_directive ()

 Arguments
 'directive',

Object method.
Deletes the directive passed as argument, if defined, and returns true, an Err object 
otherwise.

=cut

sub delete_directive
{
	my ($self, $dir) = @_;

	return (Unix::Conf->_err ('delete_zonedir', "directive to be deleted not passed"))
		unless ($dir);
	# validate $dir 
	return (Unix::Conf->_err ('delete_zonedir', "illegal zone directive `$dir'"))
		if ($dir !~ /^(type|file|masters|check-names|allow-update|allow-query|allow-transfer|forward|forwarders|transfer-source|max-transfer-time-in|notify|also-notify)$/);
	return (Unix::Conf->_err ('delete_zonedir', "cannot delete `$dir'"))
		if ($dir =~ /^(name|type)$/);
	undef ($self->{$dir});
	$self->dirty (1);
	return (1);
}

=item get_db ()

 Arguments,
 number,    # 0/1 secure open

Constructor
This method is a wrapper method of the class constructor of the Unix::Conf::Bind8::DB
class. Creates and returns a new Unix::Conf::Bind8::DB object representing the records
file for the zone, if successful, an error object otherwise.

=cut

sub get_db
{
	require Unix::Conf::Bind8::DB;
	my ($self, $secure_open) = @_;
	$secure_open = 1 unless (defined ($secure_open));

	return (
		Unix::Conf::Bind8::DB::->new (
			FILE		=> $self->file (),
			ORIGIN		=> $self->name (),
			CLASS		=> uc ($self->class ()),
			SECURE_OPEN	=> $secure_open
		)
	);
}

1;
