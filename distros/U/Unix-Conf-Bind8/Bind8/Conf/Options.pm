# Bind8 Options
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Options - Class for representing Bind8 options
directive

=head1 SYNOPSIS

    use Unix::Conf;
    my ($conf, $options, $ret);
    $conf = Unix::Conf::Bind8->new_conf (
        FILE        => '/etc/named.conf',
        SECURE_OPEN => 1,
    ) or $conf->die ("couldn't open `named.conf'");

    #
    # Get an Options object
    #

    # get an options object if one is defined
    $options = $conf->get_options ()
        or $options->die ("couldn't get options");
    
    # or create a new one
    $options = $conf->new_options (
        DIRECTORY  => 'db',
        VERSION    => '8.2.3-P5',
    ) or $options->die ("couldn't create options");

     
    #
    # Operations that can be performed on an Options object
    # Since the number of operations are too many, only a
    # hint is given here. Consult the METHODS section, for
    # a comprehnsive list.
    #

    my $acl = $conf->new_acl (
        NAME     => 'query-acl',
	   ELEMENTS => [ qw (10.0.0.1 10.0.0.2 10.0.0.3) ],
    );
    $acl->die ("couldn't create `query-acl'") unless ($acl);

    $ret = $options->allow_query ($acl) 
        or $ret->die ("couldn't set allow-query");

    # OR

    $ret = $options->allow_query (qw (10.0.0.1 10.0.0.2 10.0.0.3))
        or $ret->die ("couldn't set allow-query");

    # Delete the option.
    $options->delete_allow_query ();
        
=head1 METHODS

=cut

package Unix::Conf::Bind8::Conf::Options;

use strict;
use warnings;
use Unix::Conf;

use Unix::Conf::Bind8::Conf::Directive;
our @ISA = qw (Unix::Conf::Bind8::Conf::Directive);

use Unix::Conf::Bind8::Conf;
use Unix::Conf::Bind8::Conf::Lib;
use Unix::Conf::Bind8::Conf::Acl;


# Methods that have a valid routine are automatically created. The rest are
# hand coded.
my %Supported_Options = (
	'version'				=> \&__valid_string,
	'directory'				=> \&__valid_string,
	'named-xfer'			=> \&__valid_string,
	'dump-file'				=> \&__valid_string,
	'memstatistics-file'	=> \&__valid_string,
	'pid-file'				=> \&__valid_string,
	'statistics-file'		=> \&__valid_string,

	'auth-nxdomain'			=> \&__valid_yesno,
	'deallocate-on-exit'	=> \&__valid_yesno,
	'dialup'				=> \&__valid_yesno,
	'fake-iquery'			=> \&__valid_yesno,
	'fetch-glue'			=> \&__valid_yesno,
	'has-old-clients'		=> \&__valid_yesno,
	'host-statistics'		=> \&__valid_yesno,
	'host-statistics-max-number'	=> \&__valid_number,
	'multiple-cnames'		=> \&__valid_yesno,
	'notify'				=> \&__valid_yesno,
	'recursion'				=> \&__valid_yesno,
	'rfc2308-type1'			=> \&__valid_yesno,
	'use-id-pool'			=> \&__valid_yesno,
	'treat-cr-as-space'		=> \&__valid_yesno,
	'also-notify'			=> \&__valid_yesno,

	'forward'				=> \&__valid_forward,

	'allow-query'			=> 'acl',
	'allow-recursion'		=> 'acl',
	'allow-transfer'		=> 'acl',
	'blackhole'				=> 'acl',

	'lame-ttl'				=> \&__valid_number,
	'max-transfer-time-in'	=> \&__valid_number,
	'max-ncache-ttl'		=> \&__valid_number,
	'min-roots'				=> \&__valid_number,
	# the man page provides this directive
	'serial-queries'		=> \&__valid_number,
	# the sample named.conf with bind suggests this.
	'max-serial-queries'	=> \&__valid_number,

	'transfer-format'		=> \&__valid_transfer_format,

	'transfers-in'			=> \&__valid_number,
	'transfers-out'			=> \&__valid_number,
	'transfers-per-ns'		=> \&__valid_number,

	'transfer-source'		=> \&__valid_ipaddress,

	'maintain-ixfr-base'	=> \&__valid_yesno,
	'max-ixfr-log-size'		=> \&__valid_number,

	'coresize'				=> \&__valid_sizespec,
	'datasize'				=> \&__valid_sizespec,
	'files'					=> \&__valid_sizespec,
	'stacksize'				=> \&__valid_sizespec,

	'cleaning-interval'		=> \&__valid_number,
	'heartbeat-interval'	=> \&__valid_number,
	'interface-interval'	=> \&__valid_number,
	'statistics-interval'	=> \&__valid_number,

	'topology'				=> 'acl',
	'sortlist'				=> 'acl',

	# methods below have only their delete_* counterpart created via closure
	# as the pattern of arguments don't fit well into a template
	'check-names'			=> 0,
	'forwarders'			=> 1,
	'rrset-order'			=> 0,
	'listen-on'				=> 0,
	'query-source'			=> 1,
);

=over 4

=item new ()

 Arguments
 OPTION-NAME   => value,      # the value type is dependant on the option
 WHERE  => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG   => Unix::Conf::Bind8::Conf::Directive subclass object
                        # WARG is to be provided only in case WHERE eq 'BEFORE 
                        # or WHERE eq 'AFTER'
 PARENT	=> reference,   # to the Conf object datastructure.

Class Constructor.
Create a new Unix::Conf::Bind8::Conf::Options object and return it if
successful, or an Err object otherwise. Do not use this constructor 
directly. Use the Unix::Conf::Bind8::Conf::new_options () method instead.

=cut

sub new
{
	my $self = shift ();
	my $new = bless ({});
	my $ret;

	my %args = @_;
	$args{PARENT} || return (Unix::Conf->_err ('new', "PARENT not defined"));
	$ret = $new->_parent ($args{PARENT}) or return ($ret);
	delete ($args{PARENT});	# as PARENT is not a valid option
	my $where = $args{WHERE} ? $args{WHERE} : 'LAST';
	my $warg = $args{WARG};
	delete (@args{'WHERE','WARG'});
	for (keys (%args)) {
		my $option = $_;
		$option =~ tr/A-Z/a-z/;
		return (Unix::Conf->_err ('new', "option `$option' not supported"))
			unless (defined ($Supported_Options{$option}));
		# change it into the corresponding method name
		$option =~ tr/-/_/;
		$ret = $new->$option ($args{$_}) or return ($ret);
	}
	$ret = Unix::Conf::Bind8::Conf::_add_options ($new) or return ($ret);
	$ret = Unix::Conf::Bind8::Conf::_insert_in_list ($new, $where, $warg)
		or return ($ret);
	return ($new);
}

=item version ()

=item directory ()

=item named_xfer ()

=item dump_file ()

=item memstatistics_file ()

=item pid_file ()

=item statistics_file ()

 Arguments
 'string',      # optional

