#!/usr/bin/perl

package XCAP::Client;

use Moose;
use Moose::Util::TypeConstraints;

use Data::Validate::URI qw(is_uri);

use XCAP::Client::Connection;
use XCAP::Client::Document;
use XCAP::Client::Element;

our $VERSION = "0.07";

has 'connection' => (
    is => 'ro', 
    isa => 'Object',
    lazy => 1,
    default => sub {
        my $self = shift;
        XCAP::Client::Connection->new(
            uri => $self->uri,
            auth_realm => $self->auth_realm,
            auth_username => $self->auth_username,
            auth_password => $self->auth_password
        )
    }
);

has 'uri' => (
    is => 'rw', 
    isa => 'Str', 
    lazy => 1, 
    default => sub { 
        my $self = shift;
        join ('/', $self->xcap_root, $self->application, $self->tree, 
            $self->user, $self->filename);
    },
);

=head1 NAME

XCAP::Client - XCAP client protocol (RFC 4825).

=head1 SYNOPSIS

    use XCAP::Client;

	my $xcap_client = new XCAP::Client(
		xcap_root => "https://my.xcapserver.org/xcap-root",
		user => "sip:foo@domain.org",
		auth_username => "foo",
		auth_password => "bar",
	);

    # Set the document.
    $xcap_client->application('pres-rules');
    $xcap_client->filename('index');
    $xcap_client->tree('user');

    # Delete
    $xcap_client->document->delete;

    # Fetch pres-rules document.
    $xcap_client->document->fetch();

    # If you want to create or replace.
    $xcap_client->document->content($xml_content);
	
    # Create a new document.
    $xcap_client->document->create; 

    # Replace.
    $xcap_client->document->replace;


=head1 DESCRIPTION

XCAP (RFC 4825) is a protocol on top of HTTP which allows a client to manipulate the contents of Presence Information Data Format (PIDF) based presence documents. These documents are stored in a server in XML format and are fetched, modified, replaced or deleted by the client. The protocol allows multiple clients to manipulate the data, provided that they are authorized to do so. XCAP is already used in SIMPLE-based presence systems for manipulation of presence lists and presence authorization policies.

XCAPClient library implements the XCAP protocol in client side, allowing the applications to get, store, modify and delete XML documents in the server. 

The module implements the following features:

 * Fetch, create/replace and delete a document.
 * Parameters allowing customized fields for each XCAP application.
 * Manage of multiple documents per XCAP application.
 * SSL support.
 * Exception for each HTTP error response.
 * Digest and Basic HTTP authentication.

Todo:

 * Fetch, create/replace and delete a document element (XML node)
 * Fetch, create/replace and delete an element attribute. 
 * Fetch the XCAP server auids, extensions and namespaces.

=head1 ATTRIBUTES

=head2 xcap_root

It's a context that contains all the documents across all application usages and users that are managed by the server.

The root of the XCAP hierarchy is called the XCAP root. It defines the context in which all other resources exist. The XCAP root is represented with an HTTP URI, called the XCAP Root URI. This URI is a valid HTTP URI; however, it doesn't point to any resource that actually exists on the server. Its purpose is to identify the root of the tree within the domain where all XCAP documents are stored.

=cut

subtype 'IsURI' 
    => as 'Str' 
    => where { is_uri($_) } 
    => message { "This xcap_root ($_) is not an uri!" };

has 'xcap_root' => (
    is => 'rw',
    isa => 'IsURI' 
);

=head2 user 

user - User that represents the parent for all documents for a particular user for a particular application usage within a particular XCAP root.

=cut

subtype 'IsUserID'
    => as 'Str'
    => where { $_ =~ /^sip(s)?:.*@.*/ }
    => message { 'User entry needs to be sip:foo@domain.org.' };

has 'user' => (
    is => 'rw',
    isa => 'IsUserID'
);


=head2 auth_realm

auth_realm - The HTTP authentication realm or name.

=head2 auth_username

auth_username - The HTTP authentication username.

=head2 auth_password

auth_password - The HTTP authentcation password.

=cut

has ['auth_realm', 'auth_username', 'auth_password'] => ( 
    is => 'rw', 
    isa => 'Str'
);

=head2 application

Application can be resource-lists, rls-services, pres-rules, pdif-manipulations or xcap-caps. (Default: pres-rules)

=cut

has 'application' => (
    is => 'rw', 
    isa => enum([qw[resource-lists rls-services pres-rules pdif-manipulation watchers xcap-caps ]]), 
    default => 'pres-rules'
);

=head2 tree

Tree can be users or global. (Default: users)

=cut

has 'tree' => (
    is => 'rw', 
    isa => enum([qw[users global]]),
    default => 'users'
);

=head2 filename

Filename. (Default: index)

=cut

has 'filename' => (
    is => 'rw', 
    isa => 'Str', 
    default => 'index'
);

=head1 METHODS

=head2 document->[create,fetch,replace,delete]

You can create, fetch, replace or delete a document with this methods. To use create or delete you need to say the content of the "document->content".

=cut

has 'document' => (
    is => 'ro',
    isa => 'Object',
    lazy => 1,
    default => sub { 
        my $self = shift;
        XCAP::Client::Document->new(connection => $self->connection) }
);

=head2 element->[add,fetch]

=cut

has 'element' => (
    is => 'ro',
    isa => 'Object',
    lazy => 1,
    default => sub { 
        my $self = shift;
        XCAP::Client::Element->new(connection => $self->connection) }
);

=head1 AUTHOR

Thiago Rondon <thiago@aware.com.br>

http://www.aware.com.br/

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Aware.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;

