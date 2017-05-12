package VCI::VCS::Cvs;
use Moose;
our $VERSION = '0.7.1';

use MooseX::Method;
extends 'VCI';

use Cwd;
use IPC::Cmd;
use Scalar::Util qw(tainted);

use VCI::Util qw(taint_fail detaint);

has 'x_cvsps' => (is => 'ro', isa => 'Str', lazy_build => 1);
has 'x_cvs' => (is => 'ro', isa => 'Str', lazy_build => 1);

sub BUILD {
    my $self = shift;
    taint_fail("The x_cvs argument '$self->{x_cvs}' is tainted")
        if tainted($self->{x_cvs});
    taint_fail("The x_cvsps argument '$self->{x_cvsps}' is tainted")
        if tainted($self->{x_cvsps});
}

use constant revisions_are_global => 0;
use constant revisions_are_universal => 0;

sub missing_requirements {
    my @need;
    foreach my $bin qw(cvs cvsps) {
        push(@need, $bin) if !IPC::Cmd::can_run($bin);
    }
    return @need;
}

sub _build_x_cvsps {
    my $cmd = IPC::Cmd::can_run('cvsps')
        || confess('Could not find "cvsps" in your path');
    taint_fail("We found '$cmd' for cvsps, but that string is tainted."
               . ' This probably means $ENV{PATH} is tainted')
        if tainted($cmd);
    return $cmd;
}

sub _build_x_cvs {
    my $cmd = IPC::Cmd::can_run('cvs')
        || confess('Could not find "cvs" in your path');
    taint_fail("We found '$cmd' for cvs, but that string is tainted."
               . ' This probably means $ENV{PATH} is tainted')
        if tainted($cmd);        
    return $cmd;
}

