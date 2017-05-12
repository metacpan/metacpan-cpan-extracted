package WebService::TDWTF::Article;

use 5.014000;
use strict;
use warnings;
use parent qw/Class::Accessor::Fast/;

our $VERSION = '0.003';

use WebService::TDWTF ();

sub _article { goto &WebService::TDWTF::article }

__PACKAGE__->mk_ro_accessors(qw/Id Slug SummaryHtml BodyHtml FooterAdHtml Title CoalescedCommentCount DiscourseThreadUrl PublishedDate DisplayDate Url CommentsUrl PreviousArticleId PreviousArticleUrl NextArticleId NextArticleUrl/);

sub AuthorName             { shift->{Author}->{Name} }
sub AuthorShortDescription { shift->{Author}->{ShortDescription} }
sub AuthorDescriptionHtml  { shift->{Author}->{DescriptionHtml} }
sub AuthorSlug             { shift->{Author}->{Slug} }
sub AuthorImageUrl         { shift->{Author}->{ImageUrl} }

sub SeriesSlug        { shift->{Series}->{Slug} }
sub SeriesTitle       { shift->{Series}->{Title} }
sub SeriesDescription { shift->{Series}->{Description} }

sub PreviousArticle { _article shift->PreviousArticleId // return }
sub NextArticle     { _article shift->NextArticleId     // return }

sub Body {
	unless ($_[0]->BodyHtml) {
		my $ret = _article $_[0]->Id, 1;
		$_[0]->{$_} = $ret->{$_} for qw/BodyHtml FooterAdHtml/;
	}
	$_[0]->BodyHtml
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::TDWTF::Article - Class representing information about a TDWTF article

=head1 SYNOPSIS

  use WebService::TDWTF;
  my $article = tdwtf_article 8301;

  say $article->Id;                 # 8301
  say $article->Slug;               # your-recommended-virus
  say $article->SummaryHtml;
  say $article->BodyHtml;
  say $article->Body;
  say $article->Title;              # Your Recommended Virus
  say $article->CoalescedCommentCount;
  say $article->DiscourseThreadUrl; # http://what.thedailywtf.com/t/your-recommended-virus/52541
  say $article->PublishedDate;      # 2015-11-12T06:30:00
  say $article->DisplayDate;        # 2015-11-12
  say $article->Url;                # http://thedailywtf.com/articles/your-recommended-virus
  say $article->CommentsUrl;        # http://thedailywtf.com/articles/comments/your-recommended-virus
  say $article->PreviousArticleId;  # 8299
  say $article->PreviousArticleUrl; # //thedailywtf.com/articles/confession-rect-contains-point
  say $article->NextArticleId;      # 8302
  say $article->NextArticleUrl;     # //thedailywtf.com/articles/who-stole-the-search-box

  say $article->AuthorName;             # Ellis Morning
  say $article->AuthorShortDescription; # Editor
  say $article->AuthorDescriptionHtml;
  say $article->AuthorSlug;             # ellis-morning
  say $article->AuthorImageUrl;         # http://img.thedailywtf.com/images/remy/ellis01.jpg

  say $article->SeriesSlug;  # feature-articles
  say $article->SeriesTitle; # Feature Articles
  say $article->SeriesDescription;

  say $article->PreviousArticle->Title # Confession: rect.Contains(point)
  say $article->NextArticle->Title     # Who Stole the Search Box?!

=head1 DESCRIPTION

A WebService::TDWTF::Article object represents an article on
L<http://thedailywtf.com>. Objects of this class are returned by the
functions in L<WebService::TDWTF>. Each such object is guaranteed to
be a blessed hashref corresponding to the JSON returned by the TDWTF
API (possibly with some extra keys), so the data inside can be
obtained by simply dereferencing the object.

The ArticleModel class in the TDWTF source code might be helpful in
finding the available attributes and understanding their meaning. It
can be found here:
L<https://github.com/tdwtf/WtfWebApp/blob/master/TheDailyWtf/Models/ArticleModel.cs>

Several accessors and convenience functions are provided for accessing
the most common attributes. See the SYNOPSIS for usage examples.

=over

=item B<Id>

The numerical ID of the article.

=item B<Slug>

The string ID of the article.

=item B<Title>

The title of the article

=item B<Url>

URL of the article itself.

=item B<SummaryHtml>

The summary (first 1-2 paragraphs) of the article.

=item B<BodyHtml>

The body of the article. If the object comes from a tdwtf_list_* function, this method returns "".

=item B<Body>

The body of the article. If the object comes from a tdwtf_list_* function, this method retreives the body from the server, saves it in the object and returns it.

=item B<FooterAdHtml>

The advertisment in the footer of the article. If the object comes from a list_ function, this method returns "".

=item B<CoalescedCommentCount>

The number of comments of the article.

=item B<CommentsUrl>

URL to the featured comments list. See DiscourseThreadUrl for the URL to the full comment thread.

=item B<DiscourseThreadUrl>

URL of the full comment thread on what.thedailywtf.com.

=item B<PublishedDate>

Date and time when the article was published in ISO 8601 format, with no timezone.

=item B<DisplayDate>

Date when the article was published in ISO 8601 format, with no timezone.

=item B<AuthorName>

Name of the article's author.

=item B<AuthorShortDescription>

A one-line description of the article's author.

=item B<AuthorDescriptionHtml>

A longer description of the article's author.

=item B<AuthorSlug>

The ID of the article's author, suitable for passing to the tdwtf_list_author function of L<WebService::TDWTF>.

=item B<AuthorImageUrl>

URL to an image of the article's author.

=item B<SeriesSlug>

The ID of the article's series, suitable for passing to the tdwtf_list_series function of L<WebService::TDWTF>

=item B<SeriesTitle>

The name of the article's series.

=item B<SeriesDescription>

A description of the article's series.

=item B<PreviousArticleId>

The numerical ID of the previous article.

=item B<PreviousArticleUrl>

URL of the previous article.

=item B<PreviousArticle>

Retrieves the previous article using L<WebService::TDWTF> and returns it as a WebService::TDWTF::Article object.

=item B<NextArticleId>

The numerical ID of the next article.

=item B<NextArticleUrl>

URL of the next article.

=item B<NextArticle>

Retrieves the next article using L<WebService::TDWTF> and returns it as a WebService::TDWTF::Article object.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
