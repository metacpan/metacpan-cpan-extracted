package VCI::VCS::Git;
use Moose;
our $VERSION = '0.7.1';

# Assure that we die immediately upon use if somebody tries to use us
# without the proper prerequisite installed.
use Git;

extends 'VCI';


__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::VCS::Git - Object-oriented interface to Git

=head1 SYNOPSIS

 use VCI;
 my $repository = VCI->connect(type => 'Git', repo => 'path/above/clone/');

=head1 DESCRIPTION

This is a "driver" for L<VCI> for the Git version-control system.
You can find out more about Git at L<http://git-scm.com/>.

For information on how to use VCI::VCS::Git, see L<VCI>.

Due to the design of Git, VCI::VCS::Git is limited to interacting with
local repositories. Limited interaction with remote repositories may be
possible in the future, depending on what is desired from VCI users.

=head1 CONNECTING TO A GIT REPOSITORY

For the L<repo|VCI/repo> argument to L<VCI/connect>, choose the directory
above where your projects are kept. For example, if you have a project
whose path is C</var/git/project>, then the C<repo> would be C</var/git/>.

=head1 REVISION IDENTIFIERS

Commit, File, and Directory objects use the full sha1 id of the Commit
(not the abbreviated sha1 hash) as their identifier.

=head1 TAINT SAFETY

C<VCI::VCS::Git> is not yet safe to use in taint mode. It currently
uses C<Git.pm>, which is not itself taint-safe.

=head1 LIMITATIONS AND EXTENSIONS

These are limitations of VCI::VCS::Git compared to the general API specified
in the C<VCI::Abstract> modules.

=head2 VCI::VCS::Git

You can only C<connect> to a local repository. Remote repositories are not
supported.

=head2 VCI::VCS::Repository

C<projects> generates the list of projects by finding all directories in the
repository that have F<.git> directories in them (or directories that are
a "bare" repository). So if there are projects further down in the
directory hierarchy, they won't be found.

=head2 VCI::VCS::Directory

Calling C<first_revision> or C<last_revision> on a Directory will fail,
as Directories are not tracked in any History. (This may be fixed in a
future version.)

=head1 PERFORMANCE

Git itself is extremely fast, but many optimizations have not yet been
implemented in VCI itself. However, VCI::VCS::Git should still be fairly
fast on all operations for medium-sized repositories (under 10000
commits and with under 10000 files).

=head1 SEE ALSO

L<VCI>

=head1 AUTHOR

Max Kanat-Alexander <mkanat@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Everything Solved, Inc.

L<http://www.everythingsolved.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
