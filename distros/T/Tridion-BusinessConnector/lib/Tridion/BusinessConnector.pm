# Tridion::BusinessConnector
# written by Toby Corkindale (perl (at) corkindale.net)
# Copyright (c) 2004 Toby Corkindale, All rights reserved.
#
# $Id: BusinessConnector.pm 18 2005-12-21 16:38:11Z tjc $
#
# This Perl module is distributed under the terms of the LGPL:
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This license can be found at http://www.gnu.org/licenses/lgpl.html
#

# This module will help you interface Perl programs to Tridion(tm)'s
# content management system. 

package Tridion::BusinessConnector;
use strict;
use warnings;

use XML::LibXML;

our $VERSION = '0.04';

# Tridion namespaces: (Current as of 2004 - may need to be updated one day?)
our $TCM_NS = 'http://www.tridion.com/ContentManager/5.0';
our $TCMAPI_NS = 'http://www.tridion.com/ContentManager/5.0/TCMAPI';


# Initialise the SOAP subsystem:
use SOAP::Lite
    on_fault => sub {
        my $soap = shift;
        my $res = shift;
        ref $res ? die(join "\n", "--- SOAP FAULT ---", $res->faultcode,
                       $res->faultstring, '')
                 : die(join "\n", "--- TRANSPORT ERROR ---",
                       $soap->transport->status, '');
    }
;


sub new {
    my $proto = shift;
    my %args = @_;
    my $class = ref($proto) || $proto;
    my $self = {};

    $self->{hostname} = $args{hostname};
    $self->{username} = $args{username};
    $self->{password} = $args{password};

    $self->{_parser} = new XML::LibXML;

    $self->{_soaplite} = new SOAP::Lite
        uri => 'http://schemas.xmlsoap.org/soap/encoding/',
        proxy => 'http://' . $self->{hostname} . '/BCListener/services/urn:bc'
        ;
    
    $self->{_soaplite}->transport->credentials(
                                               $self->{hostname} . ':80',
                                               $self->{hostname},
                                               $self->{username},
                                               $self->{password}
                                              );

    bless($self, $class);
    return $self;
}


sub execute
{
    my $self = shift;
    my $requestXML = shift;
    my $method = SOAP::Data->name('execute')
                           ->attr({xmlns => 'urn:bc'});

    my $obj = $self->{_soaplite}->call($method => ('default', $requestXML));
    return $obj->result;
}


sub GetItem
{
    my $self = shift;
    my $uri = shift;

    die("Invalid TCM URI: $uri\n") unless ($uri =~ /^tcm:\d+(\-\d+)*$/);

    my $requestXML =<<EOM;
<tcmapi:Message xmlns:tcmapi="http://www.tridion.com/ContentManager/5.0/TCMAPI"
 version="5.0" from="SOAPMod" failOnError="true">
    <tcmapi:Request ID="Request1" preserve="false">
        <tcmapi:GetItem itemURI="$uri" />
    </tcmapi:Request>
</tcmapi:Message>
EOM

    my $result = $self->execute($requestXML);
    my $xml = $self->{_parser}->parse_string($result);
    if ($xml->findvalue('/tcmapi:Message/tcmapi:Response/@success') ne 'true') {
        die("---- Request Failed, Dumping output ----\n$result\n");
    }

    # get the first, and only, child of <Result>, and make that the new
    # document root
    my ($data) = $xml->documentElement()->findnodes('/tcmapi:Message/tcmapi:Response/tcmapi:Result/*');
    
    my $newdoc = new XML::LibXML::Document;
    $newdoc->setDocumentElement($data);

    return $newdoc;
}


sub SaveItem
{
    my $self = shift;
    my $xml = shift;
    my $uri = shift;
    my $context_uri = shift;

    die("Invalid TCM URI: $uri\n") unless ($uri =~ /^tcm:\d+(\-\d+)*$/);
    die("Invalid TCM URI: $context_uri\n") unless ($context_uri =~ /^tcm:\d+(\-\d+)*$/);

    my $requestDoc = new XML::LibXML::Document;
    my $root = $requestDoc->createElement('Message');
    $root->setNamespace($TCMAPI_NS, 'tcmapi', 1);
    $root->setAttribute('version', '5.0');
    $root->setAttribute('from', 'SOAPMod');
    $root->setAttribute('failOnError', 'true');
    $requestDoc->setDocumentElement($root);

    my $node = $requestDoc->createElement('tcmapi:Request');
    $node->setAttribute('ID', 'Request1');
    $node->setAttribute('preserve', 'false');
    $root->addChild($node);

    my $savenode = $requestDoc->createElement('tcmapi:SaveItem');
    $savenode->setAttribute('itemURI', $uri);
    $savenode->setAttribute('contextURI', $context_uri);
    $savenode->setAttribute('doneEditing', 'true');
    $node->addChild($savenode);

    # set 'itemType' attr to correct type
    my $type = $xml->documentElement->nodeName;
    $type =~ s/^\w+://;
    $savenode->setAttribute('itemType', $type);

    # And add the provided component or whatever.
    $savenode->addChild($xml->documentElement);

    my $result = $self->execute($requestDoc->toString);
    $xml = $self->{_parser}->parse_string($result);
    if ($xml->findvalue('/tcmapi:Message/tcmapi:Response/@success') ne 'true') {
        die("---- Request Failed, Dumping output ----\n$result\n");
    }

    # get the first, and only, child of <Result>, and make that the new
    # document root
    my ($data) = $xml->documentElement()->findnodes('/tcmapi:Message/tcmapi:Response/tcmapi:Result/*');
    
    my $newdoc = new XML::LibXML::Document;
    $newdoc->setDocumentElement($data);

    return $newdoc;
}