Object method.
Get/Set attributes from the invoking object.
If called with a string argument, the method tries to set the corresponding 
attribute and returns true on success, an Err object otherwise. Returns
value of the corresponding attribute if defined, an Err object otherwise.

=item auth_nxdomain ()

=item deallocate_on_exit ()

=item dialup ()

=item fake_iquery ()

=item fetch_glue ()

=item has_old_clients ()

=item host_statistics ()

=item multiple_cnames ()

=item notify ()

=item recursion () 

=item rcf2308_type1 ()

=item use_id_pool ()

=item treat_cr_as_space () 

=item also_notify ()

=item maintain_ixfr_base ()

 Arguments
 'string',     # 'yes'|'no'

Object method.
Get/Set attributes from the invoking object.
If called with a string argument, the method tries to set the corresponding 
attribute and returns true on success, an Err object otherwise. Returns
value of the corresponding attribute if defined, an Err object otherwise.

=item  forward ()

 Arguments
 'string',     # 'only'|'first'

Object method.
Get/Set attributes from the invoking object.
If called with a string argument, the method tries to set the corresponding 
attribute and returns true on success, an Err object otherwise. Returns
value of the corresponding attribute if defined, an Err object otherwise.

=item allow_query ()

=item allow_transfer ()

=item allow_recursion ()

=item blackhole ()

 Arguments
 Acl object
 or
 LIST
 or 
 [ LIST ]

Object method.
If argument(s) is/are passed, tries to set the elements of the appropriate
attribute and returns true on success, an Err object otherwise. If no
arguments are passed, tries to return the elements defined for that attribute
as an anonymous array, if defined, an Err object otherwise.

=item add_to_allow_query ()

=item add_to_allow_transfer ()

=item add_to_allow_recursion ()

=item add_to_blackhole ()

=item delete_from_allow_query ()

=item delete_from_allow_transfer ()

=item delete_from_allow_recursion ()

=item delete_from_blackhole ()

 Arguments
 LIST
 or 
 [ LIST ]

Object method.
Add to/delete from the elements defined for the appropriate attributes.
Returns true on success, an Err object otherwise.

=item lame_ttl ()

=item max_transfer_time_in ()

=item max_ncache_ttl ()

=item min_roots ()

=item serial_queries ()

=item max_serial_queries ()

=item transfers_in ()

=item transfers_out ()

=item transfers_per_ns ()

=item max_ixfr_log_size ()

=item cleaning_interval ()

=item heartbeat_interval ()

=item interface_interval ()

=item statistics_interval ()

 Arguments
 number,       # Optional

Object method.
Get/Set attributes from the invoking object.
If called with a string argument, the method tries to set the corresponding 
attribute and returns true on success, an Err object otherwise. Returns
value of the corresponding attribute if defined, an Err object otherwise.

NOTE: As 0 is also a valid argument, take care that the return value
is not tested for truth or falsehood. Instead, test thus:

if (UNIVERSAL::isa ($ret, "Unix::Conf::Err"))

=item transfer_format ()
 
 Arguments
 'string',    # Optional. Allowed arguments are 'one-answer', 
              # 'many-answers'

Object method.
Get/Set attributes from the invoking object.
If called with a string argument, the method tries to set the corresponding 
attribute and returns true on success, an Err object otherwise. Returns
value of the corresponding attribute if defined, an Err object otherwise.

=item transfer_source ()

 Arguments
 'string',   # Optional. The argument must be an IP Address in the
             # dotted quad notation

Object method.
Get/Set attributes from the invoking object.
If called with a string argument, the method tries to set the corresponding 
attribute and returns true on success, an Err object otherwise. Returns
value of the corresponding attribute if defined, an Err object otherwise.

=item coresize ()

=item datasize ()

=item files ()

=item stacksize ()

 Arguments
 'string'|number,   # Optional. The argument must be a size spec. Refer to
                    # the Bind8 manual for a definition of size_spec.

Object method.
Get/Set attributes from the invoking object.
If called with a string argument, the method tries to set the corresponding 
attribute and returns true on success, an Err object otherwise. Returns
value of the corresponding attribute if defined, an Err object otherwise.

NOTE: As 0 is also a valid argument, take care that the return value
is not tested for truth or falsehood. Instead, test thus:

if (UNIVERSAL::isa ($ret, "Unix::Conf::Err"))

=item delete_version ()

=item delete_directory ()

=item delete_named_xfer ()

=item delete_dump_file ()

=item delete_memstatistics_file ()

=item delete_pid_file ()

=item delete_statistics_file ()

=item delete_auth_nxdomain ()

=item delete_deallocate_on_exit ()

=item delete_dialup ()

=item delete_fake_iquery ()

=item delete_fetch_glue ()

=item delete_has_old_clients ()

=item delete_host_statistics ()

=item delete_multiple_cnames ()

=item delete_notify ()

=item delete_recursion ()

=item delete_rfc2308_type1 ()

=item delete_use_id_pool ()

=item delete_treat_cr_as_space ()

=item delete_also_notify ()

=item delete_forward ()

=item delete_allow_query ()

=item delete_allow_recursion ()

=item delete_allow_transfer ()

=item delete_blackhole ()

=item delete_lame_ttl ()

=item delete_max_transfer_time_in ()

=item delete_max_ncache_ttl ()

=item delete_min_roots ()

=item delete_serial_queries ()

=item delete_max_serial_queries ()

=item delete_transfer_format ()

=item delete_transfers_in ()

=item delete_transfers_out ()

=item delete_transfers_per_ns ()

=item delete_transfer_source ()

=item delete_maintain_ixfr_base ()

=item delete_max_ixfr_log_size ()

=item delete_coresize ()

=item delete_datasize ()

=item delete_files ()

=item delete_stacksize ()

=item delete_cleaning_interval ()

=item delete_heartbeat_interval ()

=item delete_interface_interval ()

=item delete_statistics_interval ()

=item delete_topology ()

=item delete_forwarders ()

=item delete_query_source ()

Object method.
Deletes the corresponding directive if defined and returns true, or an Err
object otherwise.

=cut

