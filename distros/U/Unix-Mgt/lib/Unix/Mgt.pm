###############################################################################
# Unix::Mgt
#
package Unix::Mgt;
use strict;
use IPC::System::Simple 'runx';
use Capture::Tiny 'capture_merged';
use String::Util qw{define nocontent rtrim};
use Unix::SearchPathGuess 'cmd_path_guess';
use Carp 'croak';

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# version
our $VERSION = '0.14';


#------------------------------------------------------------------------------
# export
#
use base 'Exporter';
use vars qw[@EXPORT_OK %EXPORT_TAGS];
push @EXPORT_OK, qw{unix_mgt_err unix_mgt_err_id};
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);
#
# export
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# opening POD
#

=head1 NAME

Unix::Mgt - lightweight Unix management tools

=head1 SYNOPSIS

 # get user account
 $user = Unix::Mgt::User->get('fred');

 # display some info
 print 'uid: ', $user->uid, "\n";
 print join(', ', $user->groups()), "\n";

 # set some properties
 $user->gid('websters');
 $user->shell('/bin/bash');
 $user->add_to_group('postgres');

 # create user account
 $user = Unix::Mgt::User->create('vera');

 # get user account, creating it if necessary
 $user = Unix::Mgt::User->ensure('molly');

 # get group
 $group = Unix::Mgt::Group->get('www-data');

 # display some info
 print 'gid: ', $group->gid, "\n";
 print join(', ', $group->members()), "\n";

 # add a member
 $group->add_member('tucker');

=head1 DESCRIPTION

Unix::Mgt provides simple object-oriented tools for managing your Unixish
system.  Currently this module provides tools for managing users and groups.
Other tools may follow as they evolve.

Unix::Mgt does not directly manipulate any of the system files such as
C</etc/passwd>. This module uses Perl's built-in Unix functions such as
C<getgrent> to get information, and Unix's built-in programs such as
C<adduser>.

=head2 Early release

In the spirit of "release early, release often", I'm releasing this version
of Unix::Mgt before it has all the features that might be expected. This
version does not include methods for removing users from groups, renaming
users or groups, or several other methods.

=cut

#
# opening POD
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# error id and message globals
#
our $err_id;
our $err_msg;
#
# error id and message globals
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# set_err, reset_err
#
sub set_err {
	my ($class, $id, $msg) = @_;
	$err_id = $id;
	$err_msg = $msg;
	return undef;
}

sub reset_err {
	undef $err_id;
	undef $err_msg;
}

sub unix_mgt_err {
	if ($err_id)
		{ return $err_id . rtrim(': ' . define($err_msg))}
	else
		{ return '' }
}

sub unix_mgt_err_id {
	if ($err_id)
		{ return $err_id}
	else
		{ return '' }
}
#
# reset_err
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# called_sub
#
sub called_sub {
	my (@caller, $sub_name);
	
	# TESTING
	# println subname(class=>1); ##i
	
	# get caller info
	@caller = caller(1);
	
	# get subroutine name and make it look like a method call
	$sub_name = $caller[3];
	$sub_name =~ s|^(.*)\:\:|$1\-\>|s;
	$sub_name .= '()';
	
	# return
	return $sub_name;
}
#
# called_sub
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# even_odd_params
#
sub even_odd_params {
	my $class = shift(@_);
	my $id = shift(@_);
	my ($name, %opts);
	
	# get params: even number means all params (except class) are options,
	# odd number means first param is id
	if (@_ % 2) {
		($name, %opts) = @_;
	}
	else {
		%opts = @_;
		$name = delete($opts{$id});
	}
	
	# return
	return ($name, %opts);
}
#
# even_odd_params
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# run_cmd
#
sub run_cmd {
	my ($class, $err_id_use, $cmd_id, @args) = @_;
	my ($cmd, $out, $rv);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# get command
	$cmd = cmd_path_guess($cmd_id);
	$cmd or croak "do not find path for command $cmd_id";
	
	# run command
	$out = capture_merged{
		$rv = runx(IPC::System::Simple::EXIT_ANY, $cmd, @args);
	};
	
	# if error
	if ($rv) {
		return $class->set_err(
			$err_id_use,
			"error running program $cmd: " . $out,
		);
	}
	
	# return success
	return 1;
}
#
# run_cmd
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# use_bsd
#
our ($use_bsd);

sub use_bsd {
	my ($ug) = @_;
	my $use_bsd = \$Unix::Mgt::use_bsd;
	
	# TESTING
	# println subname(method=>1); ##i
	
	# if cached, use that
	if (defined $$use_bsd)
		{ return $$use_bsd }
	
	# else get the command, cache, and return
	$$use_bsd = cmd_path_guess('pw');
	return $$use_bsd;
}
#
# use_bsd
#------------------------------------------------------------------------------


