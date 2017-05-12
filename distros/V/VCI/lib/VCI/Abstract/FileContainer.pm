package VCI::Abstract::FileContainer;
use Moose::Role;

use VCI::Abstract::Committable; # This makes the Type Constraint work

# Unfortunately we can't currently enforce this, because Moose throws an
# error about attribute conflicts for a Directory, which is both a Committable
# and a FileContainer.
#with 'VCI::Abstract::ProjectItem';

has 'contents' => (is => 'ro', isa => 'ArrayRef[VCI::Abstract::Committable]',
                   lazy_build => 1);
has 'contents_history' => (is => 'ro', isa => 'VCI::Abstract::History',
                           lazy_build => 1);
has contents_history_recursive
    => (is => 'ro', isa => 'VCI::Abstract::History', lazy_build => 1);

# Unfortunately Moose is a little dumb about Roles sometimes, and requires
# our *abstract* classes to implement these, instead of our subclasses. So
# we can't really require them.
#requires 'build_contents';

sub _build_contents_history {
    my $self = shift;
    my @histories = map {$_->history} @{$self->contents};
    return $self->history_class->union(
        histories => \@histories, project => $self->project);
}

sub _build_contents_history_recursive {
    my $self = shift;
    my @histories;
    push(@histories, $self->contents_history);
    push(@histories, @{ _get_histories($self->contents) });
    return $self->history_class->union(
               histories => \@histories, project => $self->project);
}

# Helper for build_contents_history_recursive.
sub _get_histories {
    my ($items) = @_;
    my @histories;
    foreach my $item (@$items) {
        if ($item->does('VCI::Abstract::FileContainer')) {
            push(@histories, @{ _get_histories($item->contents) });
            push(@histories, $item->contents_history);
        }
    }
    return \@histories;
}

1;

__END__

=head1 NAME

VCI::Abstract::FileContainer - Anything that can contain a
File or Directory.

=head1 DESCRIPTION

This is a L<Moose::Role> that represents anything that can hold files.
Usually that's a L<VCI::Abstract::Directory>.

=head1 METHODS

=head2 Accessors

These accessors are all read-only.

=over

=item C<contents>

An arrayref of L<VCI::Abstract::Committable> objects that we contain.
The order is not guaranteed.

=item C<contents_history>

The L<VCI::Abstract::History> of all the items in this container. The History
will contain information about all of the items inside the container, but
possibly won't contain information about anything outside of the container.

This does not include the history of the item itself, if the item itself
has a history. (That is, if this item is also a L<VCI::Abstract::Committable>,
you should use the C<history> method to get information about this specific
item.)

=item C<contents_history_recursive>

The normal L</contents_history> only returns the History of items directly
contained in the directory.

This accsessor returns an entire L<VCI::Abstract::History> for all items
in the Project from this directory I<down>.

So, for example, if F<dir1> contains F<dir2>, and F<dir2> contains F<dir3>,
this method would return the History of all items contained in F<dir1>,
F<dir2>, and F<dir3>.

=item C<project>

The L<VCI::Abstract::Project> that this FileContainer belongs to.

=back

=head1 SEE ALSO

B<Implementors>: L<VCI::Abstract::Directory> and L<VCI::Abstract::Commit>