{
	no strict 'refs';
	for my $option (keys (%Supported_Options)) {
		my $meth = $option;
		$meth =~ tr/-/_/;

		# Options taking ACL elements/anon array as arguments
		($Supported_Options{$option} eq 'acl') 		&& do {
			*$meth = sub {
				my $self = shift ();
				my $elements;

				if (@_) {
					if (ref ($_[0])) {
						if (UNIVERSAL::isa ($_[0], 'Unix::Conf::Bind8::Conf::Acl')) {
							# Acl object was passed
							$self->{options}{$option} = $_[0];
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
					$self->{options}{$option} = $acl;
					$self->dirty (1);
					return (1);
				}
				return (
					defined ($self->{options}{$option}) ? 
						$self->{options}{$option} : 
						Unix::Conf->_err ("$meth", "option not defined")
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
				$self->{options}{$option} = Unix::Conf::Bind8::Conf::Acl->new (
					PARENT => $self->_parent ()
				) unless (defined ($self->{options}{$option}));
				$ret = $self->{options}{$option}->add_elements ($elements) or return ($ret);
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

				return (Unix::Conf::->_err ("delete_from_$meth", "option not defined"))
					unless (defined ($self->{options}{$option}));
				$ret = $self->{options}{$option}->delete_elements ($elements) or return ($ret);
				# if all elements have been deleted, delete the option itself.
				delete ($self->{options}{$option})
					unless (@{$self->{options}{$option}->elements ()});
				$self->dirty (1);
				return (1);
			};

			# *_elements
			*{"${meth}_elements"} = sub {
				return (
					defined ($_[0]->{options}{$option}) ? $_[0]->{options}{$option}->elements () : 
						Unix::Conf->_err ("{$meth}_elements", "option not defined")
				);
			};
			goto CREATE_DELETE;
		};

		# These methods have the corresponding validation routines
		("$Supported_Options{$option}" =~ /^CODE/)	&& do {
			*$meth = sub {
				my ($self, $arg) = @_;
				
				if (defined ($arg)) {
					return (Unix::Conf->_err ("$meth", "invalid argument `$arg'"))
						unless (&{$Supported_Options{$option}}($arg));
					$self->{options}{$option} = $arg;
					$self->dirty (1);
					return (1);
				}
				return (
					defined ($self->{options}{$option}) ? 
					$self->{options}{$option} : 
					Unix::Conf->_err ("$meth", "option not defined")
				);
			};
		};

CREATE_DELETE:
		if ($Supported_Options{$option}) {
			# delete_*
			*{"delete_$meth"} = sub {
				return (Unix::Conf->_err ("delete_$meth", "option not defined"))
					unless (defined ($_[0]->{options}{$option}));
				delete ($_[0]->{options}{$option});
				$_[0]->dirty (1);
				return (1);
			};
		}
	}
}

=item delete_option ()

 Arguments
 'string',		# 'OPTION-NAME'

Object method.
Deletes the corresponding directive if defined and returns true, or an Err
object otherwise.

=cut

sub delete_option 
{
	my ($self, $option) = @_;

	return (Unix::Conf->_err ('delete_option', "option not supported or invalid"))
		unless (defined ($Supported_Options{$option}));
	return (Unix::Conf->_err ('delete_option', "option not defined"))
		unless (defined ($self->{options}{$option}));
	delete ($self->{options}{$option});
	return (1);
}

=item query_source ()

 Arguments
 PORT 		=> port, 	# Optional
 ADDRESS	=> address,	# Optional
 or
 { }					# with the same format as above

Object method
Get/set query-source attributes. If PORT, or ADDRESS is passed tries
to set the attributes. Returns true on success, an Err object otherwise.
Else, returns value in an anonymous hash, in the same format as argument.

=cut

sub query_source
{
	my $self = shift ();
	
	if (@_) {
		my $args;
		if (@_ == 1) {
			return (Unix::Conf->_err ("query_source", "expected argument type either LIST or hash reference"))
				unless (UNIVERSAL::isa ($_[0], "HASH"));
			$args = { %{$_[0]} };
		}
		else {
			$args = { @_ };
		}
		if ($args->{ADDRESS}) {
			return (Unix::Conf->_err ('query_source', "illegal IP address `$args->{ADDRESS}'"))
				unless (__valid_ipaddress ($args->{ADDRESS}) || $args->{ADDRESS} eq '*');
		}
		if ($args->{PORT}) {
			return (Unix::Conf->_err ('query_source', "illegal port `$args->{PORT}'"))
				unless (__valid_port ($args->{PORT}) || $args->{PORT} eq '*');
		}
		$self->{options}{'query-source'} = $args;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{options}{'query-source'}) ? { %{$self->{options}{'query-source'}} } :
			Unix::Conf->_err ('query_source', "option not defined")
	);
}

=item check_names ()

 Arguments
 type	=> value,
 type	=> value,
 or
 { }				# with the same format as above

Object method.
Get/set the 'check-names' attribute from the invoking object. If a 
list is passed as argument, it is interpreted as a hash and sets
the check-names attribute. Returns true on success, an Err object
otherwise. If only a single scalar is passed, it is interpreted as 
a type whose value is to be returned. If no arguments are passed, 
the value of the option is returned as an anonymous hash of the 
following form.

 { master => 'fail', slave => 'warn', .. }

An Err object is returned in case of error.

=cut

sub check_names
{
	my $self = shift ();
	my $check_names;

	if (@_ > 1) {
		$check_names = { @_ };
	}
	elsif (@_ == 1 && UNIVERSAL::isa ($_[0], 'HASH')) {
		$check_names = $_[0];
	}

	if ($check_names) {
		for my $type (keys (%$check_names)) {
			return (Unix::Conf->_err ('check_names', "illegal argument `$type'"))
				if ($type !~ /^(master|slave|response)$/i);
			return (Unix::Conf->_err ('check_names', "illegal argument `$check_names->{$type}'"))
				unless (__valid_checknames ($check_names->{$type}));
		}
		# reinit
		$self->{options}{'check-names'} = undef;
		$self->{options}{'check-names'}{lc ($_)} = $check_names->{$_} for (keys (%$check_names));
		$self->dirty (1);
		return (1);
	}
	
	return (Unix::Conf->_err ('check_names', "option not defined"))
		unless ($self->{options}{'check-names'});
	if (@_ == 1) {
		my $value;
		return (Unix::Conf->_err ('check_names', "option `check-names' not defined for type `$_[0]'"))
			unless (defined ($value = $self->{options}{'check-names'}{lc ($_[0])}));
		return ($value);
	}
	return ({ %{$self->{options}{'check-names'}} });
}

=item add_to_check_names ()

 Arguments
 type	=> value,
 type	=> value,
 ..

Object method.
Adds the argument to 'check-names' attribute. If a certain 'check-names' 
type is already defined, returns an Err object. Returns true on success, 
an Err object otherwise.

=cut

sub add_to_check_names
{
	my $self = shift ();

	return (Unix::Conf->_err ("add_to_check_names", "argument expected, got none"))
		unless (@_ > 1);

	my %check_names = (@_);
	# do not depend on -> autovivification.
	$self->{options}{'check-names'} = {}	unless ($self->{options}{'check-names'});
	for my $type (keys (%check_names)) {
		return (Unix::Conf->_err ('add_to_check_names', "illegal argument `$type'"))
			if ($type !~ /^(master|slave|response)$/i);
		return (Unix::Conf->_err ('add_to_check_names', "`$type' already defined"))
			if ($self->{options}{'check-names'}{$type});
		return (Unix::Conf->_err ('add_to_check_names', "illegal argument `$check_names{$type}'"))
			unless (__valid_checknames ($check_names{$type}));
	}
	$self->{options}{'check-names'}{lc($_)} = $check_names{$_} for (keys (%check_names));
	$self->dirty (1);
	return (1);
}

=item delete_from_check_names ()

 Arguments
 LIST	# of check-names types.

Object method.
Deletes 'check-names' types passed as argument, if defined and returns true
on success, an Err object otherwise.

=cut

sub delete_from_check_names
{
	my $self = shift ();

	return (Unix::Conf->_err ("add_to_check_names", "argument expected, got none"))
		unless (@_);

	for my $type (@_) {
		return (Unix::Conf->_err ('delete_from_check_names', "illegal argument `$type'"))
			if ($type !~ /^(master|slave|response)$/i);
		return (Unix::Conf->_err ('delete_from_check_names', "`$type' not defined"))
			unless ($self->{options}{'check-names'}{lc ($type)});
	}
	# use delete instead of assigning undef. this is because we copy and return
	# the hash to the user. with undef, the key will be defined, only the value will
	# be undef.
	delete ($self->{options}{'check-names'}{lc ($_)}) for (@_);
	# delete option if no keys left.
	delete ($self->{options}{'check-names'})
		unless (keys (%{$self->{options}{'check-names'}}));
	$self->dirty (1);
	return (1);
}

=item delete_check_names ()

 Arguments
 LIST		# type => 'master'|'slave'|'response'

Object method.
Deletes check-names attribute if no argument is passed, else
deletes only the specified type. Returns true on success, an
Err object otherwise.

=cut

sub delete_check_names
{
	my $self = shift ();

	return (Unix::Conf->_err ('delete_check_names', "option `check-names' not defined"))
		unless (defined ($self->{options}{'check-names'}));

	if (@_) {
		for my $type (@_) {
			return (Unix::Conf->_err ('delete_check_names', "illegal argument `$type'"))
				if ($type !~ /^(master|slave|response)$/i);
			return (Unix::Conf->_err ('delete_check_names', "check-names `$type' not defined"))
				unless ($self->{options}{'check-names'}{uc ($type)});
		}
		delete ($self->{options}{'check-names'}{lc ($_)}) for (@_);
	}
	else {
		delete ($self->{options}{'check-names'});
	}

	$self->dirty (1);
	return (1);
}

=item forwarders ()

 Arguments
 LIST				# List of IPv4 addresses in
 or                 # dotted quad notation.
 [ LIST ]

Object method.
Get/set the 'forwarders' attribute in the invoking object. If argument(s)
is/are passed, the method tries to set the 'forwarders' attribute and returns 
true on success, an Err object otherwise. If no arguments are passed then 
the method tries to return an array ref if the 'forwarders' attribute is 
defined, an Err object otherwise.

=cut

sub forwarders
{
	my $self = shift ();
	my $elements;
	
	if (@_) {
		if (ref ($_[0])) {
			return (Unix::Conf->_err ('forwarders', "expected arguments are a list or an array reference"))
				unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
			# allow empty forwarders statement.
			$elements = $_[0];
		}
		else {
			# assume a list of elements
			$elements = \@_;
		}
		for (@$elements) {
			return (Unix::Conf->_err ('forwarders', "illegal IPv4 address $_"))
				unless (__valid_ipaddress ($_));
		}
		# reinit
		$self->{options}{forwarders} = undef;
		@{$self->{options}{forwarders}}{@$elements} = (1) x @$elements;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{options}{forwarders}) ? [ keys (%{$self->{options}{forwarders}}) ] :
			Unix::Conf->_err ('forwarders', "option not defined")
	);
}

=item add_to_forwarders ()

 Arguments
 LIST				# List of IPv4 addresses in
 or                 # dotted quad notation.
 [ LIST ]

Object method.
Add the elements of the list to the 'forwarders' attribute. Return
true on success, an Err object otherwise.

=cut

sub add_to_forwarders
{
	my $self = shift ();
	my $elements;

	
	return (Unix::Conf->_err ('add_to_forwarders', "elements to be added not passed"))
		unless (@_);

	if (ref ($_[0])) {
		return (
			Unix::Conf->_err (
				'add_to_forwarders', 
				"expected arguments are a list or an array reference"
			)
		) unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
		# allow empty forwarders statement.
		$elements = $_[0];
	}
	else {
		# assume a list of elements
		$elements = \@_;
	}
	
	for (@$elements) {
		return (Unix::Conf->_err ('add_to_forwarders', "illegal IPv4 address $_"))
			unless (__valid_ipaddress ($_));
		return (
			Unix::Conf->_err ( 'add_to_forwarders', "address `$_' already defined" )
		) if ($self->{options}{forwarders}{$_});
	}
	@{$self->{options}{forwarders}}{@$elements} = (1) x @$elements;
	$self->dirty (1);
	return (1);
}

=item delete_from_forwarders ()

 Arguments
 LIST				# List of IPv4 addresses in
 or                 # dotted quad notation.
 [ LIST ]

Object method.
Delete elements of the list from the 'forwarders' attribute. Return
true on success, an Err object otherwise.

=cut

sub delete_from_forwarders
{
	my $self = shift ();
	my $elements;

	return (Unix::Conf->_err ('delete_from_forwarders', "elements to be deleted not passed"))
		unless (@_);

	if (ref ($_[0])) {
		return (Unix::Conf->_err ('add_to_forwarders', "expected arguments are a list or an array reference"))
			unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
		# allow empty forwarders statement.
		$elements = $_[0];
	}
	else {
		# assume a list of elements
		$elements = \@_;
	}
	
	for (@$elements) {
		return (Unix::Conf->_err ('delete_from_forwarders', "illegal IPv4 address $_"))
			unless (__valid_ipaddress ($_));
		return (
			Unix::Conf->_err ( 'delete_from_forwarders', "address `$_' not defined" )
		) unless ($self->{options}{forwarders}{$_});
	}
	delete (@{$self->{options}{forwarders}}{@$elements});
	# if no keys left, delete the forwarders options itself
	delete ($self->{options}{forwarders})
		unless (keys (%{$self->{options}{forwarders}}));
	$self->dirty (1);
	return (1);
}

=item listen_on ()

 Arguments
 port	=> 	[ qw (element1 element2 ..) ],

 OR

 port	=> 	Acl object,
 port	=> ...,

 OR
 {}				# with the same format

Object method.
`port' can be '' (empty string) to indicate the default port 53.
Sets the values for `port's defined in the argument as the values
for the `listen-on' attribute. Returns true on success, an Err object
otherwise.

=cut

# The address data is stored in an Acl object, which itself is stored in a hash
# keyed in port. The default port (when it is not specified) is DEFAULT.
# this option does not need the add_to_listen_on method, because every time
# listen-on is called it adds to the previous data, instead of replacing the old
# data.
sub listen_on
{
	my $self = shift ();
	my $args;

	# no arguments passed.
	return ($self->get_listen_on_elements ())
		unless (@_);
	
	if (@_ == 1) {
		return (Unix::Conf->_err ("listen_on", "expected argument either a LIST or a hash reference"))
			unless (UNIVERSAL::isa ($_[0], "HASH"));
		$args = { %{$_[0]} };
	}
	else {
		$args = { @_ };
	}

	# validate first
	for my $port (keys (%$args)) {
		return (Unix::Conf->_err ('listen_on', "illegal PORT `$port'"))
			if ($port && !__valid_port ($port));
		return (
			Unix::Conf->_err ('listen_on', "value type for port `$port' neither array ref nor Acl object")
		) unless (
				UNIVERSAL::isa ($args->{$port}, "Unix::Conf::Bind8::Conf::Acl") || 
				UNIVERSAL::isa ($args->{$port}, "ARRAY")
		);
	}

	$self->{options}{'listen-on'} = undef;
	for my $port (keys (%$args)) {
		my $_port = $port && $port == 53 ? '' : $port;
		if (UNIVERSAL::isa ($args->{$port}, "Unix::Conf::Bind8::Conf::Acl")) {
			$args->{$port}->_parent ($self->_parent ())
				unless ($args->{$port}->_parent ());
		}
		else {
			$args->{$port} = Unix::Conf::Bind8::Conf::Acl->new (
				PARENT => $self->_parent (), ELEMENTS => $args->{$port}
			) or return ($args->{$port});
		}
		$self->{options}{'listen-on'}{$_port} = $args->{$port};
	}

	$self->dirty (1);
	return (1);
}