#
# Unix::Mgt
###############################################################################



###############################################################################
# Unix::Mgt::UGCommon
#
package Unix::Mgt::UGCommon;
use strict;
use String::Util ':all';
use Carp 'croak';
use Unix::SearchPathGuess 'cmd_path_guess';
use base 'Unix::Mgt';

# debug tools
# use Debug::ShowStuff ':all';


#------------------------------------------------------------------------------
# object overloading
#
use overload
	'""'     => sub{$_[0]->{'name'}}, # stringification
	fallback => 1;                    # operations not defined here
#
# object overloading
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# normalize_name
#
sub normalize_name {
	my ($class, $name) = @_;
	
	# TESTING
	# println subname(method=>1), ' $name: ', $name; ##i
	
	# if defined, remove eerything after first space
	if (defined $name) {
		$name =~ s|\s.*||sg;
	}
	
	# TESTING
	# showvar $name;
	
	# return
	return $name;
}
#
# normalize_name
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# name_check
#
sub name_check {
	my ($class, $name, $id) = @_;
	
	# TESTING
	# println subname(method=>1); ##i
	
	# if name does not have content, that's an error
	if (nocontent $name) {
		return $class->set_err(
			$id,
			$class->called_sub() . ' requires a user name parameter'
		);
	}
	
	# normalize
	$name = $class->normalize_name($name);
	
	# return
	return $name;
}
#
# name_check
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# mod_only
#
sub mod_only {
	my ($class, $name) = @_;
	my ($only);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# get class
	if (ref $class)
		{ $class = ref($class) }
	
	# get hash with destrictions
	# KLUDGE: This is an awkward way to get the variable, but I didn't want
	# to remember how to work through package hashes.
	if ( $class eq 'Unix::Mgt::User' )
		{ $only = $Unix::Mgt::User::MOD_ONLY }
	elsif ($class eq 'Unix::Mgt::Group')
		{ $only = $Unix::Mgt::Group::MOD_ONLY }
	else
		{ croak qq|do not know package "$class" for mod restrictions | }
	
	# if $only is defined, name must be in the hash
	if ($only) {
		# deref
		if (ref $name)
			{ $name = $name->{'name'} }
		
		# if no content in name, fail
		if (nocontent $name)
			{ croak 'no content in $name' }
		
		if (! exists($only->{$name})) {
			croak qq|cannot modify user "$name"|;
		}
	}
	
	# else it's ok to mod that user
	return 1;
}
#
# mod_only
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ensure
#
sub ensure {
	my $class = shift(@_);
	my ($name, %opts) = $class->even_odd_params('name', @_);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# reset error globals
	$class->reset_err();
	
	# check and normalize name
	$name = $class->name_check($name, 'missing-user-name');
	$name or return undef;
	
	# if user exists, return get method
	if (my @fields = $class->fields($name)) {
		return $class->get($name, fields=>\@fields)
	}
	
	# else return create
	else {
		return $class->create($name);
	}
}
#
# ensure
#------------------------------------------------------------------------------


#
# Unix::Mgt::UGCommon
###############################################################################



###############################################################################
# Unix::Mgt::User
#
package Unix::Mgt::User;
use strict;
use Carp 'croak';
use String::Util ':all';
use Unix::SearchPathGuess 'cmd_path_guess';
use IPC::System::Simple 'capturex';
use base 'Unix::Mgt::UGCommon';

# debug tools
# use Debug::ShowStuff ':all';

# safety mechanism for development
our $MOD_ONLY;


#------------------------------------------------------------------------------
# POD
#

=head1 Unix::Mgt::User

A Unix::Mgt::User object represents a user in the Unix system. The object
allows you to get and set information about the user account. A user object
is created in one of three ways: C<get>, C<create>, or C<ensure>. The C<new>
method is an alias for C<get>.

Unix::Mgt::User objects stringify to the account's name. For example, the
following code would output C<miko>.

 $user = Unix::Mgt::User->get('miko');
 print $user, "\n";

=cut

#
# POD
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# field_names
#
our @field_names = qw{
	name
	passwd
	uid
	gid
	quota
	comment
	gecos
	dir
	shell
	expire
};
#
# field_names
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# get
#

=head2 get

Unix::Mgt::User->get() retrieves user account information using C<getpwnam> or
C<getpwuid>.  The single param for this method is either the name or the uid of
the user.

 $user = Unix::Mgt::User->get('vera');
 $user = Unix::Mgt::User->get('1010');

If the user is not found then the C<do-not-have-user> error id is set in
C<$Unix::Mgt::err_id> and undef is returned.

=cut

# alias new to get
sub new {
	my $class = shift(@_);
	return $class->get(@_);
}

