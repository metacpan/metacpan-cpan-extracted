package VCI::VCS::Svn::FileOrDirectory;
use Moose;

# The existence of this class is a hack, because SVN doesn't provide us with
# a way of getting the "kind" of a file from its history logs, and we don't
# want to do an "info" call on every single file in every single commit
# just to find out what it is.

extends 'VCI::VCS::Svn::File', 'VCI::VCS::Svn::Directory';

__PACKAGE__->meta->make_immutable;

1;
