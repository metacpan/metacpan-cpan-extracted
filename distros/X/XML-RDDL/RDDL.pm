
###
# XML::RDDL - Interface to RDDL (http://www.rddl.org/)
# Robin Berjon <robin@knowscape.com>
# 17/10/2001 - v.0.01
###

package XML::RDDL;
use strict;
use XML::RDDL::Directory    qw();
use XML::RDDL::Resource     qw();

use vars qw($VERSION $NS_RDDL $NS_XML $NS_XLINK);
$VERSION  = '1.02';
$NS_XML   = 'http://www.w3.org/XML/1998/namespace';
$NS_RDDL  = 'http://www.rddl.org/';
$NS_XLINK = 'http://www.w3.org/1999/xlink';



#-------------------------------------------------------------------#
# constructor
#-------------------------------------------------------------------#
sub new {
    my $class   = ref($_[0]) ? ref(shift) : shift;
    my %opt     = @_;

    my $self = {
                xLangStack  => [$opt{default_lang}],
                xBaseStack  => [$opt{default_base_uri}],
                directory   => XML::RDDL::Directory->new,
               };
    return bless $self, $class;
}
#-------------------------------------------------------------------#


#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, SAX2 Handler ,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

#-------------------------------------------------------------------#
# start_document & end_document
#-------------------------------------------------------------------#
sub start_document { $_[0]->{directory} = XML::RDDL::Directory->new; }
sub end_document   { return $_[0]->{directory}; }
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# start_element
#-------------------------------------------------------------------#
sub start_element {
    my $self = shift;
    my $e = shift;

    # xml:lang and xml:base stacks
    push @{$self->{xLangStack}}, get_attribute($e, $NS_XML, 'lang');
    push @{$self->{xBaseStack}}, get_attribute($e, $NS_XML, 'base');

    #deal with rddl:resource
    return unless $e->{NamespaceURI} eq $NS_RDDL and $e->{LocalName} eq 'resource';

    my $type  = get_attribute($e, $NS_XLINK, 'type')    || 'simple';
    my $embed = get_attribute($e, $NS_XLINK, 'embed')   || 'none';
    my $actu  = get_attribute($e, $NS_XLINK, 'actuate') || 'none';
    die "[RDDL] xlink:type can only be set to 'simple'" if $type ne 'simple';
    die "[RDDL] xlink:embed can only be set to 'none'" if $embed ne 'none';
    die "[RDDL] xlink:actuate can only be set to 'none'" if $actu ne 'none';

    my $id      = get_attribute($e, '',        'id')      || '';
    my $role    = get_attribute($e, $NS_XLINK, 'role')    || 'http://www.rddl.org/#resource';
    my $arcrole = get_attribute($e, $NS_XLINK, 'arcrole') || '';
    my $href    = get_attribute($e, $NS_XLINK, 'href')    || '';
    my $title   = get_attribute($e, $NS_XLINK, 'title')   || '';

    my $xlang = get_last_defined($self->{xLangStack}) || '';
    my $xbase = get_last_defined($self->{xBaseStack}) || '';

    my $res = XML::RDDL::Resource->new(
                                        id          => $id,
                                        base_uri    => $xbase,
                                        href        => $href,
                                        nature      => $role,
                                        purpose     => $arcrole,
                                        title       => $title,
                                        lang        => $xlang,
                                      );
    $self->{directory}->add_resource($res);
}
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# end_element
#-------------------------------------------------------------------#
sub end_element {
    my $self = shift;
    pop @{$self->{xLangStack}};
    pop @{$self->{xBaseStack}};
}
#-------------------------------------------------------------------#


#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Misc. Helpers `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

#-------------------------------------------------------------------#
# get_last_defined
#-------------------------------------------------------------------#
sub get_last_defined {
    my $arr = shift;
    for my $el (reverse @$arr) {
        return $el if defined $el;
    }
}
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# get_attribute
#-------------------------------------------------------------------#
sub get_attribute {
    my $e   = shift;
    my $ns  = shift;
    my $ln  = shift;

    if (exists $e->{Attributes}->{"{$ns}$ln"}) {
        return $e->{Attributes}->{"{$ns}$ln"}->{Value};
    }
    return undef;
}
#-------------------------------------------------------------------#



1;
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Documentation `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

=pod

=head1 NAME

XML::RDDL - Interface to RDDL (http://www.rddl.org/)

=head1 SYNOPSIS

  use XML::RDDL;
  use MySAX2Driver;

  my $handler = XML::RDDL->new(
                                default_lang     => 'en',
                                default_base_uri => 'http://foo/doc.xml',
                              );
  my $driver = MySAX2Driver->new(Handler => $handler);
  my $rddl = $driver->parse($some_rddl);

=head1 DESCRIPTION

RDDL (Resource Directory Description Language) is an XML vocabulary
used to described resources associated with a namespace. It can be
embedded inside other XML vocabularies (most frequently XHTML).

This module is meant to be used as a SAX2 handler that will return a
Directory instance containing all resource descriptions at the end of
the parse.

=head1 METHODS

=over 4

=item XML::RDDL->new(%options)

Creates an XML::RDDL instance which is a SAX2 handler. The options
are:

  - default_lang
    the default language (as described in an xml:lang attribute) to
    be used. It is recommended that this be used if you want to have
    multilingual resources and your document doesn't contain
    sufficient xml:lang attributes.

  - default_base_uri
    the default base URI (as described in an xml:base attribute) to
    be used (principally in xlink:href resolution). It is recommended
    that this be used if you want to resolve the xlink:hrefs and the
    document doesn't contain the appropriate xml:base attributes.

=back

=head1 AUTHOR

Robin Berjon, robin@knowscape.com

=head1 COPYRIGHT

Copyright (c) 2001-2002 Robin Berjon. All rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

http://www.rddl.org/, XML::RDDL::Directory, XML::RDDL::Resource,
XML::RDDL::Driver

=cut

