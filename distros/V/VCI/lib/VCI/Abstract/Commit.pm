package VCI::Abstract::Commit;
use Moose;
use VCI::Util;
use Digest::MD5 qw(md5_hex);

# XXX ProjectItem should really be composed by FileContainer, but see the
#     note there.
with 'VCI::Abstract::FileContainer', 'VCI::Abstract::ProjectItem';

# All of this crazy init_arg stuff means "coerce lazily, because
# DateTime is slow."
has 'time'       => (is => 'ro', isa => 'VCI::Type::DateTime', coerce => 1,
                     lazy => 1,
                     default => sub { shift->_time }, init_arg => '__time');
has '_time'      => (is => 'ro', isa => 'Defined', init_arg => 'time',
                     required => 1);

has 'author'    => (is => 'ro', isa => 'Str', lazy_build => 1);
has 'committer' => (is => 'ro', isa => 'Str', default => sub { '' });
has 'added'     => (is => 'ro', isa => 'ArrayRef[VCI::Abstract::Committable]',
                    lazy_build => 1);
has 'removed'   => (is => 'ro', isa => 'ArrayRef[VCI::Abstract::Committable]',
                    lazy_build => 1);
has 'modified'  => (is => 'ro', isa => 'ArrayRef[VCI::Abstract::Committable]',
                    lazy_build => 1);
has 'moved'     => (is => 'ro', isa => 'HashRef[VCI::Abstract::Committable]',
                    lazy_build => 1);
has 'copied'    => (is => 'ro', isa => 'HashRef[VCI::Abstract::Committable]',
                    lazy_build => 1);
has 'revision'  => (is => 'ro', isa => 'Str', required => 1);
has 'revno'     => (is => 'ro', isa => 'Str', lazy_build => 1);
# XXX Probably should also have shortmessage, which can be the "subject"
#     for VCSes that store that, and the first line of the message for
#     VCSes that don't.
has 'message'   => (is => 'ro', isa => 'Str', default => sub { '' });
has 'uuid'      => (is => 'ro', isa => 'Str', lazy_build => 1);

has 'as_diff'  => (is => 'ro', isa => 'VCI::Abstract::Diff', lazy_build => 1);

sub _build_removed   { [] }
sub _build_modified  { [] }
sub _build_moved     { {} }
sub _build_copied    { {} }

sub _build_contents {
    my $self = shift;
    return [@{$self->added}, @{$self->removed}, @{$self->modified}];
}

sub _build_author { shift->committer }
sub _build_revno  { shift->revision  }

sub _build_uuid {
    my ($self) = @_;
    if ($self->vci->revisions_are_universal) {
        return $self->revision;
    }

    my @pieces = ($self->_repository_for_uuid, $self->revision);
    if (!$self->vci->revisions_are_global) {
        push(@pieces, $self->project->name);
    }
    utf8::downgrade($_) foreach @pieces;
    return md5_hex(@pieces);
}