=item add_to_listen_on ()

 Arguments
 port	=> 	[ qw (element1 element2 ..) ],
 port	=> ...,

Object method.
`port' can be '' (empty string) to indicate the default port 53.

Adds the value of `port's defined in the argument, to the ones
defined in the listen-on attribute. Returns true on success, 
an Err object otherwise.

=cut

sub add_to_listen_on ()
{
	my $self = shift ();
	my (%args, $ret);

	return (Unix::Conf->_err ("add_to_listen_on", "arguments expected, got none"))
		unless (@_);

	%args = ( @_ );

	# validate first
	for my $port (keys (%args)) {
		# the length test is to ensure that if a '' is specified, $port won't
		# be tested against a number, as it will turn into 0
		return (Unix::Conf->_err ('add_to_listen_on', "illegal PORT `$port'"))
			if ($port && !__valid_port ($port));
		return (
			Unix::Conf->_err ('add_to_listen_on', "value type for port `$port' not array ref")
		) unless (UNIVERSAL::isa ($args{$port}, "ARRAY"));
	}

	for my $port (keys (%args)) {
		my $_port = $port && $port == 53 ? '' : $port;
		# if no elements defined as of yet for this port, create a new Acl object
		# to hold it.
		unless ($self->{options}{'listen-on'}{$_port}) {
			my $acl;
			# specify the reverse pointer.
			$acl = Unix::Conf::Bind8::Conf::Acl->new (PARENT => $self->_parent ()) or return ($acl);
			$self->{options}{'listen-on'}{$_port} = $acl;
		}
		$ret = $self->{options}{'listen-on'}{$_port}->add_elements ($args{$port})
			or return ($ret);
	}

	$self->dirty (1);
	return (1);
}