sub get {
	my $class = shift(@_);
	my ($name, %opts) = $class->even_odd_params('name', @_);
	my (@fields, $user);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# reset error globals
	$class->reset_err();
	
	# check and normalize name
	$name = $class->name_check($name, 'missing-user-name');
	$name or return undef;
	
	# get fields
	@fields = $class->fields($name);
	
	# if user exists, get name, else throw error
	if (@fields) {
		$name = $fields[0];
	}
	else {
		return $class->set_err(
			'do-not-have-user',
			$class->called_sub() . qq|: do not find a user with name "$name"|,
		);
	}
	
	# create object
	$user = bless({}, $class);
	
	# hold on to name
	$user->{'name'} = $name;
	
	# return
	return $user;
}
#
# get
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# entry
#
sub entry {
	my ($user) = @_;
	my (@fields, %entry);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# get fields
	@fields = $user->fields($user->{'name'});
	
	# if no fields, set error and return undef
	if (! @fields) {
		return $user->set_err(
			'do-not-have-user-entry-anymore',
			$user->called_sub() . ': do not have a user with name "' . $user->{'name'} . '"',
		);
	}
	
	# set hash
	@entry{@field_names} = @fields;
	
	# return
	return \%entry;
}
#
# entry
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# fields
#
sub fields {
	my ($class, $name) = @_;
	
	# TESTING
	# println subname(method=>1); ##i
	
	# return
	if ($name =~ m|^\d+$|s)
		{ return getpwuid($name) }
	else
		{ return getpwnam($name) }
}
#
# fields
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# create
#

=head2 create

Unix::Mgt::User->create() creates a user account.  The required param for this
method is the name for the new account.

 $user = Unix::Mgt::User->create('vera');

If the C<system> param is true, then the account is created as a system user,
like this:

 $user = Unix::Mgt::User->create('lanny', system=>1);

create() uses the Unix C<adduser> program.

=cut

sub create {
	my $class = shift(@_);
	my ($name, %opts) = $class->even_odd_params('name', @_);
	my ($user, @cmd);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# reset error globals
	$class->reset_err();
	
	# check and normalize name
	$name = $class->name_check($name, 'missing-user-name');
	$name or return undef;
	
	# if user exists, throw error
	if ($class->fields($name)) {
		return $class->set_err(
			'already-have-user',
			$class->called_sub() . qq|: already have a user with name "$name"|,
		);
	}
	
	# safety check
	$class->mod_only($name);
	
	# BSD style
	if ($class->use_bsd) {
		@cmd = (
			'pw',
			'useradd',
			'-n',
			'user-1',
			'-m'
		);
	}
	
	# else Linux style
	else {
		@cmd = (
			'adduser',
			'--disabled-password',
			'--gecos', '',
		);
		
		# if creating as system user
		if ($opts{'system'})
			{ push @cmd, '--system' }
		
		# add name
		push @cmd, $name;
	}
	
	# run command
	$class->run_cmd('error-creating-user', @cmd) or return undef;
	
	# create object
	$user = bless({}, $class);
	
	# hold on to name
	$user->{'name'} = $name;
	
	# return
	return $user;
}
#
# create
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# POD for ensure()
#

=head2 ensure

Unix::Mgt::User->ensure() gets a user account if it already exists, and
creates the account if it does not. For example, the following lines ensures
the C<molly> account:

 $user = Unix::Mgt::User->ensure('molly');

=cut

#
# POD for ensure()
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# field gets
#

=head2 name

Returns the name of the user account. Currently this method cannot be used to
set the account name.

 print $user->name(), "\n";

=head2 uid

Returns the user's user id (uid).

 print $user->uid(), "\n";

=head2 passwd

Returns the password field from C<getpwname()>.  This method will not actually
return a password, it will probably just return C<*>.

 print $user->passwd(), "\n"; # probably outputs "*"

=cut

sub field_get {
	my ($user, $key) = @_;
	my ($entry);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# reset error
	$user->reset_err();
	
	# get entry
	$entry = $user->entry();
	$entry or return undef;
	
	# return
	return $entry->{$key};
}

sub name    { return shift->field_get('name')     }
sub uid     { return shift->field_get('uid')      }
sub passwd  { return shift->field_get('passwd')   }

#
# field gets
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# field get|sets
#

=head2 gid

Sets/gets the gid of the user's primary group. Called without params, it
returns the user's gid:

 print $user->gid(), "\n";

Called with a single param, gid() sets, then returns the user's primary
group id:

 print $user->gid('1010'), "\n";

If you want to get a Unix::Mgt::Group object representing the user's primary
group, use $user->group().

=head2 dir

Sets/gets the user's home directory. Called without params, it returns the
directory name:

 print $user->dir(), "\n";

Called with a single param, dir() sets, then returns the user's home directory:

 print $user->dir('/tmp'), "\n";

