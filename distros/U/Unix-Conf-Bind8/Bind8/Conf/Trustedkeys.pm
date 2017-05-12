# Bind8 trusted-keys handling
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Trustedkeys - Class for handling Bind8 configuration
directive `trustedkeys'.

=head1 SYNOPSIS

    use Unix::Conf::Bind8;

    my ($conf, $tk, $ret);
    $conf = Unix::Conf::Bind8->new_conf (
        FILE        => '/etc/named.conf',
        SECURE_OPEN => 1,
    ) or $conf->die ("couldn't open `named.conf'");

    #
    # Ways to get a Trustedkeys object.
    #

    $tk = $conf->new_trustedkeys (
        KEYS => [
            [ 'extremix.net', 257 255 3 '"AQP2fHpZ4VMpKo/j"' ],
            [ '.', 257 255 1 '"TjKef0x54VpKod~"' ],
    ) or $tk->die ("couldn't create trustedkeys");

    $tk = $conf->get_trustedkeys ()
        or $tk->die ("couldn't get trustedkeys");

    #
    # Operations that can be performed with a trustedkeys object
    #

    # set trustedkey for `yahoo.com'
    $ret = $tk->key ('yahoo.com', 257, 255, 3, '"aRlOs7dOc/a"')
        or $ret->die ("couldn't set trustedkeys for `yahoo.com'");

    $ret = $tk->key ('extremix.net')
        or $ret->die ("couldn't get trustedkeys for `extremix.net'");

    # traverse all defined keys
    for my $domain ($tk->domains ()) {
        for my $alg ($tk->algorithms ()) {
            $ret = $tk->key ($domain, $alg);
            print ("@$ret\n"); 
        }
    }

	# another way
	my @keys = $tk->trustedkeys ();
	print "@$_\n" for (@keys);

    # delete a specific key. 
	# Note that if 3 is the only algorithm defined for `extremix.net', the
	# domain itself will be deleted from the internal structure. If the domain
	# `extremix.net' is the only one defined, the invocant object itself if
	# deleted.
    $ret = $tk->delete_key ('extremix.net', 3)
        or $ret->die ("couldn't delete key for `extremix.net', 3");

=head1 METHODS

=cut

package Unix::Conf::Bind8::Conf::Trustedkeys;

use strict;
use warnings;
use Unix::Conf;

use Unix::Conf::Bind8::Conf::Directive;
our (@ISA) = qw (Unix::Conf::Bind8::Conf::Directive);

use Unix::Conf::Bind8::Conf::Lib;


#
# This is from DNS & Bind (4th edition) by Paul Albitz and Cricket Liu
# 
# Arguments needed for a trusted key record are
#
# domain name     flags     protocol     algorithm     key
#
# Format of the flags field 
# -------------------------
#
#	  0   1   2   3   4   5   6   7   8   9   0   1   2   3   4   5
#	+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
#	|  A/C  | Z | XT| Z | Z | NAMTYP| Z | Z | Z | Z |      SIG      |
#	+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
#  
# If the value of the first bit is zero, the key can be used for authentication.
# This bit is always zero.
#
# If the value of the second bit is zero, the key can be used for confidentiality. 
# This bit is always zero for a zones public key. 
#
# The third bit is reserved for future use. For now, its value must be zero. 
#
# The fourth bit is a "flag extenstion" bit. It is designed to provide future 
# expandability. For now the value must always be zero.
#
# The fifth and sixth bits are reserved and must be zero. 
#
# The seventh and eighth bits encode the type of key:
#
# 00
#	The is the user's key. A mail user agent might use a user's key to encrypt 
#	email addressed to that user. This type of key isn't use in DNSSEC.
# 01
#	This is a zone's public key. All DNSSEC key are this type of key.
# 10
#	This is a host's key. An IPSEC implementation might use a host's key to 
#	encprypt all IP packets sent to that host. DNSSEC keys are this type of key.
# 11
#   Reserved for future use.
#
# The ninth through twelfth bits are reserved and must be zero. The last four bits 
# the signatory field, which is now obsolete.
#
# Format of the protocol field
# ----------------------------
#
# 0	Reserved
#
# 1	This key is used with Transport Layer Security (TLS), as described in RFC 2246.
#
# 2 This key is used in connection with email, e.g., an S/MIME key.
#
# 3 This key is used with DNSSEC. All DNSSEC keys, will have a protocol octet of 3.
#
# 4	This key is used with IPSEC
#
# 255
#	This key is used with any protocol that can use a KEY record.
#
# All the values between 4 and 255 are unavailable for future assignment.
#
# Format of the algorithm field
# -----------------------------
#
# 0	Reserved
#
# 1	RSA/MD5.
#
# 2	Diffe-Hellman.
#
# 3	DSA.
#
# 4. Reserved for an elliptic curve-based public key algorithm.
#
#
# The final field is the public key itself, encoded in base 64.
#

#
# This is how the data is stored
# {
#	domain	=> 
#					{ 
#						algorithm	=> 
#										[
#											DOMAIN
#											FLAGS
#											PROTOCOL
#											ALGORITHM
#											KEY
#										],
#					},
# }
#

# Index into the array passed as argument
use constant	DOMAIN		=> 0;
use constant	FLAGS		=> 1;
use constant	PROTOCOL	=> 2;
use constant	ALGORITHM	=> 3;
use constant	KEY			=> 4;

# Forward declarations
sub __valid_protocol ($);
sub __valid_algorithm ($);

=over 4

=item new ()

 Arguments
 KEYS	=> [ domain flags protocol algorithm key ]
 or
 KEYS	=> [ [ domain flags protocol algorithm key ], [..] ]
 WHERE  => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG   => Unix::Conf::Bind8::Conf::Directive subclass object
                        # WARG is to be provided only in case WHERE eq 'BEFORE 
                        # or WHERE eq 'AFTER'
 PARENT	=> reference,   # to the Conf object datastructure.

Class constructor.
Creates a new Unix::Conf::Bind8::Conf::Trustedkeys object and returns it,
on success, an Err object otherwise. Do not use this constructor directly.
Use the Unix::Conf::Bind8::Conf::new_trustedkeys () method instead.

=cut

sub new
{
	shift ();
	my %args = @_;
	my $new = bless ({});
	my ($parent, $keys, $ret);

	$args{PARENT}	||	return (Unix::Conf->_err ('new', "PARENT not defined"));
	$ret = $new->_parent ($args{PARENT}) or return ($ret);

	if ($args{KEYS}) {
		if (ref ($args{KEYS}[0]) && UNIVERSAL::isa ($args{KEYS}[0], 'ARRAY')) {
			$keys = $args{KEYS}
		}
		else {
			$keys = [ @{$args{KEYS}} ];
		}
		$ret = $new->key (@{$_}) or return ($ret)
			for (@$keys);
	}

	$ret = Unix::Conf::Bind8::Conf::_add_trustedkeys ($new)
		or return ($ret);
	$args{WHERE} = 'LAST'	unless ($args{WHERE});
	$ret = Unix::Conf::Bind8::Conf::_insert_in_list ($new, $args{WHERE}, $args{WARG})
		or return ($ret);
	return ($new);
}

=item key ()

 Arguments
 DOMAIN
 FLAGS
 PROTOCOL
 ALGORITHM
 KEY

 or

 DOMAIN
 ALGORITHM

Object method.
In the first form, sets the key for domain `DOMAIN' and protocol 
`PROTOCOL' and returns true, on success, an Err object otherwise. 
In the second form, returns (DOMAIN, FLAGS, PROTOCOL, ALGORITHM, KEY)
for the passed domain, algorithm, if defined, an Err object otherwise.

=cut

sub key
{
	my $self = shift ();
	my ($domain, $algorithm, $args);

	if (@_ == 5) { # set
		$args =  [ @_ ];
		__valid_string ($args->[DOMAIN]);
		return (Unix::Conf->_err ('key', "illegal protocol value `$args->[PROTOCOL]'"))
			unless (__valid_protocol ($args->[PROTOCOL]));
		return (Unix::Conf->_err ('key', "illegal algorithm value `$args->[ALGORITHM]'"))
			unless (__valid_algorithm ($args->[ALGORITHM]));
		$args->[KEY] = qq("$args->[KEY]") if ($args->[KEY] =~ /^[^"]/);
		$self->{keys}{$args->[DOMAIN]}{$args->[ALGORITHM]} = $args;
		$self->dirty (1);
		return (1);
	}
	elsif (@_ == 2) { # get
		($domain, $algorithm) = @_;
		__valid_string ($domain);
		return (Unix::Conf->_err ('key', "illegal algorithm value `$algorithm'"))
			unless (__valid_algorithm ($algorithm));
		return (Unix::Conf->_err ('key', "no keys for domain `$domain'"))
			unless ($self->{keys}{$domain} || keys (%{$self->{keys}{$domain}}));
		return (
			Unix::Conf->_err (
				'key', 
				"no key with algorithm `$algorithm' defined for domain `$domain'"
			)
		) unless ($self->{keys}{$domain}{$algorithm} || keys (%{$self->{keys}{$domain}}));
		return ( [ @{$self->{keys}{$domain}{$algorithm}} ] );
	}
	else {
		return (Unix::Conf->_err ('key', scalar (@_)." - unexpected number of arguments"));
	}
}

=item add_key ()

 Arguments
 DOMAIN
 FLAGS
 PROTOCOL
 ALGORITHM
 KEY

Object method.
Adds KEY for domain `DOMAIN' and algorithm `ALGORITHM' and returns
true, on success, an Err object otherwise.

=cut

sub add_key
{
	my $self = shift ();

	return (Unix::Conf->_err ('add_key', "expected number of arguments 5"))
		unless (@_ == 5);
	my $args =  [ @_ ];
	__valid_string ($args->[DOMAIN]);
	return (Unix::Conf->_err ('add_key', "illegal protocol value `$args->[PROTOCOL]'"))
		unless (__valid_protocol ($args->[PROTOCOL]));
	return (Unix::Conf->_err ('add_key', "illegal algorithm value `$args->[ALGORITHM]'"))
		unless (__valid_algorithm ($args->[ALGORITHM]));
	return (
		Unix::Conf->_err (
			'add_key', 
			"key for domain `$args->[DOMAIN]' and algorithm `$args->[ALGORITHM]' already defined"
		)
	) if ($self->{keys}{$args->[DOMAIN]}{$args->[ALGORITHM]});
	$args->[KEY] = qq("$args->[KEY]") if ($args->[KEY] =~ /^[^"]/);
	$self->{keys}{$args->[DOMAIN]}{$args->[ALGORITHM]} = $args;
	$self->dirty (1);
	return (1);
}

=item delete_key ()

 Arguments
 DOMAIN
 ALGORITHM	# optional

Object method.
Deletes the KEY for domain `DOMAIN', algorithm `ALGORITHM'. If
ALGORITHM is not passed deletes all key for domain `DOMAIN', if
defined. If all domains defined are deleted, the object itself is 
deleted Returns true, an Err object otherwise.

=cut

sub delete_key
{
	my ($self, $domain, $algorithm) = @_;

	__valid_string ($domain);
	return (Unix::Conf->_err ('delete_key', "domain`$domain' not defined"))
		unless ($self->{keys}{$domain});

	if (defined ($algorithm)) {
		return (Unix::Conf->_err ('delete_key', "illegal algorithm value `$algorithm'"))
			unless (__valid_protocol ($algorithm));
		return (
			Unix::Conf->_err (
				'delete_key', 
				"no key with algorithm `$algorithm' defined for domain `$domain'"
			)
		) unless ($self->{keys}{$domain}{$algorithm});
		delete ($self->{keys}{$domain}{$algorithm});
		goto DELKEY_RET if (keys (%{$self->{keys}{$domain}}));
	}
	delete ($self->{keys}{$domain});
	$self->delete () unless (keys (%{$self->{keys}}));

DELKEY_RET:
	$self->dirty (1);
	return (1);
}

=item trustedkeys ()

Object method.
Returns defined keys. When called in list context, returns all defined
directives. Iterates over defined keys, when called in scalar context.
Returns `undef' at the end of one iteration, and starts over if called
again.

=cut

{
	my @keys;
	my $itr = 0;
	sub trustedkeys
	{
		my $self = $_[0];
		
		# create a list of keys only if the iterator is at the start
		unless ($itr) {
			undef (@keys);
			for my $dom (keys (%{$self->{keys}})) {
				for my $alg (keys (%{$self->{keys}{$dom}})) {
					push (@keys, [ @{$self->{keys}{$dom}{$alg}} ]);
				}
			}
		}
		if (wantarray ()) {
			# reset iterator before returning
			$itr = 0;
			return (@keys);
		}
		# return undef on completion of one iteration
		return () if ($itr && !($itr %= scalar (@keys)));
		return ($keys[$itr++]);
	}
}

=item domains ()

Object method.
Iterates through all defined domains. Returns them one at a time
in scalar context, or all of them in list context.

=cut

sub domains 
{
	my $self = $_[0];

	return (
		wantarray () ? keys (%{$self->{keys}}) : (each (%{$self->{keys}}))[0]
	);
}

=item algorithms ()

 Arguments
 DOMAIN

Object method.
Iterates through all defined algorithms defined for domain `DOMAIN'. Returns
them one at a time in scalar context, or all of them in list context.

=cut

sub algorithms
{
	my ($self, $domain) = @_;

	return (Unix::Conf->_err ("domain not passed")) unless (defined ($domain));
	return (
		wantarray () ? keys (%{$self->{keys}{$domain}}) : (each (%{$self->{keys}{$domain}}))[0]
	)
}

sub __render
{
	my $self = $_[0];
	my ($rendered, $rec);

	$rendered .= "trusted-keys {\n";
	for my $domain ($self->domains ()) {
		for my $algo ($self->algorithms ($domain)) {
			$rec = $self->key ($domain, $algo)
				or return ($rec);
			$rendered .= "\t@$rec;\n";
		}
	}
	$rendered .= "};";
	return ($self->_rstring (\$rendered));
}

sub __valid_protocol ($)
{
	return (1) if (($_[0] >= 0 && $_[0] <= 4) || $_[0] == 255);
	return ();
}

sub __valid_algorithm ($)
{
	return (1) if ($_[0] >= 0 && $_[0] <= 4);
	return ();
}

1;
