# Bind8 SOA record handling
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

package Unix::Conf::Bind8::DB::SOA;

use strict;
use warnings;

use Unix::Conf;
use Unix::Conf::Bind8::DB;
use Unix::Conf::Bind8::DB::Lib;
use Unix::Conf::Bind8::DB::Record;

our @ISA = qw (Unix::Conf::Bind8::DB::Record);

=item new ()

 Arguments
 LABEL		=> 'string',
 CLASS		=> 'string',	# 'IN'|'HS'|'CHAOS'
 TTL		=> 'string'|number,
 AUTH_NS	=> 'nameserver',
 MAIL_ADDR	=> 'rp',
 SERIAL		=> zone_serial_no	# number
 REFRESH	=> refresh,
 RETRY		=> retry,
 EXPIRE		=> expire,
 MIN_TTL	=> min_ttl,
 PARENT		=> reference,	# to the DB object datastructure

Class constructor.
Creates a new Unix::Conf::Bind8::DB::* object and returns it
if successful, an Err object otherwise. Do not use this constructor
directly. Use the Unix::Conf::Bind8::DB::new_* equivalent instead.

=cut

# class constructor.
# Arguments: hash
#	PARENT	=>
#   CLASS   =>
#   TTL     =>
#   AUTH_NS =>
#   MAIL_ADDR   =>
#   SERIAL  =>
#   REFRESH =>
#   RETRY   =>
#   EXPIRE  =>
#   MIN_TTL =>
#
sub new 
{
	my $class = shift ();
	my %args = @_;
	my $new = bless ({}, $class);
	my $ret;

	return (Unix::Conf->_errr ('new', "`PARENT' not specified"))
		unless (defined ($args{PARENT}));
	$ret = $new->_parent ($args{PARENT}) or return ($ret);
	# check all arguments in the loop and call appropriate methods to set them
	for my $key qw (AUTH_NS MAIL_ADDR SERIAL REFRESH RETRY EXPIRE MIN_TTL RTYPE) {
		return (Unix::Conf->_err ('new', "`$key' not specified"))
			unless (defined ($args{$key}));
		my $meth = lc ($key);
		$ret = $new->$meth ($args{$key}) or return ($ret);
	}
	return ($new);
}

=item auth_ns ()

 Arguments
 'auth_ns'

Object method.
Get/set the record's auth_ns. If an argument is passed, the invocant's
auth_ns is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's auth_ns is returned.

=cut

sub auth_ns
{
	my ($self, $auth_ns) = @_;

	if (defined ($auth_ns)) {
		$self->{AUTH_NS} = $auth_ns;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{AUTH_NS}) ? $self->{AUTH_NS} :
			Unix::Conf->_err ('auth_ns', "AUTH_NS not defined")
	);
}

=item mail_addr ()

 Arguments
 'mail_addr'

Object method.
Get/set the record's mail_addr. If an argument is passed, the invocant's
mail_addr is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's mail_addr is returned.

=cut

sub mail_addr
{
	my ($self, $mail_addr) = @_;

	if (defined ($mail_addr)) {
		$self->{MAIL_ADDR} = $mail_addr;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{MAIL_ADDR}) ? $self->{MAIL_ADDR} :
			Unix::Conf->_err ('mail_addr', "MAIL_ADDR not defined")
	);
}

=item serial ()

 Arguments
 'serial'

Object method.
Get/set the record's serial. If an argument is passed, the invocant's
serial is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's serial is returned.

=cut

sub serial
{
	my ($self, $serial) = @_;

	if (defined ($serial)) {
		return (Unix::Conf->_err ('serial', "illegal SERIAL value `$serial'"))
			unless ($serial =~ /^\d+$/);
		$self->{SERIAL} = $serial;
		$self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{SERIAL}) ? $self->{SERIAL} :
			Unix::Conf->_err ('mail_addr', "SERIAL not defined")
	);
}

=item refresh ()

 Arguments
 'refresh'

Object method.
Get/set the record's refresh. If an argument is passed, the invocant's
refresh is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's refresh is returned.

=cut

=item retry ()

 Arguments
 'retry'

Object method.
Get/set the record's retry. If an argument is passed, the invocant's
retry is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's retry is returned.

=cut

=item expire ()

 Arguments
 'expire'

Object method.
Get/set the record's expire. If an argument is passed, the invocant's
expire is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's expire is returned.

=cut

=item min_ttl ()

 Arguments
 'min_ttl'

Object method.
Get/set the record's min_ttl. If an argument is passed, the invocant's
min_ttl is set and true returned, on success, an Err object otherwise.
If no argument is passed the invocant's min_ttl is returned.

=cut

for my $meth qw (refresh retry expire min_ttl) {
	no strict 'refs';

	*$meth = sub {
		my ($self, $arg) = @_;
		my $key = uc ($meth);
		if (defined ($arg)) {
			return (Unix::Conf->_err ("$meth", "illegal $key value `$arg'"))
				unless (__is_validttl ($arg));
			$self->{$key} = $arg;
			$self->dirty (1);
			return (1);
		}
		return (
			defined ($self->{$key}) ? $self->{$key} :
				Unix::Conf->_err ("$meth", "`$key' not defined")
		)
	};
}

1;
