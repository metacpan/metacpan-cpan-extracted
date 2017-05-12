########################################################################
#  
#    XML::RSS::FromAtom
#
#    Copyright 2005, Marcus Thiesen (marcus@thiesen.org)  All rights reserved.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of either:
#
#    a) the GNU General Public License as published by the Free Software
#    Foundation; either version 1, or (at your option) any later
#       version, or
#
#    b) the "Artistic License" which comes with Perl.
#
#    On Debian GNU/Linux systems, the complete text of the GNU General
#    Public License can be found in `/usr/share/common-licenses/GPL' and
#    the Artistic Licence in `/usr/share/common-licenses/Artistic'.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
#
########################################################################

package XML::RSS::FromAtom;

use strict;
use warnings;

use base 'Class::Accessor';
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Format::Mail;

our $VERSION = '0.02';

sub parse {
    my $self = shift;
    my $text = shift;
    
    require XML::Atom::Syndication;

    my $atomic = XML::Atom::Syndication->instance;

    return $self->atom_to_rss($atomic->parse($text));
}

sub atom_to_rss {
    my $self = shift;
    my $doc = shift;

    require XML::RSS;
    my $retval = new XML::RSS(version => '2.0');

    my ($feed_title) = $doc->query('/feed/title');
    $retval->channel(title => $feed_title->text_value) if ($feed_title);

    my ($feed_description) = $doc->query('/feed/tagline');
    $retval->channel(description => $feed_description->text_value) if ($feed_description);

    my ($feed_link) = $doc->query('/feed/link/@href');
    $retval->channel(link => $feed_link) if ($feed_link);

    foreach ($doc->query('//entry')) {
        my $desc = '';
        $desc = $_->query('summary')->text_value if defined $_->query('summary');
        if (defined $_->query('content') && 
            length $_->query('content')->text_value > length $desc) {
            $desc = $_->query('content')->text_value;
        }

        my $dt = DateTime::Format::ISO8601->parse_datetime( $_->query('modified')->text_value );

        my ($link) = $_->query('link/@href');
        my ($author) = $_->query('author/name');

        $retval->add_item(
                          title => $_->query('title')->text_value,
                          link  => $link,
                          description => $desc,
                          pubDate => DateTime::Format::Mail->format_datetime($dt),
                          author => $author ? $author->text_value : undef,
                          );
    }

    return $retval;
}

1;

=pod

=head1 NAME

XML::RSS::FromAtom - create a XML::RSS object out of an Atom feed

=head1 SYNOPSIS

    require XML::RSS::FromAtom;
    use LWP::Simple;
    
    my $atom2rss = new XML::RSS::FromAtom;
    my $data = get 'http://ntess.blogspot.com/atom.xml';

    my $rss = $atom2rss->parse($data);
    #$rss->isa('XML::RSS');

    # - OR -
    require XML::Atom::Syndication;
    my $atomic = XML::Atom::Syndication->instance;
    my $doc = $atomic->get('http://www.timaoutloud.org/xml/atom.xml');

    my $rss2 = $atom2rss->atom_to_rss($doc);
    #$rss2->isa('XML::RSS');


=head1 DESCRIPTION

XML::RSS::FromAtom converts a Atom style feed into an XML::RSS object.

=head1 METHODS

=over

=item new( )

Instanciates a new XML::RSS::FromAtom object

=item parse( $string ) 

Parses contents of $string as an Atom feed (using XML::Atom::Syncdication) and returns
it as an XML::RSS object.

=item atom_to_rss ( $object )

Converts an XML::Atom::Syndication::Element as returned by XML::Atom::Syndication get into
an XML::RSS object.

=back

=head1 AUTHOR

Marcus Thiesen, C<< <marcus@thiesen.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-rss-fromatom@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-RSS-FromAtom>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<XML::RSS> L<XML::Atom::Syndication> 

=head1 COPYRIGHT & LICENSE

Copyright 2005 Marcus Thiesen, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CVS

$Id: FromAtom.pm,v 1.1 2005/03/18 17:04:44 marcus Exp $

=cut
