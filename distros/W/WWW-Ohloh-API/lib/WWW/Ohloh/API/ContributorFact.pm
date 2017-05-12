package WWW::Ohloh::API::ContributorFact;

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
  account_id
  account_name
  primary_language_id
  primary_language_nice_name
  comment_ratio
  first_commit_time
  last_commit_time
  man_months
  commits
  median_commits
  contributor_language_facts
  /;

my @analysis_id_of : Field : Set(_set_analysis_id) : Get(analysis_id);
my @contributor_id_of : Field : Set(_set_contributor_id) :
  Get(contributor_id);
my @contributor_name_of : Field : Set(_set_contributor_name) :
  Get(contributor_name);
my @account_id_of : Field : Set(_set_account_id) : Get(account_id);
my @account_name_of : Field : Set(_set_account_name) : Get(account_name);
my @primary_language_id_of : Field : Set(_set_primary_language_id) :
  Get(primary_language_id);
my @primary_language_nice_name_of : Field :
  Set(_set_primary_language_nice_name) : Get(primary_language_nice_name);
my @comment_ratio_of : Field : Set(_set_comment_ratio) : Get(comment_ratio);
my @first_commit_time_of : Field : Set(_set_first_commit_time) :
  Get(first_commit_time);
my @last_commit_time_of : Field : Set(_set_last_commit_time) :
  Get(last_commit_time);
my @man_months_of : Field : Set(_set_man_months) : Get(man_months);
my @commits_of : Field : Set(_set_commits) : Get(commits);
my @median_commits_of : Field : Set(_set_median_commits) :
  Get(median_commits);
my @contributor_language_facts_of : Field :
  Set(_set_contributor_language_facts) : Get(contributor_language_facts);

my @account_of : Field;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    $self->_set_analysis_id( $dom->findvalue("analysis_id/text()") );
    $self->_set_contributor_id( $dom->findvalue("contributor_id/text()") );
    $self->_set_contributor_name(
        $dom->findvalue("contributor_name/text()") );
    $self->_set_account_id( $dom->findvalue("account_id/text()") );
    $self->_set_account_name( $dom->findvalue("account_name/text()") );
    $self->_set_primary_language_id(
        $dom->findvalue("primary_language_id/text()") );
    $self->_set_primary_language_nice_name(
        $dom->findvalue("primary_language_nice_name/text()") );
    $self->_set_comment_ratio( $dom->findvalue("comment_ratio/text()") );
    $self->_set_first_commit_time(
        $dom->findvalue("first_commit_time/text()") );
    $self->_set_last_commit_time(
        $dom->findvalue("last_commit_time/text()") );
    $self->_set_man_months( $dom->findvalue("man_months/text()") );
    $self->_set_commits( $dom->findvalue("commits/text()") );
    $self->_set_median_commits( $dom->findvalue("median_commits/text()") );
    $self->_set_contributor_language_facts(
        $dom->findvalue("contributor_language_facts/text()") );

}

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('contributor_fact');

    for my $attr (@api_fields) {
        $w->dataElement( $attr => $self->$attr );
    }

    if ( my $a = $account_of[$$self] ) {
        $xml .= $a->as_xml;
    }

    $w->endTag;

    return $xml;
}

sub account {
    my $self = shift;

    return $account_of[$$self] if $account_of[$$self];

    my $id = $self->account_id or return;

    return $account_of[$$self] = $self->_ohloh->get_account( id => $id );
}

'end of WWW::Ohloh::API::ContributorFact';

__END__

=head1 NAME

WWW::Ohloh::API::ContributorFact - Ohloh stats about a project's contributor

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $project = $ohloh->get_project( id => 12933 );
    
    my @contributors = $project->contributors;

=head1 DESCRIPTION

W::O::A::ContributorFact contains the information associated with 
a contributor to a project
as defined at http://www.ohloh.net/api/reference/contributori_fact. 
To be properly populated, it must be created via
the C<get_project> method of a L<WWW::Ohloh::API> object.

=head1 METHODS 

=head2 API Data Accessors

=head3 analysis_id

Return the id of the analysis which provided the data for
the contributor_fact.

=head3 contributor_id

Return the id of the contributor, which is unique 
within the scope of the project, but not globally.

=head3 contributor_name

Return the name used by the contrinutor when committing to
the source control server.

=head3 account_id

Return the Ohloh account id of the contributor, if the
contribution has been claimed.  If not, return I<undef>.


=head3 account_name

Return the account name of the contributor, if the contribution
has been claimed, or I<undef> otherwise.
configured.

=head3 primary_language_id

Return the id of the language most used by the contributor.

=head3 primary_language_nice_name

Return the name of the language most used by the contributor.

=head3 comment_ratio

Return the ratio of lines committed by this contributor
that are comments.

=head3 first_commit_time, last_commit_time

Return the time of the first/last commit by this
contributor.

=head3 man_months

The total number of months for which this contributor made at least
one commit.

=head3 commits

Return the total number of commits made by this contributor.

=head3 median_commits

Return the median number of commits by this contributor
by active month.

=head3 contributor_language_facts

Return a list of L<WWW::Ohloh::API::ContributorLanguageFact> objects
containing the information pertaining to this contributor.

=head2 Other Methods

=head3 as_xml

Return the account information (including the account information
and contributor language facts, if they have been retrieved)
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server.

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, L<WWW::Ohloh::API::KudoScore>.

=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference:
http://www.ohloh.net/api/reference/contributor_fact

=back

=head1 VERSION

This document describes WWW::Ohloh::API::ContributorFact version 0.3.2

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



