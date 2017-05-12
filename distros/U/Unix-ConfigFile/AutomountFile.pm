package Unix::AutomountFile;

# $Id: AutomountFile.pm,v 1.4 2000/05/02 15:50:36 ssnodgra Exp $

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

# Implementation Notes
#
# This module adds 2 new fields to the basic ConfigFile object.  The fields
# are 'mount' and 'options'.  Both of these fields are hashes.  The mount
# field is a hash of lists, where each list contains the possible server
# mount points for the key, and the options field contains any options
# associated with the key.  The options field may not be defined if no
# options were present.

# Preloaded methods go here.

# Read in the data structures from the supplied file
sub read {
    my ($this, $fh) = @_;

    while (<$fh>) {
	chop;
	# Currently we nuke comments and blank lines.  This may change.
	next if /^#/;
	next if /^$/;
	my @fields = split;
	my $key = shift @fields;
	my $options = undef;
	if ($fields[0] =~ /^-/) {
	    $options = shift @fields;
	}
	$this->automount($key, @fields);
	$this->options($key, $options);
    }
    return 1;
}


# Add, modify, or get an automount point
sub automount {
    my $this = shift;
    my $key = shift;

    # If no more parameters, we return automount info
    unless (@_) {
	return undef unless defined $this->{mount}{$key};
	return @{$this->{mount}{$key}} unless wantarray;
	return sort @{$this->{mount}{$key}};
    }
    $this->{mount}{$key} = [ @_ ];
    $this->{options}{$key} = undef;
    return @{$this->{mount}{$key}} unless wantarray;
    return sort @{$this->{mount}{$key}};
}


# Delete an automount entry
sub delete {
    my ($this, $key) = @_;

    return 0 unless defined $this->{mount}{$key};
    delete $this->{mount}{$key};
    delete $this->{options}{$key};
    return 1;
}


# Renames an automount entry
sub rename {
    my ($this, $oldname, $newname) = @_;

    return 0 unless exists $this->{mount}{$oldname};
    $this->{mount}{$newname} = $this->{mount}{$oldname};
    $this->{options}{$newname} = $this->{options}{$oldname};
    $this->delete($oldname);
    return 1;
}


# Add servers to an existing automount entry
sub add_server {
    my $this = shift;
    my $key = shift;

    return 0 unless defined $this->{mount}{$key};
    push @{$this->{mount}{$key}}, @_;
    return 1;
}


# Return the list of automount entries
sub automounts {
    my $this = shift;

    return keys %{$this->{mount}} unless wantarray;
    return sort keys %{$this->{mount}};
}


# Output file to disk
sub write {
    my ($this, $fh) = @_;

    foreach my $key ($this->automounts) {
	print $fh "$key\t" or return 0;
	if (defined $this->options($key)) {
	    print $fh $this->options($key), "\t" or return 0;
	}
	print $fh join(" ", $this->automount($key)), "\n" or return 0;
    }
    return 1;
}


# Set or return mount options
sub options {
    my $this = shift;
    my $key = shift;
    return undef unless defined $this->{mount}{$key};
    @_ ? $this->{options}{$key} = shift : $this->{options}{$key};
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Unix::AutomountFile - Perl interface to automounter files

=head1 SYNOPSIS

  use Unix::AutomountFile;

  $am = new Unix::AutomountFile "/etc/auto_home";
  $am->automount("newuser", "fileserver:/export/home/&");
  $am->options("newuser", "-rw,nosuid");
  $am->delete("olduser");
  $am->commit();
  undef $am;

=head1 DESCRIPTION

The Unix::AutomountFile module provides an abstract interface to automounter
files.  It automatically handles file locking, getting colons and commas in
the right places, and all the other niggling details.  WARNING: This module is
probably Solaris specific at this point.  I have only looked at Solaris format
automount files thus far.  Also, you cannot edit /etc/auto_master with this
module, since it is in a different format than the other automount files.

=head1 METHODS

=head2 add_server( MOUNT, @SERVERS )

This method will add additional servers to an existing automount point.  It
returns 1 on success and 0 on failure.

=head2 automount( MOUNT [,@SERVERS] )

This method can add, modify, or return information about a mount point.
Supplied with a single mount parameter, it will return a list of the server
entries for that mount point, or undef if no such mount exists.  If you supply
more than one parameter, the mount point will be created or modified if it
already exists.  The list is also returned to you in this case.

=head2 automounts( )

This method returns a list of all existing mount points, sorted
alphabetically.  In scalar context, this method returns the total number of
mount points.

=head2 commit( [BACKUPEXT] )

See the Unix::ConfigFile documentation for a description of this method.

=head2 delete( MOUNT )

This method will delete the named mount point.  It has no effect if the
supplied mount point does not exist.

=head2 new( FILENAME [,OPTIONS] )

See the Unix::ConfigFile documentation for a description of this method.

=head2 options( MOUNT [,OPTIONS] )

Read or modify the mount options associated with a mount point.  Returns the
options in either case.

=head2 rename( OLDNAME, NEWNAME )

Renames a mount point.  If NEWNAME corresponds to an existing mount point,
that mount point is overwritten.  Returns 0 on failure and 1 on success.

=head1 AUTHOR

Steve Snodgrass, ssnodgra@fore.com

=head1 SEE ALSO

Unix::AliasFile, Unix::ConfigFile, Unix::GroupFile, Unix::PasswdFile

=cut