# In case you need to discover the proper values for realm or netloc for
# your own server, uncomment these:
#sub SOAP::Transport::HTTP::Client::get_basic_credentials
#{
#    my($self, $realm, $uri, $proxy) = @_;
#    warn "Realm[$realm]\nURI[$uri]\nproxy[$proxy]\n";
#    warn "host_port[" . $uri->host_port . "]\n";
#}

1;

__END__

=pod

=head1 NAME

Tridion::BusinessConnector - Interface to Tridion's "Business Connector"

=head1 VERSION

  Version 0.02, released April 2004
  CVS Version $Id: BusinessConnector.pm 18 2005-12-21 16:38:11Z tjc $

=head1 NOTICE

  Written by Toby Corkindale (toby (at) corkindale.net)
  Copyright (c) 2004, 2005 Toby Corkindale.

This Perl module is distributed under the terms of the LGPL:

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This license can be found at http://www.gnu.org/licenses/lgpl.html

I am not affiliated with Tridion. This module was not created with their aid,
and is not supported by them.

=head1 SYNOPSIS

    use Tridion::BusinessConnector;
    my $bc = new Tridion::BusinessConnector(
                    hostname => 'tridionCMS',
                    username => 'DOMAIN/tjc',
                    password => 'p@ssw0rd'
                    );
    my $target_uri = shift(@ARGV);
    die("Invalid TCM URI\n") unless ($target_uri =~ /^tcm:\d+(\-\d+)*$/);
    my $item = $bc->GetItem($target_uri);
    print $item->toString(1);

=head1 DESCRIPTION

This module provides a handy interface to the Tridion CMS' SOAP interface,
known as the "Business Connector" in their documentation. It handles things
like escaping passwords, XML namespaces, request/response formats, and stuff
like that.

This is the first version, and as such provides only a few functions, mainly
at low levels. For everything other than GetItem and SaveItem issues, you will
use the execute() function. At a later date I will add direct functions for
DeleteItem, GetList, Publish, Search, and so on.

=head1 FUNCTIONS

=head2 new()

This function takes three parameters: hostname, username, password.

=over

=item *

hostname - this is the host which this instance of the T::B module should
talk to.

=item *

username - the username to connect with. Note that you may need to prefix
it with the NTLM domain, if you're using that for authentication.

=item *

password - the password to connect with.

=back

=head4 Example:

    use Tridion::BusinessConnector;
    my $bc = new Tridion::BusinessConnector(
                    hostname => 'tridionCMS',
                    username => 'DOMAIN/tjc',
                    password => 'p@ssw0rd'
                    );


=head2 execute()

This function takes one parameter: a string containing a complete XML request.

This means you need to create all the request generation yourself, etc. This
function is mainly used internally by the higher level interfaces, but is
provided so you can call Tridion functions that have not yet got a high-level
function in this module.

=head2 GetItem()

This function takes one parameter: a string containing a TCM URI.

It will query the Tridion system, and retrieve whatever that URI matches.
It will not check-out or lock the item.

Upon success, the function will return a XML::LibXML::Document.

The function will die on failure, so you can call it from an eval {}; setup to
catch the failure and get the error message if you like, or just let it dump
to stderr. This 'die on fail' behaviour will not change in future releases,
but I think I will add some better pre-processing of the error message.
Also, be warned that a non-fatal error will probably be changed to not die, but
just return undef, at some stage in the future.

=head2 SaveItem()

This function takes three parameters:

=over

=item *

An XML::LibXML::Document, which contains the item to be saved.

=item *

The URI to save the data to. If you want to create a new item, then pass in
the magic value of 'tcm:0-0-0' here.

=item *

The "context" of the item - ie. the folder or structure group which you want
the item to appear within. If you are saving an existing item, then you must
leave this set to 'tcm:0-0-0' instead. (Tridion's requirement, not mine.)

=back

Note that for reasons that are not entirely clear to me, one cannot just
get an item, change the bits you want, and then save it back. The data included
with a GetItem includes sundry information from Tridion, such as context,
permissions, status, etc. but any attempt to save an item back that includes
that information will fail! So, remember to strip out it out before saving..

=cut

