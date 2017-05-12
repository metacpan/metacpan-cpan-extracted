# Bind8 key directive handling
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Key - Class for handling Bind8 configuration
directive `key'

=head1 SYNOPSIS

	use Unix::Conf::Bind8;

	my ($conf, $key, $ret);

	$conf = Unix::Conf::Bind8->new_conf (
		FILE        => '/etc/named.conf',
		SECURE_OPEN => 1,
	) or $conf->die ("couldn't open `named.conf'");

	# 
	# Ways to get a key object
	#

	$key = $conf->new_key (
		NAME		=> 'sample_key',
		ALGORITHM	=> 'hmac-md5',
		SECRET		=> '"abcdefgh"',
	) or $key->die ("couldn't create key");

	# OR

	$key = $conf->get_key ('extremix-slaves.key')
		or $key->die ("couldn't get key");

	#
	# Operations that can be performed on a Key object
	#

	$ret = $key->name ('some_other_key')
		or $ret->die ("couldn't set name");

	$ret = $key->secret ('"secret"')
		or $ret->die ("couldn't set secret");

	# get attributes
	printf ("KEY ID => %s, ALGORITHM => %s, SECRET => %s",
		$key->name (), $key->algorithm (), $key->secret ());

	# delete key
	$ret = $key->delete () or $ret->die ("couldn't delete");

	$ret = $conf->delete_key ('sample_key')
		or $ret->die ("couldn't delete");

=head1 METHODS

=cut

package Unix::Conf::Bind8::Conf::Key;


use strict;
use warnings;
use Unix::Conf;


use Unix::Conf::Bind8::Conf::Directive;
our (@ISA) = qw (Unix::Conf::Bind8::Conf::Directive);

use Unix::Conf::Bind8::Conf;

=over 4

=item new ()

 Arguments
 NAME		=> scalar,
 ALGORITHM	=> scalar,  # number
 SECRET		=> scalar,  # quoted string
 WHERE		=> 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG		=> Unix::Conf::Bind8::Conf::Directive subclass object
                        # WARG is to be provided only in case WHERE eq 'BEFORE 
                        # or WHERE eq 'AFTER'
 PARENT		=> reference,
                        # to the Conf object datastructure.

Class constructor
Creates a new Unix::Conf::Bind8::Conf::Key object and returns it, on success,
an Err object otherwise. Do not use this constructor directly. Use the 
Unix::Conf::Bind8::Conf::new_key () method instead.

=cut

sub new
{
	my $self = shift ();
	my $new = bless ({});
	my %args = @_;
	my $ret;

	$args{NAME}		|| return (Unix::Conf->_err ('new', "NAME not defined"));
	$args{ALGORITHM}|| return (Unix::Conf->_err ('new', "ALGORITHM not defined"));
	$args{SECRET}	|| return (Unix::Conf->_err ('new', "SECRET not defined"));
	$args{PARENT}	|| return (Unix::Conf->_err ('new', "PARENT not defined"));

	$ret = $new->_parent ($args{PARENT})	or return ($ret);
	$ret = $new->name ($args{NAME})				or return ($ret);
	$ret = $new->algorithm ($args{ALGORITHM})				
			or return ($ret);
	$ret = $new->secret ($args{SECRET})		or return ($ret);

	$args{WHERE} = 'LAST' unless ($args{WHERE});
	$ret = Unix::Conf::Bind8::Conf::_insert_in_list ($new, $args{WHERE}, $args{WARG})
		or return ($ret);
	return ($new);
}


=item name

 Arguments
 value

Object method.
Get/set the corresponding attribute. Returns the attribute value or true
on success, an Err object otherwise.

=cut

sub name
{
	my ($self, $name) = @_;

	if ($name) {
		my $ret;
		$ret = Unix::Conf::Bind8::Conf::_del_key ($self) or return ($ret)
			if ($self->{name});
		$self->{name} = $name;
		$ret = Unix::Conf::Bind8::Conf::_add_key ($self) or return ($ret);
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{name}) ? $self->{name} : 
			Unix::Conf->_err ('name', "name not defined for key")
	);
}

=item algorithm

 Arguments
 value

Object method.
Get/set the corresponding attribute. Returns the attribute value or true
on success, an Err object otherwise.

=cut

sub algorithm
{
	my ($self, $algo) = @_;

	if ($algo) {
		# validate later

		$self->{algo} = $algo;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{algo}) ? $self->{algo} :
			Unix::Conf->_err ('algorithm', "algorithm not defined for key")
	);
}

=item secret

 Arguments
 value

Object method.
Get/set the corresponding attribute. Returns the attribute value or true
on success, an Err object otherwise.

=cut

sub secret
{
	my ($self, $secret) = @_;

	if ($secret) {
		# strip quotes
		$secret =~ s/^"(.+)"$/$1/;
		$self->{secret} = $secret;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{secret}) ? $self->{secret} :
			Unix::Conf->_err ('secret', "secret not defined for key")
	);
}

sub __render
{
	my $self = $_[0];
	my $rendered;

	$rendered = sprintf (
		qq /key %s {\n\talgorithm %s;\n\tsecret "%s";\n};/, 
		$self->name (), $self->algorithm (), $self->secret (),
	);
	return ($self->_rstring (\$rendered));
}

1;
