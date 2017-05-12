package WWW::Ohloh::API::Factoid;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;

our $VERSION = '0.3.2';

my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @xml_of : Field : Arg(xml);

my @api_fields = qw/
  id
  analysis_id
  type
  description
  severity
  license_id
  /;

my @id_of : Field : Set(_set_id) : Get(id);
my @analysis_id_of : Field : Set(_set_analysis_id) : Get(analysis_id);
my @type_of : Field : Set(_set_type) : Get(type);
my @description_of : Field : Set(_set_description) : Get(description);
my @severity_of : Field : Set(_set_severity) : Get(severity);
my @license_id_of : Field : Set(_set_license_id) : Get(license_id);

my @ohloh_of : Field : Arg(ohloh);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    $self->_set_id( $dom->findvalue("id/text()") );
    $self->_set_analysis_id( $dom->findvalue("analysis_id/text()") );
    $self->_set_type( $dom->findvalue("type/text()") );
    $self->_set_description( $dom->findvalue("description/text()") );
    $self->_set_severity( $dom->findvalue("severity/text()") );
    $self->_set_license_id( $dom->findvalue("license_id/text()") );

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('factoid');

    for my $e (@api_fields) {
        $w->dataElement( $e => $self->$e );
    }

    $w->endTag;

    return $xml;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

'end of WWW::Ohloh::API::Factoid';

__END__

=head1 NAME

WWW::Ohloh::API::Factoid - A factoid about an Ohloh project

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my @factoids =  $ohloh->get_factoids( $project_id );

    print join "\n", map { $_->type } @factoids;

=head1 DESCRIPTION

W::O::A::Factoid is a bit of information about a project.

=head1 METHODS 

=head2 API Data Accessors

=head3 id

    $id = $factoid->id;

Return the id of the factoid.  Note that the ids change
every time that a project is reanalyzed.

=head3 analysis_id

    $id = $factoid->analysis_id;

Return the id of the analysis used to create the factoid.

=head3 type

    $type = $factoid->type;

Return the factoid type.

=head3 description

    $desc = $factoid->description;

Return a description of the factoid type.

=head3 severity

    $sev = $factoid->severity;

Return the factoid's severity (ranges between -3 and +3).

=head3 license_id

    $license_id = $factoid->license_id;

If the factoid's type is B<FactoidGplConflict>, 
return the id of the conflicting license.

=head2 Other Methods

=head3 as_xml

Return the activity fact information 
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server. 

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>. 

=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/activity_fact

=back

=head1 VERSION

This document describes WWW::Ohloh::API version 0.3.2

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

The C<as_xml()> method returns a re-encoding of the activity fact data, which
can differ of the original xml document sent by the Ohloh server.

Please report any bugs or feature requests to
C<bug-www-ohloh-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut


