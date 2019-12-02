package XML::NewsML_G2;

use XML::NewsML_G2::Audio;
use XML::NewsML_G2::Binary;
use XML::NewsML_G2::Concept;
use XML::NewsML_G2::Concept_Item;
use XML::NewsML_G2::Copyright_Holder;
use XML::NewsML_G2::Creator;
use XML::NewsML_G2::Desk;
use XML::NewsML_G2::ElectionDistrict;
use XML::NewsML_G2::ElectionProvince;
use XML::NewsML_G2::Event_Item;
use XML::NewsML_G2::Event_Ref;
use XML::NewsML_G2::Facet;
use XML::NewsML_G2::Genre;
use XML::NewsML_G2::Graphics;
use XML::NewsML_G2::Group;
use XML::NewsML_G2::Icon;
use XML::NewsML_G2::Inline_CData;
use XML::NewsML_G2::Inline_Data;
use XML::NewsML_G2::Link;
use XML::NewsML_G2::Destination;
use XML::NewsML_G2::Location;
use XML::NewsML_G2::Media_Topic;
use XML::NewsML_G2::News_Item;
use XML::NewsML_G2::News_Item_Audio;
use XML::NewsML_G2::News_Item_Graphics;
use XML::NewsML_G2::News_Item_Picture;
use XML::NewsML_G2::News_Item_Text;
use XML::NewsML_G2::News_Item_Video;
use XML::NewsML_G2::News_Message;
use XML::NewsML_G2::Organisation;
use XML::NewsML_G2::Package_Item;
use XML::NewsML_G2::Picture;
use XML::NewsML_G2::Product;
use XML::NewsML_G2::Provider;
use XML::NewsML_G2::Remote_Info;
use XML::NewsML_G2::Scheme;
use XML::NewsML_G2::Scheme_Manager;
use XML::NewsML_G2::Service;
use XML::NewsML_G2::SportFacet;
use XML::NewsML_G2::SportFacetValue;
use XML::NewsML_G2::StoryType;
use XML::NewsML_G2::Substancial_Item;
use XML::NewsML_G2::Topic;
use XML::NewsML_G2::Translatable_Text;
use XML::NewsML_G2::Video;
use XML::NewsML_G2::Writer::Concept_Item;
use XML::NewsML_G2::Writer::Event_Item;
use XML::NewsML_G2::Writer::News_Item;
use XML::NewsML_G2::Writer::News_Message;
use XML::NewsML_G2::Writer::Package_Item;
use XML::NewsML_G2::Writer::Substancial_Item;

use warnings;
use strict;

use version; our $VERSION = qv('0.3.4');

1;

__END__

=head1 NAME

XML::NewsML_G2 - generate NewsML-G2 news items


=head1 VERSION

0.3.4

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme

=head1 SYNOPSIS

    use XML::NewsML_G2;

    my $provider = XML::NewsML_G2::Provider->new
        (qcode => 'nsa', name => 'News Somewhere Agency');

    my $ni = XML::NewsML_G2::News_Item_Text->new
        (title => 'My first NewsML-G2 news item',
         language => 'en', provider => $provider);

    my $writer = XML::NewsML_G2::Writer::News_Item->new(news_item => $ni);
    my $dom = $writer->create_dom();
    print $dom->serialize(1);


=head1 DESCRIPTION

This module tries to implement the creation of XML files conforming to
the NewsML-G2 specification as published by the IPTC. It does not aim
to implement the complete standard, but to cover the most common use
cases in a best-practice manner.

For the full specification of the format, visit
L<http://www.newsml-g2.org/>. For a quick introduction, you might
prefer the L<Quick Start
Guides|http://www.iptc.org/download?g2quickstartguides>.

=head1 GETTING STARTED

To start, you need to create an instance of the item class of your
choice, e.g. L<XML::NewsML_G2::News_Item_Text> for a text story, or
L<XML::NewsML_G2::News_Item_Picture> for an image. Each of these
classes might have some required attributes (e.g. C<title>,
C<language>, C<provider>), which you will have to provide when
creating the instance, as well as a number of optional ones
(e.g. C<note>). While for some attributes scalar values will do,
others will require further instances of classes, e.g. for C<provider>
you will need an instance of L<XML::NewsML_G2::Provider>. Please see
each class' documentation for details.

Once you're done setting up your data structure, you have to create a
writer instance in order to retrieve your DOM. For simple news items
like text or picture, L<XML::NewsML_G2::Writer::News_Item> will be the
writer class to use.

=head1 CURRENT STATUS

The implementation currently supports text, picture, video, audio,
graphics, as well as multimedia packages and slideshows.

Version 2.18 is the latest version of the standard supported by this
software, and should be your first choice. Using versions 2.9, 2.12
and 2.15 is deprecated, and support for it will beremoved in future
releases.

=for readme stop

=head1 SCHEMES AND CATALOGS

Before starting to use schemes or catalogs with this module, read the
chapter 13 of the L<NewsML-G2 implementation
guide|http://www.iptc.org/std/NewsML-G2/2.17/documentation/IPTC-G2-Implementation_Guide_6.1.pdf>.
Go on, do it now. I'll wait.

You don't need to use either schemes or catalogs in order to use this
module, unless you are required to do so by the NewsML-G2 standard
(e.g. the C<service> attribute). If you specify a value for such an
attribute and don't add a corresponding scheme, creating the DOM tree
will die.

For all attributes where a scheme is not required by the standard, you
can start without specifying anything. In that case, a C<literal>
attribute will be created, with the value you specified in the
C<qcode> attribute. For instance:

    my $org = XML::NewsML_G2::Organisation->new(name => 'Google', qcode => 'gogl');
    $ni->add_organisation($org);