=head2 shell

Sets/gets the user's default command line shell. Called without params, it
returns the shell name:

 print $user->shell(), "\n";

Called with a single param, shell() sets, then returns the user's shell:

 print $user->shell('/bin/sh'), "\n";

=cut

our %bsd_switches = (
	home => 'd',
	gid => 'g',
	shell => 's',
);

sub field_get_set {
	my $user = shift(@_);
	my $field = shift(@_);
	my $option = shift(@_);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# if a value was sent, set the field to that value
	if (@_) {
		my ($value) = @_;
		my (@cmd);
		
		# safety check
		$user->mod_only($user->{'name'});
		
		# BSD style
		if ($user->use_bsd) {
			@cmd = (
				'pw',
				'usermod',
				$user->{'name'},
				'-' . $bsd_switches{$option},
				$value
			);
		}
		
		# else Linux style
		else {
			# build command
			@cmd = (
				'usermod',
				"--$option",
				$value,
				$user->{'name'},
			);
		}
		
		# TESTING
		# sudo pw usermod -d "/home/whatever"
		# showaref @cmd;
		
		# run command
		$user->run_cmd("usermod-error-$field", @cmd) or return undef;
	}
	
	# return field
	return $user->field_get($field);
}


sub gid    { return shift->field_get_set('gid',    'gid',      @_)  }
sub dir    { return shift->field_get_set('dir',    'home',     @_)  }
sub shell  { return shift->field_get_set('shell',  'shell',    @_)  }

# sub quota   { return shift->field_get_set('quota')    }
# sub comment { return shift->field_get_set('comment', 'comment',    @_)  }
# sub expire  { return shift->field_get_set('expire',  'expiredate', @_)  }
# sub gecos   { return shift->field_get_set('gecos')    }

#
# field get|sets
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# group
#

=head2 group

Sets/gets the user's primary group. When called without any params, C<group()>
returns a Unix::Mgt::Group object representing the user's primary group:

 $group = $user->group();

When called with a single param, C<group()> sets the user's primary group. The
param can be either the group's name or its gid:

 $user->group('video');
 $user->group(44);

=cut

sub group {
	my $user = shift(@_);
	my ($new_group, %opts) = $user->even_odd_params('new', @_);
	my ($entry, $gid, $group);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# default options
	%opts = (object=>1, %opts);
	
	# set new group
	if (defined $new_group) {
		my (@args, $success);
		
		# reset error globals
		$user->reset_err();
		
		# BSD style
		if ($user->use_bsd) {
			@args = (
				'pw',
				'usermod',
				$user->{'name'},
				'-g',
				"$new_group",
			);
		}
		
		# else Linux style
		else {
			# build usermod arguments
			@args = (
				'usermod',
				'-g',
				"$new_group",
				"$user"
			);
		}
		
		# change user's group
		$success = $user->run_cmd('error-setting-user-group', @args);
		$success or return 0;
	}
	
	# get gid
	$gid = $user->gid();
	defined($gid) or return undef;
	
	# get group
	$group = Unix::Mgt::Group->get($gid);
	
	# return
	if ($opts{'object'})
		{ return $group }
	else
		{ return $group->name }
}
#
# group
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# secondary_groups
#

=head2 secondary_groups

C<secondary_groups()> returns an array of the user's secondary groups. Each
element in the array is a Unix::Mgt::Group object.

 @groups = $user->secondary_groups();

=cut

sub secondary_groups {
	my ($user, %opts) = @_;
	my (%groups, @rv);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# default options
	%opts = (object=>1, %opts);
	
	# loop through all groups
	while (my @fields = getgrent()) {
		my (%group);
		@group{@Unix::Mgt::Group::field_names} = @fields;
		
		# if there are any members, of the group, see if this user is in it
		if (my $member_str = $group{'members'}) {
			my (%members);
			
			# parse out members
			$member_str = crunch($member_str);
			@members{split m|\s+|, $member_str} = ();
			
			# if this user is in the membership
			if (exists $members{$user->{'name'}})
				{ $groups{$group{'name'}} = 1 }
		}
	}
	
	# build return value
	foreach my $key (keys %groups) {
		my $group = Unix::Mgt::Group->get($key);
		
		# set as just string if options indicate to do so
		if (! $opts{'object'})
			{ $group = $group->{'name'} }
		
		# add to return array
		push @rv, $group;
	}
	
	# return
	return @rv;
}
#
# secondary_groups
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# groups
#

=head2 groups

C<groups()> returns an array of all of the groups the user is a member of. The
first element in the array will be the user's primary group.

 @groups = $user->groups();

=cut

sub groups {
	my ($user, %opts) = @_;
	my (@rv);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# get user's primary group
	push @rv, $user->group(%opts);
	
	# add user's secondary groups
	push @rv, $user->secondary_groups(%opts);
	
	# return
	return @rv;
}
#
# groups
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# add_to_group
#

