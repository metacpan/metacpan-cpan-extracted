###############################################################################
#
#         May be distributed under the terms of the artistic license
#
#                  Copyright @ 1998, Hewlett-Packard, Inc.,
#                            All Rights Reserved
#
###############################################################################
#
#   @(#)$Id: Access.pm,v 1.3 1999/08/11 00:19:23 idsweb Exp $
#
#   Description:    Components to read and write access control lists (ACLs)
#                   for the client-side release manager tools.
#
#                   Eventually, I want to move to a model of another table
#                   within the same Oracle DB that is used for mirror specs
#                   and other RlsMgr-related data. For now, ACLs are
#                   implemented as one file per host, named as such, all
#                   stored under $ACL_DIR.
#
#   Functions:      ACL_dir
#                   ACL_get
#                   ACL_put
#
#   Libraries:      None.
#
#   Global Consts:  $VERSION            Version information for this module
#                   $revision           Copy of the RCS revision string
#                   $ACL_DIR            Pseudo-constant (can be set by calling
#                                         ACL_dir) defining the dir in which
#                                         the files reside.
#
#   Environment:    None.
#
###############################################################################
package IMS::ReleaseMgr::Access;

use 5.002;
use strict;
use vars qw($VERSION $revision @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
            $ACL_DIR $ACL_ERROR);
use subs qw(ACL_dir ACL_error ACL_get ACL_put);

use AutoLoader 'AUTOLOAD';

require Exporter;
require IO::File;

