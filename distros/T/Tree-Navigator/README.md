# NAME

Tree::Navigator - Generic navigation in various kinds of trees

# SYNOPSIS

Create a file `treenav.psgi` like this :

    # create a navigator, then mount various kinds of nodes as shown below
    use Tree::Navigator;
    my $tn = Tree::Navigator->new;

    # example 1 : browse through the filesystem
    $tn->mount(Files => Filesys 
                     => {attributes => {label => 'My Web Files'},
                         mount_point => {root  => '/path/to/files'}});

    # example 2 : inspect tables and columns in a database
    my $dbh = DBI->connect(...);
    $tn->mount(MyDB => 'DBI' => {mount_point => {dbh => $dbh}});

    # example 3 : browse through the Win32 registry
    $tn->mount(HKCU => 'Win32::Registry' => {mount_point => {key => 'HKCU'}});

    # example 4 : browse through Perl internals
    $tn->mount(Ref => 'Perl::Ref' => {mount_point => {ref => $some_ref}});
    $tn->mount(Stack => 'Perl::StackTrace' => {mount_point => {}});
    $tn->mount(Symdump => 'Perl::Symdump' => {});

    # create the application
    my $app = $tn->to_app;

Then run the app

    plackup treenav.psgi

or mount the app in Apache

    <Location /treenav>
      SetHandler perl-script
      PerlResponseHandler Plack::Handler::Apache2
      PerlSetVar psgi_app /path/to/treenav.psgi
    </Location>

and use your favorite web browser to navigate through your data.

# DESCRIPTION

## Introduction

This is a set of tools for navigating within various kinds of
_trees_; a tree is just a set of _nodes_, where each node may have a
_content_, may have _attributes_, and may have _children_
nodes. Examples of such structures are filesystems, FTP sites, email
boxes, Web sites, HTML pages, XML documents, etc.

The distribution provides

- an [abstract class for nodes](https://metacpan.org/pod/Tree%3A%3ANavigator%3A%3ANode), with a few
concrete classes for some of the examples just mentioned above
- a server application for exposing the tree structure to
web clients 
- a [debugging application](https://metacpan.org/pod/Tree%3A%3ANavigator%3A%3AApp%3A%3APerlDebug)
that uses the Tree Navigator to navigate into the
memory of a running Perl program.

## Status

This application was built as a proof-of-concept in 2012 and hasn't been much reworked
since. It is functional and actually is being used in production for some minor tasks,
but is not polished into a fully documented product. A minor modernization was performed
in 2024 to remove deprecated features no longer supported by recent versions of perl.

## Implemented nodes

The following kinds of nodes come with the distribution and therefore can readily be mounted
into a tree navigator :

- [Tree::Navigator::Node::DBI](https://metacpan.org/pod/Tree%3A%3ANavigator%3A%3ANode%3A%3ADBI)

    Displays the metadata (tables and columns) of a database.
    Navigation within the data rows is not implemented yet.

- [Tree::Navigator::Node::DBIDM](https://metacpan.org/pod/Tree%3A%3ANavigator%3A%3ANode%3A%3ADBIDM)

    Meant to navigate in a database through a [DBIx::DataModel](https://metacpan.org/pod/DBIx%3A%3ADataModel) schema.
    Not fully implemented.

- [Tree::Navigator::Node::Filesys](https://metacpan.org/pod/Tree%3A%3ANavigator%3A%3ANode%3A%3AFilesys)

    Navigation in a filesystem, displaying file attributes and providing a download facility.

- [Tree::Navigator::Node::Perl::Ref](https://metacpan.org/pod/Tree%3A%3ANavigator%3A%3ANode%3A%3APerl%3A%3ARef)

    Navigation in a perl datastructure.

- [Tree::Navigator::Node::Perl::StackTrace](https://metacpan.org/pod/Tree%3A%3ANavigator%3A%3ANode%3A%3APerl%3A%3AStackTrace)

    Navigation in a perl stacktrace.

- [Tree::Navigator::Node::Perl::Symdump](https://metacpan.org/pod/Tree%3A%3ANavigator%3A%3ANode%3A%3APerl%3A%3ASymdump)

    Navigation in a perl symbol table.

- [Tree::Navigator::Node::Win32::Registry](https://metacpan.org/pod/Tree%3A%3ANavigator%3A%3ANode%3A%3AWin32%3A%3ARegistry)

    Navigation in Windows registry.

Other kinds of nodes can be integrated into the framework by subclassing
[Tree::Navigator::Node](https://metacpan.org/pod/Tree%3A%3ANavigator%3A%3ANode) with methods for accessing the node's content, attributes and children.

# METHODS

## call

Main request dispatcher (see ["Component" in Plack](https://metacpan.org/pod/Plack#Component)).

# DEPENDENCIES

This application uses [Plack](https://metacpan.org/pod/Plack) and [Moose](https://metacpan.org/pod/Moose).

# AUTHOR

Laurent Dami, `<dami at cpan.org>`

# SEE ALSO

[Tree::Simple](https://metacpan.org/pod/Tree%3A%3ASimple)

# LICENSE AND COPYRIGHT

Copyright 2012, 2024 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
