package WWW::Ohloh::API::Language;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;

our $VERSION = '0.3.2';

use overload '""' => sub { $_[0]->nice_name };

my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @xml_of : Field : Arg(xml);
my @ohloh_of : Field : Arg(ohloh);

my @api_fields = qw/
  id
  name
  nice_name
  category
  code
  comments
  blanks
  comment_ratio
  projects
  contributors
  commits
  /;

my @id_of : Field : Set(_set_id) : Get(id);
my @name_of : Field : Set(_set_name) : Get(name);
my @nice_name_of : Field : Set(_set_nice_name) : Get(nice_name);
my @category_of : Field : Set(_set_category) : Get(category);
my @lines_of_code_of : Field : Set(_set_code) : Get(code);
my @comments_of : Field : Set(_set_comments) : Get(comments);
my @comment_ratio_of : Field : Set(_set_comment_ratio) : Get(comment_ratio);
my @blanks_of : Field : Set(_set_blanks) : Get(blanks);
my @projects_of : Field : Set(_set_projects) : Get(projects);
my @contributors_of : Field : Set(_set_contributors) : Get(contributors);
my @commits_of : Field : Set(_set_commits) : Get(commits);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    $self->_set_id( $dom->findvalue("id/text()") );
    $self->_set_name( $dom->findvalue("name/text()") );
    $self->_set_nice_name( $dom->findvalue("nice_name/text()") );
    $self->_set_category( $dom->findvalue("category/text()") );
    $self->_set_code( $dom->findvalue("code/text()") );
    $self->_set_comments( $dom->findvalue("comments/text()") );
    $self->_set_blanks( $dom->findvalue("blanks/text()") );
    $self->_set_comment_ratio( $dom->findvalue("comment_ratio/text()") );
    $self->_set_projects( $dom->findvalue("projects/text()") );
    $self->_set_contributors( $dom->findvalue("contributors/text()") );
    $self->_set_commits( $dom->findvalue("commits/text()") );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('language');

    for my $e (@api_fields) {
        $w->dataElement( $e => $self->$e );
    }

    $w->endTag;

    return $xml;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub is_code {
    my $self = shift;

    return $self->category eq 'code';
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub is_markup {
    my $self = shift;

    return $self->category eq 'markup';
}

'end of WWW::Ohloh::API::Language';

__END__

=head1 NAME

WWW::Ohloh::API::Language - a programming language information on Ohloh

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $languages =  $ohloh->get_languages;

    my ( $perl  ) = grep { $_->nice_name eq 'Perl' } $languages->all;

    print $perl->projects, " projects use Perl";

=head1 DESCRIPTION

W::O::A::Language contains the information associated with a programming
language recognized by Ohloh as defined at http://www.ohloh.net/api/reference/language. 
To be properly populated, it must be created via
the C<get_languages> or C<get_language> method of a L<WWW::Ohloh::API> object.

=head1 METHODS 

=head2 API Data Accessors

=head3 id

Return the language's unique id.

=head3 name

Return the short name of the language.

=head3 nice_name

Return the human-friendly name of the language.

=head3 category

Return the type of language, which can be either C<code> or
C<markup>.

=head3 is_markup

Return true if the language is a markup language, false if it's a
code language.

=head3 is_code 

Return true if the language is a code language, false if it's a
markup language.


=head3 code

Return the total number of lines of code, excluding comments and blank lines, written
in the language across all projects.

=head3 comments

Return the total number of comment lines,  written
in the language across all projects.

=head3 blanks

Return the total number of blanks lines,  written
in the language across all projects.

=head3 comment_ratio

Return the ratio of comment lines over the total number of lines for all projects using
the language.

=head3 projects

Return the number of projects using this language.

=head3 contributors

Return the number of contributors who have written at least one line of code
using this language.

=head3 commits

Return the number of commits which include at least one line in this language.

=head2 Other Methods

=head3 as_xml

Return the language information 
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server. 

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, 
L<WWW::Ohloh::API::KudoScore>.

=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/language

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

=cut
