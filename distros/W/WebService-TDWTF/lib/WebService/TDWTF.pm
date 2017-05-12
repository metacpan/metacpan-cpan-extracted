package WebService::TDWTF;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter/;

use Carp;
use HTTP::Tiny;
use JSON::MaybeXS qw/decode_json/;
use Scalar::Util qw/looks_like_number/;
use WebService::TDWTF::Article;

my @subs = qw/article list_recent list_series list_author series/;
our @EXPORT = map { "tdwtf_$_" } @subs;
our @EXPORT_OK = (@EXPORT, @subs);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
our $VERSION = '0.003';
our $AGENT = "WebService-TDWTF/$VERSION";
our $BASE_URL = 'http://thedailywtf.com/api';

sub _ht { HTTP::Tiny->new(agent => $AGENT) }

sub _query {
	my ($url) = @_;

	my $ht = _ht;
	my $response = $ht->get($url);
	croak $response->{reason} unless $response->{success};
	$response = decode_json $response->{content};
	croak $response->{Status} if ref $response eq 'HASH' && !exists $response->{BodyHtml};

	$response
}

sub _objectify {
	my ($response) = @_;

	return map { _objectify($_) } @$response if ref $response eq 'ARRAY';
	WebService::TDWTF::Article->new($response)
}

sub article {
	my ($id_or_slug, $only_body_and_html) = @_;
	my $url = "$BASE_URL/articles/";
	$url .= @_ == 0 ? 'random' : looks_like_number $id_or_slug ? "/id/$id_or_slug" : "/slug/$id_or_slug";
	$url .= '/true' if $only_body_and_html;
	_objectify _query $url
}

sub _list {
	my $url = join '/', $BASE_URL, @_;
	_objectify _query $url
}

sub list_recent { my $url = @_ == 2 ? 'articles' : 'articles/recent'; _list $url, @_ }
sub list_series { _list 'series',   @_ }
sub list_author { _list 'author',   @_ }

sub series { @{_query "$BASE_URL/series/"} }

BEGIN {
	*tdwtf_article     = \&article;
	*tdwtf_list_recent = \&list_recent;
	*tdwtf_list_series = \&list_series;
	*tdwtf_list_author = \&list_author;
	*tdwtf_series      = \&series;
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::TDWTF - retrieve articles from thedailywtf.com

=head1 SYNOPSIS

  use WebService::TDWTF;
  my $random_article = tdwtf_article;
  say $random_article->Title;
  say $random_article->Body;

  my $x = tdwtf_article 8301;
  say $x->Title;  # Your Recommended Virus
  my $y = tdwtf_article 'your-recommended-virus'; # $x and $y are equivalent

  my @recent = tdwtf_list_recent;
  say scalar @recent; # 8
  @recent = tdwtf_list_recent 10;
  say scalar @recent; # 10

  my @dec15 = tdwtf_list_recent 2015, 12;
  say $dec15[0]->Title; # Best of 2015: The A(nti)-Team
  say $dec15[0]->Body;  # (this makes an API call, see NOTES)
  say $dec15[0]->Body;  # (this doesn't make an API call)

  my @erik = tdwtf_list_author 'erik-gern'; # (most recent 8 articles by Erik Gern)
  my @sod  = tdwtf_list_series 'code-sod', 5;  # (most recent 5 CodeSOD articles)

  # All Error'd articles published in January 2014
  my @jan14_errord = tdwtf_list_series 'errord', 2014, 1;

  my @series = series;           # List of all series
  my $series = series;           # Number of series ($series == @series)
  print $series[0]->Slug;        # alexs-soapbox
  print $series[0]->Title;       # Alex's Soapbox
  print $series[0]->Description; # <description of this series>
  print $series[0]->CssClass;    # tales

=head1 DESCRIPTION

WebService::TDWTF is an interface to the API of L<http://thedailywtf.com>.
Quoting the website's sidebar:

    Founded in 2004 by Alex Papadimoulis, The Daily WTF is your
    how-not-to guide for developing software. We recount tales of
    disastrous development, from project management gone spectacularly
    bad to inexplicable coding choices.

This module exports the following functions:

=over

=item B<tdwtf_article>()

=item B<tdwtf_article>(I<$id_or_slug>)

=item B<article>()

=item B<article>(I<$id_or_slug>)

With an argument, returns a L<WebService::TDWTF> object representing
the article with the given ID or slug.

With no arguments, returns a L<WebService::TDWTF> object representing
a random article.

=item B<tdwtf_list_recent>()

=item B<tdwtf_list_recent>(I<$count>)

=item B<tdwtf_list_recent>(I<$year>, I<$month>)

=item B<list_recent>()

=item B<list_recent>(I<$count>)

=item B<list_recent>(I<$year>, I<$month>)

With no arguments, returns the most recent 8 articles.

With one argument, returns the most recent I<$count> articles.
I<$count> is at most 100.

With two arguments, returns all articles published in the given month
of the given year. I<$month> is an integer between 1 and 12.

=item B<tdwtf_list_series>(I<$slug>)

=item B<tdwtf_list_series>(I<$slug>, I<$count>)

=item B<tdwtf_list_series>(I<$slug>, I<$year>, I<$month>)

=item B<list_series>(I<$slug>)

=item B<list_series>(I<$slug>, I<$count>)

=item B<list_series>(I<$slug>, I<$year>, I<$month>)

With no arguments, returns the most recent 8 articles in the given
series.

With one argument, returns the most recent I<$count> articles in the
given series. I<$count> is at most 100.

With two arguments, returns all articles in the given series published
in the given month of the given year. I<$month> is an integer between
1 and 12.

=item B<tdwtf_list_author>(I<$slug>)

=item B<tdwtf_list_author>(I<$slug>, I<$count>)

=item B<tdwtf_list_author>(I<$slug>, I<$year>, I<$month>)

=item B<list_author>(I<$slug>)

=item B<list_author>(I<$slug>, I<$count>)

=item B<list_author>(I<$slug>, I<$year>, I<$month>)

With no arguments, returns the most recent 8 articles by the given
author.

With one argument, returns the most recent I<$count> articles by the
given author. I<$count> is at most 100.

With two arguments, returns all articles by the given author published
in the given month of the given year. I<$month> is an integer between
1 and 12.

=item B<tdwtf_series>

=item B<series>

In list context, returns a list of all existing article series. Each
series is an unblessed hashref with the keys C<Slug>, C<Title>,
C<Description> and C<CssClass>.

In scalar context, returns the number of existing article series.

=back

=head1 NOTES

All functions are exported of the name B<tdwtf_foo> are exported by
default. The unprefixed variants can be exported on request.

The B<tdwtf_list_*> functions return a list of incomplete
L<WebService::TDWTF::Article> objects. These objects contain all of
the fields of a normal object, except for BodyHtml and FooterAdHtml.
For these objects, the B<Body> mehod of L<WebService::TDWTF::Article>
retrieves the BodyHtml and FooterAdHtml fields from the API and saves
them into the object.

All B<tdwtf_list_*> functions return articles in reverse chronological
order. That is, the first element of the list is the most recent article.

=head1 SEE ALSO

L<http://thedailywtf.com/>

L<https://github.com/tdwtf/WtfWebApp/blob/master/Docs/API.md>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
