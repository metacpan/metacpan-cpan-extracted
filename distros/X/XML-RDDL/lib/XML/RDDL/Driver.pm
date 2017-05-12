
###
# XML::RDDL::Driver - SAX2 Driver for RDDL Directories
# Robin Berjon <robin@knowscape.com>
# 17/10/2001 - v.0.01
###

package XML::RDDL::Driver;
use strict;
use XML::RDDL               qw();

use base qw(XML::SAX::Base);
use vars qw($VERSION $NS_RDDL $NS_XML $NS_XLINK);
$VERSION  = $XML::RDDL::VERSION;
$NS_RDDL  = $XML::RDDL::NS_RDDL;
$NS_XML   = $XML::RDDL::NS_XML;
$NS_XLINK = $XML::RDDL::NS_XLINK;


#-------------------------------------------------------------------#
# parse
#-------------------------------------------------------------------#
sub parse {
    my $self = shift;
    my $dir  = shift;

    my $doc = $self->_create_node;
    my $pm_rddl = $self->_create_node(
                                    Prefix       => 'rddl',
                                    NamespaceURI => $NS_RDDL,
                                    );
    my $pm_xlnk = $self->_create_node(
                                    Prefix       => 'xlink',
                                    NamespaceURI => $NS_XLINK,
                                    );

    $self->SUPER::start_document($doc);
    $self->SUPER::start_prefix_mapping($pm_rddl);
    $self->SUPER::start_prefix_mapping($pm_xlnk);
    for my $res ($dir->get_resources) {
        my %attr;
        $attr{"{}id"} = $self->_create_node(
                                            Name         => 'id',
                                            LocalName    => 'id',
                                            Prefix       => '',
                                            Value        => $res->get_id,
                                            NamespaceURI => '',
                                            );
        $attr{"{$NS_XML}base"} = $self->_create_node(
                                                    Name         => 'xml:base',
                                                    LocalName    => 'base',
                                                    Prefix       => 'xml',
                                                    Value        => $res->get_base_uri,
                                                    NamespaceURI => $NS_XML,
                                                    );
        $attr{"{$NS_XML}lang"} = $self->_create_node(
                                                    Name         => 'xml:lang',
                                                    LocalName    => 'lang',
                                                    Prefix       => 'xml',
                                                    Value        => $res->get_lang,
                                                    NamespaceURI => $NS_XML,
                                                    );
        $attr{"{$NS_XLINK}href"} = $self->_create_node(
                                                    Name         => 'xlink:href',
                                                    LocalName    => 'href',
                                                    Prefix       => 'xlink',
                                                    Value        => $res->get_href,
                                                    NamespaceURI => $NS_XLINK,
                                                    );
        $attr{"{$NS_XLINK}role"} = $self->_create_node(
                                                    Name         => 'xlink:role',
                                                    LocalName    => 'role',
                                                    Prefix       => 'xlink',
                                                    Value        => $res->get_nature,
                                                    NamespaceURI => $NS_XLINK,
                                                    );
        $attr{"{$NS_XLINK}arcrole"} = $self->_create_node(
                                                    Name         => 'xlink:arcrole',
                                                    LocalName    => 'arcrole',
                                                    Prefix       => 'xlink',
                                                    Value        => $res->get_purpose,
                                                    NamespaceURI => $NS_XLINK,
                                                    );
        $attr{"{$NS_XLINK}title"} = $self->_create_node(
                                                    Name         => 'xlink:title',
                                                    LocalName    => 'title',
                                                    Prefix       => 'xlink',
                                                    Value        => $res->get_title,
                                                    NamespaceURI => $NS_XLINK,
                                                    );

        my $e = $self->_create_node(
                                    Name         => 'rddl:resource',
                                    LocalName    => 'resource',
                                    Prefix       => 'rddl',
                                    NamespaceURI => $NS_RDDL,
                                    Attributes   => \%attr,
                                    );

        $self->SUPER::start_element($e);
        delete $e->{Attributes};
        $self->SUPER::end_element($e);
    }
    $self->SUPER::end_prefix_mapping($pm_xlnk);
    $self->SUPER::end_prefix_mapping($pm_rddl);
    $self->SUPER::end_document($doc);
}
#-------------------------------------------------------------------#

#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Private Helpers `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

#-------------------------------------------------------------------#
# _create_node
#-------------------------------------------------------------------#
sub _create_node {
    shift;
    # this may check for a factory later
    return {@_};
}
#-------------------------------------------------------------------#



1;
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Documentation `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

=pod

=head1 NAME

XML::RDDL::Driver - SAX2 Driver for RDDL Directories

=head1 SYNOPSIS

  use XML::RDDL::Directory;
  use XML::RDDL::Driver;
  use MySAX2Handler;

  my $dir = XML::RDDL::Directory->new;
  # do various things to add to the directory...

  my $handler = MySAX2Handler->new;
  my $driver  = XML::RDDL::Driver->new(Handler => $handler);
  $driver->parse($dir);

=head1 DESCRIPTION

This module is a SAX2 driver that will take an RDDL Directory instance
and generate the appropriate events to serialize it to RDDL.

Note that the rest of the document won't be present, and that if you
don't use the start_document() event to create a container document
and have more than one resource, the generated document won't be
valid. This driver's output is meant to be embedded in something else.

=head1 METHODS

=over 4

=item XML::RDDL->new(%options)

Creates a new XML::RDDL::Driver ready to fire off events. The options
are the same as those passed to all SAX2 drivers.

=item XML::RDDL->parse($directory)

Takes a Directory object and generates the appropriate events.

=back

=head1 AUTHOR

Robin Berjon, robin@knowscape.com

=head1 COPYRIGHT

Copyright (c) 2001-2002 Robin Berjon. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

http://www.rddl.org/, XML::RDDL

=cut

