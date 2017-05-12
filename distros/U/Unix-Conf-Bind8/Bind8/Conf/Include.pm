# Bind8 Include
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Include - Class for representing an 'include' 
statement in a Bind8 configuration file.

=head1 DESCRIPTION

Objects of this class contain a Unix::Conf::Bind8::Conf object 

=head1 SYNOPSIS

	use Unix::Conf::Bind8;

	my ($conf, $include, $conf1, $ret);

	$conf = Unix::Conf::Bind8->new_conf (
		FILE        => '/etc/named.conf',
		SECURE_OPEN => 1,
	) or $conf->die ("couldn't open `named.conf'");

	# 
	# Ways to get an include object
	#

	$include = $conf->new_include (
		FILE			=> 'slaves.conf',
		SECURE_OPEN		=> 0,
	) or $include->die ("couldn't create include object");

	# OR

	$include = $conf->get_include ('masters.conf')
		or $include->die ("couldn't get include object");

	#
	# Operations that can be performed on an Include object
	#
	
	# get embedded conf object.
	$conf1 = $include->get_conf () 	
		or $conf1->die ("couldn't get conf");

	# set embedded conf object
	$conf1 = Unix::Conf::Bind8->new_conf (
		FILE		=> '/etc/masters.conf',
		SECURE_OPEN	=> 0,
	) $conf1->die ("couldn't create `masters.conf'");

	$ret = $include->conf ($conf1)
		or $ret->die ("couldn't set conf");

	# delete include
	$ret = $include->delete ()
		or $ret->die ("couldn't delete");

	# OR

	$ret = $conf->delete_include ('slaves.conf')
		or $ret->die ("couldn't delete");

=head1 METHODS

=cut

package Unix::Conf::Bind8::Conf::Include;

use strict;
use warnings;
use Unix::Conf;

use Unix::Conf::Bind8::Conf::Directive;
our @ISA = qw (Unix::Conf::Bind8::Conf::Directive);

use Unix::Conf::Bind8::Conf;
use Unix::Conf::Bind8::Conf::Lib;

=over 4

=item new ()

 Arguments
 FILE         => 'path of the configuration file',
 SECURE_OPEN  => 0/1,   # default 1 (enabled)
 WHERE  => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG   => Unix::Conf::Bind8::Conf::Directive subclass object
                        # WARG is to be provided only in case WHERE eq 'BEFORE 
                        # or WHERE eq 'AFTER'
 PARENT	=> reference,   # to the Conf object datastructure.

Class constructor.
Creates a Unix::Conf::Bind8::Conf::Include object, with an embedded 
Unix::Conf::Bind8::Conf object, and returns it, on success, an Err 
object otherwise. Do not use this constructor directly. Use the 
Unix::Conf::Bind8::Conf::new_include () method instead. 

=cut

sub new 
{
	my $self = shift ();
	my %args = @_;
	my ($new, $ret, $new_conf);
	$new = bless ({});

	$args{PARENT} || return (Unix::Conf->_err ('new', "PARENT not specified"));
	$ret = $new->_parent ($args{PARENT}) or return ($ret);
	# Just make sure we were passed ROOT. It will however be set in the
	# Unix::Conf::Bind8::Conf->new () constructor
	$args{ROOT} || return (Unix::Conf->_err ('new', "ROOT not specified"));
	$new_conf = Unix::Conf::Bind8::Conf->new ( %args ) or return ($new_conf);
	$ret = $new->conf ($new_conf) or return ($ret);
	$ret = Unix::Conf::Bind8::Conf::_add_include ($new) or return ($ret);
	$args{WHERE} = 'LAST' unless ($args{WHERE});
	$ret = Unix::Conf::Bind8::Conf::_insert_in_list ($new, $args{WHERE}, $args{WARG})
		or return ($ret);
	return ($new);
}

=item name ()

Returns the name of the include file.

=cut

sub name 
{ 
	return (sprintf ("%s", $_[0]->conf ()->fh ())); 
}

=item conf ()

 Arguments
 Unix::Conf::Bind8::Conf object,     # optional

Get/Set the embedded Unix::Conf::Bind8::Conf. If an argument is passed, the
method tries to set the embedded object to the argument, and returns true
if successful, an Err object otherwise. If the argument is not passed, returns
the contained Unix::Conf::Bind8::Conf object.

=cut

sub conf
{
	my ($self, $conf) = @_;

	if ($conf) {
		return (Unix::Conf->_err ('conf', "argument should be object of type Unix::Conf::Bind8::Conf"))
			unless (UNIVERSAL::isa ($conf, 'Unix::Conf::Bind8::Conf'));
		$self->{conf} = $conf;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{conf}) ? $self->{conf} : Unix::Conf->_err ('conf', "conf not defined")
	);
}

sub __root
{
	my ($self, $root) = @_;

	if ($root) {
		$self->{ROOT} = $root;
		return (1);
	}
	return (
		defined ($self->{ROOT}) ? $self->{ROOT} :
			Unix::Conf->_err ('__root', "ROOT not defined")
	);
}

sub __render
{
	my $self = $_[0];

	my $rendered = sprintf (qq (include "%s";), $self->conf ()->fh ());
	return ($self->_rstring (\$rendered));
}

1;
__END__
