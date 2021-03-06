package XML::GSA;

use strict;
use warnings;

use XML::Writer;
use Data::Dumper;
use Carp;
use DateTime    ();
use Date::Parse ();
use XML::GSA::Group;

sub new {
    my $class = shift;

    return bless {
        'type'       => 'incremental',
        'datasource' => 'web',
        @_,
        'groups'   => [],
        'encoding' => 'UTF-8',    #read-only
        },
        ref $class || $class;
}

#encoding is read-only
sub encoding {
    my $self = shift;

    return $self->{'encoding'};
}

#getters
sub xml {
    my $self = shift;

    return $self->{'xml'};
}

sub to_string {
    my $self = shift;

    return $self->{'xml'};
}

sub writer {
    my $self = shift;

    return $self->{'writer'};
}

#getters and setters
sub type {
    my ( $self, $value ) = @_;

    $self->{'type'} = $value
        if $value && $value =~ /(incremental|full|metadata-and-url)/;

    return $self->{'type'};
}

sub datasource {
    my ( $self, $value ) = @_;

    $self->{'datasource'} = $value
        if $value;

    return $self->{'datasource'};
}

sub base_url {
    my ( $self, $value ) = @_;

    $self->{'base_url'} = $value
        if $value;

    return $self->{'base_url'};
}

sub groups {
    my $self = shift;

    return $self->{'groups'} || [];
}

sub add_group {
    my ( $self, $value ) = @_;

    unless ( ref $value eq 'HASH' || ref $value eq 'XML::GSA::Group' ) {
        carp("Must receive an HASH ref or an XML::GSA::Group object");
        return;
    }

    my $group
        = ref $value eq 'HASH'
        ? XML::GSA::Group->new(
        'action'  => $value->{'action'},
        'records' => $value->{'records'}
        )
        : $value;

    push @{ $self->groups }, $group;
}

#empties the group arrayref
sub clear_groups {
    my $self = shift;

    $self->{'groups'} = [];
}

sub create {
    my ( $self, $data ) = @_;

    #use $self->groups
    if ( !defined $data ) {
        $data = $self->groups();
    }
    else {    #add each structure as new group, emptying the existing groups
        unless ( ref $data eq 'ARRAY' ) {
            carp("An array data structure must be passed as parameter");
            return;
        }

        $self->clear_groups();
    }

    my $writer = XML::Writer->new( OUTPUT => 'self', 'UNSAFE' => 1 );
    $self->{'writer'} = $writer;

    $self->writer->xmlDecl( $self->encoding );
    $self->writer->doctype( "gsafeed", '-//Google//DTD GSA Feeds//EN', "" );

    $self->writer->startTag('gsafeed');
    $self->writer->startTag('header');
    $self->writer->dataElement( 'datasource', $self->datasource() );
    $self->writer->dataElement( 'feedtype',   $self->type() );
    $self->writer->endTag('header');

    for my $group ( @{ $data || [] } ) {

        #if not group, add it as one
        unless ( ref $group eq 'XML::GSA::Group' ) {

            $group = XML::GSA::Group->new(
                'action'  => $group->{'action'},
                'records' => $group->{'records'}
            );
        }
        $group->create($self);

        $self->writer->raw( $group->to_string );
    }

    $self->writer->endTag('gsafeed');

    my $xml = $self->writer->to_string;

    #gsa needs utf8 encoding
    utf8::encode($xml);

    $self->{'xml'} = $xml;
    return $xml;
}

1;

=head1 NAME

XML::GSA - Creates xml in google search appliance (GSA) format

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

This is a lib that allows one to create xml in Google Search Appliance (GSA) format.

You can use this lib in the following way:

    use XML::GSA;

    my $gsa = XML::GSA->new('base_url' => 'http://foo.bar');
    my $xml = $gsa->create(
        [   {   'action'  => 'add',
                'records' => [
                    {   'url'      => '/aaa',
                        'mimetype' => 'text/plain',
                        'action'   => 'delete',
                    },
                    {   'url'      => '/bbb',
                        'mimetype' => 'text/plain',
                        'metadata' => [
                            { 'name' => 'og:title', 'content' => 'BBB' },
                        ],
                    }
                ],
            },
        ]
    );
    print $xml;