=head2 add_to_group

C<add_to_group()> adds the user to a group.  The group will be one of the user's
secondary groups, not the primary group.

 $user->add_to_group('video');

=cut

sub add_to_group {
	my ($user, $group) = @_;
	my (@args, $success);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# BSD style
	if ($user->use_bsd) {
		@args = (
			'pw',
			'usermod',
			$user->{'name'},
			'-G',
			"$group"
		);
	}
	
	# else Linux style
	else {
		# build command arguments
		@args = (
			'usermod',
			'--append',
			'--groups',
			"$group",
			"$user"
		);
	}
	
	# run command
	$success = $user->run_cmd('error-adding-user-to-group', @args);
	
	# return success|failure
	return $success;
}
#
# add_to_group
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# remove
#

=head2 remove

C<remove> removes the user account from the system. C<remove> does not take any
parameters.

 $user->remove();

=cut

sub remove {
	my ($user) = @_;
	my (@args);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# safety check
	$user->mod_only($user);
	
	# reset error
	$user->reset_err();
	
	# BSD style
	if ($user->use_bsd) {
		@args = (
			'pw',
			'userdel',
			'-n',
			$user->name,
			'-r',
		);
	}
	
	# else use userdel
	else {
		@args = (
			'userdel',
			$user->name
		);
	}
	
	$user->run_cmd('error-deleting-user', @args) or return undef;
	
	# return
	return 1;
}
#
# remove
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# default_inc
#
sub default_inc {
	my ($env_path, $perl_path, $default_str, @default_arr);
	
	# TESTING
	# println subname(); ##i
	
	# path to perl binary currently being run
	$perl_path = $^X;
	
	# path to the env command
	$env_path = cmd_path_guess('env');
	$env_path or return undef;
	
	# get raw string containing the default @INC
	eval {
		$default_str = capturex(
			$env_path,
			'-i',
			$perl_path,
			'-wT',
			'-e',
			'print join(":", @INC)',
		);
	};
	
	# if the capture threw an error, return empty array
	if ($@) {
		# println 'error getting default @INC: ', $@;
		return ();
	}
	
	# if we didn't get a defined string, return empty array
	if (! defined $default_str)
		{ return () }
	
	# parse string
	@default_arr = split(':', $default_str);
	
	# return
	return (@default_arr);
}
#
# default_inc
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# new_libs
# private sub
#
sub new_libs {
	my (@defaults_arr, %defaults, @rv);
	
	# TESTING
	# println subname(as_sub=>1); ##i
	
	# get defaults, return if none
	@defaults_arr = default_inc();
	@defaults_arr or return();
	
	# build hash of defaults
	@defaults{@defaults_arr} = ();
	
	# loop through @INC, adding paths that aren't in defaults
	LIB_LOOP:
	foreach my $lib (@INC) {
		# special case: remove current directory
		if ($lib eq '.')
			{ next LIB_LOOP }
		
		# if the library isn't in the defaults, add it to the return array
		if (! exists $defaults{$lib})
			{ push @rv, $lib }
	}
	
	# return
	return join(':', @rv);
}
#
# new_libs
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# file_tests
# TODO:
#	- Write regtests for this method.
#	- Document this method.
#
# Document: If -e returns false, not other tests are run. -e does not indiciate
# why it returns false. I might be because the file doesn't exist. It also
# might be that the user doesn't have permission to even see the file.
#
# Regtest: test with multiple extra libs
#
sub file_tests {
	my ($user, $paths_in) = @_;
	my (@cmd, $single, @paths, $cmd_str, @su, $json, $tests);
	
	# TESTING
	# println subname(); ##i
	
	# load JSON module
	require JSON::Tiny;
	
	# paths must be sent
	if (! defined $paths_in)
		{ croak 'defined $paths_in not sent' }
	
	# build @paths
	if (ref $paths_in) {
		@paths = @$paths_in;
	}
	else {
		@paths = $paths_in;
		$single = $paths[0];
	}
	
	# remove empties
	@paths = grep {$_ =~ m|\S|s} @paths;
	
	# if no paths, nothing to do
	if (! @paths)
		{ croak 'no @paths sent' }
	
	# escape quotes, add quotes
	foreach my $path (@paths) {
		$path =~ s|\"|\\"|sg;
		$path =~ s|\'|\\'|sg;
		$path = "'$path'";
	}
	
	# path to perl binary currently being run
	push @cmd, $^X, '-wT';
	
	# extra libs to add to perl command
	if (my $new_libs = new_libs()) {
		my @libs = split(':', $new_libs);
		
		# loop through libs adding each one to command
		foreach my $lib (@libs) {
			push @cmd, '-I', $lib;
		}
	}
	
	# add Unix::Mgt module
	push @cmd, '-MUnix::Mgt';
	
	# add call to file_tests_from_external
	push @cmd, '-e', '"Unix::Mgt::User::file_tests_from_external(' . join(', ', @paths) . ')"';
	
	# get command to send to su
	$cmd_str = join(' ', @cmd);
	
	# build su command
	@su = (
		cmd_path_guess('su'),
		$user->name(),
		'-c',
		$cmd_str,
	);
	
	# run command, get results
	$json = capturex(@su);
	
	# decode json
	eval {
		$tests = JSON::Tiny::decode_json($json);
	};
	
	# throw error if unable to decode
	if (! $tests) {
		croak 'unable to parse results from file tests';
	}
	
	# if single, just return the tests for that file
	if ($single)
		{ return $tests->{$single} }
	
	# else return the entire hash
	else
		{ return $tests }
}
#
# file_tests
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# file_tests_from_external
# Don't call this sub directly.
#
sub file_tests_from_external {
	my (@paths) = @_;
	my ($rv);
	
	# TESTING
	# println subname(); ##i
	
	# load JSON module
	require JSON::Tiny;
	
	# initialize return hashref
	$rv = {};
	
	# loop through paths
	PATH_LOOP:
	foreach my $path (@paths) {
		my ($tests);
		
		# TESTING
		# println '$path: ', $path; ##i
		
		# initialize tests for this path
		$rv->{$path} = $tests = {};
		
		# -e file exists
		unless ($tests->{'-e'} = -e($path)) {
			next PATH_LOOP;
		}
		
		# add rest of tests
		$tests->{'-r'} = -r($path);   # -r  File is readable by effective uid/gid.
		$tests->{'-w'} = -w($path);   # -w  File is writable by effective uid/gid.
		$tests->{'-x'} = -x($path);   # -x  File is executable by effective uid/gid.
		$tests->{'-o'} = -o($path);   # -o  File is owned by effective uid.
		$tests->{'-R'} = -R($path);   # -R  File is readable by real uid/gid.
		$tests->{'-W'} = -W($path);   # -W  File is writable by real uid/gid.
		$tests->{'-X'} = -X($path);   # -X  File is executable by real uid/gid.
		$tests->{'-O'} = -O($path);   # -O  File is owned by real uid.
	}
	
	# TODO:
	#	- test for multiple files
	#	- write tests
	#	- document
	
	# output
	print JSON::Tiny::encode_json($rv);
}
#
# file_tests_from_external
#------------------------------------------------------------------------------



#
# Unix::Mgt::User
###############################################################################



###############################################################################
# Unix::Mgt::Group
#
package Unix::Mgt::Group;
use strict;
use String::Util ':all';
use Carp 'croak';
use base 'Unix::Mgt::UGCommon';


# debug tools
# use Debug::ShowStuff ':all';

# safety mechanism for development
our $MOD_ONLY;

#------------------------------------------------------------------------------
# POD
#

=head1 Unix::Mgt::Group

A Unix::Mgt::Group object represents a group in the Unix system. The object
allows you to get and set information about the group. A group object is
created in one of three ways: C<get>, C<create>, or C<ensure>. The C<new>
method is an alias for C<get>.

Unix::Mgt::Group objects stringify to the groups's name. For example, the
following code would output C<video>.

 $group = Unix::Mgt::Group->get('video');
 print $group, "\n";

=cut

#
# POD
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# field_names
#
our @field_names = qw{
	name
	passwd
	gid
	members
};
#
# field_names
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# fields
#
sub fields {
	my ($class, $name) = @_;
	
	# TESTING
	# println subname(method=>1); ##i
	
	# return
	if ($name =~ m|^\d+$|s)
		{ return getgrgid($name) }
	else
		{ return getgrnam($name) }
}
#
# fields
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# get
#

=head2 get

Unix::Mgt::Group->get() retrieves group information using C<getgrnam> or
C<getgrgid>.  The single param for this method is either the name or the gid of
the group.

 $group = Unix::Mgt::Group->get('video');
 $group = Unix::Mgt::Group->get('44');

If the group is not found then the C<do-not-have-group> error id is set in
C<$Unix::Mgt::err_id> and undef is returned.

=cut

# alias new to get
sub new {
	my $class = shift(@_);
	return $class->get(@_);
}

