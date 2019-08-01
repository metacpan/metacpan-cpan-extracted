package Web::NewsAPI;

our $VERSION = '0.002';

use v5.10;
use Moose;

use Readonly;
use LWP;
use JSON;
use Carp;
use DateTime::Format::ISO8601::Format;
use Scalar::Util qw(blessed);

use Web::NewsAPI::Result;
use Web::NewsAPI::Source;

Readonly my $API_BASE_URL => 'https://newsapi.org/v2/';

has 'ua' => (
    isa => 'LWP::UserAgent',
    is => 'ro',
    lazy_build => 1,
);

has 'api_key' => (
    required => 1,
    is => 'ro',
    isa => 'Str',
);

sub top_headlines {
    my ($self, %args) = @_;

    # Collapse the source-param into a comma-separated string,
    # if it's an array.
    $self->_collapse_list( 'source', \%args );

    return $self->_make_article_set( 'top-headlines', \%args );
}

sub everything {
    my ($self, %args) = @_;

    # Collapse each source/domain-param into a comma-separated string,
    # if it's an array.
    for my $param (qw(source domains excludeDomains) ) {
        $self->_collapse_list( $param, \%args );
    }

    # Convert time-params into ISO 8601 strings, if they are DateTime
    # objects. (And throw an exception if they're something weird.)
    my $dt_formatter = DateTime::Format::ISO8601::Format->new;
    for my $param (qw(to from)) {
        if ( $args{$param} && ( blessed $args{$param} ) ) {
            if ($args{$param}->isa('DateTime')) {
                $args{$param} =
                    $dt_formatter->format_datetime(
                        $args{$param}
                    );
            }
            else {
                croak "The '$param' parameter of the 'everything' "
                    . "method must be either a DateTime object or an ISO 8601-"
                    . "formatted time-string. (Got: $args{$param}";
            }
        }
    }

    return $self->_make_article_set( 'everything', \%args );

}

sub _make_article_set {
    my ($self, $endpoint, $args) = @_;

    my $article_set = Web::NewsAPI::Result->new(
        newsapi => $self,
        api_endpoint => $endpoint,
        api_args => $args,
        page => $args->{page} || 1,
        page_size => $args->{pageSize} || 20,
    );

    if (wantarray) {
        return $article_set->articles;
    }
    else {
        return $article_set;
    }
}

sub _collapse_list {
    my ($self, $param, $args) = @_;
    if ( $args->{$param} && ( ref $args->{$param} eq 'ARRAY' ) ) {
        $args->{$param} = join q{,}, @{$args->{$param}};
    }
}

sub sources {
    my ($self, %args) = @_;

    my @sources;
    my ($source_data_list) = $self->_request( 'sources', 'sources', %args );
    for my $source_data ( @$source_data_list ) {
        push @sources, Web::NewsAPI::Source->new( $source_data );
    }

    return @sources;
}

sub _build_ua {
    my $self = shift;

    my $ua = LWP::UserAgent->new;
    $ua->default_header(
        'X-Api-Key' => $self->api_key,
    );

    return $ua;
}

sub _request {
    my $self = shift;
    my ($endpoint, $container, %args) = @_;

    my $uri = URI->new( $API_BASE_URL . $endpoint );
    $uri->query( $uri->query_form( \%args ) );

    my $response = $self->ua->get( $uri );
    if ($response->is_success) {
        my $data_ref = decode_json( $response->content );
        return ($data_ref->{$container}, $data_ref->{totalResults});
    }
    else {
        my $code = $response->code;
        die "News API responded with an error ($code): " . $response->content;
    }
}

1;

=head1 NAME

Web::NewsAPI - Fetch and search news headlines and sources from News API

=head1 SYNOPSIS

 use Web::NewsAPI;
 use v5.10;

 # To use this module, you need to get a free API key from
 # https://newsapi.org. (The following is a bogus example key that will
 # not actually work. Try it with your own key instead!)
 my $api_key = 'deadbeef1234567890f001f001deadbeef';

 my $newsapi = Web::NewsAPI->new(
    api_key => $api_key,
 );

 say "Here are the top ten headlines from American news sources...";
 # This will be a Web::NewsAPI::Results object.
 my $result = $newsapi->top_headlines( country => 'us', pageSize => 10 );
 for my $article ( $result->articles ) {
    # Each is a Web::NewsAPI::Article object.
    say $article->title;
 }

 say "Here are the top ten headlines worldwide containing 'chicken'...";
 my $chicken_heds = $newsapi->everything( q => 'chicken', pageSize => 10 );
 for my $article ( $chicken_heds->articles ) {
    # Each is a Web::NewsAPI::Article object.
    say $article->title;
 }
 say "The total number of chicken-flavor articles returned: "
     . $chicken_heds->total_results;


 say "Here are some sources for English-language technology news...";
 my @sources = $newsapi->sources(
    category => 'technology',
    language => 'en'
 );
 for my $source ( @sources ) {
    # Each is a Web::NewsAPI::Source object.
    say $source->name;
 }

=head1 DESCRIPTION

This module provides a simple, object-oriented interface to L<the News
API|https://newsapi.org>, version 2. It supports that API's three public
endpoints, allowing your code to fetch and search current news headlines
and sources.

=head1 METHODS

=head2 Class Methods

=head3 new

 my $newsapi = Web::NewsAPI->new( api_key => $your_api_key );

Object constructor. Takes a hash as an argument, whose only recognized
key is C<api_key>. This must be set to a valid News API key. You can
fetch a key for yourself by registering a free account with News API
L<at its website|https://newsapi.org>.