=item get_listen_on ()

 Arguments
 port		# Optional.

Object method.
`port' can be '' (empty string) to indicate the default port 53.
If `port' is specified, addresses defined for that port are returned
as an Acl object. Else all listen-on statements are returned 
as an anonymous hash with keys as the defined portnos ('' for the 
default port) and values as Acl objects defined for that port.
An Err object is returned if the listen-on option has not yet 
been defined.

NOTE: 

Do not manipulate the returned Acl objects directly. If you
do so, set the dirty flag for the Options object.

=cut

sub get_listen_on
{
	my ($self, $port) = @_;
	my $_port;

	return (Unix::Conf->_err ('get_listen_on', "option not defined"))
		unless ($self->{options}{'listen-on'});

	if (defined ($port)) {
		return (Unix::Conf->_err ('get_listen_on', "illegal PORT `$port'"))
			if ($port && !__valid_port ($port));

		$_port = ($port && $port == 53) ? '' : $port;

		# return Acl object for $port
		return (Unix::Conf->_err ('get_listen_on', "no elements defined for port `$port'"))
			unless ($self->{options}{'listen-on'}{$_port});
		return ($self->{options}{'listen-on'}{$_port});
	}

	# return  { port => Acl } for all ports
	my $ret = {};
	my @keys = keys (%{$self->{options}{'listen-on'}});
	# don't know if this can occur. sanity.
	return (Unix::Conf->_err ('get_listen_on', "no listen-on statements left"))
		unless (@keys);
	$ret->{$_} =  $self->{options}{'listen-on'}{$_} for (@keys);
	return ($ret);
}

=item get_listen_on_elements ()

 Arguments
 port		# Optional.

Object method.
`port' can be '' (empty string) to indicate the default port 53.
If `port' is specified, addresses defined for that port are returned
as an anonymous array. Else all listen-on statements are returned 
as an anonymous hash with keys as the defined portnos ('' for the 
default port) and values as anonymous array with addresses defined 
for that port. An Err object is returned if the listen-on option 
has not yet been defined.

=cut

sub get_listen_on_elements
{
	my ($self, $port) = @_;
	my $_port;

	return (Unix::Conf->_err ('get_listen_on_elements', "option not defined"))
		unless ($self->{options}{'listen-on'});

	if (defined ($port)) {
		return (Unix::Conf->_err ('get_listen_on', "illegal PORT `$port'"))
			if ($port && !__valid_port ($port));

		$_port = ($port && $port == 53) ? '' : $port;

		# return Acl object for $port
		return (Unix::Conf->_err ('get_listen_on_elements', "no elements defined for port `$port'"))
			unless ($self->{options}{'listen-on'}{$_port});
		return ($self->{options}{'listen-on'}{$_port}->elements ());
	}

	# return  { port => Acl } for all ports
	my $ret = {};
	my @keys = keys (%{$self->{options}{'listen-on'}});
	# don't know if this can occur. sanity.
	return (Unix::Conf->_err ('get_listen_on_elements', "no listen-on statements left"))
		unless (@keys);
	$ret->{$_} =  $self->{options}{'listen-on'}{$_}->elements () for (@keys);
	return ($ret);
}

=item delete_from_listen_on ()

 Arguments
 port	=> 	[ qw (element1 element2 ..) ],
 port	=> ...,

Object method.
`port' can be '' (empty string) to indicate the default port 53.
Deletes the value of `port's defined in the argument from the 
ones defined in the `listen-on' attribute and returns true on 
success, an Err object otherwise.

=cut

sub delete_from_listen_on
{
	my $self = shift ();
	my %args;

	return (Unix::Conf->_err ("delete_from_listen_on", "arguments expected, got none"))
		unless (@_);

	%args = ( @_ );

	# validate first
	for my $port (keys (%args)) {
		my $_port = $port == 53 ? '' : $port;
		# the length test is to ensure that if a '' is specified, $port won't
		# be tested against a number, as it will turn into 0
		return (Unix::Conf->_err ('delete_from_listen_on', "illegal PORT `$port'"))
			if ($port && !__valid_port ($port));
		return (
			Unix::Conf->_err ('delete_from_listen_on', "value type for port `$port' not array ref")
		) unless (UNIVERSAL::isa ($args{$port}, "ARRAY"));
		return (Unix::Conf->_err ('delete_from_listen_on', "listen-on not defined for port `$port'"))
			unless ($self->{options}{'listen-on'}{$_port});
	}

	for my $port (keys (%args)) {
		my $_port = $port == 53 ? '' : $port;
		my $ret;
		$ret = $self->{options}{'listen-on'}{$_port}->delete_elements ($args{$port})
			or return ($ret);
		# delete the port if no elements left remaining for that port.
		delete ($self->{options}{'listen-on'}{$_port})
			unless (@{$self->{options}{'listen-on'}{$_port}->elements ()});
	}
	# delete the option itself, if no ports left.
	delete ($self->{options}{'listen-on'})	unless (keys (%{$self->{options}{'listen-on'}}));

	$self->dirty (1);
	return (1);
}

