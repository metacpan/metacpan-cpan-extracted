package VCI::Abstract::Committable;
use Moose::Role;
use VCI::Util;

with 'VCI::Abstract::ProjectItem';

has 'history'        => (is => 'ro', isa => 'VCI::Abstract::History', lazy_build => 1);

has 'first_revision' => (is => 'ro', does => 'VCI::Abstract::Committable',
                         lazy_build => 1);
                                          
has 'last_revision'  => (is => 'ro', does => 'VCI::Abstract::Committable',
                         lazy_build => 1);

has 'revision'   => (is => 'ro', lazy_build => 1, predicate => '_has_revision');
has 'revno'      => (is => 'ro', lazy_build => 1);
# All of this crazy init_arg stuff means "coerce lazily, because it's
# slow to make thousands of DateTime and Path::Abstract::Underload objects."
has 'time'       => (is => 'ro', isa => 'VCI::Type::DateTime', coerce => 1,
                     lazy => 1,
                     default => sub { shift->_time }, init_arg => '__time');
has '_time'      => (is => 'ro', isa => 'Defined', init_arg => 'time',
                     lazy_build => 1, builder => '_build_time');
has 'path'       => (is => 'ro', isa => 'VCI::Type::Path', coerce => 1,
                     lazy => 1,
                     default => sub { shift->_path }, init_arg => '__path');
has '_path'      => (is => 'ro', isa => 'Defined', required => 1,
                     init_arg => 'path');
has 'name'       => (is => 'ro', isa => 'Str', lazy => 1,
                     default => sub { shift->path->last });

has 'parent'     => (is => 'ro', does => 'VCI::Abstract::Committable',
                     lazy_build => 1);

# Unfortunately Moose is a little dumb about Roles sometimes, and requires
# our *abstract* classes to implement these, instead of our subclasses. So
# we can't really require them.
# requires 'build_revision', 'build_time';

sub _build_first_revision {
    my $self = shift;
    my $commit = $self->history->commits->[0];
    return $self->_me_from($commit);
}

sub _build_last_revision {
    my $self = shift;
    my $commit = $self->history->commits->[-1];
    return $self->_me_from($commit);
}

sub _build_revno {
    my $self = shift;
    my $commit = $self->project->get_commit(revision => $self->revision);
    return $commit->revno;
}

sub _me_from {
    my ($self, $commit) = @_;
    my @item = grep {$_->path->stringify eq $self->path->stringify
                     # This assures we don't get a Directory if we're a File.
                     && $_->isa(blessed $self)}
                    @{$commit->contents};
    warn("More than one item in the contents of commit "
         . $commit->revision . " with path " . $self->path)
        if scalar @item > 1;
    return $item[0];
}

sub _build_history {
    my $self = shift;
    
    my $current_path = $self->path->stringify;
    my @commits;
    # We go backwards in time to catch renames.
    foreach my $commit (reverse @{ $self->project->history->commits }) {
        my $in_contents = grep {$_->path->stringify eq $current_path}
                               @{$commit->contents};
        push(@commits, $commit) if $in_contents;
        # XXX Need to also track our history through copies.
        if (exists $commit->moved->{$current_path}) {
            $current_path = $commit->moved->{$current_path}->path->stringify;
        }
    }
    
    return $self->history_class->new(
        commits => [reverse @commits],
        project => $self->project,
    );
}

sub _build_parent {
    my $self = shift;
    my $path = $self->path;
    return undef if $path->is_empty;

    my $parent_path = $self->path->parent;
    return $self->project->get_path(path => $parent_path);
}

#######################
# Implementor Helpers #
#######################

sub _no_time_without_revision {
    my $self = shift;
    if (defined $self->{time} && !defined $self->{revision}) {
        confess("You cannot build a Committable that has its time"
                . " defined but not its revision");
    }
}

1;

__END__

=head1 NAME

VCI::Abstract::Committable - Anything that can be committed to a repository.

=head1 DESCRIPTION

This is a L<Moose::Role> that represents any item that can be committed
to a repository. In other words, a File I<or> a Directory.

It represents it at a specific time in its history, so it has a revision
identifier and time.

=head1 METHODS

=head2 Accessors

All accessors are read-only.

A lot of these accessors have to do with revision identifiers. Some
committables (such as directories) might not I<have> revision identifiers
of their own in certain types of version-control systems. In this case,
the revision identifiers will be an empty string or something specified
by the VCI::VCS implementation, but they will still have revision times.
(L</first_revision> and L</last_revision> might be equal to each other,
though.)

=head3 Information About The History of the Item

These are accessors that don't tell you about I<this> particular
file or directory, but actually tell you about its history in the repository.

=over

=item C<history>

A L<VCI::Abstract::History> representing the history of all commits to this
item.

Note that this L<VCI::Abstract::History> object is only guaranteed to have
information about I<this> file or directory--it may or may not contain
information about commits to other items.

=item C<first_revision>

A L<VCI::Abstract::Committable> representing the earliest revision for this
item in the current Project.

This will be the same type of Committable as the current one. (For example,
if this is a L<VCI::Abstract::File>, then C<first_revision> will also
be a L<VCI::Abstract::File>.)

=item C<last_revision>

A L<VCI::Abstract::Committable> representing the most recent revision for this
item in the current Project.

This will be the same type of Committable as the current one. (For example,
if this is a L<VCI::Abstract::File>, then C<last_revision> will also
be a L<VCI::Abstract::File>.)

=back

=head3 Information About This Point In History

This is the current revision and time of the specific item you're looking
at right now. If you're looking at an old verion of the file/directory,
it may not be the same as the information about the most recent revision.

=over

=item C<revision>

The revision identifier of the particular item that you're dealing with
right now. Similar to L<VCI::Abstract::Commit/revision>.

This may be different than the revision id of the commit that
this file/directory was committed in, because some VCSes (like CVS) have
revision ids for individual files.

=item C<revno>

Similar to L<VCI::Abstract::Commit/revno>. This represents the revision
number that corresponds to the revision id in L</revision>. In some VCSes,
this is identical to L</revision>.

=item C<time>

A L<datetime|VCI::Util/VCI::Type::DateTime> representing the time that this
revision was committed to the repository.

=item C<path>

The L<Path|VCI::Util/VCI::Type::Path> of this file, from the root of the project,
including its filename if it's a file.

In some version-control systems, this will never change, but there are
many modern systems that understand the idea of moving, renaming, or copying
a file, so this could be different at different points in history.

=item C<name>

The particular name of just this item, without its full path. If it's a
directory, it will just be the name of the directory (without any separators
like C<E<sol>>).

Just like L</path>, this may change over time in some version-control systems.

For the root directory of a project, this will be an empty string.

=item C<parent>

The L<VCI::Abstract::Directory> that contains this item. If this is the
root directory of the Project, then this will be C<undef>.

The most reliable way to check if this is the root directory is to see if this
accessor returns C<undef>.

=item C<project>

The L<VCI::Abstract::Project> that this committable is in.

=back

=head1 FOR IMPLEMENTORS OF VCI::VCS MODULES: CONSTRUCTION

When you call C<new> on a Committable, if you don't specify C<revision> and
C<time>, then we assume that you're talking about the most recent version
that's in the repository, and L</revision> and L</time> will return the
revision and time of the most recent revision.

You cannot specify L</time> without specifying L</revision>, in the
constructor. (However you can specify L</revision> without specifying
L</time>.)

=head1 SEE ALSO

B<Implementors>: L<VCI::Abstract::File> and L<VCI::Abstract::Directory>