Note that the validity of the API key you provide isn't checked until
this object (or one of its derivative objects) tries to send a query to
News API.

=head2 Object Methods

Each of these methods will attempt to call News API using the API key
you provided during construction. If the call fails, then this module
will throw an exception, sharing the error code and message passed back
from News API.

=head3 everything

 # Call in scalar context to get a result object.
 my $chicken_result-> = $newsapi->everything( q => 'chickens' );

 # Or call in array context to just get one page of articles.
 my @chicken_stories = $newsapi->everything( q => 'chickens' );

In scalar context, returns a L<Web::NewsAPI::Result> object representing
news articles matching the query parameters you provide. In array
context, it returns one page-worth of L<Web::NewsAPI::Article> objects
(equivalent to calling L<Web::NewsAPI::Result/"articles"> on the result
object, and then discarding it).

In either case, the argument hash must contain I<at least one> of the
following keys:

=over

=item q

Keywords or phrases to search for.

See L<the News API docs|https://newsapi.org/docs/endpoints/everything>
for a complete description of what's allowed here.

=item sources

I<Either> a comma-separated string I<or> an array reference of News API
news source ID strings to limit results from.

See L<the News API sources index|https://newsapi.org/sources> for a list
of valid source IDs.

=item domains

I<Either> a comma-separated string I<or> an array reference of domains
(e.g. "bbc.co.uk, techcrunch.com, engadget.com") to limit results from.

=back

You may also provide any of these optional keys:

=over

=item excludeDomains

I<Either> a comma-separated string I<or> an array reference of domains
(e.g. "bbc.co.uk, techcrunch.com, engadget.com") to remove from the
results.

=item from

I<Either> an ISO 8601-formatted date-time string I<or> a L<DateTime>
object representing the timestamp of the oldest article allowed.

=item to

I<Either> an ISO 8601-formatted date-time string I<or> a L<DateTime>
object representing the timestamp of the most recent article allowed.

=item language

The 2-letter ISO-639-1 code of the language you want to get headlines
for. Possible options include C<ar>, C<de>, C<en>, C<es>, C<fr>, C<he>,
C<it>, C<nl>, C<no>, C<pt>, C<ru>, C<se>, C<ud>, and C<zh>.

=item sortBy

The order to sort the articles in. Possible options: C<relevancy>,
C<popularity>, C<publishedAt>. (Default: C<publishedAt>)

=item pageSize

The number of results to return per page. 20 is the default, 100 is the
maximum.

=item page

Which page of results to return. The default is 1.

=back

=head3 top_headlines

 # Call in scalar context to get a result object.
 my $top_us_headlines = $newsapi->top_headlines( country => 'us' );

 # Or call in array context to just get one page of articles.
 my @top_us_headlines = $newsapi->top_headlines( country => 'us' );

Like L<"everything">, but limits results only to the latest articles,
sorted by recency. (Note that this arguments are a little different, as
well.)

In scalar context, returns a L<Web::NewsAPI::Result> object representing
news articles matching the query parameters you provide. In array
context, it returns one page-worth of L<Web::NewsAPI::Article> objects
(equivalent to calling L<Web::NewsAPI::Result/"articles"> on the result
object, and then discarding it).

In either case, the argument hash must contain I<at least one> of the
following keys:

=over

=item country

Limit returned headlines to a single country, expressed as a 2-letter
ISO 3166-1 code. (See L<the News API
documentation|https://newsapi.org/docs/endpoints/top-headlines> for a
full list of country codes it supports.)

News API will return an error if you mix this with C<sources>.

=item category

Limit returned headlines to a single category. Possible options include
C<business>, C<entertainment>, C<general>, C<health>, C<science>,
C<sports>, and C<technology>.

News API will return an error if you mix this with C<sources>.

=item sources

I<Either> a comma-separated string I<or> an array reference of News API
news source ID strings to limit results from.

See L<the News API sources index|https://newsapi.org/sources> for a list
of valid source IDs.

News API will return an error if you mix this with C<country> or
C<category>.

=item q

Keywords or a phrase to search for.

=back

You may also provide either of these optional keys:

=over

=item pageSize

The number of results to return per page (request). 20 is the default,
100 is the maximum.

=item page

Use this to page through the results if the total results found is
greater than the page size.

=back

=head3 sources

 my @sources = $newsapi->sources( language => 'en' );

Returns a number of L<Web::NewsAPI::Source> objects reprsenting News
API's news sources.

You may provide any of these optional parameters:

=over

=item category

Limit sources to a single category. Possible options include
C<business>, C<entertainment>, C<general>, C<health>, C<science>,
C<sports>, and C<technology>.

=item country

Limit sources to a single country, expressed as a 2-letter ISO 3166-1
code. (See L<the News API
documentation|https://newsapi.org/docs/endpoints/sources> for a full
list of country codes it supports.)

=item language

Limit sources to a single language. Possible options include C<ar>,
C<de>, C<en>, C<es>, C<fr>, C<he>, C<it>, C<nl>, C<no>, C<pt>, C<ru>,
C<se>, C<ud>, and C<zh>.

=back

=head1 NOTES AND BUGS

This is this module's first release (or nearly so). It works for the
author's own use-cases, but it's probably buggy beyond that. Please
report issues at L<the module's GitHub
site|https://github.com/jmacdotorg/newsapi-perl>. Code and documentation
pull requests are very welcome!

=head1 AUTHOR

Jason McIntosh (jmac@jmac.org)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Jason McIntosh.

This is free software, licensed under:

  The MIT (X11) License