Which will output:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE gsafeed PUBLIC "-//Google//DTD GSA Feeds//EN" "">
    <gsafeed>
        <header>
            <datasource>Source</datasource>
            <feedtype>incremental</feedtype>
        </header>
        <group action="add">
            <record action="delete" url="http://www.foo.bar/aaa" mimetype="text/plain"></record>
            <record url="http://www.foo.bar/bbb" mimetype="text/plain">
                <metadata>
                    <meta content="BBB" name="og:title"></meta>
                </metadata>
            </record>
        </group>
    </gsafeed>

=head1 METHODS

=head2 new( C<$params> )

Create a new XML::GSA object:

        my $gsa = XML::GSA->new('base_url' => 'http://foo.bar');

Arguments of this method are an anonymous hash of parameters:

=head3 datasource

Defines the datasource to be included in the header of the xml.

=head3 type

Defines the type of the feed. This attribute tells the feed what kind of attributes the records are able to receive.

=head3 base_url

Defines a base url to be preppended to all records' urls.

=cut

=head2 type( C<$value> )

Getter/setter for the type attribute of GSA feed. By default it is 'incremental'.
Possible values are 'incremental', 'full' or 'metadata-and-url'

=cut

=head2 datasource( C<$value> )

Getter/setter for the datasource attribute of GSA feed. By default it is 'web'.

=cut

=head2 base_url( C<$value> )

Getter/setter for the base_url attribute of GSA feed. This is an url that will be preppended to all record urls. If a base_url is not defined, one must pass full urls in the records data structure.

=cut

=head2 create( C<$data> )

Receives an arrayref data structure where each entry represents a group in the xml, generates an xml in GSA format and returns it as a string.
Important note: All data passed to create must be in unicode! This class will utf-8 encode it making it compatible with GSA.

One can have has many group has one wants, and a group is an hashref with an optional key 'action' and a mandatory key 'records'. The key 'action' can have the values of 'add' or 'delete' and the 'records' key is an array of hashrefs.

Each hashref in the array corresponding to 'records' can have the following keys:

    * Mandatory
        * url
        * mimetype => (text/plain|text/html) - in the future it will also support other mimetype
    * Optional
        * action            => (add|delete)
        * lock              => (true|false)
        * displayurl        => an url
        * last-modified     => a well formatted date as string
        * authmethod        => (none|httpbasic|ntlm|httpsso)
        * pagerank          => an int number
        * crawl-immediately => (true|false)
        * crawl-once        => (true|false)

=cut

=head2 create

Creates the xml using the groups already added to the object.

=head2 add_group( C<$group> )

Receives an hashref data structure representing a group and adds it to the current feed - you must call the `create` method with no arguments to have the xml updated. A group is an hashref with an optional key 'action' and a mandatory key 'records'. The key 'action' can have the values of 'add' or 'delete' and the 'records' key is an array of hashrefs.

Each hashref in the array corresponding to 'records' can have the following keys:

    * Mandatory
        * url
        * mimetype => (text/plain|text/html) - in the future it will also support other mimetype
    * Optional
        * action            => (add|delete)
        * lock              => (true|false)
        * displayurl        => an url
        * last-modified     => a well formatted date as string
        * authmethod        => (none|httpbasic|ntlm|httpsso)
        * pagerank          => an int number
        * crawl-immediately => (true|false)
        * crawl-once        => (true|false)

Important note: All data passed must be in unicode! This class will utf-8 encode it making it compatible with GSA.

=head2 add_group( C<$group> )

Receives an instance of the class XML::GSA::Group and adds it to the current feed - you must call the `create` method with no arguments to have the xml updated.

=head2 clear_groups

Empties the property `groups` of this class.

=head2 xml

Getter for the xml generated by the `create` method.

=head2 to_string

    Getter for the xml generated by the `create` method.

=head2 encoding

Getter for the encoding used in this class

=head2 groups

Getter for the array of groups added to this class

=head2 writer

Getter for the XML::Writer object used in this class to create the xml

=cut

=head1 AUTHOR

Shemahmforash, C<< <shemahmforash at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-gsa at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-GSA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::GSA


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-GSA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-GSA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-GSA>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-GSA/>

=item * Github Repository

L<https://github.com/Shemahmforash/xml-gsa/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Shemahmforash.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut
