package Unix::AliasFile;

# $Id: AliasFile.pm,v 1.5 2000/05/02 15:50:11 ssnodgra Exp $

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Unix::ConfigFile;
use Text::ParseWords;

require Exporter;

@ISA = qw(Unix::ConfigFile Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.06';

# Implementation Notes
#
# This module adds one field to the basic ConfigFile object.  The field
# is called 'alias' and is a hash of hashes.  The key is the alias name and
# the subhash contains members of the alias as keys.  The values of those
# keys are normally just '1', but may be object references in the case of
# :include: aliases.  The module also makes use of the file sequencing
# facility provided by ConfigFile to preserve comments and keep the file in
# its original order.

# Preloaded methods go here.

# Read in the data structures from the supplied file
sub read {
    my ($this, $fh) = @_;

    my $alias = "";	# Current alias being processed
    while (<$fh>) {
	if (/^#/ || /^$/) {		    # Comments/Blank Lines
	    $this->seq_append($_);
	}
	elsif (/^[^\s]/) {		    # Alias start
	    s/,?\s*$//;
	    ($alias, my $rhs) = split /:\s*/, $_, 2;

	    # I use the parse_line routine from Text::ParseWords here because
	    # a simple split would hose program aliases with embedded commas.
	    # Note that this routine does not exist prior to 5.005, so older
	    # perl versions will have the comma bug.
	    my @members;
	    if ($] >= 5.005) {
		@members = parse_line(',\s*', 1, $rhs);
	    }
	    else {
		@members = split /,\s*/, $rhs;
	    }

	    # This weird little hack fixes a bug that caused empty aliases
	    # to be deleted when the file was read, since the alias method
	    # won't actually create an empty alias.
	    $this->alias($alias, "empty");
	    $this->remove_user($alias, "empty");
	    $this->alias($alias, @members);
	}
	elsif (/^\s+$/) {		    # Junk whitespace
	    $this->seq_append("\n");
	}
	elsif (/^\s+/ && $alias) {	    # Alias continuation
	    s/,?\s*$//;
	    s/^\s+//;
	    if ($] >= 5.005) {
		$this->add_user($alias, parse_line(',\s*', 1, $_));
	    }
	    else {
		$this->add_user($alias, split /,\s*/);
	    }
	}
	else {				    # What's this?
	    die "Bogus line: $_";
	}
    }
    return 1;
}


# Add, modify or get an alias
sub alias {
    my $this = shift;
    my $name = shift;

    # If no more parameters, we return alias members
    unless (@_) {
	return undef unless defined $this->{alias}{$name};
	return keys %{$this->{alias}{$name}} unless wantarray;
	return sort keys %{$this->{alias}{$name}};
    }

    # Create or modify an alias
    $this->seq_append("_ALIAS_ $name") unless defined $this->{alias}{$name};
    $this->{alias}{$name} = {};
    $this->add_user($name, @_);
    return keys %{$this->{alias}{$name}} unless wantarray;
    return sort keys %{$this->{alias}{$name}};
}


# Delete an alias
sub delete {
    my ($this, $name) = @_;

    return 0 unless defined $this->{alias}{$name};
    $this->seq_remove("_ALIAS_ $name");
    delete $this->{alias}{$name};
    return 1;
}


# Delete aliases with no members
sub delempty {
    my $this = shift;

    my $count = 0;
    foreach my $name ($this->aliases) {
	unless ($this->alias($name)) {
	    $this->delete($name);
	    $count++;
	}
    }
    return $count;
}


# Add users to an existing alias
sub add_user {
    my $this = shift;
    my $name = shift;
    my @aliases = ($name eq "*") ? $this->aliases : ($name);

    foreach (@aliases) {
	return 0 unless defined $this->{alias}{$_};
	foreach my $user (@_) {
	    $this->{alias}{$_}{$user} = 1;
	}
    }
    return 1;
}


# Remove users from an existing alias
sub remove_user {
    my $this = shift;
    my $name = shift;
    my @aliases = ($name eq "*") ? $this->aliases : ($name);

    foreach (@aliases) {
	return 0 unless defined $this->{alias}{$_};
	foreach my $user (@_) {
	    delete $this->{alias}{$_}{$user};
	}
    }
    return 1;
}


# Rename a user
sub rename_user {
    my ($this, $oldname, $newname) = @_;

    my $count = 0;
    foreach ($this->aliases) {
	if (exists $this->{alias}{$_}{$oldname}) {
	    delete $this->{alias}{$_}{$oldname};
	    $this->{alias}{$_}{$newname} = 1;
	    $count++;
	}
    }
    return $count;
}


