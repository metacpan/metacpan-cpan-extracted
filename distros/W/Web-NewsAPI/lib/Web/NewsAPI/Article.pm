package Web::NewsAPI::Article;

use DateTime;
use DateTime::Format::ISO8601;

use URI;

use Moose;

use Web::NewsAPI::Types;

has 'source' => (
    is => 'ro',
    isa => 'Web::NewsAPI::Source',
    required => 1,
);

has 'author' => (
    is => 'ro',
    required => 1,
    isa => 'Maybe[Str]',
);

has 'title' => (
    is => 'ro',
    required => 1,
    isa => 'Maybe[Str]',
);

has 'description' => (
    is => 'ro',
    required => 1,
    isa => 'Maybe[Str]',
);

has 'content' => (
    is => 'ro',
    required => 1,
    isa => 'Maybe[Str]',
);

has 'publishedAt' => (
    is => 'ro',
    required => 1,
    coerce => 1,
    isa => 'NewsDateTime',
);

has 'url' => (
    is => 'ro',
    required => 1,
    coerce => 1,
    isa => 'NewsURI',
);

has 'urlToImage' => (
    is => 'ro',
    required => 1,
    coerce => 1,
    isa => 'NewsURI',
);

1;

=head1 NAME

Web::NewsAPI::Artcle - Object class representing a News API article

=head1 SYNOPSIS

 use v5.10;
 use Web::NewsAPI;

 my $newsapi = Web::NewsAPI->new(
    api_key => $my_secret_api_key,
 );

 say "Here are some top American-news headlines about science...";
 my $result = $newsapi->top_headlines(
    category => 'science', country => 'us',
 );
 # $result is now a Web::NewsAPI::Result object.
 # We can call its 'articles' method to get a list of article objects:
 for my $article ( $result->articles ) {
    say $article->title;
    say $article->description;
    print "\n";
 }

=head1 DESCRIPTION

Objects of this class represent a News API news article. Generally, you
won't create these objects yourself; you'll get them as a result of
calling methods on a L<Web::NewsAPI> object or a L<Web::NewsAPI::Result>
object.

=head1 METHODS

=head2 Object attributes

These are all read-only attributes, based on information provided by
News API. (They use camelCase because they just copy the attribute names
from News API itself.)

=head3 source

 my $source = $article->source;
 say "The source of this article was " . $source->name;

A L<Web::NewsAPI::Source> object.

=head3 author

 my $author = $article->author;
 say "$author wrote this article.";

A string.

=head3 title

 my $title = $article->title;

A string.

=head3 description

 my $description = $article->description;

=head3 url

 my $url = $article->url;

A L<URI> object. (Possibly undefined.)

=head3 urlToImage

 my $image_url = $article->urlToImage;

A L<URI> object. (Possibly undefined.)

=head3 publishedAt

 my $publication_datetime = $article->publishedAt;

A L<DateTime> object.

=head1 AUTHOR

Jason McIntosh (jmac@jmac.org)
