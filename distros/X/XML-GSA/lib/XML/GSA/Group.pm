package XML::GSA::Group;

use strict;
use warnings;

use XML::Writer;
use Data::Dumper;
use Carp;
use DateTime    ();
use Date::Parse ();

sub new {
    my $class = shift;

    return bless { 'records' => [], 'action' => 'add', @_, },
        ref $class || $class;
}

#getters
sub writer {
    my $self = shift;

    return $self->{'writer'};
}

sub xml {
    my $self = shift;

    return $self->{'xml'};
}

sub to_string {
    my $self = shift;

    return $self->{'xml'};
}

sub records {
    my $self = shift;

    return $self->{'records'} || [];
}

#getters and setters
sub action {
    my ( $self, $value ) = @_;

    $self->{'action'} = $value
        if $value && $value =~ /(add|delete)/;

    return $self->{'action'};
}

#other public methods
sub create {
    my ( $self, $feed ) = @_;

    return unless $feed && ref $feed eq 'XML::GSA';

    #always
    my $writer = XML::Writer->new( OUTPUT => 'self', );
    $self->{'writer'} = $writer;

    my %attributes;
    $attributes{'action'} = $self->action
        if defined $self->action;

    $self->writer->startTag( 'group', %attributes );

    for my $record ( @{ $self->records || [] } ) {
        $self->_add_record( $record, $feed );
    }

    $self->writer->endTag('group');

    my $xml = $self->writer->to_string;
    $self->{'xml'} = $xml;

    return $xml;
}

#private methods

#adds a record to a feed
sub _add_record {
    my ( $self, $record, $feed ) = @_;

    return unless $self->writer && $record && ref $record eq 'HASH';

    #url and mimetype are mandatory parameters for the record
    return unless $record->{'url'} && $record->{'mimetype'};

    my $attributes = $self->_record_attributes( $record, $feed );

    $self->writer->startTag( 'record', %{ $attributes || {} } );

    if ( $record->{'metadata'} && ref $record->{'metadata'} eq 'ARRAY' ) {
        $self->_add_metadata( $record->{'metadata'} );
    }

    $self->_record_content($record)
        if $feed->type eq 'full';

    $self->writer->endTag('record');
}

#adds record content part
sub _record_content {
    my ( $self, $record ) = @_;

    return unless $self->writer && $record->{'content'};

    if ( $record->{'mimetype'} eq 'text/plain' ) {
        $self->writer->dataElement( 'content', $record->{'content'} );
    }
    elsif ( $record->{'mimetype'} eq 'text/html' ) {
        $self->writer->cdataElement( 'content', $record->{'content'} );
    }

    #else {
    #TODO support other mimetype with base64 encoding content
    #}
}

#creates record attributes
sub _record_attributes {
    my ( $self, $record, $feed ) = @_;

    #must be a full record url
    #that is: if no base url, the url in record must start with http
    #base url and url in record can't include the domain at the same time
    if (( !$feed->base_url && $record->{'url'} !~ /^http/ )
        || (   $feed->base_url
            && $feed->base_url  =~ /^http/
            && $record->{'url'} =~ /^http/ )
        )
    {
        return {};
    }

    #mandatory attributes
    my %attributes = (
        'url' => $feed->base_url
        ? sprintf( '%s%s', $feed->base_url, $record->{'url'} )
        : $record->{'url'},
        'mimetype' => $record->{'mimetype'},
    );

    ####optional attributes####

    #action is delete or add
    $attributes{'action'} = $record->{'action'}
        if $record->{'action'}
            && $record->{'action'} =~ /^(delete|add)$/;

    #lock is true or false
    $attributes{'lock'} = $record->{'lock'}
        if $record->{'lock'}
            && $record->{'lock'} =~ /^(true|false)$/;

    $attributes{'displayurl'} = $record->{'displayurl'}
        if $record->{'displayurl'};

    #validate datetime format
    if ( $record->{'last-modified'} ) {
        my $date = $self->_to_RFC822_date( $record->{'last-modified'} );

        $attributes{'last-modified'} = $date
            if $date;
    }

    #allowed values for authmethod
    $attributes{'authmethod'} = $record->{'authmethod'}
        if $record->{'authmethod'}
            && $record->{'authmethod'} =~ /^(none|httpbasic|ntlm|httpsso)$/;

    $attributes{'pagerank'} = $record->{'pagerank'}
        if $feed->type ne 'metadata-and-url' && defined $record->{'pagerank'};

    #true or false and only for web feeds
    $attributes{'crawl-immediately'} = $record->{'crawl-immediately'}
        if $feed->datasource eq 'web'
            && $record->{'crawl-immediately'}
            && $record->{'crawl-immediately'} =~ /^(true|false)$/;

    #for web feeds
    $attributes{'crawl-once'} = $record->{'crawl-once'}
        if ( $feed->datasource eq 'web'
        && $feed->type() eq 'metadata-and-url'
        && $record->{'crawl-once'}
        && $record->{'crawl-once'} =~ /^(true|false)$/ );

    return \%attributes;
}

sub _add_metadata {
    my ( $self, $metadata ) = @_;

    return unless $self->writer && scalar @{ $metadata || [] };

    $self->writer->startTag('metadata');
    for my $meta ( @{ $metadata || [] } ) {
        next unless $meta->{'name'} && $meta->{'content'};

        my $content = $meta->{'content'};

        if( ref $content eq 'ARRAY' ) {
            $content = join ';', @{ $content || [] };
        }

        my %attributes = (
            'name'    => $meta->{'name'},
            'content' => $content,
        );

        $self->writer->dataElement( 'meta', '', %attributes );
    }

    $self->writer->endTag('metadata');
}

#receives a string representing a datetime and returns its RFC822 representation
sub _to_RFC822_date {
    my ( $self, $value ) = @_;

    my $epoch = Date::Parse::str2time($value);

    unless ($epoch) {
        carp("Unknown date format received");
        return;
    }

    my $datetime = DateTime->from_epoch(
        'epoch'     => $epoch,
        'time_zone' => 'local',
    );

    return $datetime->strftime('%a, %d %b %Y %H:%M:%S %z');
}

1;


=head1 NAME

XML::GSA::Group - A class that represents a group in gsa xml

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 METHODS

=head2 new( C<$params> )

Create a new XML::GSA::Group object:

    my $gsa = XML::GSA->new('records' => [], 'action' => 'add');

Arguments of this method are an anonymous hash of parameters:

=head3 records

An arrayref of hashrefs where each of the hashrefs represents a gsa xml record

=head3 action

A string that can be 'add' or 'delete' that defines what this group will do to the gsa indexer

=cut

=head2 create( C<$feed> )

Receives an instance of XML::GSA so that when creating the group, one know to what feed will it belong. This is necessary because the type of feed influences the type of parameters acccepted by the group.

=cut

=head2 action

Getter or the action attribute


=head2 xml

Getter for the xml generated by the `create` method.

=head2 to_string

Getter for the xml generated by the `create` method.

=head2 records

Getter for the array of groups records added to this class

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