$VERSION = do {my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d"x$#r,@r};
$revision = q$Id: Access.pm,v 1.3 1999/08/11 00:19:23 idsweb Exp $;

@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(ACL_dir ACL_error ACL_get ACL_put);
%EXPORT_TAGS = ();

$ACL_DIR = '/opt/ims/local/acl';
# This is used to preserve error messages, and is readable via ACL_error
$ACL_ERROR = '';

1;

###############################################################################
#
#   Sub Name:       ACL_dir
#
#   Description:    Return the current value of $ACL_DIR. If there is a non-
#                   reference argument passed, then set $ACL_DIR to the new
#                   value and return the old value.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $dir      in      scalar    If passed, sets the value of
#                                                 $ACL_DIR
#
#   Globals:        $ACL_DIR
#
#   Environment:    None.
#
#   Returns:        Current value of $ACL_DIR, even if it being re-set.
#
###############################################################################
sub ACL_dir
{
    my $dir = shift;

    my $ret_val = $ACL_DIR;
    $ACL_DIR = $dir if (defined $dir and ! ref($dir));

    $ret_val;
}

__END__

###############################################################################
#
#   Sub Name:       ACL_get
#
#   Description:    Read the ACL file for the specified host and return a hash
#                   reference keyed by projects. See the documentation for the
#                   structure of the returned data.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $host     in      scalar    Host name to do a lookup on
#
#   Globals:        None. (uses access methods instead)
#
#   Environment:    None.
#
#   Returns:        Success:    hashref
#                   Failure:    undef, error message available via ::error
#
###############################################################################
sub ACL_get
{
    my $host = shift;

    unless (defined $host and $host)
    {
        ACL_error 'ACL_get: No host specified to read from';
        return undef;
    }

    #
    # If $host is already an absolute path, skip this. Otherwise, prepend the
    # current ACL directory.
    #
    unless ($host =~ m|^/|)
    {
        $host = sprintf("%s/$host", ACL_dir);
    }

    my $fh = new IO::File "< $host";
    if (! defined($fh))
    {
        ACL_error "ACL_get: Could not open $host for reading: $!";
        return undef;
    }

    my $acl = {};
    my ($name, $users, $email, $owner, $owner_email, $comments);

    while (defined($_ = <$fh>))
    {
        # Skip blank lines and comments
        next if /^\s*$/;
        next if /^\s*\#/;

        ($name, $users, $email, $owner, $owner_email, $comments) =
            split(/:/, $_, 6);

        #$acl->{lc $name} = { #lowercase is causing release problems here
        $acl->{$name} = {
                            NAME          => lc $name,
                            USERS         => lc $users,
                            EMAIL         => lc $email,
                            OWNER         => lc $owner,
                            OWNER_EMAIL   => lc $owner_email,
                            COMMENTS      => $comments
                           };
    }
    $fh->close;

    $acl;
}

###############################################################################
#
#   Sub Name:       ACL_put
#
#   Description:    Write the ACL table specified in $acl to the file specified
#                   in $host (which is considered relative to $ACL_DIR). Don't
#                   prepend $ACL_DIR if $host is an absolute path.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $acl      in      hashref   An ACL, probably read in by
#                                                 ACL_get
#                   $host     in      scalar    The file to write to.
#
#   Globals:        None. (uses access methods instead)
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
###############################################################################
sub ACL_put
{
    my ($acl, $host) = (shift, shift);

    ACL_error 'ACL_put: not implemented yet';
    0;
}

###############################################################################
#
#   Sub Name:       ACL_error
#
#   Description:    Return/set the value of $ACL_ERROR
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $err      in      scalar    If passed, sets $ACL_ERROR and
#                                                 causes a void return value.
#
#   Globals:        $ACL_ERROR
#
#   Environment:    None.
#
#   Returns:        Current error string if called with no args, void if called
#                   to set the error string.
#
###############################################################################
sub ACL_error
{
    my $err = shift;

    if (defined $err and $err)
    {
        $ACL_ERROR = $err;
        return;
    }

    $ACL_ERROR;
}

=head1 NAME

IMS::ReleaseMgr::Access - A small module to abstract the Access Control Lists

=head1 SYNOPSIS

    use IMS::ReleaseMgr::Access qw(ACL_get ACL_error);

    $acl = ACL_get('www.interactive.hp.com');
    unless (defined $acl)
    {
        die ACL_error;
    }

=head1 DESCRIPTION

The access control lists (ACLs) are the means by which the client-side release
manager tools mediate which users have permission to release which projects.
Access is managed on a per-host-per-project basis; that is, a person may be
given permission to release project "commcenter" on the host
B<www.interactive.hp.com> without being given permission to release other
projects on that same host, or even be given permission to release that
particular project on other, different hosts.

The ACLs are currently implemented as plain-text files using lines that are
colon-delimited. Future plans include moving this information to a database
platform such as Oracle.

=head1 SUBROUTINES

The following subroutines are provided and may be imported. None are imported
by default, so a program using this library needs to explicitly specify which
components are to be used:

=over

=item ACL_dir [ B<$dir> ]

Return the current directory in which the B<IMS::ReleaseMgr::Access> library
expects to find the host files. This is used whenever a read request is made,
unless the parameter passed to ACL_get (see below) is an absolute path.
If B<ACL_dir> is passed a string argument, then the default directory is set
to the new value, and the return value is the I<old> value.

=item ACL_get B<$host>

Read the ACL specified in the parameter B<$host>. If $host is an absolute file
pathname, it is opened directly. Otherwise, the current value of B<ACL_dir> is
prepended to it. The return value is a hash reference whose keys are the names
of the projects specified in the ACL file. Should an error occur, the special
value B<undef> is returned, and the error message may be retrieved via the
B<ACL_error> routine described below. See the section on FORMAT for a 
description of the ACL data format.

=item ACL_put B<$acl>, B<$host>

This is not yet implemented. In the future, it will dump the ACL specified in
the parameter B<$acl> to a host file specified in B<$host>. At present, it
immediately returns an error value of 0 with a message in B<ACL_error>.

=item ACL_error

This returns the current value of the internal error message string. All
operations clear the error string upon success, so there is no danger of 
getting a stale error message.

=back

=head1 FORMAT

When an ACL is returned by the "read" operation, it is expressed as a hash
table reference whose keys are the names of projects that can be released to
the specified host. The value that corresponds to each of these keys is also a
hash table reference with the following key/value pairs:

=over

=item NAME

The project name. This name need only be unique within the scope of a given
host ACL file. It is not recommended that the same name be used to refer to
different projects on different hosts, however. This is the name by which
users refer to the project for B<populate>, B<stage> and B<release> operations.

=item USERS

A list of one or more users permitted to release the project. The names (if
there are more than one) are comma-separated (no intervening whitespace between
names). This list is only consulted for the B<release> operation. Anyone can
still perform the other operations, provided they have sufficient permissions
on the relevant files.

=item EMAIL

A list of e-mail addresses to which notification of a release is sent. This
may be blank if so desired. These addresses are also attached to the outgoing
release package so as to be included on any e-mail sent by the server-side
release tools.

=item OWNER

The name (generally not the user ID) of the person currently considered the
project "owner".

=item OWNER_EMAIL

The email address for the owner.

=item COMMENTS

This is an optional sixth field in the ACL file. It is not used anywhere
programatically, but servers to make the ACL file itself a little more
understandable to the casual reader.

=back

To access the B<USERS> field for a project B<$project>, one would do:

    $users = $acl->{$project}->{USERS};

(Assuming that B<$acl> is the valid return value from a call to
B<ACL_get>).

=head1 AUTHOR

Randy J. Ray <randyr@nafohq.hp.com>

=head1 SEE ALSO

L<IMS::ReleaseMgr>, L<IMS::ReleaseMgr::Utils>, L<perl>

=cut