sub get {
	my $class = shift(@_);
	my ($name, %opts) = $class->even_odd_params('name', @_);
	my (@fields, $group);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# reset error globals
	$class->reset_err();
	
	# check and normalize name
	$name = $class->name_check($name, 'missing-group-name');
	$name or return undef;
	
	# get fields
	@fields = $class->fields($name);
	
	# if group exists, set name, else throw error
	if (@fields) {
		$name = $fields[0];
	}
	else {
		return $class->set_err(
			'do-not-have-group',
			$class->called_sub() . qq|: do not find a group with name "$name"|,
		);
	}
	
	# create object
	$group = bless({}, $class);
	
	# hold on to name
	$group->{'name'} = $name;
	
	# return
	return $group;
}
#
# get
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# create
#

=head2 create

Unix::Mgt::Group->create() creates a group.  The required param for this method
is the name for the new group.

 $group = Unix::Mgt::Group->create('websters');

create() uses the Unix C<groupadd> program.

=cut

sub create {
	my $class = shift(@_);
	my ($name, %opts) = $class->even_odd_params('name', @_);
	my ($group, @cmd);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# reset error globals
	$class->reset_err();
	
	# check and normalize name
	$name = $class->name_check($name, 'missing-group-name');
	$name or return undef;
	
	# if group exists, throw error
	if ($class->fields($name)) {
		return $class->set_err(
			'already-have-group',
			$class->called_sub() . qq|: already have a group with name "$name"|,
		);
	}
	
	# safety check
	$class->mod_only($name);
	
	# BSD style
	if ($class->use_bsd) {
		@cmd = (
			'pw',
			'groupadd',
			'-n',
			$name,
		);
	}
	
	# else Linux style
	else {
		# command
		push @cmd, 'groupadd';
		
		# if creating as system group
		if ($opts{'system'})
			{ push @cmd, '--system' }
		
		# add name
		push @cmd, $name;
	}
	
	# run command
	$class->run_cmd('error-creating-group', @cmd) or return undef;
	
	# create object
	$group = bless({}, $class);
	
	# hold on to name
	$group->{'name'} = $name;
	
	# return
	return $group;
}
#
# create
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# POD for ensure()
#

=head2 ensure

Unix::Mgt::Group->ensure() gets a group if it already exists, and creates the
group if it does not. For example, the following lines ensures
the C<wbesters> group:

 $group = Unix::Mgt::User->ensure('wbesters');

=cut

#
# POD for ensure()
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# field gets
#

=head2 name

Returns the name of the group. Currently this method cannot be used to set the
group name.

 print $group->name(), "\n";

=head2 gid

Returns the groups's group id (gid).

 print $group->gid(), "\n";

=cut

sub field_get {
	my ($group, $key) = @_;
	my ($entry);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# reset error
	$group->reset_err();
	
	# get entry
	$entry = $group->entry();
	$entry or return undef;
	
	# return
	return $entry->{$key};
}

sub name    { return shift->field_get('name')     }
sub gid     { return shift->field_get('gid')      }

#
# field gets
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# entry
#
sub entry {
	my ($group) = @_;
	my (@fields, %entry);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# get fields
	@fields = $group->fields($group->{'name'});
	
	# if no fields, set error and return undef
	if (! @fields) {
		return $group->set_err(
			'do-not-have-group-entry-anymore',
			$group->called_sub() . ': do not have a group with name "' . $group->{'name'} . '"',
		);
	}
	
	# set hash
	@entry{@field_names} = @fields;
	
	# return
	return \%entry;
}
#
# entry
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# members
#

=head2 members

C<members()> returns an array of all members of the group. Both users for whom
this is the primary group, and users for whom this is a secondary group are
returned.

 @members = $group->members();

The elements in the array are Unix::Mgt::User objects.

=cut

sub members {
	my ($group, %opts) = @_;
	my (%members, @rv);
	
	# add users for whom this is their primary group
	foreach my $user ($group->primary_members(%opts)) {
		$members{"$user"} = $user;
	}
	
	# add users for whom this is a secondary group
	foreach my $user ($group->secondary_members(%opts)) {
		$members{"$user"} = $user;
	}
	
	# build return value
	@rv = values(%members);
	
	# return
	return @rv;
}
#
# members
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# primary_members
#

=head2 primary_members

C<primary_members()> returns an array of users for whom this is the primary
group.

 @members = $group->primary_members();

The elements in the returned array are Unix::Mgt::User objects.

=cut

sub primary_members {
	my ($group, %opts) = @_;
	my ($gid, %members, @rv);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# default options
	%opts = (object=>1, %opts);
	
	# get gid
	$gid = $group->gid();
	
	# get users for whom this i
	while (my @fields = getpwent()) {
		my (%user);
		@user{@Unix::Mgt::User::field_names} = @fields;
		
		# if the user is in the group, add to %members
		if ( defined($user{'gid'}) && ($user{'gid'} eq $gid) ) {
			$members{$user{'name'}} = 1;
		}
	}
	
	# build return array of objects
	if ($opts{'object'}) {
		foreach my $name (keys %members) {
			push @rv, Unix::Mgt::User->get($name);
		}
	}
	
	# else build return array of names
	else {
		@rv = keys(%members);
	}
	
	# return
	return @rv;
}
#
# primary_members
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# secondary_members
#