=item delete_listen_on ()

 Arguments
 LIST		# of ports.

Object method.
port can be '' (empty string) to indicate the default port 53.
If an argument(s) are passed, these ports deleted from the internal
representation.  Else all listen-on statements are deleted. Returns 
true on success, an Err object otherwise. 

=cut

sub delete_listen_on
{
	my $self = shift ();
	my $_port;

	return (Unix::Conf->_err ('delete_listen_on', "option not defined"))
		unless ($self->{options}{'listen-on'});

	if (@_) {
		for my $port (@_) {
			return (Unix::Conf->_err ('delete_listen_on', "illegal PORT `$port'"))
				if ($port && !__valid_port ($port));
			$_port = ($port && $port == 53) ? '' : $port;

			# return elements defined for PORT
			return (Unix::Conf->_err ('delete_listen_on', "no elements defined for port `$port'"))
				unless ($self->{options}{'listen-on'}{$_port});
			delete ($self->{options}{'listen-on'}{$_port});

		}

		# check to see if any port is left. if all defined ones have been deleted
		# fall below and delete the whole statement
		if (keys (%{$self->{options}{'listen-on'}})) {
			$self->dirty (1);
			return (1)
		}
	}

	# delete the whole statement
	delete ($self->{options}{'listen-on'});
	$self->dirty (1);
	return (1);
}

=item rrset_order ()

 Arguments
 NAME		=> name,	# Optional ('*'|'.*')
 CLASS		=> class,	# Optional ('ANY'|'IN')
 TYPE		=> type,	# Optional ('ANY'|'A'|'NS'|'MX')
 ORDER		=> order,	# ('fixed'|'randon'|'cyclic')

 or a list of hash references, where the hashes have the same
 structure as above.
 or a array reference populated with hash references with the
 same structure as above.

Object method.
Sets the rrset-order option. CLASS, TYPE, NAME can be optional, in which case they
are assumed to be, 'ANY', 'ANY', and '*'. Returns true on success, an Err object
otherwise.

=cut

sub rrset_order
{
	my $self = shift ();
	my ($args, $_port);

	return ($self->get_rrset_order ())
		unless (@_);

	if (ref ($_[0])) {
		if (UNIVERSAL::isa ($_[0], 'HASH')) {
			# assume that a list of hashrefs have been passed
			$args = \@_;
		}
		elsif (UNIVERSAL::isa ($_[0], 'ARRAY')) {
			$args = $_[0];
		}
		else {
			return (Unix::Conf->_err ('rrset_order', "Argument must either be a list or a list of hash references"))
		}
	}
	else {
		# assume arguments specified as a list directly as PORT => ..
		$args = [ { @_ } ];
	}
	
	for my $itr (@$args) {
		$itr->{CLASS}	= 'ANY' 	unless ($itr->{CLASS});
		$itr->{TYPE}	= 'ANY' 	unless ($itr->{TYPE});
		$itr->{NAME}	= '*'		unless ($itr->{NAME});
		return (Unix::Conf->_err ('rrset_order', "illegal CLASS `$itr->{CLASS}'"))
			unless ($itr->{CLASS} =~ /^(ANY|IN)$/);
		return (Unix::Conf->_err ('rrset_order', "illegal TYPE `$itr->{TYPE}'"))
			unless ($itr->{TYPE} =~ /^(ANY|A|NS|MX)$/);
		# strip quotes if any
		$itr->{NAME} =~ s/^"(.+)"$/$1/;
		return (Unix::Conf->_err ('rrset_order', "ORDER not defined"))
			unless ($itr->{ORDER});
		return (Unix::Conf->_err ('rrset_order', "illegal value for ORDER `$itr->{ORDER}'"))
			unless ($itr->{ORDER} =~ /^(fixed|random|cyclic)$/);
	}

	# reinit
	$self->{options}{'rrset-order'} = undef;
	for my $itr (@$args) {
		$self->{options}{'rrset-order'}{$itr->{NAME}}{$itr->{CLASS}}{$itr->{TYPE}} = $itr->{ORDER};
	}

	$self->dirty (1);
	return (1);
}

=item get_rrset_order ()

 Arguments
 name,		# Optional
 class,		# Optional
 type		# Optional

Object method.
The following diagram should make clear the type of return to expect.
If all 3 arguments are passed, the return is the order defined for the
arguments as a scalar, if defined, an Err object otherwise.
If type is not passed, the return value is an anonymous hash

 {
    'TYPE1' => 'order',
    'TYPE2' => 'order',
    ..
 }

for the passed name and class, if defined, an Err object otherwise.
If class is not passed, the return value is an anonymous hash

 {
    'CLASS1'    => {
                        'TYPE1	=> 'order',
                        'TYPE2'	=> 'order',
                        ..
                   },
    'CLASS2'    => {
                        'TYPE1	=> 'order',
                        'TYPE2'	=> 'order',
                        ..
                   },
    ...
 }

for the passed name, if defined, an Err object otherwise.
If even the name is not passed, the return value is an anonymous hash

 {
    'NAME1'     =>	{
        'CLASS1'    => {
                            'TYPE1	=> 'order',
                            'TYPE2'	=> 'order',
                            ..
					   },
        'CLASS2'    => {
                            'TYPE1	=> 'order',
                            'TYPE2'	=> 'order',
                            ..
					   },
        ...
				},
    'NAME2'     =>	{
        'CLASS1'    => {
                            'TYPE1	=> 'order',
                            'TYPE2'	=> 'order',
                            ..
					   },
        'CLASS2'    => {
                            'TYPE1	=> 'order',
                            'TYPE2'	=> 'order',
                            ..
					   },
        ...
               },
    ...
 }

for all defined names, if any is defined, an Err object otherwise.

=cut

