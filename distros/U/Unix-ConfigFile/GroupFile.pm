package Unix::GroupFile;

# $Id: GroupFile.pm,v 1.6 2000/05/02 15:59:34 ssnodgra Exp $

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Unix::ConfigFile;

require Exporter;

@ISA = qw(Unix::ConfigFile Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.06';

# Package variables
my $MAXLINELEN = 511;

# Implementation Notes
#
# This module adds 3 new fields to the basic ConfigFile object.  The fields
# are 'gid', 'gpass', and 'group'.  All three of these fields are hashes.
# The gid field maps names to GIDs.  The gpass field maps names to passwords.
# The group fields maps GIDs to another hash of group members.  There are
# no real values in the group subhash, just a '1' as a placeholder.  This is
# a hash instead of a list because it makes duplicate elimination and user
# deletion much easier to deal with.

# Preloaded methods go here.

# Read in the data structures from the supplied file
sub read {
    my ($this, $fh) = @_;

    while (<$fh>) {
	chop;
	my ($name, $password, $gid, $users) = split /:/;
	my @users = split /,/, $users;
	if (defined $this->{group}{$gid}) {
	    foreach (@users) {
		$this->{group}{$gid}{$_} = 1;
	    }
	}
	else {
	    $this->group($name, $password, $gid, @users);
	}
    }
    return 1;
}


# Add, modify, or get a group
sub group {
    my $this = shift;
    my $name = shift;

    # If no more parameters, we return group info
    unless (@_) {
	my $gid = $this->gid($name);
	return undef unless defined $gid;
	return ($this->passwd($name), $gid, $this->members($name));
    }

    # Create or modify a group
    return undef if @_ < 2;
    my $password = shift;
    my $gid = shift;

    # Have to be careful with this test - 0 is a legitimate return value
    return undef unless defined $this->gid($name, $gid);
    $this->passwd($name, $password);
    $this->members($name, @_);
    return ($gid, $password, $this->members($name));
}


# Delete a group
sub delete {
    my ($this, $name) = @_;

    my $gid = $this->gid($name);
    return 0 unless defined $gid;
    delete $this->{gpass}{$name};
    delete $this->{group}{$gid};
    delete $this->{gid}{$name};
    return 1;
}


# Add users to an existing group
sub add_user {
    my $this = shift;
    my $name = shift;
    my @groups = ($name eq "*") ? $this->groups : ($name);

    foreach (@groups) {
	my $gid = $this->gid($_);
	return 0 unless defined $gid;
	foreach my $user (@_) {
	    $this->{group}{$gid}{$user} = 1;
	}
    }
    return 1;
}


# Remove users from an existing group
sub remove_user {
    my $this = shift;
    my $name = shift;
    my @groups = ($name eq "*") ? $this->groups : ($name);

    foreach (@groups) {
	my $gid = $this->gid($_);
	return 0 unless defined $gid;
	foreach my $user (@_) {
	    delete $this->{group}{$gid}{$user};
	}
    }
    return 1;
}


# Rename a user
sub rename_user {
    my ($this, $oldname, $newname) = @_;

    my $count = 0;
    foreach ($this->groups) {
	my $gid = $this->gid($_);
	if (exists $this->{group}{$gid}{$oldname}) {
	    delete $this->{group}{$gid}{$oldname};
	    $this->{group}{$gid}{$newname} = 1;
	    $count++;
	}
    }
    return $count;
}


# Return the list of groups
# Accepts a sorting order parameter: gid or name (default gid)
sub groups {
    my $this = shift;
    my $order = @_ ? shift : "gid";

    return keys %{$this->{gid}} unless wantarray;
    if ($order eq "name") {
	return sort keys %{$this->{gid}};
    }
    else {
	return sort { $this->gid($a) <=> $this->gid($b) } keys %{$this->{gid}};
    }
}


# Returns the maximum GID in use in the file
sub maxgid {
    my $this = shift;
    my @gids = sort { $a <=> $b } keys %{$this->{group}};
    return pop @gids;
}


# Output the file to disk
sub write {
    my ($this, $fh) = @_;

    foreach my $name ($this->groups) {
	my @users = $this->members($name);
	my $head = join(":", $name, $this->passwd($name), $this->gid($name), "");
	my $ind = join(":", "$name%n", $this->passwd($name), $this->gid($name), "");
	print $fh $this->joinwrap($MAXLINELEN, $head, $ind, ",", "", @users),
		"\n" or return 0;
    }
    return 1;
}


# Accessors (these all accept a group name and an optional value)
sub passwd {
    my $this = shift;
    my $name = shift;
    @_ ? $this->{gpass}{$name} = shift : $this->{gpass}{$name};
}


# Note that it is illegal to change a group's GID to one used by another group
# This method also has to take into account side effects produced by doing
# this, such as the fact that the member hash is keyed against the GID.
sub gid {
    my $this = shift;
    my $name = shift;

    return $this->{gid}{$name} unless @_;
    my $newgid = shift;
    my $oldgid = $this->{gid}{$name};
    # Return OK if you try to set the same GID a group already has
    return $oldgid if defined $oldgid && $newgid == $oldgid;
    return undef if grep { $newgid == $_ } values %{$this->{gid}};
    if (defined $oldgid) {
	$this->{group}{$newgid} = $this->{group}{$oldgid};
	delete $this->{group}{$oldgid};
    }
    $this->{gid}{$name} = $newgid;
}


# Return or set the list of users in a group
sub members {
    my $this = shift;
    my $name = shift;

    my $gid = $this->gid($name);
    return undef unless defined $gid;
    if (@_) {
	$this->{group}{$gid} = { };
	$this->add_user($name, @_);
    }
    return keys %{$this->{group}{$gid}} unless wantarray;
    return sort keys %{$this->{group}{$gid}};
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Unix::GroupFile - Perl interface to /etc/group format files

=head1 SYNOPSIS

  use Unix::GroupFile;

  $grp = new Unix::GroupFile "/etc/group";
  $grp->group("bozos", "*", $grp->maxgid + 1, @members);
  $grp->remove_user("coolgrp", "bgates", "badguy");
  $grp->add_user("coolgrp", "joecool", "goodguy");
  $grp->remove_user("*", "deadguy");
  $grp->passwd("bozos", $grp->encpass("newpass"));
  $grp->commit();
  undef $grp;

=head1 DESCRIPTION

The Unix::GroupFile module provides an abstract interface to /etc/group format
files.  It automatically handles file locking, getting colons and commas in
the right places, and all the other niggling details.

This module also handles the annoying problem (at least on some systems) of
trying to create a group line longer than 512 characters.  Typically this is
done by creating multiple lines of groups with the same GID.  When a new
GroupFile object is created, all members of groups with the same GID are
merged into a single group with a name corresponding to the first name found
in the file for that GID.  When the file is committed, long groups are written
out as multiple lines of no more than 512 characters, with numbers appended to
the group name for the extra lines.

=head1 METHODS

=head2 add_user( GROUP, @USERS )

This method will add the list of users to an existing group.  Users that are
already members of the group are silently ignored.  The special group name *
will add the users to every group.  Returns 1 on success or 0 on failure.

=head2 commit( [BACKUPEXT] )

See the Unix::ConfigFile documentation for a description of this method.

=head2 delete( GROUP )

This method will delete the named group.  It has no effect if the supplied
group does not exist.

=head2 encpass( PASSWORD )

See the Unix::ConfigFile documentation for a description of this method.

=head2 gid( GROUP [,GID] )

Read or modify a group's GID.  Returns the GID in either case.  Note that it
is illegal to change a group's GID to a GID that is already in use by another
group.  In this case, the method returns undef.

=head2 group( GROUP [,PASSWD, GID, @USERS] )

This method can add, modify, or return information about a group.  Supplied
with a single group parameter, it will return a list consisting of (PASSWORD,
GID, @MEMBERS), or undef if no such group exists.  If you supply at least
three parameters, the named group will be created or modified if it already
exists.  The list is also returned to you in this case.  Note that it is
illegal to specify a GID that is already in use by another group.  In this
case, the method returns undef.

=head2 groups( [SORTBY] )

This method returns a list of all existing groups.  By default the list will
be sorted in order of the GIDs of the groups.  You may also supply "name" as a
parameter to the method to get the list sorted by group name.  In scalar
context, this method returns the total number of groups.

=head2 maxgid( )

This method returns the maximum GID in use by all groups.

=head2 members( GROUP [,@USERS] )

Read or modify the list of members associated with a group.  If you specify
any users when you call the method, all existing members of the group are
removed and your list becomes the new set of members.  In scalar context,
this method returns the total number of members in the group.

=head2 new( FILENAME [,OPTIONS] )

See the Unix::ConfigFile documentation for a description of this method.

=head2 passwd( GROUP [,PASSWD] )

Read or modify a group's password.  Returns the encrypted password in either
case.  If you have a plaintext password, use the encpass method to encrypt it
before passing it to this method.

=head2 remove_user( GROUP, @USERS )

This method will remove the list of users from an existing group.  Users that
are not members of the group are silently ignored.  The special group name *
will remove the users from every group.  Returns 1 on success or 0 on failure.

=head2 rename_user( OLDNAME, NEWNAME )

This method will change one username to another in every group.  Returns the
number of groups affected.

=head1 AUTHOR

Steve Snodgrass, ssnodgra@fore.com

=head1 SEE ALSO

Unix::AliasFile, Unix::AutomountFile, Unix::ConfigFile, Unix::PasswdFile

=cut
