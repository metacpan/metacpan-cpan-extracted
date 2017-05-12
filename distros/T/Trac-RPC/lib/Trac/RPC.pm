package Trac::RPC;
{
  $Trac::RPC::VERSION = '1.0.0';
}

# ABSTRACT: access to Trac via XML-RPC Plugin



use strict;
use warnings;

use base qw(
    Trac::RPC::Wiki
    Trac::RPC::System
    Trac::RPC::Tools
);

1;

__END__

=pod

=head1 NAME

Trac::RPC - access to Trac via XML-RPC Plugin

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

    my $params = {
        realm => "My Trac Server",  # This is a string that shows in the
                                    # box with login/password with
                                    # basic authorization.
                                    # It should be written exactly
        user => "rpc",
        password => "secret",
        host => "https://trac.example.com/test/login/rpc",

        # If the trac works without authentication
        # you should use a bit different url:
        # host => "https://trac.example.com/test/rpc",

    };

    my $tr = Trac::RPC->new($params);

    print $tr->get_page("WikiStart");
    $tr->put_page("WikiStart", "Sample text");

More on synopsion on appropriate pages:

=over

=item L<Trac::RPC::System>

=item L<Trac::RPC::Wiki>

=back

There are also some high level tools to work with trac L<Trac::RPC::Tools>

=head1 DESCRIPTION

Trac is a great project management and bug/issue tracking system.
http://trac.edgewall.org/.

Trac by itself does not provide API. But there is a plugin that
adds this functionality. It is called XmlRpcPlugin
http://trac-hacks.org/wiki/XmlRpcPlugin.

Trac::RPC is the libraty to use trac functions from perl programs
through XmlRpcPlugin.

On CPAN there is one more module to interact with trac instanse.
It is called L<Net::Trac>. It parses webforms and it does not need
the presense of XmlRpcPlugin.

This is the very early version of Trac::RPC. It has only several
API methods implemented, but it is a skeleton and it is very
easy to add methods implementation. Plese fork this module on github.

Trac::RPC version numbers uses Semantic Versioning standart.
Please visit L<http://semver.org/> to find out all about this great thing.

=encoding UTF-8

=head1 Exceptions

Trac::RPC uses <Exception::Class> to work with extraordinary situations.
Simple example:

    eval {
        $page = $tr->get_page("NoSuchPage");
    };

    if ( Exception::Class->caught('TracExceptionNoWikiPage') ) {
        print "Wiki page not found\n";
    }

=head1 Files

    lib/
    `-- Trac
        |-- RPC
        |   |-- Base.pm         # Abstact base class for all Trac::RPC classes
        |   |-- Exception.pm    # Trac::RPC exceptions declarations (uses Exception::Class)
        |   |-- System.pm       # Implementation of all system.* API methods
        |   |-- Tools.pm        # High level tools
        |   `-- Wiki.pm         # Implementation of all wiki.* API methods
        `-- RPC.pm

=head1 IMPLEMENTED METHODS

For now the module has very few API methods implemented. Here is the list:

    system.listMethods
    wiki.getAllPages
    wiki.getPage
    wiki.putPage

=head1 NOT IMPLEMENTED METHODS

And here is the list of all API methods that needed to be implementd:

    system.multicall
    system.methodHelp
    system.methodSignature
    system.getAPIVersion
    ticket.query
    ticket.getRecentChanges
    ticket.getAvailableActions
    ticket.getActions
    ticket.get
    ticket.create
    ticket.update
    ticket.delete
    ticket.changeLog
    ticket.listAttachments
    ticket.getAttachment
    ticket.putAttachment
    ticket.deleteAttachment
    ticket.getTicketFields
    ticket.status.getAll
    ticket.status.get
    ticket.status.delete
    ticket.status.create
    ticket.status.update
    ticket.component.getAll
    ticket.component.get
    ticket.component.delete
    ticket.component.create
    ticket.component.update
    ticket.version.getAll
    ticket.version.get
    ticket.version.delete
    ticket.version.create
    ticket.version.update
    ticket.milestone.getAll
    ticket.milestone.get
    ticket.milestone.delete
    ticket.milestone.create
    ticket.milestone.update
    ticket.type.getAll
    ticket.type.get
    ticket.type.delete
    ticket.type.create
    ticket.type.update
    ticket.resolution.getAll
    ticket.resolution.get
    ticket.resolution.delete
    ticket.resolution.create
    ticket.resolution.update
    ticket.priority.getAll
    ticket.priority.get
    ticket.priority.delete
    ticket.priority.create
    ticket.priority.update
    ticket.severity.getAll
    ticket.severity.get
    ticket.severity.delete
    ticket.severity.create
    ticket.severity.update
    wiki.getRecentChanges
    wiki.getRPCVersionSupported
    wiki.getPageVersion
    wiki.getPageHTML
    wiki.getPageHTMLVersion
    wiki.getPageInfo
    wiki.getPageInfoVersion
    wiki.listAttachments
    wiki.getAttachment
    wiki.putAttachment
    wiki.putAttachmentEx
    wiki.deletePage
    wiki.deleteAttachment
    wiki.listLinks
    wiki.wikiToHtml
    search.getSearchFilters
    search.performSearchend

=head1 SOURCE CODE

The source code for this module is hosted on GitHub http://github.com/bessarabov/Trac-RPC

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
