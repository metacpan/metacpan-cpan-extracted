# Bind8 package directive handling
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Controls - Class for handling Bind8 configuration
directive `controls'

=head1 SYNOPSIS

	use Unix::Conf::Bind8;

	my ($conf, $controls, $ret);
	$conf = Unix::Conf::Bind8->new_conf (
		FILE        => '/etc/named.conf',
		SECURE_OPEN => 1,
	) or $conf->die ("couldn't open `named.conf'");

	#
	# Ways to get a Controls object
	#

	$controls = Unix::Conf::Bind8::Conf->new_controls (
		UNIX	=> [ '/var/run/ndc', 0600, 0, 0 ],
		INET	=> [ '*', 52, [ qw (any) ], ],
	) or $controls->die ("couldn't create controls object");

	# or

	$controls = Unix::Conf::Bind8::Conf->get_controls ()
		or $controls->die ("couldn't get controls object");

	# 
	# Operations that can be performed on an Controls object.
	#

	# set the various attributes.

	$ret = $controls->inet ('192.168.1.1', '1000', [ qw (localhost) ])
		or $ret->die ("couldn't set inet channel");

	$ret = $controls->unix ('/etc/namedb/control.pipe', 0600, 0, 0)
		or $ret->die ("couldn't set unix channel");

	# get the attributes

	$ret = $controls->inet () or $ret->die ("couldn't get inet channel");
	printf ("ADDRESS => %s, PORT => %s, ALLOW => %s\n", $ret->[0], $ret->[1],
		"@{$ret->[2]->elements ()});

	$ret = $controls->unix () or $ret->die ("couldn't get unix channel");
	printf ("PATH => %s, PERMS => %d, OWNER => %d, GROUP => %d",
		$ret->[0], $ret->[1], $ret->[2], $ret->[3]);

	# delete
	$ret = $controls->delete_inet () or $ret->die ("couldn't delete inet channel");
	$ret = $controls->delete_unix () or $ret->die ("couldn't delete unix channel");

=head1 METHODS

=cut

package Unix::Conf::Bind8::Conf::Controls;

use strict;
use warnings;
use Unix::Conf;
use Unix::Conf::Bind8::Conf::Directive;
our (@ISA) = qw (Unix::Conf::Bind8::Conf::Directive);

use Unix::Conf::Bind8::Conf::Lib;


use constant	I_ADDR	=> 0;
use constant	I_PORT	=> 1;
use constant	I_ALLOW	=> 2;

use constant	U_PATH	=> 0;
use constant	U_PERM	=> 1;
use constant	U_OWNER	=> 2;
use constant	U_GROUP	=> 3;

=item new ()

 Arguments
 UNIX	=> [ PATH, PERM, OWNER, GROUP ],
 INET	=> [ ADDR, PORT, ALLOW ]
 WHERE  => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG   => Unix::Conf::Bind8::Conf::Directive subclass object
                  # WARG is to be provided only in case WHERE eq 'BEFORE 
                  # or WHERE eq 'AFTER'
 PARENT	=> reference,   
                  # to the Conf object datastructure.

Class constructor.
Creates a new Unix::Conf::Bind8::Conf::Controls object and returns it, on 
success, an Err object otherwise. Do not use this constructor directly. Use
the Unix::Conf::Bind8::Conf::new_controls () method instead.

=cut

sub new
{
	shift ();
	my %args = @_;
	my $new = bless ({});
	my $ret;

	$args{PARENT} 	||	return (Unix::Conf->_err ('new', "PARENT not defined"));
	$ret = $new->_parent ($args{PARENT}) or return ($ret);
	$ret = $new->inet (@{$args{INET}}) or return ($ret)
		if ($args{INET});
	$ret = $new->unix (@{$args{UNIX}}) or return ($ret)
		if ($args{UNIX});
	$ret = Unix::Conf::Bind8::Conf::_add_controls ($new)
		or return ($ret);
	$args{WHERE} = 'LAST'	unless ($args{WHERE});
	$ret = Unix::Conf::Bind8::Conf::_insert_in_list ($new, $args{WHERE}, $args{WARG})
		or return ($ret);
	return ($new);
}


=item inet ()

 Arguments
 ADDRESS	# optional
 PORT		# optional
 ALLOW		# optional

Object method.
Argument `ALLOW' can either be an Acl object, or an array reference.
Get/sets the corresponding attribute, and returns either the attribute
values or true on success, an Err object otherwise. The attribute values
are returned as an anonymous array [ ADDRESS PORT ALLOW ], where ALLOW
is an Acl object.

=cut

sub inet
{
	my ($self, $addr, $port, $allow) = @_;
	my $acl;

	if ($addr) {
		return (Unix::Conf->_err ('inet', "illegal address `$addr'"))
			unless ($addr eq '*' || __valid_ipaddress ($addr));
		return (Unix::Conf->_err ('inet', "illegal port `$port'"))
			unless (__valid_port ($port));
		if (ref ($allow)) {
			if (UNIVERSAL::isa ($allow, 'ARRAY')) {
				$acl = Unix::Conf::Bind8::Conf::Acl->new (
					PARENT		=> $self->_parent (),
					ELEMENTS	=> $allow,
				) or return ($acl);
			}
			elsif (UNIVERSAL::isa ($allow, 'Unix::Conf::Bind8::Conf::Acl')) {
				$acl = $allow;
			}
			else {
				return (	
					Unix::Conf->_err (
						'inet', 
						"expected arguments are array reference or Unix::Conf::Bind8::Conf::Acl object"
					)
				);
			}
		}
		else {
			# assume a single element
			$acl = Unix::Conf::Bind8::Conf::Acl->new (
				PARENT		=> $self-_parent (),
				ELEMENTS	=> [ $allow ],
			) or return ($acl);
		}
		$self->{inet} = [ $addr, $port, $acl ];
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{inet}) ? [ @{$self->{inet}} ] :
			Unix::Conf->_err ('inet', "inet control channel not defined")
	);
}