sub get_rrset_order
{
	my ($self, $name, $class, $type) = @_;
	my $ret;

	return (Unix::Conf->_err ('get_rrset_order', "option not defined"))
		unless ($self->{options}{'rrset-order'});

	$class	= 'ANY' 	if (defined ($class) && !$class);
	$type	= 'ANY' 	if (defined ($type) && !$type);
	$name	= '*'		if (defined ($name) && !$name);

	return (Unix::Conf->_err ('get_rrset_order', "illegal CLASS `$class'"))
		if (defined ($class) && $class !~ /^(ANY|IN)$/);
	return (Unix::Conf->_err ('get_rrset_order', "illegal TYPE `$type'"))
		if (defined ($type) && $type !~ /^(ANY|A|NS|MX)$/);

	if (defined ($name)) {
		# strip quotes if any
		$name =~ s/^"(.+)"$/$1/;
		return (Unix::Conf->_err ('get_rrset_order', "$name not defined"))
			unless ($self->{options}{'rrset-order'}{$name});

		if (defined ($class)) {
			return (Unix::Conf->_err ('get_rrset_order', "$class not defined for $name"))
				unless ($self->{options}{'rrset-order'}{$name}{$class});

			if (defined ($type)) {
				return (Unix::Conf->_err ('get_rrset_order', "$type not defined for $name, $class"))
					unless ($self->{options}{'rrset-order'}{$name}{$class}{$type});

				$ret = $self->{options}{'rrset-order'}{$name}{$class}{$type};
			}
			else {
				for my $type (keys (%{$self->{options}{'rrset-order'}{$name}{$class}})) {
					$ret->{$type} = $self->{options}{'rrset-order'}{$name}{$class}{$type};
				}
			}
		}
		else {
			for my $class (keys (%{$self->{options}{'rrset-order'}{$name}})) {
				for my $type (keys (%{$self->{options}{'rrset-order'}{$name}{$class}})) {
					$ret->{$class}{$type} = $self->{options}{'rrset-order'}{$name}{$class}{$type};
				}
			}
		}
	}
	else {
		for my $name (keys (%{$self->{options}{'rrset-order'}})) {
			for my $class (keys (%{$self->{options}{'rrset-order'}{$name}})) {
				for my $type (keys (%{$self->{options}{'rrset-order'}{$name}{$class}})) {
					$ret->{$name}{$class}{$type} = $self->{options}{'rrset-order'}{$name}{$class}{$type};
				}
			}
		}
	}
	return ($ret);
}

=item add_to_rrset_order ()

 Arguments
 NAME		=> name,	# Optional ('*'|'.*')
 CLASS		=> class,	# Optional ('ANY'|'IN')
 TYPE		=> type,	# Optional ('ANY'|'A'|'NS'|'MX')
 ORDER		=> order,	# ('fixed'|'randon'|'cyclic')

 or a list of hash references, where the hashes have the same
 structure as above.

Object method.
Adds to any defined rrset-order option. CLASS, TYPE, NAME can be optional, in which 
case they are assumed to be, 'ANY', 'ANY', and '*'. Returns true on success, an Err object
otherwise.

=cut

sub add_to_rrset_order
{
	my $self = shift ();
	my ($args, $_port);

	if (ref ($_[0])) {
		if (UNIVERSAL::isa ($_[0], 'HASH')) {
			# assume that a list of hashrefs have been passed
			$args = \@_;
		}
		else {
			return (Unix::Conf->_err ('add_to_rrset_order', "Argument must either be a list or a list of hash references"))
		}
	}
	else {
		# assume arguments specified as a list directly as PORT => ..
		$args = [ { @_ } ];
	}
	
	for my $itr (@$args) {
		$itr->{CLASS}	= 'ANY' 	unless ($itr->{CLASS});
		$itr->{TYPE}	= 'ANY' 	unless ($itr->{TYPE});
		$itr->{NAME}	= '*'		unless ($itr->{NAME});
		return (Unix::Conf->_err ('add_to_rrset_order', "illegal value of CLASS `$itr->{CLASS}'"))
			unless ($itr->{CLASS} =~ /^(ANY|IN)$/);
		return (Unix::Conf->_err ('add_to_rrset_order', "illegal value of TYPE `$itr->{TYPE}'"))
			unless ($itr->{TYPE} =~ /^(ANY|A|NS|MX)$/);
		# strip quotes if any
		$itr->{NAME} =~ s/^"(.+)"$/$1/;
		return (Unix::Conf->_err ('add_to_rrset_order', "ORDER not defined"))
			unless ($itr->{ORDER});
		return (Unix::Conf->_err ('add_to_rrset_order', "illegal value for ORDER `$itr->{ORDER}'"))
			unless ($itr->{ORDER} =~ /^(fixed|random|cyclic)$/);
		return (Unix::Conf->_err ('add_to_rrset_order', "order already defined for $itr->{NAME}, $itr->{CLASS}, $itr->{TYPE}"))
			if ($self->{options}{'rrset-order'}{$itr->{NAME}}{$itr->{CLASS}}{$itr->{TYPE}});
	}

	for my $itr (@$args) {
		$self->{options}{'rrset-order'}{$itr->{NAME}}{$itr->{CLASS}}{$itr->{TYPE}} = $itr->{ORDER};
	}

	$self->dirty (1);
	return (1);
}

=item delete_from_rrset_order ()

 Arguments
 NAME		=> name,	# Optional ('*'|'.*')
 CLASS		=> class,	# Optional ('ANY'|'IN')
 TYPE		=> type,	# Optional ('ANY'|'A'|'NS'|'MX')

 or a list of hash references, where the hashes have the same
 structure as above.

Object method.
Deletes from any defined rrset-order option. CLASS, TYPE, NAME can be optional, in which 
case they are assumed to be, 'ANY', 'ANY', and '*'. Returns true on success, an Err object
otherwise. 
Note that the method, deletes branches that have become leaves because of deletions. 
For example, if for NAME, CLASS the only TYPE defined is deleted, CLASS
gets deleted. If NAME has no other records, NAME gets deleted too. If NAME is the only 
rrset-order defined, the option gets deleted.

=cut

sub delete_from_rrset_order
{
	my $self = shift ();
	my ($args, $_port);

	if (ref ($_[0])) {
		if (UNIVERSAL::isa ($_[0], 'HASH')) {
			# assume that a list of hashrefs have been passed
			$args = \@_;
		}
		else {
			return (Unix::Conf->_err ('delete_from_rrset_order', "Argument must either be a list or a list of hash references"))
		}
	}
	else {
		# assume arguments specified as a list directly as PORT => ..
		$args = [ { @_ } ];
	}
	
	for my $itr (@$args) {
		$itr->{CLASS}	= 'ANY' 	unless ($itr->{CLASS});
		$itr->{TYPE}	= 'ANY' 	unless ($itr->{TYPE});
		$itr->{NAME}	= '*'		unless ($itr->{NAME});
		return (Unix::Conf->_err ('delete_from_rrset_order', "illegal value of CLASS `$itr->{CLASS}'"))
			unless ($itr->{CLASS} =~ /^(ANY|IN)$/);
		return (Unix::Conf->_err ('delete_from_rrset_order', "illegal value of TYPE `$itr->{TYPE}'"))
			unless ($itr->{TYPE} =~ /^(ANY|A|NS|MX)$/);
		# strip quotes if any
		$itr->{NAME} =~ s/^"(.+)"$/$1/;
		# test every step, as it can create unwanted keys through autovivification.
		# keys thus created will be deleted down below, but still
		return (Unix::Conf->_err ('delete_from_rrset_order', "$itr->{NAME} not defined"))
			unless ($self->{options}{'rrset-order'}{$itr->{NAME}});
		return (Unix::Conf->_err ('delete_from_rrset_order', "$itr->{CLASS} not defined for $itr->{NAME}"))
			unless ($self->{options}{'rrset-order'}{$itr->{NAME}}{$itr->{CLASS}});
		return (Unix::Conf->_err ('delete_from_rrset_order', "$itr->{TYPE} not defined for $itr->{NAME}, $itr->{CLASS}"))
			unless ($self->{options}{'rrset-order'}{$itr->{NAME}}{$itr->{CLASS}}{$itr->{TYPE}});
	}

	for my $itr (@$args) {
		delete ($self->{options}{'rrset-order'}{$itr->{NAME}}{$itr->{CLASS}}{$itr->{TYPE}});

		# delete if no keys left.
		delete ($self->{options}{'rrset-order'}{$itr->{NAME}}{$itr->{CLASS}})
			unless (keys (%{$self->{options}{'rrset-order'}{$itr->{NAME}}{$itr->{CLASS}}}));

		delete ($self->{options}{'rrset-order'}{$itr->{NAME}})
			unless (keys (%{$self->{options}{'rrset-order'}{$itr->{NAME}}}));

		# delete the option itself, if no keys left.
		delete ($self->{options}{'rrset-order'})
			unless (keys (%{$self->{options}{'rrset-order'}}));
	}
	return (1);
}