sub _repository_for_uuid {
    my ($self) = @_;
    # Many VCSes allow access over URIs, where you can specify
    # a username and password in the URI. However, no matter what credentials
    # you use to access a repository, it's still the same repo, so we
    # shouldn't take those credentials into account when creating the UUID.
    #
    # bzr can have "+" in the protocol identifiers, so we allow that.
    my $repo = $self->repository->root;
    $repo =~ s{^([A-Za-z\+]+://)[^/]+@}{$1};
    return $repo;
}

# as_patch, as_bundle
# Also as_patch_binary, as_bundle_binary?
# And perhaps as_diff_from, as_bundle_from

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::Abstract::Commit - Represents a single atomic commit to the repository.

=head1 DESCRIPTION

Usually, when you modify a repository in version control, you modify many
files simultaneously in a single "commit" (also called a "checkin").

This object represents one of those commits in the history of a project.

Some version-control systems don't actually understand the idea of an
"atomic commit" (meaning they don't understand that certain changes
were all committed simultaneously), but VCI does its best to figure out
what files were committed together and represent them all as one object.

A L<VCI::Abstract::Commit> implements L<VCI::Abstract::FileContainer>,
so all of FileContainer's methods are also available here.

B<Note>: Depending on how this object was constructed, it may or may
not actually contain information on all of the files that were committed
in this change. For example, when you use L<VCI::Abstract::File/history>, Commit
objects might only contain information about that single file. This is
due to the limits of various version-control systems.

=head1 METHODS

=head2 Accessors

These are all read-only.

=over

=item C<time>

A L<datetime|VCI::Util/VCI::Type::DateTime> representing the date and time of
this commit.

On VCSes that don't understand atomic commits, this will be the time of
the I<earliest> commited file in this set.

=item C<committer>

A string identifying who committed this revision. That is, the username
of the committer, or their real name and email address (or something
similar). The format of this string is not guaranteed.

=item C<author>

Some VCSes differentiate between the person who wrote a patch, and the
person who committed it. For VCSes that understand this difference, this
is a string identifying who wrote the patch, in a simialr format to
L</committer>.

For VCSes that don't understand the concept of "author" (or for
commits where the "author" field isn't set), this is identical to
L</committer>.

=item C<contents>

All of the items added, removed, or modified in this commit, as an arrayref
of L<VCI::Abstract::Committable> objects.

=item C<added>

Just the items that were added in this commit, as an arrayref of
L<VCI::Abstract::Committable> objects.

=item C<removed>

Just the items that were deleted in this commit, as an arrayref of
L<VCI::Abstract::Committable> objects.

=item C<modified>

The items that were modified (not added or removed, just changed) in this
commit, as an arrayref of L<VCI::Abstract::Committable> objects.

Any files that were L</moved> will have their I<new> names, not their old
names.

=item C<moved>

Some version-control systems understand the idea that a file can be renamed
or moved, not just removed and then added.

If a file was moved or renamed, it will show up in this accessor, which is a
hashref where the keys are the B<new> path and the value is a
L<VCI::Abstract::Committable> representing the B<old> path. (That might seem
backwards until you realize that the I<new> name is what shows up in
L</modified>, so having keys on the I<new> name is much more useful.)

Each file will also show up in L</modified> if it also had modifications
during this commit. (However, if there were no changes to the file other
than that it was moved, it won't show up in L</modified>.)

=item C<copied>

A hashref of objects that were copied from another file/directory, preserving
their history. The place we were copied from could have been in some other 
Project (and in rare cases, a completely different Repository, though VCI
might not track that it was copied in that case).

The keys are the name of the file as it is now, and the value is a
C<VCI::Abstract::Committable> that represents the path it was copied from.

Any item in C<copied> will also show up in C<modified> if it was changed
during this commit, and C<added> otherwise.

=item C<revision>

A string representing the unique identifier of this commit, according to
the version-control system.

For version-controls systems that don't understand atomic commits, this
will be some unique identifier generated by VCI. This identifier is
guaranteed to be stable--that is, you can use it to retrieve this commit
object from L<VCI::Abstract::Project/get_commit>.

Individual C<VCI::VCS> implementations will specify the format of their
revision IDs, if they are a VCS that doesn't have unique identifiers for
commits, or if there is any ambiguity about what exactly "revision id"
means for that VCS.

=item C<revno>

In many VCSes, there is a difference between the "unique revision identifier"
(which is a long and complex string uniquely identifying a particular
revision) and the actual simple "revision number" displayed. C<revno>
represents the revision number (as opposed to L</revision>, which
represents the unique identifier).

Often this is a simple integer, but in some VCSes this could also be a
string like "1.2.3.4".

In some VCSes, C<revno> and L</revision> are identical. In other VCSes,
C<revno> is just a shorter version of L</revision>.

=item C<uuid>

A universally-unique identifier for this Commit. This is a unique string
that identifies this exact commit across all possible Repositories and
Projects in the world. If any Commit from any Repository or Project
has this uuid, it I<is> this Commit.

Note that it's possible that two Commits with differing uuids I<could> be the
same Commit, because for VCSes where L<VCI/revisions_are_universal> isn't
true, the uuid is generated based on the name of the Repository (and
possibly Project) this Commit is in, and if you call the same Repository
or Project by two different names, you may get two different UUIDs for the
Commit objects in that Repository/Project.

B<Note:> Currently, there is a chance that the way this is generated
will change between versions of VCI. If it does, it will be noted in the
Changes file that comes along with the VCI package.

=item C<message>

The message that was entered by the committer, describing this commit.

=item C<as_diff>

Returns a representation of the changes made to files in this commit,
as a L<VCI::Abstract::Diff> object.

If the VCS provides a diff format that tracks renames and copies, the
diff will be in that format. In other words, it will represent the changes
in the same way the Commit represents them. For example, if a file has
been moved and then modified, in a normal diff you'd see one entire
file removed and then another added. In this diff you will only see
that a file was modified, and that file will have the new name.

=back

=head1 CLASS METHODS

=head2 Constructors

Usually you won't construct an instance of this class directly, but
instead, use various methods of L<VCI::Abstract::Project> to get
Commits out of the Project's History.

=over

=item C<new>

Takes all L</Accessors> as named parameters. The following fields are
B<required>: L</time>, L</revision>, and
L<project|VCI::Abstract::FileContainer/project>.

If L</committer> and L</message> aren't specified, they default to an
empty string.

=back
