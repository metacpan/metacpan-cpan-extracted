package UserDB;

use 5.016003;
use strict;
use DBI;
use Digest::SHA qw(sha256_hex);

our $VERSION = '1.00';

# Open a user database or create one if needed
sub new
{
	my $class = shift;
	my ($filename) = @_;
	my $sql;
	if(!$filename) { return undef; }
	my $db = DBI->connect("dbi:SQLite:dbname=" . $filename, "", "", { RaiseError => 0, PrintError => 0 }) or return undef;
	$sql = $db->prepare("SELECT * FROM users WHERE 0 = 1;") or do
	{
		$sql = $db->prepare("CREATE TABLE users (username TEXT, password TEXT, name TEXT, email TEXT, profile TEXT, phone TEXT, manager TEXT, department TEXT, url TEXT, notes TEXT);");
		$sql->execute();
	};
	$sql->finish();
	$sql = $db->prepare("SELECT * FROM groups WHERE 0 = 1;") or do
	{
		$sql = $db->prepare("CREATE TABLE groups (groupname TEXT, members TEXT);");
		$sql->execute();
	};
	$sql->finish();
	my $self = bless({ db => $db, error => ""}, $class);
	return $self;
}

# Create a new user
sub create_user
{
	my ($self, $username) = @_;
	my $sql;
	my $db = $self->{db};
	$self->{error} = "";
	if(!$username || $username eq "")
	{
		$self->{error} = "User name not specified.";
		return undef; 
	}
	$sql = $db->prepare("SELECT ROWID FROM users WHERE username = ?;");
	$sql->execute($username);
	while(my @res = $sql->fetchrow_array())
	{
		$self->{error} = "User name already exists.";
		return undef;
	}
	my $sql = $db->prepare("INSERT INTO users VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);");
	$sql->execute($username, "", "", "", "", "", "", "", "", "");
	return 1;
}

# Get attributes for a username
sub get_attributes
{
	my ($self, $username) = @_;
	my $sql;
	my $db = $self->{db};
	$self->{error} = "";
	if(!$username || $username eq "")
	{
		$self->{error} = "User name not specified.";
		return undef;
	}
	$sql = $db->prepare("SELECT * FROM users WHERE username = ?;");
	$sql->execute($username);
	while(my @res = $sql->fetchrow_array())
	{
		return ("name", $res[2], "email", $res[3], "profile", $res[4], "phone", $res[5], "manager", $res[6], "department", $res[7], "url", $res[8], "notes", $res[9]);
	}
	$self->{error} = "Username not found.";
	return undef;
}

# Set attributes for a userid
sub set_attributes
{
	my ($self, $username, %attrs) = @_;
	my $sql;
	my $db = $self->{db};
	$self->{error} = "";
	if(!$username || $username eq "")
	{
		$self->{error} = "User name not specified.";
		return undef;
	}
	foreach my $attr (("name", "email", "profile", "phone", "manager", "department", "url", "notes"))
	{
		if($attrs{lc($attr)})
		{
			$sql = $db->prepare("UPDATE users SET " . $attr . " = ? WHERE username = ?;");
			$sql->execute($attrs{lc($attr)}, $username);
		}
	}
	return 1;
}

# Create a new group
sub create_group
{
	my ($self, $groupname) = @_;
	my $sql;
	my $db = $self->{db};
	$self->{error} = "";
	if(!$groupname || $groupname eq "")
	{
		$self->{error} = "Group name not specified.";
		return undef; 
	}
	$sql = $db->prepare("SELECT ROWID FROM groups WHERE groupname = ?;");
	$sql->execute($groupname);
	while(my @res = $sql->fetchrow_array())
	{
		$self->{error} = "Group name already exists.";
		return undef;
	}
	my $sql = $db->prepare("INSERT INTO groups VALUES (?, ?);");
	$sql->execute($groupname, "");
	return 1;
}

