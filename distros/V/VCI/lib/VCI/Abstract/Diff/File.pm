package VCI::Abstract::Diff::File;
use Moose;

use VCI::Util;

has 'changes'  => (is => 'ro', isa => 'ArrayRef[Text::Diff::Parser::Change]',
                   required => 1);
# XXX Eventually this should be replaced with a VCI::Abstract::File
has 'path'     => (is => 'ro', isa => 'Str', required => 1);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::Abstract::Diff::File - The changes made to a particular file, in a Diff.

=head1 DESCRIPTION

Diffs are basically lists of changes made to files. So this represents the
modifications made to just one file in a Diff.

B<NOTE>: The interface of this module is particularly unstable. The names
and types of the accessors may drastically change in some future release.

=head1 METHODS

=head2 Accessors

All accessors are read-only.

=over

=item C<changes>

An arrayref of L<Text::Diff::Parser::Change|Text::Diff::Parser/CHANGE_METHODS>
objects, representing the changes made to this file.

=item C<path>

A string representing the path of the file that's been changed, relative
to the base of the Project the Diff is related to.

=back

=head1 CLASS METHODS

=head2 Constructor

Usually you won't construct an instance of this class directly, but
instead, use L<VCI::Abstract::Diff/files>.

=over

=item C<new>

Takes all L</Accessors> as named parameters. The following fields are
B<required>: L</changes>, and L</path>.

=back