method 'x_do' => named (
    args    => { isa => 'ArrayRef', required => 1 },
    fromdir => { isa => 'Str', default => '.' },
) => sub {
    my ($self, $params) = @_;
    my $fromdir = $params->{fromdir};
    my $args    = $params->{args};

    my $full_command = $self->x_cvs . ' -f ' . join(' ', @$args);
    if ($self->debug) {
        print STDERR "Command: $full_command\n",
                     "   From: $fromdir\n";
    }
    
    my $old_cwd = cwd();
    chdir $fromdir or confess("Failed to chdir to $fromdir: $!");

    my ($success, $error_msg, $all, $stdout, $stderr) =
        IPC::Cmd::run(command => [$self->x_cvs, '-f', @$args]);

    my $error_code = 0;
    if (defined $error_msg) {
        if ($error_msg =~ /exited with value (\d+)/) {
            $error_code = $1;
        }
        else {
            $error_code = -1;
        }
    }
    
    # We are forced to trust this directory, and we don't do
    # anything dangerous with it, only chdir (which we can't do while
    # it's tainted).
    detaint($old_cwd);
    chdir $old_cwd or confess("Failed to chdir back to $old_cwd: $!");

    # "cvs diff" returns 256 always, it seems.
    if (!$success && !(grep($_ eq 'diff', @$args) && $error_code == 256)) {
        my $err_string = join('', @$stderr);
        chomp($err_string);
        confess("$full_command failed: $err_string");
    }
    
    my $output = join('', @$all);
    if ($self->debug) {
        print STDERR "Error Message: $error_msg\n" if $error_msg;
        (print STDERR "Results: $output\n") if $self->debug > 1;
    }
    return $output;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::VCS::Cvs - Object-oriented interface to CVS

=head1 SYNOPSIS

 use VCI;
 my $repository = VCI->connect(
    type => 'Cvs',
    repo => ':pserver:anonymous@cvs.example.com:/cvsroot'
 );

=head1 DESCRIPTION

This is a "driver" for L<VCI> for the CVS (Concurrent Versioning System)
version-control system. You can find out more about CVS at
L<http://www.nongnu.org/cvs/>.

For information on how to use VCI::VCS::Cvs, see L<VCI>.

=head1 CONNECTING TO A CVS REPOSITORY

For CVS, the format of the L<repo|VCI/repo> argument to L<VCI/connect> is
the same as what you would put in the C<CVSROOT> environment variable
when using the C<cvs> program.

The constructor also takes two additional, optional parameters:

=over

=item C<x_cvs>

The path to the "cvs" binary on your system. If not specified, we will
search your C<PATH> and throw an error if C<cvs> isn't found.

B<Taint Mode>: VCI will throw an error if this argument is tainted,
because VCI just runs this command blindly, and we wouldn't want
to run something like C<delete_everything_on_this_computer.sh>.

=item C<x_cvsps>

The path to the "cvsps" binary on your system. If not specified, we will
search your C<PATH> and throw an error if C<cvsps> isn't found.

B<Taint Mode>: VCI will throw an error if this argument is tainted,
because VCI just runs this command blindly, and we wouldn't want
to run something like C<delete_everything_on_this_computer.sh>.

=back

=head2 Local Repositories

Though CVS itself doesn't allow relative paths in C<:local:> roots,
VCI::VCS::Cvs does. So C<:local:path/to/repo> (or just C<path/to/repo>)
will be interpreted as meaning that you want the CVS repository in the
directory C<path/to/repo>.

In actuality, VCI::VCS::Cvs converts the relative path to an absolute path
when creating the Repository object, so using relative paths will fail
if you are in an environment where L<Cwd/abs_path> fails.

=head1 REQUIREMENTS

In addition to the Perl modules listed for CVS Support when you install
L<VCI>, VCI::VCS::Cvs requires that the following things be installed
on your system:

=over

=item cvs

The C<cvs> client program, at least version 1.11. You can get this at
L<http://www.nongnu.org/cvs> for *nix systems and
L<http://www.cvsnt.org/> for Windows systems.

=item cvsps

This is a program that interacts with CVS to figure out what files were
committed together, since CVS doesn't normally track that information,
and VCI needs that information.

You can get it from L<http://www.cobite.com/cvsps/>. (Windows users
have to use Cygwin to run cvsps, which you can get from
L<http://www.cygwin.com/>.)

=back

=head1 REVISION IDENTIFIERS

cvsps groups file commits that are close together in time and have the same
message into "PatchSets". Each of these PatchSets is given a unique,
integer identifier.

Since VCI::VCS::Cvs uses cvsps, the revision identifiers on Commit objects
will be these PatchSet ids.

These patchset ids are cached by C<cvsps> in your home directory, so as long
as you keep using VCI on the same system, the revision identifiers should stay
stable. However, if you move VCI to a different system and don't copy the
cvsps cache (usually in C<$HOME/.cvsps/>) then the revision identifiers for
Commits might change.

For File objects, the revision identifiers will be the actual revision
identifier as returned by CVS for that file. For example C<1.1>, etc.

For Directory objects, the revision identifier is currently always C<HEAD>.

=head1 LIMITATIONS AND EXTENSIONS

=over

=item *

Currently VCI doesn't understand the concept of "branches", so you are
always dealing with the C<HEAD> branch of a project. This will change
in the future so that VCI can access branches of projects. If this feature
is important to you, please let the author of VCI know so that he is
encouraged to implement it more quickly.

=item *

cvsps needs to write to the C<HOME> directory of the current user,
you must have write access to that directory in order to interact
with the History of a Project.

=item *

VCI::VCS::Cvs has to write files to your system's temporary
directory (F</tmp> on *nix systems), and many operations will fail
if it cannot. It uses the temporary directory returned by
L<File::Spec/tmpdir>.

=item *

If your program dies during execution, there is a chance that
directories named like F<vci.cvs.XXXXXX> will be left in your temporary
directory. As long as no instance of VCI is currently running, it should
be safe to delete these directories.

=back

In addition, here are the limitations of specific modules compared to the
general API specified in the C<VCI::Abstract> modules:

=head2 VCI::VCS::Cvs::Repository

C<get_project> doesn't support modules yet, only directory names in
the repository. Using a module name won't throw an error, but operations
on that Project are likely to then fail.

=head2 VCI::VCS::Cvs::Project

CVS supports L<"root_project"|VCI::Abstract::Project/root_project>.

=head2 VCI::VCS::Cvs::Commit

CVS doesn't track the history of a Directory, so Directory objects will
never show up in the added, removed, modified, or contents of a Commit.

=head2 VCI::VCS::Cvs::Directory

=over

=item *

For the C<time> accessor, we return the time of the most-recently-modified
file in this directory. If there are no files in the directory, we return
a time that corresponds to C<time() == 0> on your system, probably January
1, 1970 00:00:00. Currently this is a fairly slow operation, but it may be
optimized in the future.

=item *

All Directory objects have a revision of C<HEAD>, even if you get
them through the C<parent> accessor of a File.

=item *

If you manually create a Directory with a revision other than C<HEAD>,
the L<contents|VCI::Abstract::FileContainer/contents> will be incorrect.

=back

=head1 PERFORMANCE

VCI::VCS::Cvs performs fairly well, although it may be slower on projects
that have lots of files in one directory, or very long histories.

Working with a local repository will always be faster than working with
a remote repository. For most operations, the latency between you and
the repository is far more important than the bandwidth between you and
the repository.

=head1 SEE ALSO

L<VCI>

=head1 AUTHOR

Max Kanat-Alexander <mkanat@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Everything Solved, Inc.

L<http://www.everythingsolved.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
