# Bind8 Conf class.
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf - Front end for a suite of classes for manipulating
a Bind8 style configuration file. 

=head1 SYNOPSIS

    my ($conf, $obj, $ret);

    $conf = Unix::Conf::Bind8->new_conf (
        FILE		=> 'named.conf',
        SECURE_OPEN	=> '/etc/named.conf',
    ) or $conf->die ("couldn't create `named.conf'");

    #
    # All directives have corrresponding new_*, get_*, delete_*
    # methods
    #

    $obj = $conf->new_zone (
        NAME	=> 'extremix.net',
        TYPE	=> 'master',
        FILE	=> 'db.extremix.net',
    ) or $obj->die ("couldn't create zone `extremix.net'");

    # For objects that have a name attribute, name is to
    # be specified, otherwise no arguments are needed.
    $obj = $conf->get_zone ('extremix.net')
        or $obj->die ("couldn't get zone `extremix.net'");

    $obj = $conf->get_options ()
        or $obj->die ("couldn't get options");

    # For objects that have a name attribute, name is to
    # be specified, otherwise no arguments are needed.
    $obj = $conf->delete_zone ('extremix.net')
        or $obj->die ("couldn't delete zone `extremix.net'");

    $obj = $conf->delete_options ()
        or $obj->die ("couldn't get options");

    # directives that have a name attribute, have iterator
    # methods
    printf ("Zones defined in %s:\n", $conf->fh ());
    for my $zone ($conf->zones ()) {
        printf ("%s\n", $zone->name ();
    }

    printf ("Directives defined in %s:\n", $conf->fh ());
    for my $dir ($conf->directives ()) {
        print ("$dir\n");
    }

    $db = $conf->get_db ('extremix.net')
        or $db->die ("couldn't get db for `extremix.net'");

=head1 DESCRIPTION

This class has interfaces for the various class methods of the classes that 
reside beneath Unix::Conf::Bind8::Conf. This class is an internal class and 
should not be accessed directly. Methods in this class can be accessed 
through a Unix::Conf::Bind8::Conf object which is returned by 
Unix::Conf::Bind8->new_conf ().

=head1 METHODS

=cut

package Unix::Conf::Bind8::Conf;

use strict;
use warnings;

use Unix::Conf;
use Unix::Conf::Bind8::Conf::Comment;
use Unix::Conf::Bind8::Conf::Lib;
use Unix::Conf::Bind8::Conf::Logging;
use Unix::Conf::Bind8::Conf::Options;
use Unix::Conf::Bind8::Conf::Acl;
use Unix::Conf::Bind8::Conf::Zone;
use Unix::Conf::Bind8::Conf::Trustedkeys;
use Unix::Conf::Bind8::Conf::Key;
use Unix::Conf::Bind8::Conf::Controls;
use Unix::Conf::Bind8::Conf::Server;
use Unix::Conf::Bind8::Conf::Include;
use Unix::Conf::Bind8::Conf::Lib;

#
# Unix::Conf::Bind8::Conf object
# The object is a reference to reference to an anonymous hash.
# The anonymous hash is referred to here as CONFDS for conf datastructure.
# => {
#	ROOT => CONFDS of the first Conf object in the tree.
#	FH
#	HEAD
#	TAIL
#	LOGGING
#	OPTION
#	ACL
#	ZONE
#	INCLUDE
#	ALL_LOGGING		defined only in a ROOT node
#	ALL_OPTION		defined only in a ROOT node
#	ALL_ACL			defined only in a ROOT node
#	ALL_ZONE		defined only in a ROOT node
#	ALL_INCLUDE		defined only in a ROOT node
#	ERRORS
#	DIRTY
# }
#

=over 4

=item new ()

 Arguments
 FILE         => 'path of the configuration file',
 SECURE_OPEN  => 0/1,       # default 1 (enabled)

Class constructor.
Creates a new Unix::Conf::Bind8::Conf object. The constructor parses the 
Bind8 file specified by FILE and contains subobjects representing various 
directives like options, logging, zone, acl etc. Direct use of this 
constructor is deprecated. Use Unix::Conf::Bind8->new_conf () instead.
Returns a Unix::Conf::Bind8::Conf object on success, or an Err object on 
failure.

=cut

sub new
{
	my $invocant = shift ();
	my %args =  @_;
	my ($new, $conf_fh, $ret);

	# get and validate arguments
	my $conf_path = $args{FILE} || return (Unix::Conf->_err ('new', "FILE not specified"));
	my $secure_open = defined ($args{SECURE_OPEN}) ? $args{SECURE_OPEN} : 1;
	$conf_fh = Unix::Conf->_open_conf (
		NAME 		=> $conf_path,
		SECURE_OPEN => $secure_open,
	) or return ($conf_fh);

	my $head =  { PREV => undef }; 
	my $tail =  { NEXT => undef }; 
	$head->{NEXT} = $tail;
	$tail->{PREV} = $head;

	$new = bless (
		\{
			DIRTY	=> 0, 
			ITR		=> 0,
			DIRARR	=> [],
			HEAD	=> $head,
			TAIL	=> $tail,
			ERRORS	=> [],
		},
	);
	$$new->{FH} = $conf_fh;
	# in case no ROOT was passed then we were not called from 
	# Unix::Conf::Bind8::Conf::Include->new (). So set ourself
	# as ROOT.
	# NOTE: we set the hashref to which the object (a scalar ref)
	# points to as the value for ROOT, to solve the circular ref problem
	$ret = $new->__root ($args{ROOT} ? $args{ROOT} : $$new) or return ($ret);
	eval { $ret = $new->__parse_conf () } or do {
		return ($@) if (ref ($@) && UNIVERSAL::isa ($@, 'Unix::Conf::Err'));
		# if a run time perl error has been trapped, make it into an Err obj.
		return (
			Unix::Conf->_err ('new', "Parse of $conf_fh failed because\n$@")
		);
	};
	return ($new);
}

# Class destructor.
sub DESTROY
{
	my $self = $_[0];
	my $dirty = $self->dirty ();
	#print sprintf ("destructor for conf object (%s:%x)\n", $self->fh (), $self);
	my $file;

	# make sure we destroy DIRARR (used for iteration first)
	undef ($$self->{DIRARR});

	# go through the array of directives and create a string representing
	# the whole file.
	my ($ptr, $tmp, $tws);
	$ptr = $$self->{HEAD}{NEXT};
	$$self->{HEAD}{NEXT} = undef;
	while ($ptr && $ptr ne $$self->{TAIL}) {
		if ($dirty) {
			$file .= ${$ptr->_rstring ()};
			$tws = $ptr->_tws ();
			$file .= defined ($tws) ? $$tws : "\n";
		}
		$tmp = $ptr;
		$ptr = $ptr->{NEXT};
		# remove circular references
		$tmp->{NEXT} = undef;
		$tmp->{PREV} = undef;
	}
	# clear TAIL's prev pointer too.
	$ptr->{PREV} = undef;

	# set the string as the contents of the ConfIO object.
	$$self->{FH}->set_scalar (\$file) if ($file);
	# ensure that we release our own Conf file first.
	undef ($$self->{FH});
	# then include directives
	undef ($$self->{INCLUDE});
	undef ($$self->{ALL_INCLUDE});
	# then the rest
	undef (%{$$self});
	undef ($self);
}

=item fh ()

Object method.
Returns the ConfIO object representing the configuration file.

=cut

sub fh
{
	my $self = $_[0];
	return ($$self->{FH});
}

sub dirty
{
	my ($self, $dirty) = @_;

	if (defined ($dirty)) {
		$$self->{DIRTY} = $dirty;
		return (1);
	}
	return ($$self->{DIRTY});
}

#
# The _add_dir* routines, insert an object into the per Conf hash and the
# ALL_* hash which resides in the ROOT Conf.

for my $dir qw (zone acl key server include comment) {
	no strict 'refs';

	my $_add = "_add_$dir";
	my $_get = "_get_$dir";
	my $_del = "_del_$dir";
	my $new = "new_$dir";
	my $get = "get_$dir";
	my $delete = "delete_$dir";
	my $itr = "${dir}s";

	*$_add = sub {
		my $obj = $_[0];
		my ($root, $parent, $name);
		$parent = $obj->_parent () or return ($root);
		$root = $parent->{ROOT};
		$name = $obj->name () or return ($name);
		return (Unix::Conf->_err ("$_add", "$dir `$name' already defined"))
			if ($root->{"ALL_\U$dir\E"}{$name});
		# store in per Conf hash as well as in the ROOT Conf object
		$parent->{"\U$dir\E"}{$name} = $root->{"ALL_\U$dir\E"}{$name} = $obj;
		return (1);
	};

	# we get from the ROOT ALL_DIR* hash, so we can get a directive
	# defined in any Conf file from any Conf object.
	# maybe it is better to restrict _get_* to directives defined in
	# that file only. 
	# added later. validation routines in Unix::Conf::Bind8::Conf::Lib
	# get confds structures and need to validate names defined throughout.
	# some more thought needed.
	*$_get = sub {
		my ($confds, $name) = @_;
		return (Unix::Conf->_err ("$_get", "$dir `$name' not defined"))
			unless ($confds->{ROOT}{"ALL_\U$dir\E"}{$name});
		return ($confds->{ROOT}{"ALL_\U$dir\E"}{$name});
	};

	*$_del = sub {
		my $obj = $_[0];
		my ($root, $parent, $name);
		$parent = $obj->_parent () or return ($root);
		$root = $parent->{ROOT};
		$name = $obj->name () or return ($name);
		return (Unix::Conf->_err ("$_del", "$dir `$name' not defined"))
			unless ($root->{"ALL_\U$dir\E"}{$name});
		delete ($root->{"ALL_\U$dir\E"}{$name});
		delete ($parent->{"\U$dir\E"}{$name});
		return (1);
	};

	##################################################################
	#                     PUBLIC INTERFACE                           #
	##################################################################

	if ($dir eq 'include') {
		*$new = sub {
			my $self = shift ();

			return (Unix::Conf->_err ("$new", "not a class constructor"))
				unless (ref ($self));
			my $class = "Unix::Conf::Bind8::Conf::\u$dir";
			return ($class->new (@_, PARENT => $$self, ROOT => $self->__root ()));
		};
		# no real need to create this here.
		my $get_conf = "get_include_conf";
		*$get_conf = sub {
			my ($self, $name) = @_;

			return (Unix::Conf->_err ("$get_conf", "not a class method"))
				unless (ref ($self));
			return (Unix::Conf->_err ("$get_conf", "name not specified"))
				unless (defined ($name));
			my $ret;
			$ret = _get_include ($$self, $name) or return ($ret);
			return ($ret->conf ());
		};
	}
	else {
		*$new = sub {
			my $self = shift ();

			return (Unix::Conf->_err ("$new", "not a class constructor"))
				unless (ref ($self));
			my $class = "Unix::Conf::Bind8::Conf::\u$dir";
			return ($class->new (@_, PARENT => $$self));
		};
	}
	
	# no get_ and delete_, iterator methods for comment. at least for now
	if ($dir ne 'comment') {
		*$get = sub {
			my ($self, $name) = @_;
			return (Unix::Conf->_err ("$get", "not a class constructor"))
				unless (ref ($self));
			return (Unix::Conf->_err ("$get", "$dir name not passed"))
				unless ($name);
			return (&$_get($$self, $name));
		};

		*$delete = sub {
			my ($self, $name) = @_;
			return (Unix::Conf->_err ("$delete", "not a class constructor"))
				unless (ref ($_[0]));
			return (Unix::Conf->_err ("$delete", "$dir name not passed"))
				unless ($name);
			my $obj;
			$obj = &$_get($$self, $name)	or return ($obj);
			return ($obj->delete ());
		};
		
		*$itr = sub {
			my ($self, $context) = @_;

			return (Unix::Conf->_err ("$delete", "not a class constructor"))
				unless (ref ($self));
			if ($context && __valid_yesno ($context)) {
				return (
					wantarray () ? values (%{$$self->{ROOT}{"ALL_\U$dir\E"}}) :
						(each (%{$$self->{ROOT}{"ALL_\U$dir\E"}}))[1]
				);
			}
			return (
				wantarray () ? values (%{$$self->{"\U$dir\E"}}) :
					(each (%{$$self->{"\U$dir\E"}}))[1]
			);
		};
	}
}

# directives that do not have names, and hence
# defined once only.
for my $dir qw (options logging trustedkeys controls) {
	no strict 'refs';

	my $_add	= "_add_$dir";
	my $_get	= "_get_$dir";
	my $_del	= "_del_$dir";
	my $new		= "new_$dir";
	my $get		= "get_$dir";
	my $delete	= "delete_$dir";

	*$_add = sub {
		my $obj = $_[0];
		my ($root, $parent);
		$parent = $obj->_parent () or return ($parent);
		$root = $parent->{ROOT};
		return (Unix::Conf->_err ("$_add", "`$dir' already defined"))
			if ($root->{"ALL_\U$dir\E"});
		$root->{"ALL_\U$dir\E"} = $parent->{"\U$dir\E"} = $obj;
		return (1);
	};

	# we get from the ROOT ALL_DIR* hash, so we can get a directive
	# defined in any Conf file from any Conf object.
	# maybe it is better to restrict _get_* to directives defined in
	# that file only.
	*$_get = sub {
		my $confds = $_[0];
		return (Unix::Conf->_err ("$_get", "`$dir' not defined"))
			unless ($confds->{ROOT}{"ALL_\U$dir\E"});
		return ($confds->{ROOT}{"ALL_\U$dir\E"});
	};

	$_del = "_del_$dir";
	*$_del = sub {
		my $obj = $_[0];
		my ($root, $parent);
		$parent = $obj->_parent () or return ($root);
		$root = $parent->{ROOT};
		return (Unix::Conf->_err ("$_del", "`$dir' not defined"))
			unless ($root->{"ALL_\U$dir\E"});
		delete ($root->{"ALL_\U$dir\E"});
		delete ($parent->{"\U$dir\E"});
		return (1);
	};

	##################################################################
	#                     PUBLIC INTERFACE                           #
	##################################################################

	*$new = sub {
		my $self = shift ();

		return (Unix::Conf->_err ("$new", "not a class constructor"))
			unless (ref ($self));
		my $class = "Unix::Conf::Bind8::Conf::\u$dir";
		return ($class->new (@_, PARENT => $$self));
	};

	*$get = sub {
		return (Unix::Conf->_err ("$get", "not a class constructor"))
			unless (ref ($_[0]));
		return (&$_get(${$_[0]}));
	};

	*$delete = sub {
		my $obj;

		return (Unix::Conf->_err ("$delete", "not a class constructor"))
			unless (ref ($_[0]));
		$obj = &$_get(${$_[0]})	or return ($obj);
		return ($obj->delete ());
	};
}

# ARGUMENTS:
# 	Unix::Conf::Bind8::Conf::Directive subclass instalce
#	WHERE => ('FIRST'|'LAST'|'BEFORE'|'AFTER')
#	WARG  => Unix::Conf::Bind8::Conf::Directive subclass instance
#			 # in case WHERE =~ /('BEFORE'|'AFTER')/
# This routine uses the PARENT ref in an object to insert itself in the
# doubly linked list in the parent Unix::Conf::Bind8::Conf object.
sub _insert_in_list ($$;$)
{
	my ($obj, $where, $arg) = @_;

	return (Unix::Conf->_err ("__insert_in_list", "`$obj' not instance of a subclass of Unix::Conf::Bind8::Conf::Directive"))
		unless (UNIVERSAL::isa ($obj, "Unix::Conf::Bind8::Conf::Directive"));
	return (Unix::Conf->_err ("__insert_in_list", "`$where', illegal argument"))
		if ($where !~ /^(FIRST|LAST|BEFORE|AFTER)$/i);
	my $conf = $obj->_parent ();

	# now insert the directive in the doubly linked list
	# insert at the head
	(uc ($where) eq 'FIRST') && do {
		$obj->{PREV} = $conf->{HEAD};
		$obj->{NEXT} = $conf->{HEAD}{NEXT};
		$conf->{HEAD}{NEXT}{PREV} = $obj;
		$conf->{HEAD}{NEXT} = $obj;
		goto END;
	};
	# insert at tail
	(uc ($where) eq 'LAST') && do {
		$obj->{NEXT} = $conf->{TAIL};
		$obj->{PREV} = $conf->{TAIL}{PREV};
		$conf->{TAIL}{PREV}{NEXT} = $obj;
		$conf->{TAIL}{PREV} = $obj;
		goto END;
	};

	return (Unix::Conf->_err ("__insert_in_list", "$where not an child of Unix::Conf::Bind8::Conf::Directive"))
		unless (UNIVERSAL::isa ($arg, "Unix::Conf::Bind8::Conf::Directive"));
	# before $arg
	(uc ($where) eq 'BEFORE') && do {
		$obj->{NEXT} = $arg;
		$obj->{PREV} = $arg->{PREV};
		$arg->{PREV}{NEXT} = $obj;
		$arg->{PREV} = $obj;
		goto END;
	};
	# after $arg
	(uc ($where) eq 'AFTER') && do {
		$obj->{NEXT} = $arg->{NEXT};
		$obj->{PREV} = $arg;
		$arg->{NEXT}{PREV} = $obj;
		$arg->{NEXT} = $obj;
	};
END:
	return (1);
}

# ARGUMENTS
# Unix::Conf::Bind8::Conf::Directive subclass object
# Delete object from the doubly linked list.
sub _delete_from_list ($)
{
	my $obj = $_[0];

	return (
		Unix::Conf->_err (
			"__delete_from_list", 
			"`$obj' not instance of a subclass of Unix::Conf::Bind8::Conf::Directive"
		)
	) unless (UNIVERSAL::isa ($obj, "Unix::Conf::Bind8::Conf::Directive"));
	$obj->{NEXT}{PREV} = $obj->{PREV};
	$obj->{PREV}{NEXT} = $obj->{NEXT};
	return (1);
}

sub __root
{
	my ($self, $root) = @_;

	if ($root) {
		$$self->{ROOT} = $root;
		return (1);
	}
	return (
		defined ($$self->{ROOT}) ? $$self->{ROOT} :
			Unix::Conf->_err ('__root', "ROOT not defined")
	);
}

=item parse_errors ()

Object method.
Returns a list of Err objects, created during the parse of the conf file.
There represent warnings generated.

=cut

sub parse_errors
{
	my $self = $_[0];
	return (@{$$self->{ERRORS}});
}


# ARGUMENTS:
#	Unix::Conf::Err obj
# called by the parser to push errors messages generated during parsing.
sub __add_err
{
	my ($self, $errobj, $lineno) = @_;

	$errobj = Unix::Conf->_err ('add_err', "argument not passed")
		unless (defined ($errobj));
	push (@{$$self->{ERRORS}}, $errobj);
}

=item directives ()

 Arguments
 SCALAR		# Optional

Object method.
Returns defined directives (comments too, if argument is defined). When
called in a list context, returns all defined directives. Iterates over
defined directives, when called in a scalar method. Returns `undef' at
the end of one iteration, and starts over if called again.

NOTE: This method returns objects which represent directives. Make sure
that the variable holding these objects is undef'ed or goes out of scope
before or at the same time as the one holding the invocant. For example
if you hold an Include object, while the parent Conf object has been released
and then the code tries to create a new Conf object for the same conf file,
it will return with an error, because the include file is still open and locked
as you hold the Include object.

Also this method returns only those directives that are defined in the invocant
Conf object and not those in embedded objects.

=cut

sub directives
{
	my ($self, $nocomment) = @_;
	
	# create list of directives only if iterator is at start
	unless ($$self->{ITR}) {
		undef (@{$$self->{DIRARR}});
		for (my $ptr = $$self->{HEAD}{NEXT}; $ptr && $ptr ne $$self->{TAIL}; $ptr = $ptr->{NEXT}) {
			next if ($nocomment && UNIVERSAL::isa ($ptr, "Unix::Conf::Bind8::Conf::Comment"));
			push (@{$$self->{DIRARR}}, $ptr);
		}
	}

	if (wantarray ()) {
		# reset iterator before returning
		$$self->{ITR} = 0;
		return (@{$$self->{DIRARR}}) 
	}
	# return undef on completion of one iteration
	return () if ($$self->{ITR} && !($$self->{ITR} %= scalar (@{$$self->{DIRARR}})));
	return (${$$self->{DIRARR}}[$$self->{ITR}++]);
}


=item new_comment ()

 Arguments
                  # WARG is to be provided only in case WHERE eq 'BEFORE 
                  # or WHERE eq 'AFTER'

Object method.
Creates a Unix::Conf::Bind8::Conf::Comment object, links it in the invocant
Conf object and returns it, on success, an Err object otherwise.
Such directives are used to hold comments between two directives.

=cut

=item new_options ()

 Arguments
 SUPPORTED-OPTION-NAME-IN-CAPS => value    
 WHERE         => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG          => Unix::Conf::Bind8::Conf::Directive subclass object
                  # WARG is to be provided only in case WHERE eq 'BEFORE 
                  # or WHERE eq 'AFTER'

Object Method.
Refer to Unix::Conf::Bind8::Conf::Options for supported options. The 
arguments should be same as expected by various the various methods of 
Unix::Conf::Bind8::Conf::Options.
Creates a Unix::Conf::Bind8::Conf::Options object, links it in the invocant
Conf object and returns it, on success, an Err object on otherwise.

=cut
 
=item get_options ()

Object method.
Returns the Unix::Conf::Bind8::Conf::Options object if defined (either 
through a call to new_options or one created when the configuration file 
is parsed) or Err if none is defined.

=cut

=item delete_options ()

Object method
Deletes the defined (either through a call to new_options or one created 
when the configuration file is parsed) Unix::Conf::Bind8::Conf::Options 
object.
Returns true if a Unix::Conf::Bind8::Conf::Options object is present, an 
Err object otherwise.

=cut

=item new_logging ()

 Arguments
 CHANNELS   => [
    { 
	   NAME             => 'channel-name1',
	   OUTPUT           => 'value',      # syslog|file|null
	   SEVERITY         => 'severity',   # if OUTPUT eq 'syslog'
	   FILE             => 'path',       # if OUTPUT eq 'file'
	   'PRINT-TIME'     => 'value',      # 'yes|no'
	   'PRINT-SEVERITY' => 'value',      # 'yes|no'
	   'PRINT-CATEGORY' => 'value',      # 'yes|no'
   },
 ],
 CATEGORIES  => [
      [ category1        => [ qw (channel1 channel2) ],
      [ category2        => [ qw (channel1 channel2) ],
 ],
 WHERE         => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG          => Unix::Conf::Bind8::Conf::Directive subclass object
                  # WARG is to be provided only in case WHERE eq 'BEFORE 
                  # or WHERE eq 'AFTER'

Object method.
Creates a new Unix::Conf::Bind8::Conf::Logging object, links it to the invocant
Conf object and returns it, on success, an Err object otherwise.

=cut

=item get_logging ()

Object method.
Returns the Unix::Conf::Bind8::Logging object if defined (either through a
call to new_logging () or one created when parsing the configuration file),
an Err object otherwise.

=cut

=item delete_logging ()

Object method.
Deletes the Unix::Conf::Bind8::Logging object if defined (either through a
call to new_logging () or one created when parsing the configuration file) 
and returns true, or returns an Err object otherwise.

=cut

=item new_trustedkeys ()

 Arguments
 KEYS	=> [ domain flags protocol algorithm key ]
 or
 KEYS	=> [ [ domain flags protocol algorithm key ], [..] ]
 WHERE  => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG   => Unix::Conf::Bind8::Conf::Directive subclass object
                  # WARG is to be provided only in case WHERE eq 'BEFORE 
                  # or WHERE eq 'AFTER'

Object method.
Creates a new Unix::Conf::Bind8::Conf::Trustedkeys object, links it in the
invocant Conf object and returns it if successful, an Err object otherwise.

=cut

=item get_trustedkeys ()

Object method.
Returns the Unix::Conf::Bind8::Conf::Trustedkeys object if defined (either 
through a call to new_trustedkeys or one created when the configuration file 
is parsed) or Err if none is defined.

=cut

=item delete_trustedkeys ()

Object method
Deletes the defined (either through a call to new_trustedkeys or one created 
when the configuration file is parsed) Unix::Conf::Bind8::Conf::Trustedkeys 
object.
Returns true if a Unix::Conf::Bind8::Conf::Trustedkeys object is present, an 
Err object otherwise.

=cut

=item new_controls ()

 Arguments
 UNIX	=> [ PATH, PERM, OWNER, GROUP ],
 INET	=> [ ADDR, PORT, ALLOW ]
 WHERE  => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG   => Unix::Conf::Bind8::Conf::Directive subclass object
                  # WARG is to be provided only in case WHERE eq 'BEFORE 
                  # or WHERE eq 'AFTER'

Object method.
ALLOW in INET can either be an Acl object or an anonymous array of elements.
Creates a new Unix::Conf::Bind8::Conf::Controls object, links it in the invocant
Conf object if successful, and returns it, an Err object otherwise.

=cut

=item get_controls ()

Object method.
Returns the Unix::Conf::Bind8::Conf::Controls object if defined (either 
through a call to new_trustedkeys or one created when the configuration file 
is parsed) or Err if none is defined.

=cut

=item delete_controls ()

Object method
Deletes the defined (either through a call to new_trustedkeys or one created 
when the configuration file is parsed) Unix::Conf::Bind8::Conf::Controls 
object.
Returns true if a Unix::Conf::Bind8::Conf::Controls object is present, an 
Err object otherwise.

=cut

=item new_zone ()
 
 Arguments
 NAME          => 'zone-name',
 CLASS         => 'zone-class',        # in|hs|hesiod|chaos
 TYPE          => 'zone-type',         # master|slave|forward|stub|hint
 FILE          => 'records-file',
 MASTERS       => [ qw (10.0.0.1 10.0.0.2) ],
 FORWARD       => 'value',             # yes|no
 FORWARDERS    => [ qw (192.168.1.1 192.168.1.2) ],
 CHECK-NAMES   => 'value'              # fail|warn|ignore
 ALLOW-UPDATE  => Unix::Conf::Bind8::Conf::Acl object,
 ALLOW-QUERY   => Unix::Conf::Bind8::Conf::Acl object,
 ALLOW-TRANSFER=> Unix::Conf::Bind8::Conf::Acl object,
 NOTIFY        => 'value,              # yes|no
 ALSO-NOTIFY   => [ qw (10.0.0.3) ],
 WHERE         => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG          => Unix::Conf::Bind8::Conf::Directive subclass object
                  # WARG is to be provided only in case WHERE eq 'BEFORE 
                  # or WHERE eq 'AFTER'

Object method.
Creates and returns a new Unix::Conf::Bind8::Conf::Zone object, links it
in the invocant Conf object, and returns it, on success, an Err 
object otherwise.

=cut

=item get_zone ()

 Arguments
 'ZONE-NAME',

Object method.
Returns the Unix::Conf::Bind8::Conf::Zone object representing ZONE-NAME 
if defined (either through a call to new_zone () or one created when 
parsing the configuration file), an Err object otherwise.

=cut

=item delete_zone ()

 Arguments
 'ZONE-NAME',

Object method.
Deletes the Unix::Conf::Bind8::Conf::Zone object representing ZONE-NAME 
if defined (either through a call to new_zone () or one created when 
parsing the configuration file) and returns true, or returns an Err 
object otherwise.

=cut

=item zones ()

 Arguments
 ALL		# Optional

Object method.
Iterates through a list of defined Unix::Conf::Bind8::Conf::Zone objects 
(either through a call to new_zone () or ones created when parsing the 
configuration file), returning one at a time when called in scalar context, 
or a list of all objects when called in list context.
Argument ALL can either be 0, no, 1, or yes. When ALL is 1 or 'yes', it
returns all defined Zone objects across files. Else only those defined
in the invocant are returned.

=cut

=item new_acl ()

 Arguments
 NAME      => 'acl-name',				# Optional
 ELEMENTS  => [ qw (10.0.0.1 10.0.0.2 192.168.1.0/24) ],
 WHERE     => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG      => Unix::Conf::Bind8::Conf::Directive subclass object
                  # WARG is to be provided only in case WHERE eq 'BEFORE 
                  # or WHERE eq 'AFTER'

Object method.
Creates a new Unix::Conf::Bind8::Conf::Acl object, links it in the invocant
Conf object, on success, an Err object otherwise.

=cut

=item get_acl ()

 Arguments
 'ACL-NAME',

Object method.
Returns the Unix::Conf::Bind8::Conf::Acl object representing 'ACL-NAME' if
defined (either through a call to new_acl or one created when the 
configuration file is parsed), an Err object otherwise.

=cut

=item delete_acl ()

 Arguments
 'ACL-NAME',

Object method.
Deletes the Unix::Conf::Bind8::Conf::Acl object representing 'ACL-NAME' 
if defined (either through a call to new_acl or one created when the 
configuration file is parsed) and returns true, or returns an Err object 
otherwise.

=cut

=item acls ()

 Arguments
 ALL		# Optional

Object method.
Iterates through the list of defined Unix::Conf::Bind8::Conf::Acl objects 
(either through a call to new_acl or ones created when parsing the file, 
returning an object at a time when called in scalar context, or a list of 
all objects when called in list context.
Argument ALL can either be 0, no, 1, or yes. When ALL is 1 or 'yes', it
returns all defined Acl objects across files. Else only those defined
in the invocant are returned.

=cut

=item new_key
 
 Arguments
 NAME       => scalar,
 ALGORITHM  => scalar,	# number
 SECRET     => scalar,	# quoted string
 WHERE      => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG       => Unix::Conf::Bind8::Conf::Directive subclass object
                  # WARG is to be provided only in case WHERE eq 'BEFORE 
                  # or WHERE eq 'AFTER'

Object method.
Creates a new Unix::Conf::Bind8::Conf::Key object links it in
the invocant Conf object and returns it, on success, an Err object 
on failure.

=cut

=item get_key ()

 Arguments
 'KEY-NAME',

Object method.
Returns the Unix::Conf::Bind8::Conf::Key object representing 'KEY-NAME' if
defined (either through a call to new_key or one created when the 
configuration file is parsed), an Err object otherwise.

=cut

=item delete_key ()

 Arguments
 'KEY-NAME',

Object method.
Deletes the Unix::Conf::Bind8::Conf::Key object representing 'KEY-NAME' 
if defined (either through a call to new_key or one created when the 
configuration file is parsed) and returns true, or returns an Err object 
otherwise.

=cut

=item keys ()

 Arguments
 ALL		# Optional

Object method.
Iterates through the list of defined Unix::Conf::Bind8::Conf::Key objects 
(either through a call to new_key or ones created when parsing the file, 
returning an object at a time when called in scalar context, or a list of 
all objects when called in list context.
Argument ALL can either be 0, no, 1, or yes. When ALL is 1 or 'yes', it
returns all defined Key objects across files. Else only those defined
in the invocant are returned.

=cut


=item new_server ()

 Arguments
 NAME           => scalar,
 BOGUS          => scalar,	# Optional
 TRANSFERS      => scalar,	# Optional
 TRANSFER-FORMAT=> scalar,	# Optional
 KEYS           => [elements ],	# Optional
 WHERE          => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG           => Unix::Conf::Bind8::Conf::Directive subclass object
                       # WARG is to be provided only in case WHERE eq 'BEFORE 
                       # or WHERE eq 'AFTER'
 
Object method.
Creates a new Unix::Conf::Bind8::Conf::Server object, links it in the invocant
Conf object and returns it, on success, an Err object otherwise.

=cut

=item get_server ()

 Arguments
 'SERVER-NAME',

Object method.
Returns the Unix::Conf::Bind8::Conf::Server object representing 'SERVER-NAME' if
defined (either through a call to new_server or one created when the 
configuration file is parsed), an Err object otherwise.

=cut

=item delete_server ()

 Arguments
 'SERVER-NAME',

Object method.
Deletes the Unix::Conf::Bind8::Conf::Server object representing 'SERVER-NAME' 
if defined (either through a call to new_server or one created when the 
configuration file is parsed) and returns true, or returns an Err object 
otherwise.

=cut

=item servers ()

 Arguments
 ALL		# Optional

Object method.
Iterates through the list of defined Unix::Conf::Bind8::Conf::Server objects 
(either through a call to new_servers or ones created when parsing the file, 
returning an object at a time when called in scalar context, or a list of 
all objects when called in list context.
Argument ALL can either be 0, no, 1, or yes. When ALL is 1 or 'yes', it
returns all defined Key objects across files. Else only those defined
in the invocant are returned.

=cut

=item new_include ()

 Arguments
 FILE         => 'path of the configuration file',
 SECURE_OPEN  => 0/1,        # default 1 (enabled)
 WHERE        => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG         => Unix::Conf::Bind8::Conf::Directive subclass object
                  # WARG is to be provided only in case WHERE eq 'BEFORE 
                  # or WHERE eq 'AFTER'

Object method.
Creates a new Unix::Conf::Bind8::Conf::Include object which contains an 
Unix::Conf::Bind8::Conf object representing FILE, links it in the invocant
Conf object and returns it, on success, an Err object otherwise. 

=cut

=item get_include ()

 Arguments
 'INCLUDE-NAME',

Object method.
Returns the Unix::Conf::Bind8::Conf::Include object representing INCLUDE-NAME 
if defined (either through a call to new_include () or one created when 
parsing the configuration file), an Err object otherwise.

=cut

=item get_include_conf ()

 Arguments
 'INCLUDE-NAME'

Object method.
Return the Unix::Conf::Bind8::Conf object inside a defined 
Unix::Conf::Bind8::Conf::Include of name INCLUDE-NAME.

=cut

=item delete_include ()

 Arguments
 'INCLUDE-NAME',

Object method.
Deletes the Unix::Conf::Bind8::Conf::Include object representing INCLUDE-NAME 
if defined (either through a call to new_include () or one created when 
parsing the configuration file) and returns true, or returns an Err 
object otherwise.

=cut

=item includes ()

 Arguments
 ALL		# Optional

Object method.
Iterates through defined Unix::Conf::Bind8::Conf::Include objects (either 
through a call to new_include () or ones created when parsing the 
configuration file), returning one at a time when called in scalar context, 
or a list of all defined includes when called in list context.
Argument ALL can either be 0, no, 1, or yes. When ALL is 1 or 'yes', it
returns all defined Include objects across files. Else only those defined
in the invocant are returned.

=cut

=item get_db ()

 Arguments
 'ZONE-NAME',
 0/1,        # SECURE_OPEN (OPTIONAL). If not specified the value
             # for the ConfIO object is taken.

Object method
Returns a Unix::Conf::Bind8::DB object representing the records file for
zone 'ZONE-NAME' if successful, an Err object otherwise.

=cut

sub get_db 
{
	my ($self, $zone, $secure_open) = @_;
	my $ret;

	return (Unix::Conf->_err ('get_db', "not a class method"))
		unless (ref ($self));
	$secure_open = $self->fh ()->secure_open () 
		unless (defined ($secure_open));
	$ret = $self->get_zone ($zone) or return ($ret);
	return ($ret->get_db ($secure_open));
}

#################################  PARSER  #####################################
#                                                                              #
require 'Unix/Conf/Bind8/Conf/Parser.pm';
#                                   END                                        #
#################################  PARSER  #####################################

1;
__END__
