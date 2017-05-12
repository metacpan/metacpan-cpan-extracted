package WWW::Ohloh::API::ActivityFact;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;

our $VERSION = '0.3.2';

my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @xml_of : Field : Arg(xml);

my @api_fields = qw/
  month
  code_added
  code_removed
  comments_added
  comments_removed
  blanks_added
  blanks_removed
  commits
  contributors
  /;

my @month_of : Field : Set(_set_month) : Get(month);
my @code_added_of : Field : Set(_set_code_added) : Get(code_added);
my @code_removed_of : Field : Set(_set_code_removed) : Get(code_removed);
my @comments_added_of : Field : Set(_set_comments_added) :
  Get(comments_added);
my @comments_removed_of : Field : Set(_set_comments_removed) :
  Get(comments_removed);
my @blanks_added_of : Field : Set(_set_blanks_added) : Get(blanks_added);
my @blanks_removed_of : Field : Set(_set_blanks_removed) :
  Get(blanks_removed);
my @commits_of : Field : Set(_set_commits) : Get(commits);
my @contributors_of : Field : Set(_set_contributors) : Get(contributors);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    $self->_set_month( $dom->findvalue("month/text()") );
    $self->_set_code_added( $dom->findvalue("code_added/text()") );
    $self->_set_code_removed( $dom->findvalue("code_removed/text()") );
    $self->_set_comments_added( $dom->findvalue("comments_added/text()") );
    $self->_set_comments_removed(
        $dom->findvalue("comments_removed/text()") );
    $self->_set_blanks_added( $dom->findvalue("blanks_added/text()") );
    $self->_set_blanks_removed( $dom->findvalue("blanks_removed/text()") );
    $self->_set_commits( $dom->findvalue("commits/text()") );
    $self->_set_contributors( $dom->findvalue("contributors/text()") );

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('activity_fact');

    for my $e (@api_fields) {
        $w->dataElement( $e => $self->$e );
    }

    $w->endTag;

    return $xml;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

'end of WWW::Ohloh::API::ActivityFact';

__END__

=head1 NAME

WWW::Ohloh::API::ActivityFact - collection of statistics about an Ohloh project

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $facts =  $ohloh->get_activity_facts( $project_id, $analysis);
    my $fact = $facts->latest;

    print $fact->month, ": ", $fact->contributors;

=head1 DESCRIPTION

W::O::A::ActivityFact contains monthly statistics about an Ohloh-registered
project. 
To be properly populated, it must be retrieved via
a L<WWW::Ohloh::API::ActivityFacts> object.

=head1 METHODS 

=head2 API Data Accessors

=head3 month

Return the month covered by this activity fact.

=head3 code_added, code_removed, comments_added, comments_removed,
        blanks_added, blanks_removed

Return the number of lines of code/comments/blanks added/removed during this
month.

=head3 commits

Return the number of commits made during that month.

=head3 contributors

Return the number of contributors having made at least one commit during
this month.

=head2 Other Methods

=head3 as_xml

Return the activity fact information 
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server. 

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, 
L<WWW::Ohloh::ActivitieFacts>,
L<WWW::Ohloh::API::KudoScore>.

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