# Return the list of aliases
sub aliases {
    my $this = shift;
    wantarray ? sort keys %{$this->{alias}} : keys %{$this->{alias}};
}


# Add a comment before an alias
sub comment {
    my ($this, $name, @cmnt) = @_;
    grep { chomp; s/$/\n/; } @cmnt;
    return $this->seq_insert("_ALIAS_ $name", @cmnt);
}


# Remove a comment
sub uncomment {
    my ($this, $cmnt) = @_;
    chomp $cmnt;
    $cmnt =~ s/$/\n/;
    return $this->seq_remove($cmnt);
}


# Output file to disk
sub write {
    my ($this, $fh) = @_;

    foreach my $seq ($this->sequence) {
	unless ($seq =~ /^_ALIAS_ ([^\s]+)$/) {
	    print $fh $seq or return 0;
	    next;
	}
	my $name = $1;
	my @users = $this->alias($name);
	next if !defined @users;
	print $fh $this->joinwrap(80, "$name: ", "\t", ",", ",", @users), "\n"
		or return 0;
    }
    return 1;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Unix::AliasFile - Perl interface to /etc/aliases format files

=head1 SYNOPSIS

  use Unix::AliasFile;

  $al = new Unix::AliasFile "/etc/aliases";
  $al->alias("bozos", @members);
  $al->delete("deadlist");
  $al->remove_user("coolmail", "bgates", "badguy");
  $al->add_user("coolmail", "joecool", "goodguy");
  $al->remove_user("*", "deadguy");
  $al->commit();
  undef $al;

=head1 DESCRIPTION

The Unix::AliasFile module provides an abstract interface to Unix alias files.
It automatically handles file locking, getting colons and commas in the right
places, and all the other niggling details.

Unlike some of the other Unix::*File modules, this module will preserve the
order of your alias file, with a few exceptions.  Comments and aliases will
appear in the file in the same order that they started in, unless you have
comment lines interspersed between the beginning of an alias and continuation
lines for that same alias.  In this case, those comments will appear after the
alias that contains them.

=head1 METHODS

=head2 add_user( ALIAS, @USERS )

This method will add the list of users to an existing alias.  Users that are
already members of the alias are silently ignored.  The special alias name *
will add the users to every alias.  Returns 1 on success or 0 on failure.

=head2 alias( ALIAS [,@USERS] )

This method can add, modify, or return information about an alias.  Supplied
with a single alias parameter, it will return a list consisting of the members
of that alias, or undef if no such alias exists.  If you supply more
parameters, the named alias will be created or modified if it already exists.
The member list is also returned to you in this case.

=head2 aliases( )

This method returns a list of all existing aliases.  The list will be sorted
in alphabetical order.  In scalar context, this method returns the total
number of aliases.

=head2 comment( ALIAS, COMMENT )

This method inserts a comment line before the specified alias.  You must
supply your own comment marker (#) but a newline will be automatically
appended to the comment unless it already has one.  Returns 1 on success
and 0 on failure.

=head2 commit( [BACKUPEXT] )

See the Unix::ConfigFile documentation for a description of this method.

=head2 delempty( )

This method will delete all existing aliases that have no members.  It returns
a count of how many aliases were deleted.

=head2 delete( ALIAS )

This method will delete the named alias.  It has no effect if the supplied
alias does not exist.

=head2 new( FILENAME [,OPTIONS] )

See the Unix::ConfigFile documentation for a description of this method.

=head2 remove_user( ALIAS, @USERS )

This method will remove the list of users from an existing alias.  Users that
are not members of the alias are silently ignored.  The special alias name *
will remove the users from every alias.  Returns 1 on success or 0 on failure.

=head2 rename_user( OLDNAME, NEWNAME )

This method will change one username to another in every alias.  Returns the
number of aliases affected.

=head2 uncomment( COMMENT )

Remove the comment from the file that matches the supplied text.  The match
must be exact.  Returns 1 on success and 0 on failure.

=head1 BUGS

While the Unix::AliasFile module will work with Perl versions prior to 5.005,
it may exhibit a minor bug under those versions.  The bug will cause program
aliases with embedded comma characters to be broken apart.  This will not
happen under 5.005 and up, due to the use of the Text::ParseWords module,
which changed significantly with the 5.005 release.

=head1 AUTHOR

Steve Snodgrass, ssnodgra@fore.com

=head1 SEE ALSO

Unix::AutomountFile, Unix::ConfigFile, Unix::GroupFile, Unix::PasswdFile

=cut