=item inet_allow

Object method.
Returns the elements defined for the allow as an anonymous array.
if defined, an Err object otherwise.

=cut

sub inet_allow
{
	my $self = $_[0];

	return (
		defined ($self->{inet}) ? $self->{inet}[I_ALLOW]->elements () :
			Unix::Conf->_err ('inet_allow', "inet control channel not defined")
	);
}

=item unix ()

 Arguments
 PATH,
 'PERM',	# As string.
 OWNER,
 GROUP

Object method.
If arguments are passed, sets it as the value of the corresponding attribute,
returns true on success, an Err otherwise. If no arguments are passed, returns
the defined value as an anonymous array [ PATH, PERM, OWNER, GROUP ], if defined,
an Err object otherwise.

NOTE: The PERM argument is to be specified as a string, to avoid
unecessary complications. As this module does not interpret these values,
it makes sense to use a string, instead of octal.

=cut

sub unix
{
	my ($self, $path, $perm, $owner, $group) = @_;

	if ($path) {
		$path = qq("$path")	if ($path =~ /^[^"]/);
		return (Unix::Conf->_err ('unix', "perm `$perm' not a number"))
			unless ($perm =~ /^\d+$/);
		return (Unix::Conf->_err ('unix', "owner `$owner' not a number"))
			unless ($perm =~ /^\d+$/);
		return (Unix::Conf->_err ('unix', "group `$group' not a number"))
			unless ($perm =~ /^\d+$/);
		$self->{unix} = [ $path, $perm, $owner, $group ];
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{unix}) ? [ @{$self->{unix}} ] :
			Unix::Conf->_err ('unix', "unix control channel not defined")
	);
}

=item delete_inet ()

Object method.
Deletes the `inet' attribute, and returns true, if defined, an Err object
otherwise.

=cut

sub delete_inet
{
	my $self = $_[0];
	return (Unix::Conf->_err ('delete_inet', "inet control channel not defined"))
		unless (defined ($self->{inet}));
	delete ($self->{inet});
	$self->dirty (1);
	return (1);
}

=item delete_unix ()

Object method.
Deletes the `unix' attribute, and returns true, if defined, an Err object
otherwise.

=cut

sub delete_unix
{
	my $self = $_[0];
	return (Unix::Conf->_err ('delete_unix', "unix control channel not defined"))
		unless (defined ($self->{unix}));
	delete ($self->{unix});
	$self->dirty (1);
	return (1);
}

sub __render
{
	my $self = $_[0];
	my $tmp;
	
	my $rendered = "controls {\n";
	if ($tmp = $self->inet ()) {
		$rendered .= sprintf (
			"\tinet $tmp->[I_ADDR] port $tmp->[I_PORT] allow %s\n",
			${$tmp->[I_ALLOW]->_rstring (undef, 1)}
		);
	}
	if ($tmp = $self->unix ()) {
		$rendered .= 
			"\tunix $tmp->[U_PATH] perm $tmp->[U_PERM] owner $tmp->[U_OWNER] group $tmp->[U_GROUP];\n"
	}
	$rendered .= "};";
	return ($self->_rstring (\$rendered));
}

1;
