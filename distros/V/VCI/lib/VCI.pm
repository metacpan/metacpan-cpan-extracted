package VCI;
use 5.008;
use Moose;
our $VERSION = '0.7.1';

use Class::MOP;
use VCI::Util;

use constant CLASS_BASE => 'VCI::VCS::';

use constant revisions_are_universal => 1;
use constant revisions_are_global => 1;

# Will also need a write_repo in the future, if we add commit support,
# for things like Hg that read from hgweb but have to write through the
# actual hg client.

has 'repo' => (is => 'ro', isa => 'Str', required => 1);
has 'type' => (is => 'ro', isa => 'Str', required => 1);
has 'debug' => (is => 'ro', isa => 'VCI::Type::IntBool', coerce => 1,
                default => sub { 0 });

has 'repository' => (is => 'ro', isa => 'VCI::Abstract::Repository',
                     lazy_build => 1);

has 'vci_class'        => (is => 'ro', isa => 'ClassName', lazy_build => 1);
has 'commit_class'     => (is => 'ro', isa => 'ClassName', lazy_build => 1);
has 'diff_class'       => (is => 'ro', isa => 'ClassName', lazy_build => 1);
has 'directory_class'  => (is => 'ro', isa => 'ClassName', lazy_build => 1);
has 'file_class'       => (is => 'ro', isa => 'ClassName', lazy_build => 1);
has 'history_class'    => (is => 'ro', isa => 'ClassName', lazy_build => 1);
has 'project_class'    => (is => 'ro', isa => 'ClassName', lazy_build => 1);
has 'repository_class' => (is => 'ro', isa => 'ClassName', lazy_build => 1);

sub connect {
    my $class = shift;
    my %params = @_;
    my $type = $params{type};
    my $vci_class = $params{vci_class} || CLASS_BASE . $type;
    eval { Class::MOP::load_class($vci_class) }
        || confess("$type is not a valid VCI driver: $@");
    my $vci = $vci_class->new(@_);
    $vci->_check_api();
    my $repo = $vci->repository;
    return $repo;
}

sub missing_requirements { () }

sub api_version {
    my $invocant = shift;
    my $version = $invocant->VERSION;
    $version =~ /^(\d+)\.(\d+)/;
    return { major => int($1), api => int($2) };
}

# Note that this default build_repository doesn't do anything about
# authentication.
sub _build_repository {
    my $self = shift;
    return $self->repository_class->new(root => $self->repo, vci => $self);
}

sub _check_api {
    my $self = shift;
    my $package = blessed $self;
    my $driver = $self->api_version;
    my $vci    = __PACKAGE__->api_version;
    my $driver_ver = "$driver->{major}.$driver->{api}";
    my $vci_ver    = "$vci->{major}.$vci->{api}";
    if ($driver->{major} > $vci->{major}
        || ($driver->{major} == $vci->{major} && $driver->{api} > $vci->{api}))
    {
        confess("This driver implements VCI $driver_ver but you only have"
                . " VCI $vci_ver installed. You probably need to update VCI.");
    }
    
    if ($driver->{major} < $vci->{major}) {
        confess("VCI has a major version of $vci->{major} but your $package"
                . " only implements VCI $driver->{major}. You probably need"
                . " to upgrade $package.");
    }
    
    if ($driver->{major} == $vci->{major} && $driver->{api} < $vci->{api}) {
        warn "$package only implements VCI $driver_ver but you have VCI"
             . " $vci_ver installed. You probably need to upgrade $package."
             if $self->debug;
    }
}

sub _build_vci_class        { CLASS_BASE . shift->type }
sub _build_commit_class     { return shift->_class('Commit')     }
sub _build_diff_class       { return shift->_class('Diff')       }
sub _build_directory_class  { return shift->_class('Directory')  }
sub _build_file_class       { return shift->_class('File')       }
sub _build_history_class    { return shift->_class('History')    }
sub _build_project_class    { return shift->_class('Project')    }
sub _build_repository_class { return shift->_class('Repository') }

