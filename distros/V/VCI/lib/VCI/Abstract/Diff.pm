package VCI::Abstract::Diff;
use Moose;
with 'VCI::Abstract::ProjectItem';

use Text::Diff::Parser;

use VCI::Util;
use VCI::Abstract::Diff::File;

has 'files'    => (is => 'ro', isa => 'ArrayRef[VCI::Abstract::Diff::File]',
                   lazy_build => 1);
has 'raw'      => (is => 'ro', isa => 'Str', required => 1);
has '_parsed'  => (is => 'ro', isa => 'Text::Diff::Parser', lazy_build => 1);

sub _build__parsed {
    my $self = shift;
    return Text::Diff::Parser->new(Diff => $self->raw);
}

sub _build_files {
    my $self = shift;
    my %files;
    foreach my $change ($self->_parsed->changes) {
        my $file1 = $self->_transform_filename($change->filename1);
        my $file2 = $self->_transform_filename($change->filename2);
        # We access filename2 directly to avoid things like project names of
        # "/dev/null"
        my $changed_file = $change->filename2 eq '/dev/null' ? $file1 : $file2;        
        $files{$changed_file} ||= { path => $changed_file, changes => [] };
        push(@{ $files{$changed_file}->{changes} }, $change);
    }
    return [map { VCI::Abstract::Diff::File->new($files{$_}) } (keys %files)];
}

sub _transform_filename { return $_[1] }

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::Abstract::Diff - An object representing a "diff" or "patch" from
a Version-Control System

=head1 SYNOPSIS

 my $diff = $commit->as_diff;

 my $file_changes = $diff->files;
 foreach my $file (@$files) {
     my $changes = $file->changes;
     my $path    = $file->path;
 }

 my $text = $diff->raw;

=head1 DESCRIPTION

Every VCS can generate a patch in "diff" format that can be applied to
re-create the changes in a particular commit.

This class represents the actual changes made to each file in a commit,
and can also be represented in "diff" format.

=head1 METHODS

=head2 Accessors

All accessors are read-only.

=over

=item C<files>

An arrayref of L<VCI::Abstract::Diff::File> objects, which each represent
the changes made to that particular file.

Files that were added but have no contents aren't tracked in the Diff.

Note that changes to binary files aren't tracked.

=item C<raw>

The exact text of the diff, as it would be returned by the version-control
system. If will be in unified diff format, but other details of the format
of the patch may be specific to the VCS.

=item C<project>

The L<VCI::Abstract::Project> that this Diff is from.

=back

=head2 For Subclass Implementors

If you are just a user of VCI::Abstract::Diff, you don't need to read
about these.

=over

=item C<_transform_filename>

To make implementing this class easier, you can override this function
to transform the filenames that appear in the patch into filenames
relative to the root of your Project.

=back

=head1 CLASS METHODS

=head2 Constructor

Usually you won't construct an instance of this class directly, but
instead, use L<VCI::Abstract::Commit/as_diff>.

=over

=item C<new>

Takes all L</Accessors> as named parameters. The following fields are
B<required>: L</raw>, and L</project>.

=back
