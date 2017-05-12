package WWW::Ohloh::API::Enlistment;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;

use WWW::Ohloh::API::Repository;

our $VERSION = '0.3.2';

my @ohloh_of : Field : Arg(ohloh) : Get(_ohloh);
my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @xml_of : Field : Arg(xml);

my @api_fields = qw/
  id
  project_id
  repository_id
  /;

my @id_of : Field : Set(_set_id) : Get(id);
my @project_id_of : Field : Set(_set_project_id) : Get(project_id);
my @repository_id_of : Field : Set(_set_repository_id) : Get(repository_id);

my @repository_of : Field;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    $self->_set_id( $dom->findvalue("id/text()") );
    $self->_set_project_id( $dom->findvalue("project_id/text()") );
    $self->_set_repository_id( $dom->findvalue("repository_id/text()") );

    $repository_of[$$self] = WWW::Ohloh::API::Repository->new(
        xml   => $dom->findnodes('repository[1]'),
        ohloh => $self->_ohloh,
    );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub repository {
    my $self = shift;

    return $repository_of[$$self];
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('enlistment');

    for my $attr (@api_fields) {
        $w->dataElement( $attr => $self->$attr );
    }

    $xml .= $self->repository->as_xml;

    $w->endTag;

    return $xml;
}

'end of WWW::Ohloh::API::Enlistment';

__END__

=head1 NAME

WWW::Ohloh::API::Enlistment - an Ohloh enlistment

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my @enlistments = $ohloh->get_enlistments( 
        project_id => 12933,
    );
    
=head1 DESCRIPTION

W::O::A::Enlistment contains the information that join 
a project with a repository 
as defined at http://www.ohloh.net/api/reference/enlistment. 
To be properly populated, it must be created via
the C<get_enlistments> method of a L<WWW::Ohloh::API> object.

=head1 METHODS 

=head2 API Data Accessors

=head3 id, project_id, repository_id

    my $id            = $enlistment->id;
    my $project_id    = $enlistment->project_id;
    my $repository_id = $enlistment->repository_id;

Return the id of the enlistment / project / repository.

=head3 repository

    my $repository = $enlistment->repository

Return the repository associated with the enlistment
as a L<WWW::Ohloh::API::Repository> object.

=head2 Other Methods

=head3 as_xml

Return the account information 
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server.

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, L<WWW::Ohloh::API::KudoScore>,
L<WWW::Ohloh::API::ContributorFact>.

=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference:
http://www.ohloh.net/api/reference/contributor_language_fact

=back

=head1 VERSION

This document describes WWW::Ohloh::API::ContributorLanguageFact 
version 0.0.6

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

The C<as_xml()> method returns a re-encoding of the account data, which
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