sub _class {
    my ($self, $class) = @_;
    my $module = $self->vci_class . '::' . $class;
    Class::MOP::load_class($module);
    return $module;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI - A library for interacting with version-control systems.

=head1 SYNOPSIS

 my $repository = VCI->connect(type => $type, repo => $repo);

=head1 DESCRIPTION

This is VCI, the generic Version Control Interface. The goal of VCI is to
create a common API that can interface with all version control systems
(which are sometimes also called Software Configuration Management or "SCM"
systems).

The VCI home page is at L<http://vci.everythingsolved.com/>.

=head2 New to VCI?

If you aren't sure where to start, you want to first look at L</connect>
and then at L<VCI::Abstract::Repository>.

Basically, when using VCI, you L<connect|/connect> to
a L<Repository|VCI::Abstract::Repository>,
L<get|VCI::Abstract::Repository/get_project> a
L<Project|VCI::Abstract::Project> from that Repository,
and then L<call methods on that Project|VCI::Abstract::Project/METHODS>.

The general interface of VCI is described in the various VCI::Abstract
modules, and those contain the documentation you should read in order to
find out how VCI works.

"Drivers" for different VCSes are in modules whose names start with
C<VCI::VCS>. For example, L<VCI::VCS::Cvs> is the "CVS support" for
VCI. You only have to read L<VCI::VCS::Cvs> or the manual of any other
driver if you want to know:

=over

=item *

The L</connect> syntax for that driver.

=item *

The limitations of the driver. That is, any way that it differs
from how VCI is supposed to work.

=item *

Explanations of things that might be surprising or unexpected when
dealing with that particular version-control system.

=item *

Any extensions that that driver has implemented.

=back

=head2 Repositories and Projects

A server that contains your version-controlled files is considered a
"repository", and is represented by L<VCI::Abstract::Repository>.

An actual set of code that you could check out of the repository is
considered a "project", and is represented by L<VCI::Abstract::Project>.

Almost all information that VCI gives is in relation to the I<project>.
For example, file paths are relative to the base directory of the project,
not the base directory of the entire repository.

For information on how to get a Project object from a Repository, see
L<VCI::Abstract::Repository>.

=head2 The Structure of VCI (VCI::Abstract vs. VCI::VCS)

The general interface of VCI classes is described in the VCI::Abstract
modules, but the specific implementations for particular VCSes are in the
C<VCI::VCS> namespace.

For example, the methods that you use on a File in your version-control
system are described in L<VCI::Abstract::File>, but the actual specific
implementation for CVS is in C<VCI::Cvs::File>. C<VCI::Cvs::File>
B<must> implement all of the methods described in L<VCI::Abstract::File>,
but it also may implement extension methods whose names start with C<x_>.

If you are going to use C<isa> on objects to check their type, you should
check that they are the abstract type, not the specific type. For example,
to find out if an object is a File, you would do:

  $obj->isa('VCI::Abstract::File')

=head1 VERSION NUMBERING SCHEME

VCI has three-number version numbers, like this:

C<MAJOR.API.MINOR>_C<DEVEL>

Here's what each number means:

=over

=item B<MAJOR>

As long as this number is C<0>, major breaking changes may
occur to the API all the time. When this becomes C<1>, the API is
stable. For numbers greater than C<1>, it means we made a major breaking
change to the API.

For example, VCI 2.0.1 would have breaking changes for the user or for the
drivers, compared to VCI 1.0.1. But VCI 0.1.1 and 0.2.1 could contain
breaking changes between them, also, because the first number is still C<0>.

=item B<API>

VCI has various features, but the drivers may not implement all of these
features. So, when we add new features that drivers must implement, the
C<API> number gets incremented.

For example, VCI 0.0.1 doesn't have support for authenticating to repositories,
but VCI 0.2.1 might support it.

Drivers will say which VCI API they support. Using a driver that doesn't
support the current VCI API will throw a warning if L</debug> mode is on.
Using a driver that supports an API I<later> than the current VCI will
throw an error.

=item B<MINOR>

This indicates a bug-fix release, with the API staying the same.

This will always be C<1> or higher unless this is a development release,
in which case it will be C<0>.

=item B<DEVEL>

If this is an unstable development release, this number will be included.
In this case, the C<MINOR> number should almost always be C<0>.

=back

=head1 CLASS METHODS

=head2 Constructors

=over

=item C<connect>

=over

=item B<Description>

Returns a L<VCI::Abstract::Repository> object based on your parameters. This is
how you "start" using VCI.

Note that you cannot currently connect to repositories that require
authentication, as VCI has no way of dealing with usernames or
passwords. So you must connect to repositories that don't require
authentication, or to which you have already authenticated. Future versions
of VCI will support authentication.

=item B<Parameters>

=over

=item C<repo> B<(Required)>

This is a string representing the repository you want to connect to, in
the exact same format that you'd pass to the command-line interface to your
VCS. For example, for CVS this would be the contents of C<CVSROOT>.

The documentation of individual drivers will explain what the format
required for this field is.

B<Taint Mode>: VCI will throw an error if this is tainted, because drivers use
this string to do various operations (such as filesystem operations) that
could be unsafe with untrusted data. If VCI didn't throw the error, you'd
instead get some weird error from some internal part of VCI or one of the
modules it uses, so it's better to just throw it right here.

=item C<type> B<(Required)>

What VCI driver you want to use. For example, to use CVS (L<VCI::VCS::Cvs>)
you'd say C<Cvs> for this parameter. It is case-sensitive, and must be the
name of an installed module in the C<VCI::VCS> namespace.

=item C<debug>

If you'd like VCI to print out a lot of information about what it's doing
to C<STDERR>, set this to C<1>. Different drivers will print out different
information.

Some drivers will print out more information if you set C<debug> to higher
values than C<1>.

(Note: This is an L<IntBool|VCI::Util/VCI::Type::IntBool>.)

=back

=back

=item C<missing_requirements>

Some drivers have requirements beyond just Perl modules, in order to work.
Calling this method will tell you if those requirements are installed.
You would call this method like:

 use VCI::VCS::Cvs;
 my @need = VCI::VCS::Cvs->missing_requirements;

Returns an array (not an arrayref) of strings representing items that still
need to be installed in order for this driver to function. If the array is
empty, then all non-Perl requirements for this driver are already installed
and available.

=item C<new>

This has the same parameters as L</connect>, but actually returns a
C<VCI> object, not a L<VCI::Abstract::Repository>.

You'll generally want use L</connect> instead of this.

=back

=head2 VCS Information

These represent information about a particular version-control system.
You can call these on a class, like
C<< VCI::VCS::Cvs->revisions_are_universal >>, or if you have a
L<VCI::Abstract::Repository> object, you can call these methods using the
C<vci> accessor, like: C<< $repository->vci->revisions_are_universal >>.

=over

=item C<revisions_are_global>

A boolean. If true, then the "revision" accessor on a L<VCI::Abstract::Commit>
for this VCS is globally unique within an entire Repository, not just
for this Project. (For example, Subversion's commit ids are globally unique
within a repository.)

If false, then different Projects could have overlapping revision identifiers.

=item C<revisions_are_universal>

A boolean. If true, then the "revision" accessor on a L<VCI::Abstract::Commit>
returns a value that will be universally unique across all repositories in
the world. For example, Git, Mercurial, and Bazaar have universally unique
revision identifiers--no two revisions in existence are likely to have
duplicate revision ids unless they are actually the same revision.

=back

=head2 Other

=over

=item C<api_version>

This is for drivers, to indicate what API version they implement.

Returns a hashref with two items:

C<major> - The L<major|/MAJOR> version number of the VCI API that this driver
implements.

C<api> - The L<api|/API> version number of the VCI API that this driver
implements.

For more information about what these numbers mean, see
L</VERSION NUMBERING SCHEME>.

=back

=head1 METHODS

=head2 Accessors

All of the fields that L</connect> takes can also be accessed with methods
named after them. In addition to the fields that you pass in to new, there
are other accessors:

=over

=item C<repository>

Returns the L<VCI::Abstract::Repository> that this VCI is connected to.
Generally you don't want to use this, and you just want to use L</connect>.

=back

=head1 HOW TO GET VCI

VCI is available on CPAN, which is the recommended way to get it:
L<http://search.cpan.org/dist/VCI/>

VCI is also available from its source repository. You can get the latest
development version by doing:

 bzr co http://bzr.everythingsolved.com/vci/trunk

Note that if you check out code from the trunk repository, it may be unstable
or completely broken.

You can get the latest stable version by doing:

 bzr co http://bzr.everythingsolved.com/vci/stable

You have to do C<perl Makefile.PL> and C<make manifest> on any checked-out
code before you can install it.

=head1 PERFORMANCE

VCI strives to perform well. It will never perform faster than the VCS being
used, however. Also, on very large projects (tens of thousands of
files or tens of thousands of commits) some operations may be slow
(such as asking for the History of an entire Project). However, for most
uses and for the majority of projects, VCI should be fast enough.

Using local repositories is always faster than using remote repositories,
usually by orders of magnitude.

VCI uses L<Moose> extensively, so installing the latest version of
L<Moose> often helps improve the performance of VCI.

If the performance of VCI is too slow for your project, please let the
author know using one of the mechanisms described in L</SUPPORT>. Without
knowing exactly what sort of things are slow in real-world use, it's
impossible to know what to optimize.

=head1 SUPPORT

The author of VCI is available via IRC, on irc.mozilla.org, in
L<#mozwebtools|http://landfill.bugzilla.org/irc/>. His IRC name is
C<mkanat>.

Otherwise, the best way to get support for VCI is just to email
the author at C<mkanat@cpan.org>.

VCI also has a home page at:

L<http://vci.everythingsolved.com/>

And there is a blog with updates about VCI at:

L<http://avatraxiom.livejournal.com/tag/vci>

=head1 USING VCI IN TAINT MODE

VCI strives to work properly and safely under taint mode. Unless specified
otherwise in their POD, all VCS drivers work correctly under taint mode.

Various methods check their arguments for being tainted and throw an
error if they are. Methods that do this have a note about B<Taint Mode>
in their documentation.

=head1 GENERAL NOTES FOR VCI::VCS IMPLEMENTORS

This is information for people who want to hack on the internals of VCI
or implement a driver for their VCS.

=head2 Constructors

VCI uses L<Moose>, so all constructors for all objects are called
C<new> (although for L<VCI> itself you'll want to use L</connect>),
and they all take named parameters as a hash (not a hashref). Generally
users don't call constructors--we only call constructors internally.

=head2 The POD is an API

If the POD of the C<VCI::Abstract> modules says something,
B<that is an API for VCI>. Unless the POD specifically I<says> you can
change the behavior of a method, you B<must> not deviate from how the
POD says the methods and accessors work.

You may add new C<required> attributes to the constructors of various
modules, but you must not add C<required> attributes to methods other
than what is already specified in the POD for that method.

=head2 Extending VCI

VCI provides a base set of functions that are common to all Version-Control
Systems, but if your VCS can do special things, feel free to add extension
methods.

So that your methods don't conflict with VCI methods, their names should start
with C<x_> (or C<_x_> for private methods). VCI won't I<enforce> that, but
if you don't do it, your module could seriously break in the future if VCI
implements a method with the same name as yours.

VCI promises not to have any abstract methods or accesors that start
with C<x_> or C<_x_>.

=head2 The Design Goals of VCI

In order of priority, the goals of VCI are:

=over

=item 1

Correctness

=item 2

Ease of Driver Implementation

=item 3

To implement as many VCS features as possible, not to only implement the
common denominator of all VCSes.

=item 4

Speed Efficiency

=back

Memory Efficiency is a fourth consideration to be taken into account when
writing drivers, but isn't considered as important as the above items.


=head3 Correctness

This means that drivers (and VCI) should do exactly what the user asks,
without any surprises or side-effects, and should conform fully to all
required elements of the API.

If you have doubts about what is "correct", ask yourself the question,
"What would be most logical for a web application that views and interacts
with a repository?" That is the function that VCI was originally designed
for.

=head3 Ease of Driver Implementation

VCI is designed to make life easy for implementors. The only things
that you B<must> implement are:

=over

=item C<_build_projects> in L<VCI::Abstract::Repository>

=item C<_build_history> in L<VCI::Abstract::Project>

=item C<_build_contents> in L<VCI::Abstract::Directory>

=item C<_build_revision> for L<VCI::Abstract::Committable> objects
(File and Directory), for objects that have no revision specified (meaning
this is the "HEAD" revision).

=item C<_build_time> for L<VCI::Abstract::Committable> objects that have
a revision but no time specified.

=item C<_build_as_diff> in L<VCI::Abstract::Commit>

=item  C<_build_content> in L<VCI::Abstract::File>

=back

That's basically the I<minimum> you have to implement. The more you implement,
the I<faster> your VCI driver will be. But it will still be fully I<correct>
(if sometimes slow) with only the above implemented.

=head3 Many Features, Not the Common Denominator of Features

Many abstractions limit you to the common denominator of all the things
they abstract. That is, we could say, "You can only do X with VCI if
I<all VCSes> can do X." But that's not the goal of VCI.

Instead, we say, "VCI allows you to do X. If the VCS can't do X, VCI will
provide some reasonable default instead."

For example, not all VCSes track if a file is executable. But we provide
L<VCI::VCS::File/is_executable>, and it behaves sensibly when the VCS
doesn't track that information.

=head3 Efficiency

In general, VCI strives to be efficient in terms of I<speed>. Working with
a version-control system can often be a slow experience, and we don't
want to make that any worse than it already is.

This means that individual methods should do the least work possible to
return the information that the user needs, and store it internally for later
use.

For example, a L<file|VCI::Abstract::File> in a version control system
has a L<first revision|VCI::Abstract::Committable/first_revision> . If
there's a fast way to just get the first revision, you should do that.

But if we've already read the whole
L<history|VCI::Abstract::Committable/history> of a file, that has information
about the first revision in it, so we should just be able to reference the
history we already retrieved, instead of asking the version-control system
for the first revision all over again.

=head2 Order of Implementation

This is just some tips to make your life easier if you're going to implement
a driver for your version-control system.

First, you want to implement a method of connecting to your VCS, which
means implementing L<VCI>. Then L<VCI::Abstract::Repository>, and
then L<VCI::Abstract::Project>.

After that you're probably going to want to implement L<VCI::Abstract::File>
and L<VCI::Abstract::Directory>.

Then you can implement L<VCI::Abstract::History>, and now that you
have everything, you can implement L<VCI::Abstract::Commit>.

=head1 NOTES FOR IMPLEMENTORS OF VCI.pm

In general, you shouldn't override L</connect>. Also, using C<before>
on L</connect> probably also isn't a good idea. You could use C<after>,
but it mostly just makes sense to implement L</_build_repository> and leave
it at that.

If you I<do> override connect, you B<must> call I<this> C<connect> at some
point in your C<connect>.

You B<must> not add new C<required> attributes to C<connect>.

=head2 Optional Methods To Implement

=over

=item C<_build_repository>

Returns the L<VCI::Abstract::Repository> object. (This is basically
what L</connect> returns, so this does the "heavy_lifting" for
L</connect>.)

=back

=head1 SEE ALSO

L<VCI::Abstract::Repository>

B<Drivers>: L<VCI::VCS::Svn>, L<VCI::VCS::Bzr>, L<VCI::VCS::Hg>,
L<VCI::VCS::Git>, and L<VCI::VCS::Cvs>

=head1 TODO

Eventually the drivers may be split into their own packages.

Need C<user> and C<pass> support for L</connect>.

Come up with a meaningful "branch" abstraction.

Commits need to understand C<parent> and C<children>, for VCSes like
Hg and Git that don't necessarily have a linear series of commits.

Commits need to have a C<subcommits> accessor that gives minor
commits that are part of this larger commit. (For example, "merge commits"
in bzr or git.)

L<VCI::Abstract::Commit/moved> should be a hashref that points to objects,
not to strings.

=head1 BUGS

All complex software has bugs, and VCI is probably no exception.
However, VCI's test suite has nearly 100% code coverage, and VCI currently
passes all tests.

Some drivers do have limitations, see their documentation for details.

=head1 AUTHOR

Max Kanat-Alexander <mkanat@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Everything Solved, Inc.

L<http://www.everythingsolved.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