=head2 secondary_members

C<secondary_members()> returns an array of users for whom this is a secondary group.

 @members = $group->secondary_members();

The elements in the returned array are Unix::Mgt::User objects.

=cut

sub secondary_members {
	my ($group, %opts) = @_;
	my ($gid, $members_str, %members, @rv);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# default options
	%opts = (object=>1, %opts);
	
	# get users for whom this is a secondary group
	$members_str = $group->entry->{'members'};
	defined($members_str) or return ();
	
	# loop through members
	NAME_LOOP:
	foreach my $name (split m|\s+|s, $members_str) {
		if (hascontent $name) {
			my $user = Unix::Mgt::User->get($name);
			$members{$user->{'name'}} = 1;
		}
	}
	
	# build return array of objects
	if ($opts{'object'}) {
		foreach my $name (keys %members) {
			push @rv, Unix::Mgt::User->get($name);
		}
	}
	
	# else build return array of names
	else {
		@rv = keys(%members);
	}
	
	# return
	return @rv;
}
#
# secondary_members
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# add_member
#

=head2 add_member

C<add_member()> adds a user to the group as a secondary group.  The single
param can be a user name, uid, or Unix::Mgt::User object.

 $group->add_member('miko');

If the user is already a member of the group then nothing is done and no error
is set.

=cut

sub add_member {
	my ($group, $user) = @_;
	
	# TESTING
	# println subname(method=>1); ##i
	
	# get user object
	if (! ref $user)
		{ $user = Unix::Mgt::User->get($user) }
	
	# add user to group
	return $user->add_to_group($group);
}
#
# add_member
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# remove
#

=head2 remove

C<remove> removes the group from the system. C<remove> does not take any
parameters.

 $group->remove();

If any users have the group as a primary group then this method will fail.

=cut

sub remove {
	my ($group) = @_;
	my (@cmd);
	
	# TESTING
	# println subname(method=>1); ##i
	
	# safety check
	$group->mod_only($group);
	
	# reset error
	$group->reset_err();
	
	# cannot remove if any users have this group as primary group
	if (my @primaries = $group->primary_members) {
		my ($id, $msg);
		
		# ste id
		$id = 'cannot-remove-primary-group';
		
		# begin message
		$msg =
			'cannot remove the group "' . $group->name() .
			'" because it is the primary group for ';
		
		# plural
		if (@primaries > 1) {
			$msg .= 'the following users: ' . join(', ', @primaries);
		}
		
		# singular
		else {
			$msg .= 'the user "' . $primaries[0] . '"';
		}
		
		# return failure
		return $group->set_err($id, $msg);
	}
	
	# if using pw command
	if ($group->use_bsd) {
		@cmd = (
			'pw',
			'groupdel',
			'-n',
			$group->name,
		);
	}
	
	# else use groupdel
	else {
		@cmd = (
			'groupdel',
			$group->name,
		);
	}
	
	# run command
	$group->run_cmd('error-deleting-group', @cmd) or return undef;
	
	# return
	return 1;
}
#
# remove
#------------------------------------------------------------------------------


#
# Unix::Mgt::Group
###############################################################################



# return true
1;

__END__

=head1 SEE ALSO

L<Passwd::Unix|http://search.cpan.org/~strzelec/Passwd-Unix/> and
L<Unix::Passwd::File|http://search.cpan.org/~sharyanto/Unix-Passwd-File/>
provide similar functionality.

=head1 TERMS AND CONDITIONS

Copyright (c) 2014 by Miko O'Sullivan. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with no warranty of any kind.

=head1 AUTHOR

Miko O'Sullivan C<miko@idocs.com>

=head1 TO DO

This is an early release of Unix::Mgt. It does not include methods for
deleting users, removing them from groups, or other deletion oriented
objectives.

Please feel free to contribute code for these purposes.

=head1 HISTORY

=over

=item Version 0.10 December 30, 2014

Initial release

=item Version 0.11 December 31, 2014

Changed addgroup to groupadd.

Added tests for existence of adduser, usermod, and groupadd.

=item Version 0.12 January 3, 2015

Fixed some POD formatting issues.

Revised tests to include test names.

=item Version 0.13 January 4, 2015

Added $user->remove() and $group->remove().

Added slots where BSD-style commands will go. Currently, methods for creating,
modifying, or deleting users or group will fail on BSD.

=item Version 0.14 February 2, 2015

Added support for BSD. The support is poorly tested because I don't have a BSD
system. Any feedback is appreciated.

Added Unix::Mgt::User::new and Unix::Mgt::Group::new as aliases to get().

=back

=cut
