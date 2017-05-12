package WWW::Ohloh::API::ContributorLanguageFact;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;

our $VERSION = '0.3.2';

my @ohloh_of : Field : Arg(ohloh) : Get(_ohloh);
my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @xml_of : Field : Arg(xml);

my @api_fields = qw/
  analysis_id
  contributor_id
  contributor_name
  language_id
  language_nice_name
  comment_ratio
  man_months
  commits
  median_commits
  /;

my @analysis_id_of : Field : Set(_set_analysis_id) : Get(analysis_id);
my @contributor_id_of : Field : Set(_set_contributor_id) :
  Get(contributor_id);
my @contributor_name_of : Field : Set(_set_contributor_name) :
  Get(contributor_name);
my @language_id_of : Field : Set(_set_language_id) : Get(language_id);
my @language_nice_name_of : Field : Set(_set_language_nice_name) :
  Get(language_nice_name);
my @comment_ratio_of : Field : Set(_set_comment_ratio) : Get(comment_ratio);
my @man_months_of : Field : Set(_set_man_months) : Get(man_months);
my @commits_of : Field : Set(_set_commits) : Get(commits);
my @median_commits_of : Field : Set(_set_median_commits) :
  Get(median_commits);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    $self->_set_analysis_id( $dom->findvalue("analysis_id/text()") );
    $self->_set_contributor_id( $dom->findvalue("contributor_id/text()") );
    $self->_set_contributor_name(
        $dom->findvalue("contributor_name/text()") );
    $self->_set_language_id( $dom->findvalue("language_id/text()") );
    $self->_set_language_nice_name(
        $dom->findvalue("language_nice_name/text()") );
    $self->_set_comment_ratio( $dom->findvalue("comment_ratio/text()") );
    $self->_set_man_months( $dom->findvalue("man_months/text()") );
    $self->_set_commits( $dom->findvalue("commits/text()") );
    $self->_set_median_commits( $dom->findvalue("median_commits/text()") );

}

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('contributor_language_fact');

    for my $attr (@api_fields) {
        $w->dataElement( $attr => $self->$attr );
    }

    $w->endTag;

    return $xml;
}

'end of WWW::Ohloh::API::ContributorLanguageFact';

__END__

=head1 NAME

WWW::Ohloh::API::ContributorLanguageFact - Ohloh stats about a project's
contributor for a specific language

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my @facts = $ohloh->get_contributor_language_facts( 
        project_id => 12933,
        contributor_id => 1234
    );
    
=head1 DESCRIPTION

W::O::A::ContributorLanguageFact contains the information associated with 
a language-specific contribution of a member of a project
as defined at http://www.ohloh.net/api/reference/contributor_language_fact. 
To be properly populated, it must be created via
the C<get_contributor_language_facts> method of a 
L<WWW::Ohloh::API> object.

=head1 METHODS 

=head2 API Data Accessors

=head3 analysis_id

Return the id of the analysis which provided the data for
the contributor_language_fact.

=head3 contributor_id

Return the id of the contributor, which is unique 
within the scope of the project, but not globally.

=head3 contributor_name

Return the name used by the contrinutor when committing to
the source control server.

=head3 language_id

Return the id of the language measured.

=head3 language_nice_name

Return the name of the language measured.

=head3 comment_ratio

Return the ratio of lines committed by this contributor
that are comments.

=head3 man_months

The total number of months for which this contributor made at least
one commit.

=head3 commits

Return the total number of commits made by this contributor.

=head3 median_commits

Return the median number of commits by this contributor
by active month.

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