will result in this output:

    <subject type="cpnat:organisation" literal="org#gogl">
      <name>Google</name>
    </subject>

If the qcodes used in your organisation instances are part of a
controlled vocabulary, you can convey this information by creating a
L<XML::NewsML_G2::Scheme> instance, specifying a custom, unique C<uri>
for your vocabulary, and registering it with the
L<XML::NewsML_G2::Scheme_Manager>:

    my $os = XML::NewsML_G2::Scheme->new(alias => 'xyzorg',
        uri => 'http://xyz.org/cv/org');
    my $sm = XML::NewsML_G2::Scheme_Manager->new(org => $os);

The output will now contain an inline catalog with your scheme:

    <catalog>
      <scheme alias="xyzorg" uri="http://xyz.org/cv/org"/>
    </catalog>

and the literal will be replaced by a qcode:

    <subject type="cpnat:organisation" qcode="xyzorg:gogl">
      <name>Google</name>
    </subject>

If you have multiple schemes, you can package them together into a
single catalog, which you publish on your website. Simply specify the
URL of the catalog when creating the L<XML::NewsML_G2::Scheme>
instance:

    my $os = XML::NewsML_G2::Scheme->new(alias => 'xyzorg',
        catalog => 'http://xyz.org/catalog_1.xml');

and the inline catalog will be replaced with a link:

    <catalogRef href="http://xyz.org/catalog_1.xml"/>

=head1 API

=head2 Main Classes

=over 4

=item L<XML::NewsML_G2::News_Item>

=item L<XML::NewsML_G2::News_Item_Text>

=item L<XML::NewsML_G2::News_Item_Audio>

=item L<XML::NewsML_G2::News_Item_Picture>

=item L<XML::NewsML_G2::News_Item_Video>

=item L<XML::NewsML_G2::News_Item_Graphics>

=item L<XML::NewsML_G2::News_Message>

=item L<XML::NewsML_G2::Package_Item>

=item L<XML::NewsML_G2::AnyItem>

=back


=head2 Scheme Handling

=over 4

=item L<XML::NewsML_G2::Scheme>

=item L<XML::NewsML_G2::Scheme_Manager>

=back


=head2 Classes for Structured Data Attributes

=over 4

=item L<XML::NewsML_G2::Service>

=item L<XML::NewsML_G2::Video>

=item L<XML::NewsML_G2::Media_Topic>

=item L<XML::NewsML_G2::Topic>

=item L<XML::NewsML_G2::Genre>

=item L<XML::NewsML_G2::Provider>

=item L<XML::NewsML_G2::Desk>

=item L<XML::NewsML_G2::Location>

=item L<XML::NewsML_G2::Organisation>

=item L<XML::NewsML_G2::Product>

=item L<XML::NewsML_G2::Group>

=item L<XML::NewsML_G2::Picture>

=item L<XML::NewsML_G2::Graphics>

=item L<XML::NewsML_G2::Audio>

=item L<XML::NewsML_G2::Copyright_Holder>

=item L<XML::NewsML_G2::Icon>

=item L<XML::NewsML_G2::Link>

=back


=head2 Writer Classes and Roles

=over 4

=item L<XML::NewsML_G2::Writer>

=item L<XML::NewsML_G2::Writer::News_Item>

=item L<XML::NewsML_G2::Writer::News_Message>

=item L<XML::NewsML_G2::Writer::Package_Item>

=item L<XML::NewsML_G2::Role::Writer>

=item L<XML::NewsML_G2::Role::Writer_2_9>

=item L<XML::NewsML_G2::Role::Writer_2_12>

=item L<XML::NewsML_G2::Role::Writer_2_15>

=item L<XML::NewsML_G2::Role::Writer_2_18>

=item L<XML::NewsML_G2::Role::Writer::News_Item_Text>

=item L<XML::NewsML_G2::Role::Writer::News_Item_Audio>

=item L<XML::NewsML_G2::Role::Writer::News_Message>

=item L<XML::NewsML_G2::Role::Writer::News_Item_Picture>

=item L<XML::NewsML_G2::Role::Writer::Package_Item>

=item L<XML::NewsML_G2::Role::Writer::News_Item_Video>

=item L<XML::NewsML_G2::Role::Writer::News_Item_Graphics>

=back


=head2 Type Definitions

=over 4

=item L<XML::NewsML_G2::Types>

=back


=head2 Utility Roles

=over 4

=item L<XML::NewsML_G2::Role::HasQCode>

=item L<XML::NewsML_G2::Role::Remote>

=item L<XML::NewsML_G2::Role::RemoteVisual>

=item L<XML::NewsML_G2::Role::RemoteAudible>

=back

=for readme continue


=head1 DEPENDENCIES

Moose, XML::LibXML, DateTime, DateTime::Format::XSD, UUID::Tiny,
Module::Runtime

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests at
L<https://github.com/apa-it/xml-newsml-g2/issues>.

Be aware that the API for this module I<will> change with each
upcoming release.

=head1 SEE ALSO

=over 4

=item L<XML::NewsML> - Simple interface for creating NewsML documents

=back

=head1 AUTHORS

=over 4

=item Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=item Mario Paumann  C<< <mario.paumann@apa.at> >>

=item Christian Eder  C<< <christian.eder@apa.at> >>

=item Stefan Hrdlicka  C<< <stefan.hrdlicka@apa.at> >>

=back

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2015, APA-IT. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This module is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this module.  If not, see L<http://www.gnu.org/licenses/>.