=item delete_rrset_order ()

 Arguments
 name,		# Optional
 class		# Optional
 type		# Optional

Object method.
If name, class and type are passed, the defined order, if any, for
the same is deleted. If only name, class are passed, all defined
types for that name and class are deleted, if defined. If only the
name is specified, all classes defined for that name are deleted.
Note that the method, deletes branches that have become leaves because of deletions. 
For example, if for NAME, CLASS the only TYPE defined is deleted, CLASS
gets deleted. If NAME has no other records, NAME gets deleted too. If NAME is the only 
rrset-order defined, the option gets deleted.
In all cases, true is returned on success, an Err object otherwise.

=cut

sub delete_rrset_order
{
	my ($self, $name, $class, $type) = @_;

	return (Unix::Conf->_err ('delete_rrset_order', "option not defined"))
		unless ($self->{options}{'rrset-order'});

	if (defined ($name)) {
		# strip quotes if any
		$name =~ s/^"(.+)"$/$1/;
		return (Unix::Conf->_err ('delete_rrset_order', "$name not defined"))
			unless ($self->{options}{'rrset-order'}{$name});

		if (defined ($class)) {
			return (Unix::Conf->_err ('delete_rrset_order', "$class not defind for $name"))
				unless ($self->{options}{'rrset-order'}{$name}{$class});

			if (defined ($type)) {
				return (Unix::Conf->_err ('delete_rrset_order', "$type not defined for $name, $class"))
					unless ($self->{options}{'rrset-order'}{$name}{$class}{$type});
				delete ($self->{options}{'rrset-order'}{$name}{$class}{$type});
				goto DELETE_RRS_RET
					if (keys (%{$self->{options}{'rrset-order'}{$name}{$class}}));
			}
			delete ($self->{options}{'rrset-order'}{$name}{$class});
			goto DELETE_RRS_RET
				if (keys (%{$self->{options}{'rrset-order'}{$name}}));
		}
		delete ($self->{options}{'rrset-order'}{$name});
		goto DELETE_RRS_RET
			if (keys (%{$self->{options}{'rrset-order'}}));
	}
	delete ($self->{options}{'rrset-order'});

DELETE_RRS_RET:
	$self->dirty (1);
	return (1);
}

=item options

Object method.
Iterates through the list of defined options returning their name one at a
time in a scalar context, or a list of all defined option names in list
context.

=cut

sub options
{
	return (
		wantarray () ? sort keys (%{$_[0]->{options}}) : (each (%{$_[0]->{options}}))[0]
	);
}

sub __valid_option
{
	my ($self, $option) = @_;

	local $" = "|";
	my  @opts = keys (%Supported_Options);
	return ($option =~ /^(@opts)$/);
}

my @AclOptions = qw (
	allow-transfer
	allow-query
	allow-recursion
	topology
	blackhole
	sortlist
);

my @StringOptions = qw (
	version
	directory
	named-xfer
	dump-file
	statistics-file
	memstatistics-file
	pid-file
);

sub __render ()
{
	my $self = $_[0];
	my ($rendered, $meth, $tmp);
		
	$rendered = qq (options {\n);
	
	for my $option ($self->options ()) {
		($option eq 'forwarders')		&& do {
			$tmp = $self->forwarders ();
			local $" = "; ";
			$rendered .= "\tforwarders {";
			# the list can be empty
			$rendered .= " @$tmp;" if (@$tmp);
			$rendered .= " };\n";
			next;
		};
		($option eq 'check-names')		&& do {
			$tmp = $self->check_names ();
			$rendered .= "\tcheck-names $_ $tmp->{$_};\n"
				for (keys (%$tmp));
			next;
		};
		($option eq 'listen-on')		&& do {
			$tmp = $self->get_listen_on ();
			for (keys (%$tmp)) {
				$rendered .= qq (\tlisten-on );
				# port can be ''
				$rendered .= qq (port $_ )
					if ($_);
				$rendered .= ${$tmp->{$_}->_rstring (undef, 1)} . "\n";
			}
			next;
		};
		($option eq 'query-source')		&& do {
			$tmp = $self->query_source ();
			next;
			$rendered .= qq (\tquery-source );
			$rendered .= qq (port $tmp->{PORT}) 	
				if ($tmp->{PORT});
			$rendered .= qq ( address $tmp->{ADDRESS})	
				if ($tmp->{ADDRESS});
			$rendered .= ";\n";
			next;
		};
		($option eq 'rrset-order')		&& do {
			$tmp= $self->get_rrset_order ();
			$rendered .= "\trrset-order {\n";
			for my $name (keys (%$tmp)) {
				for my $class (keys (%{$tmp->{$name}})) {
					for my $type (keys (%{$tmp->{$name}{$class}})) {
						$rendered .= "\t\t";
						$rendered .= "class $class " if ($class ne 'ANY');
						$rendered .= "type $type " if ($type ne 'ANY');
						$rendered .= qq(name "$name" ) if ($name ne '*');
						$rendered .= "order $tmp->{$name}{$class}{$type};\n";
					}
				}
			}
			$rendered .= "\t};\n";
			next;
		};

		local $"= "|";
		$meth = $option;
		$meth =~ tr/-/_/;
		$tmp = $self->$meth ();

		($option =~ /^(@AclOptions)$/)		&& do {
			$rendered .= "\t$option " . ${$tmp->_rstring (undef, 1)} . "\n";
			next;
		};

		($option =~ /^(@StringOptions)$/)	&& do {
			$rendered .= qq(\t$option "$tmp";\n);
			next;
		};
		
		# most of the other options.
		$rendered .= "\t$option $tmp;\n";
	}

	$rendered .= qq (};);
	return ($_[0]->_rstring (\$rendered));
}


1;
__END__