# Add a user to a group
sub add_to_group
{
	my ($self, $username, $groupname) = @_;
	my $sql;
	my $db = $self->{db};
	$self->{error} = "";
	if(!$username || $username eq "")
	{
		$self->{error} = "User name not specified.";
		return undef; 
	}
	if(!$groupname || $groupname eq "")
	{
		$self->{error} = "Group name not specified.";
		return undef; 
	}
	my $userid = -1;
	$sql = $db->prepare("SELECT ROWID FROM users WHERE username = ?;");
	$sql->execute($username);
	while(my @res = $sql->fetchrow_array()) { $userid = $res[0]; }
	if($userid == -1)
	{
		$self->{error} = "User name not found.";
		return undef;
	}
	$sql = $db->prepare("SELECT members FROM groups WHERE groupname = ?;");
	$sql->execute($groupname);
	my $members;
	while(my @res = $sql->fetchrow_array()) { $members = $res[0]; }
	if(!defined($members))
	{
		$self->{error} = "Group name not found.";
		return undef;
	}
	$members =~ s/(\|$userid\|)//g;
	$members .= "|" . $userid . "|";
	$sql = $db->prepare("UPDATE groups SET members = ? WHERE groupname = ?");
	$sql->execute($members, $groupname);
	return 1;
}

# Remove a user from a group
sub remove_from_group
{
	my ($self, $username, $groupname) = @_;
	my $sql;
	my $db = $self->{db};
	$self->{error} = "";
	if(!$username || $username eq "")
	{
		$self->{error} = "User name not specified.";
		return undef; 
	}
	if(!$groupname || $groupname eq "")
	{
		$self->{error} = "Group name not specified.";
		return undef; 
	}
	my $userid = -1;
	$sql = $db->prepare("SELECT ROWID FROM users WHERE username = ?;");
	$sql->execute($username);
	while(my @res = $sql->fetchrow_array()) { $userid = $res[0]; }
	if($userid == -1)
	{
		$self->{error} = "User name not found.";
		return undef;
	}
	$sql = $db->prepare("SELECT members FROM groups WHERE groupname = ?;");
	$sql->execute($groupname);
	my $members;
	while(my @res = $sql->fetchrow_array()) { $members = $res[0]; }
	if(!defined($members))
	{
		$self->{error} = "Group name not found.";
		return undef;
	}
	$members =~ s/(\|$userid\|)//g;
	$sql = $db->prepare("UPDATE groups SET members = ? WHERE groupname = ?");
	$sql->execute($members, $groupname);
	return 1;
}

# Return members of a group
sub members_of_group
{
	my ($self, $groupname) = @_;
	my $sql;
	my $db = $self->{db};
	$self->{error} = "";
	if(!$groupname || $groupname eq "")
	{
		$self->{error} = "Group name not specified.";
		return undef; 
	}
	$sql = $db->prepare("SELECT members FROM groups WHERE groupname = ?;");
	$sql->execute($groupname);
	my @memberids;
	while(my @res = $sql->fetchrow_array()) { @memberids = split(/\|/, $res[0]); }
	if(!@memberids)
	{
		$self->{error} = "Group name not found."; 
		return undef;
	}
	my @users;
	$sql = $db->prepare("SELECT ROWID,username FROM users;");
	$sql->execute();
	while(my @res = $sql->fetchrow_array()) { $users[int($res[0])] = $res[1]; }
	my @members;
	foreach my $id (@memberids)
	{
		if($id ne "|" && $id ne "")
		{
			push(@members, $users[int($id)]);
		}
	}
	return @members;
}

# Set password for a user
sub set_password
{
	my ($self, $username, $password) = @_;
	my $sql;
	my $db = $self->{db};
	$self->{error} = "";
	if(!$username || $username eq "")
	{
		$self->{error} = "User name not specified.";
		return undef;
	}
	if(!$password || $password eq "")
	{
		$self->{error} = "Password not specified.";
		return undef;
	}
	$sql = $db->prepare("UPDATE users SET password = ? WHERE username = ?");
	$sql->execute(sha256_hex($password), $username);
	return 1;
}

