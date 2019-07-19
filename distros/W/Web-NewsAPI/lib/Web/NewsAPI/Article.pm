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
 my @articles = $newsapi->top_headlines(
    category => 'science', country => 'us',
 );
 for my $article ( @articles ) {
    say $article->title;
    say $article->description;
    print "\n";
 }

=head1 DESCRIPTION

Objects of this class represent a News API news article. Generally, you
won't create these objects yourself; you'll get them as a result of
calling L<methods on a Web::NewsAPI object|Web::NewsAPI/"Object
methods">.

=head1 METHODS

=head2 Object attributes

These are all read-only attributes, based on information provided by
News API. (They use camelCase because they just copy the attribute names
from News API itself.)

=over

=item source

A L<Web::NewsAPI::Source> object.

=item author

A string.

=item title

A string.

=item description

A string.

=item url

A L<URI> object. (Possibly undefined.)

=item urlToImage

A L<URI> object. (Possibly undefined.)

=item publishedAt

A L<DateTime> object.



=back

=head1 AUTHOR

Jason McIntosh (jmac@jmac.org)
