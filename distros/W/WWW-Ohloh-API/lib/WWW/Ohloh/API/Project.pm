package WWW::Ohloh::API::Project;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;
use WWW::Ohloh::API::Analysis;
use WWW::Ohloh::API::ContributorFact;

our $VERSION = '0.3.2';

my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @ohloh_of : Field : Arg(ohloh) : Get( _ohloh );
my @xml_of : Field : Arg(xml);

my @id_of : Field : Get(id) : Set(_set_id);
my @name_of : Field : Get(name) : Set(_set_name);
my @created_at_of : Field : Get(created_at) : Set(_set_created_at);
my @updated_at_of : Field : Get(updated_at) : Set(_set_updated_at);
my @description_of : Field : Get(description) : Set(_set_description);
my @homepage_url_of : Field : Get(homepage_url) : Set(_set_homepage_url);
my @download_url_of : Field : Get(download_url) : Set(_set_download_url);
my @irc_url_of : Field : Get(irc_url) : Set(_set_irc_url);
my @stack_count_of : Field : Get(stack_count) : Set(_set_stack_count);
my @average_rating_of : Field : Get(average_rating) :
  Set(_set_average_rating);
my @rating_count_of : Field : Get(rating_count) : Set(_set_rating_count);
my @analysis_id_of : Field : Get(analysis_id) : Set(_set_analysis_id);
my @analysis_of : Field;
my @facts_of : Field;
my @factoids_of : Field;

my @contributors_of : Field;

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    $self->_set_id( $dom->findvalue('id/text()') );
    $self->_set_name( $dom->findvalue('name/text()') );
    $self->_set_created_at( $dom->findvalue('created_at/text()') );
    $self->_set_updated_at( $dom->findvalue('updated_at/text()') );
    $self->_set_description( $dom->findvalue('description/text()') );
    $self->_set_homepage_url( $dom->findvalue('homepage_url/text()') );
    $self->_set_download_url( $dom->findvalue('download_url/text()') );
    $self->_set_irc_url( $dom->findvalue('irc_url/text()') );
    $self->_set_stack_count( $dom->findvalue('stack_count/text()') );
    $self->_set_average_rating( $dom->findvalue('average_rating/text()') );
    $self->_set_rating_count( $dom->findvalue('rating_count/text()') );
    $self->_set_analysis_id( $dom->findvalue('analysis_id/text()') );

    if ( my ($n) = $dom->findnodes('analysis[1]') ) {
        $analysis_of[$$self] = WWW::Ohloh::API::Analysis->new( xml => $n );
    }

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub analysis {
    my $self = shift;
    my $id   = shift;

    if ( $id or not $analysis_of[$$self] ) {
        $analysis_of[$$self] =
          $ohloh_of[$$self]->get_analysis( $self->id, $id );
        $analysis_id_of[$$self] = $analysis_of[$$self]->id;
    }

    return $analysis_of[$$self];
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub activity_facts {
    my $self = shift;
    my $id   = shift;

    if ( $id or not $facts_of[$$self] ) {
        $facts_of[$$self] =
          $ohloh_of[$$self]->get_activity_facts( $self->id,
            $id || $self->analysis_id || 'latest' );
    }

    return $facts_of[$$self];
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('project');
    for my $attr (
        qw/ id name created_at updated_at
        description homepage_url
        download_url irc_url stack_count
        average_rating rating_count
        analysis_id /
      ) {
        $w->dataElement( $attr, $self->$attr );
    }
    $xml .= $self->analysis->as_xml if $analysis_of[$$self];

    if ( my $factoids = $factoids_of[$$self] ) {
        $xml .= '<factoids>';
        $xml .= $_->as_xml for @$factoids;
        $xml .= '</factoids>';
    }

    $w->endTag;

    return $xml;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub contributors {
    my $self = shift;

    unless ( $contributors_of[$$self] ) {
        my ( $url, $xml ) = $self->_ohloh->_query_server(
            'projects/' . $self->id . '/contributors.xml' );

        $contributors_of[$$self] = [
            map {
                WWW::Ohloh::API::ContributorFact->new(
                    request_url => $url,
                    xml         => $_,
                    ohloh       => $self->_ohloh
                  )
              } $xml->findnodes('//contributor_fact') ];
    }

    return @{ $contributors_of[$$self] };
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub factoids {
    my $self = shift;

    unless ( defined $factoids_of[$$self] ) {
        $factoids_of[$$self] =
          [ $ohloh_of[$$self]->get_factoids( $self->id ) ];
    }

    return @{ $factoids_of[$$self] };
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

'end of WWW::Ohloh::API::Project';
__END__

=head1 NAME

WWW::Ohloh::API::Project - an Ohloh project

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $project = $ohloh->get_project( id => 1001 );

    print $project->homepage_url;

=head1 DESCRIPTION

W::O::A::Project contains the information associated with an Ohloh 
project as defined at http://www.ohloh.net/api/reference/project. 
To be properly populated, it must be created via
the C<get_project> method of a L<WWW::Ohloh::API> object.

=head1 METHODS 

=head2 API Data Accessors

=head3 id

Return the project's id.

=head3 name

Return the  name of the project.

=head3 created_at

Return the time at which the project was initially 
added to Ohloh.

=head3 updated_at

Return the time of the most recent modification of the project's
record.

=head3 description

Return a description of the project.

=head3 homepage_url

Return the URL of the project's homepage.

=head3 download_url

Return an url to a project download.

=head3 irc_url

Return a URL to an IRC channel associated to the project.

=head3 stack_count

Return the number of stacks currently using the project.

=head3 average_rating

Return a number ranging from 1.0 to 5.0, representing the average 
value of all user ratings for this project, where 1 is the worst possible rating,
and 5 the best.

=head3 rating_count

Return the number of users having rated this project.

=head3 analysis_id

Return the id of the current analysis associated with the project. 
It'll be the latest 
analysis if the project has been retrieved via C<get_project>, and 
will be null if retrieved via C<get_projects>.

=head3 analysis( $id )

Return the Ohloh analysis I<$id> (which can also be the 
keyword 'latest') as an L<WWW::Ohloh::API::Analysis>
object. If I<$id> is omitted, return the previously requested
analysis for this project or, if none has been requested yet, 
the latest analysis available for the project.

=head3 activity_facts( $analysis_id )

Return activity facts related to the project as a
L<WWW::Ohloh::API::ActivityFacts> object. The activity facts
are taken from the analysis specified by I<$analysis_id>.
If C<$analysis_id> is not given, the previously called
analysis will be used and, if no analysis has been explicitly
called, the latest one will be used.

    $project = $ohloh->get_project( 12345);       # retrieve the project

    $latest = $project->activity_facts;           # get the latest facts

    $specific = $project->activity_facts( 789 );  # get facts from analysis 789

    $project->analysis( 789 );  
    $specific = $project->activity_facts;      # equivalent to previous example


=head3 factoids

    @factoids = $project->factoids;

Return the factoids associated with the project
as L<WWW::Ohloh::API::Factoid> objects.

=head2 Other Methods

=head3 as_xml

Return the account information (including the kudo score if it applies)
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server.

Factoids will be included in the xml output if
they have been queried prior to the call to I<as_xml>.


=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, 
L<WWW::Ohloh::API::KudoScore>, 
L<WWW::Ohloh::API::Factoid>, 
L<WWW::Ohloh::API::Analysis>, 
L<WWW::Ohloh::API::Account>.


=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/project

=back

=head1 VERSION

This document describes WWW::Ohloh::API version 0.3.2

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



