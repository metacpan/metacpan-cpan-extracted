# Bind8 server handling
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Server - Class for handling Bind8 configuration
directive `server'

=head1 SYNOPSIS

    use Unix::Conf::Bind8;

    my ($conf, $server, $ret);

    $conf = Unix::Conf::Bind8->new_conf (
        FILE        => '/etc/named.conf',
        SECURE_OPEN => 1,
    ) or $conf->die ("couldn't open `named.conf'");

    #
    # Ways to get a server object.
    #

    $server = $conf->new_server (
        NAME	=> '192.168.1.1',
        BOGUS	=> 'yes',
    ) or $server->die ("couldn't create server `192.168.1.1'");

    # OR

    $server = $conf->get_server ('10.0.0.1')
        or $server->die ("couldn't get server `10.0.0.1'");

    # 
    # Operations that can be performed on a server object.	
    # 

    $ret = $server->bogus ('no') 
        or $ret->die ("couldn't set attribute");

    $ret = $server->keys (qw (extremix-slaves.key sample_key));
	
    # get attributes
    $ret = $server->keys ()
        or $ret->die ("couldn't get keys");
    local $" = "\n";
    printf "Keys defined:\n@$ret\n";

    # delete attribute
    $ret = $server->delete_transfer_format ()
        or $ret->die ("couldn't delete attribute");

=head1 METHODS

=cut


package Unix::Conf::Bind8::Conf::Server;

use strict;
use warnings;
use Unix::Conf;
use Unix::Conf::Bind8::Conf::Directive;
our (@ISA) = qw (Unix::Conf::Bind8::Conf::Directive);
use Unix::Conf::Bind8::Conf::Lib;

my %ServerDirectives = (
	'bogus'					=> \&__valid_yesno,
	# the man page doesn't mention this, but the
	# sample conf file has it
	'support-ixfr'			=> \&__valid_yesno,
	'transfers'				=> \&__valid_number,
	'transfer-format'		=> \&__valid_transfer_format,

	'keys'					=> 0,
);

=over 4

=item new ()

 Arguments
 NAME			=> scalar,
 BOGUS			=> scalar,	# Optional
 TRANSFERS		=> scalar,	# Optional
 SUPPORT-IXFR	=> scalar,
 TRANSFER-FORMAT
 				=> scalar,	# Optional
 KEYS			=> [elements ],	# Optional
 WHERE  		=> 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG   => Unix::Conf::Bind8::Conf::Directive subclass object
                        # WARG is to be provided only in case WHERE eq 'BEFORE 
                        # or WHERE eq 'AFTER'
 PARENT			=> reference,
                        # to the Conf object datastructure.

Class constructor.
Creates a new Unix::Conf::Bind8::Conf::Server object, and returns it,
on success, an Err object otherwise. Do not call this constructor 
directly. Use Unix::Conf::Bind8::Conf::new_server () instead. 

=cut

sub new
{
	shift ();
	my $new = bless ({});
	my %args = @_;
	my $ret;

	$args{PARENT}	|| return (Unix::Conf->_err ('new', "PARENT not defined"));
	$args{NAME}		|| return (Unix::Conf->_err ('new', "NAME not defined"));

	$ret = $new->_parent ($args{PARENT})	or return ($ret);
	$ret = $new->name ($args{NAME})		or return ($ret);
	my $where = $args{WHERE} ? $args{WHERE} : 'LAST';
	my $warg  = $args{WARG};
	delete (@args{'PARENT','NAME','WHERE','WARG'});

	for (keys (%args)) {
		my $meth = $_;
		$meth =~ tr/A-Z/a-z/;
		return (Unix::Conf->_err ("new", "attribute `$meth' not supported"))
			unless (defined ($ServerDirectives{$meth}));
		$meth =~ tr/-/_/;
		$ret = $new->$meth ($args{$_}) or return ($ret);
	}

	$ret = Unix::Conf::Bind8::Conf::_insert_in_list ($new, $where, $warg)
		or return ($ret);

	return ($new);
}


=item name ()

 Arguments
 value		# optional

Object method.
Get/set the name attribute in the invocant. Returns the attribute value
or true on success, an Err object otherwise.

=cut

sub name
{
	my ($self, $name) = @_;

	if ($name) {
		my $ret;
		return (Unix::Conf->_err ('name', "illegal name `$name'"))
			unless (__valid_ipaddress ($name));
		$self->{name} = $name;
		$ret = Unix::Conf::Bind8::Conf::_add_server ($self) 
			or return ($ret);
		$ret = $self->dirty (1);
		return (1);
	}
	return (
		defined ($self->{name}) ? $self->{name} :
			Unix::Conf->_err ('name', "name not defined for server")
	);
}

=item bogus ()

 Arguments
 value		# optional

Object method.
Get/set the name attribute in the invocant. Returns the attribute value
or true on success, an Err object otherwise.

=cut

=item delete_bogus ()

Object method.
Deletes the corresponding attribute, if defined, and returns true,
an Err object otherwise.

=cut

=item support_ixfr ()

 Arguments
 value		# optional

Object method.
Get/set the name attribute in the invocant. Returns the attribute value
or true on success, an Err object otherwise.

=cut

=item delete_support_ixfr ()

Object method.
Deletes the corresponding attribute, if defined, and returns true,
an Err object otherwise.

=cut

=item transfers ()

 Arguments
 value	# number, optional

Object method.
Get/set the name attribute in the invocant. Returns the attribute value
or true on success, an Err object otherwise.

=cut

=item delete_transfers ()

Object method.
Deletes the corresponding attribute, if defined, and returns true,
an Err object otherwise.

=cut

=item transfer_format ()

 Arguments
 value	# 'one-answer'|'many-answers', optional

Object method.
Get/set the name attribute in the invocant. Returns the attribute value
or true on success, an Err object otherwise.

=cut

=item delete_transfer_format ()

Object method.
Deletes the corresponding attribute, if defined, and returns true,
an Err object otherwise.

=cut

for my $dir (keys (%ServerDirectives)) {
	no strict 'refs';
	
	my $meth = $dir;
	$meth =~ tr/-/_/;

	($ServerDirectives{$dir} =~ /^CODE/)	&& do {
		*$meth = sub {
			my ($self, $arg) = @_;

			if (defined ($arg)) {
				return (Unix::Conf->_err ("$meth", "invalid argument `$arg'"))
					unless (&{$ServerDirectives{$dir}}($arg));
				$self->{$dir} = $arg;
				$self->dirty (1);
				return (1);
			}
			return (
				defined ($self->{$dir}) ? $self->{$dir} :
					Unix::Conf->_err ("$dir", "`$dir' not defined")
			);
		};
	};
	*{"delete_$meth"} = sub {
		my $self = $_[0];

		return (Unix::Conf->_err ("delete_$meth", "`$dir' not defined"))
			unless (defined ($self->{$dir}));
		delete ($self->{$dir});
		$self->dirty (1);
		return (1);
	};
}

=item keys ()

 Arguments
 LIST	# name, optional
 or
 [ LIST ]

Object method.
Get/set the name attribute in the invocant. Returns the attribute value
or true on success, an Err object otherwise.

=cut

=item delete_keys ()

Object method.
Deletes the corresponding attribute, if defined, and returns true,
an Err object otherwise.

=cut

sub keys
{
	my $self = shift ();

	if (@_) {
		my $args;
		if (ref ($_[0])) {
			return (Unix::Conf->_err ('keys', "expected argument LIST or [ LIST ]"))
				unless (UNIVERSAL::isa ($_[0], 'ARRAY'));
			$args = $_[0];
		}
		else {
			# assume a list
			$args = \@_;
		}

		for (@$args) {
			return (Unix::Conf->_err ('keys', "`$_' not a valid key"))
				unless (Unix::Conf::Bind8::Conf::_get_key ($self->_parent (), $_));
		}
		@{$self->{keys}}{@$args} = (1) x @$args;
		$self->dirty (1);
		return (1);
	}
	return (Unix::Conf->_err ('keys', "keys not defined"))
		unless ($self->{keys});
	return ([ keys (%{$self->{keys}}) ]);
}

# no add_to_keys, delete_from_keys as there are not likely to be
# many keys in for one server.

sub __render
{
	my $self = $_[0];
	my ($rendered, $tmp);

	$tmp = $self->name (); 
	$rendered = "server $tmp {\n";
	$rendered .= "\tbogus $tmp;\n"
		if ($tmp = $self->bogus ());
	$rendered .= "\tsupport-ixfr $tmp;\n"
		if ($tmp = $self->support_ixfr ());
	$rendered .= "\ttransfers $tmp;\n"
		if ($tmp = $self->transfers ());
	$rendered .= "\ttransfer-format $tmp;\n"
		if ($tmp = $self->transfer_format ());
	$rendered .= "\tkeys { @$tmp };\n"
		if ($tmp = $self->keys ());
	$rendered .= "};";
	return ($self->_rstring (\$rendered));
}

1;