# Check password for a user
sub check_password
{
	my ($self, $username, $password) = @_;
	my $sql;
	my $db = $self->{db};
	$self->{error} = "";
	if(!$username || $username eq "")
	{
		$self->{error} = "User name not specified.";
		return undef;
	}
	if(!$password || $password eq "")
	{
		$self->{error} = "Password not specified.";
		return undef;
	}
	$sql = $db->prepare("SELECT password FROM users WHERE username = ?");
	$sql->execute($username);
	while(my @res = $sql->fetchrow_array()) 
	{
		if($res[0] eq sha256_hex($password)) { return 1; }
	}
	$self->{error} = "Invalid password.";
	return undef;
}

# List users
sub list_users
{
	my ($self) = @_;
	my $sql;
	my $db = $self->{db};
	$self->{error} = "";
	$sql = $db->prepare("SELECT username FROM users;");
	$sql->execute();
	my @users;
	while(my @res = $sql->fetchrow_array()) { push(@users, $res[0]); }
	if(!@users) { $self->{error} = "No user found."; }
	return @users;
}

# Get the last error
sub error
{
	my ($self) = @_;
	return $self->{error};
}

1;

__END__

=head1 NAME

UserDB - A simple users and groups management interface

=head1 SYNOPSIS

  use UserDB;
  
  my $userdb = UserDB->new("user.db");   # Connect to the database
  if(!$userdb) { die "Could not connect to database!"; }
  
  $userdb->create_user("tanya");   # Create a new user
  $userdb->set_attributes("tanya", name => "Tanya Harding", email => "tanya.harding\@example.com");   # Set some attributes
  my %attrs = $userdb->get_attributes("tanya");   # Get attributes
  
  print "Name: " . $attrs{"name"} . "\n";
  print "Email: " . $attrs{"email"} . "\n";
  print "Department: " . $attrs{"department"} . "\n";
  
  $userdb->create_group("Finance Staff");   # Create a group
  $userdb->add_to_group("tanya", "Finance Staff");   # Add user to group
  
  $userdb->create_user("joe");   # Create a new user
  $userdb->add_to_group("joe", "Finance Staff");   # Add the new user to group
  
  foreach my $member ($userdb->members_of_group("Finance Staff"))   # List members of group
  {
    print "Finance Staff contains: " . $member . "\n";
    $userdb->remove_from_group($member, "Finance Staff");    # Remove member from the group
  }
  
  $userdb->set_password("joe", "Test123");   # Set a password
  if($userdb->check_password("joe", "Test321"))   # Verify the password
  {
    print "Login successful!\n"; 
  }
  else 
  {
    print "Login failed! " . $userdb->error . "\n"; 
  }

=head1 DESCRIPTION

UserDB is a simple management module for users and groups. It uses a flat file database to store information and as such does not rely on any external resource. It provides an interface to do simple functions for implementing users and groups, and handles errors gracefully. Any method can return 'undef' in case an error happened, the expected value (or true) otherwise.

=head2 METHODS

=item $userdb = UserDB->new($filename)

Create or open an existing UserDB file.

=item $userdb->error

Returns the last error message.

=item $userdb->create_user($username)

Create a new user.

=item $userdb->set_attributes($username, %attributes)

Set attributes for a user. The available attributes include: name, email, profile, phone, manager, department, url, notes.

=item %attributes = $userdb->get_attributes($username)

Returns an associative array of attributes for the user.

=item $userdb->set_password($username, $password)

Set a user password. The password is hashed before being stored.

=item $userdb->check_password($username, $password)

Check a user password against the stored one.

=item @users = $userdb->list_users

Return a full list of users.

=item $userdb->create_group($groupname)

Create a new group.

=item $userdb->add_to_group($username, $groupname)

Add a user to a group.

=item $userdb->remove_from_group($username, $groupname)

Remove a user from a group.

=item @members = $userdb->members_of_group($groupname)

Returns an array of members for a group.

=head1 DEPENDENCIES

=item DBI

=item Digest::SHA

=head1 AUTHOR

Patrick Lambert, E<lt>dendory@live.caE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Patrick Lambert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
