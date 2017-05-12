package VCI::VCS::Hg;
use Moose;
our $VERSION = '0.7.1';

use LWP::UserAgent;

use VCI::Util;

extends 'VCI';


has 'x_ua' => (is => 'ro', isa => 'LWP::UserAgent', lazy_build => 1);
has 'x_timeout' => (is => 'ro', isa => 'Int', default => sub { 60 });

sub _build_x_ua {
    my $self = shift;
    return LWP::UserAgent->new(
        agent => __PACKAGE__ . " $VERSION",
        protocols_allowed => [ 'http', 'https'],
        timeout => $self->x_timeout);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::VCS::Hg - Object-oriented interface to Mercurial (aka Hg)

=head1 SYNOPSIS

 use VCI;
 my $repository = VCI->connect(type => 'Hg',
                               repo => 'http://hgweb.example.com/');

=head1 DESCRIPTION

This is a "driver" for L<VCI> for the Mercurial version-control system.
You can find out more about Mercurial at L<http://mercurial.selenic.com/>.

For information on how to use VCI::VCS::Hg, see L<VCI>.

Currently VCI::VCS::Hg actually interacts with HgWeb, not directly with Hg
repositories. The only supported connections are C<http://> or C<https://>.

Local repositories are not yet supported.

=head1 CONNECTING TO A MERCURIAL REPOSITORY

For the L<repo|VCI/repo> argument to L<VCI/connect>, choose the actual
root of your hgweb installation.

For example, for C<http://hg.intevation.org/mercurial/stable>,
the C<repo> would be C<http://hg.intevation.org/>.

=head1 REVISION IDENTIFIERS

Mercurial has two revision identifiers on a commit: an integer and a hex
string. VCI::VCS::Hg uses the hex string as the revision id for Commit,
File, and Directory objects, and does not understand integer revision
ids.

=head1 LIMITATIONS AND EXTENSIONS

These are limitations of VCI::VCS::Hg compared to the general API specified
in the C<VCI::Abstract> modules.

=head2 VCI::VCS::Hg

You can only connect to hgweb installations. You cannot use ssh,
static-http, or local repositories. In the future we plan to support
local repositories, but ssh and static-http repositories will probably never
be supported. (Mercurial cannot work with them without cloning them, at which
point they are just a local repository.)

=head2 VCI::VCS::Hg::Directory

=over

=item *

Directory objects without a revision specified (such as those that you
get through L<get_path|VCI::Abstract::Project/get_path>,
L<get_directory|VCI::Abstract::Project/get_path>, and
L<VCI::Abstract::Project/get_file>) will always have the revision "tip",
even if this wasn't the revision they were modified most recently in.

This also means that their C<time> will be the time of the C<tip> revision,
not the time they were last modified.

=item *

File objects in a Directory's C<contents> will always have their latest
revision ID, instead of the correct revision ID for that revision of the
Directory.

Directory objects in C<contents> will have the revision identifier of
the parent directory.

=back

=head2 VCI::VCS::Hg::History

When directories were added/removed is not tracked by Mercurial, so
Directory objects never show up in a History.

=head2 VCI::VCS::Hg::Commit

=over

=item *

Although Mercurial supports renames and copies of files, the hgweb
interface doesn't track renames and copies. So renames just look like
a file was deleted and then a file was added. Copies are simply
added files.

=item *

Mercurial doesn't track when directories were added or removed, so
Directory objects never show up in the contents of a Commit.

=item *

If a File is added but has no content (that is, it's an empty file),
it will not show up as "added" in the Commit where it was added. (It will
show up in some later commit as "modified" if somebody adds contents,
though.)

Similarly, empty files that are removed will not show up in "removed".

=back

=head1 PERFORMANCE

On remote repositories, many operations can be B<extremely slow>. This
is because VCI::VCS::Hg makes many calls to the web interface, and any
delay between you an the remote server is magnified by the fact that
it happens over and over.

Working with the History of a Project involves using the RSS version of
the changelog from hgweb. The more items you allow hgweb to display in the
RSS version of the changelog, the faster VCI::VCS::Hg will be when working
with the history of a Project.

Getting the contents (or added/removed/modified) of a Commit can be
slow, as it has to access the web interface.

=head1 SEE ALSO

L<VCI>

=head1 AUTHOR

Max Kanat-Alexander <mkanat@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Everything Solved, Inc.

L<http://www.everythingsolved.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
