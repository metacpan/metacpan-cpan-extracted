package Web::NewsAPI::Result;

use Moose;

use Web::NewsAPI::Article;

has 'page' => (
    is => 'rw',
    isa => 'Int',
    default => 1,
    trigger => sub { $_[0]->reset },
);

has 'page_size' => (
    is => 'rw',
    isa => 'Int',
    default => 20,
    trigger => sub { $_[0]->reset },
);

has 'total_results' => (
    is => 'rw',
    isa => 'Int',
    lazy_build => 1,
    clearer => 'clear_total_results',
);

has 'articles_ref' => (
    is => 'rw',
    isa => 'ArrayRef[Web::NewsAPI::Article]',
    lazy_build => 1,
    clearer => 'clear_articles_ref',
);

has 'query_results' => (
    is => 'rw',
    isa => 'HashRef',
    lazy_build => 1,
    clearer => 'clear_query_results',
);

has 'newsapi' => (
    is => 'ro',
    required => 1,
    isa => 'Web::NewsAPI',
);

has 'api_endpoint' => (
    is => 'ro',
    required => 1,
    isa => 'Str',
);

has 'api_args' => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

sub BUILD {
    my $self = shift;

    if ( defined $self->api_args->{pageSize} ) {
        $self->page_size( $self->api_args->{pageSize} )
    }

    if ( defined $self->api_args->{page} ) {
        $self->page( $self->api_args->{page} )
    }

    return $self;
}

sub articles {
    my $self = shift;

    return @{ $self->articles_ref };
}

sub turn_page {
    my $self = shift;

    $self->page( $self->page + 1 );
}

sub turn_page_back {
    my $self = shift;

    if ( $self->page > 1 ) {
        $self->page( $self->page - 1 );
    }
}

sub _build_articles_ref {
    my $self = shift;

    my @articles;

    for my $article_data (@{ $self->query_results->{articles} }) {
        push @articles, Web::NewsAPI::Article->new(
            %$article_data,
            source => Web::NewsAPI::Source->new(
                id => $article_data->{source}->{id},
                name => $article_data->{source}->{name},
            ),
        );
    }

    return \@articles;
};

sub _build_query_results {
    my $self = shift;

    my %args = %{ $self->api_args };
    $args{ pageSize } = $self->page_size;
    $args{ page } = $self->page;

    my ($articles, $total_results) =
        $self->newsapi->_request(
            $self->api_endpoint,
            'articles',
            %args,
        )
    ;

    return {
        articles => $articles,
        total_results => $total_results,
    };
}

sub _build_total_results {
    my $self = shift;

    return $self->query_results->{total_results};
}

sub _make_articles {
    my ($self, @article_data) = @_;
    my @articles;
    for my $article_data (@article_data) {
        push @articles, Web::NewsAPI::Article->new(
            %$article_data,
            source => Web::NewsAPI::Source->new(
                id => $article_data->{source}->{id},
                name => $article_data->{source}->{name},
            ),
        );
    }
    return @articles;
}

sub reset {
    my $self = shift;

    $self->clear_articles_ref;
    $self->clear_query_results;
    $self->clear_total_results;
}

1;

=head1 NAME

Web::NewsAPI::Result - Object representing a News API query result.

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

 my $count = $result->total_results;
 say "There are $count such headlines in the news right now.";

 say "Here are the top headlines...";
 print_articles();

 say "And here's page two...";
 $result->turn_page;
 print_articles();

 sub print_articles {
     for my $article ( $result->articles ) {
        say $article->title;
        say $article->description;
        print "\n";
     }
 }

=head1 DESCRIPTION

Objects of this class represent the result of a News API query, such as
C<top-headlines> or C<everything>. Generally, you won't create these
objects yourself; you'll get them as a result of calling L<methods on a
Web::NewsAPI object|Web::NewsAPI/"Object methods">.

An Web::NewsAPI::Result object gives you methods to retrieve one "page" of
articles, change the current page or page-size, and get the count of all
articles in the current set.

=head1 METHODS

=head2 Object attributes

=head3 page

 my $current_page = $result->page;
 $result->page( 2 );

The current page of results that L<"artciles"> will return, expressed as
an integer.

Default: 1.

=head3 page_size

 my $page_size = $result->page_size;
 $result->page_size( 10 );

How many articles to return per call to L<"articles">.

Default: 20.

=head2 Object methods

=head3 articles

 my @articles = $result->articles;

Returns all the L<Web::NewsAPI::Article> objects that constitute the
current page of results.

=head3 total_results

 my $count = $result->total_results;

Returns the total number of results that News API has for the given
query parameters.

=head3 turn_page

 $result->turn_page;

Increment the current page.

=head3 turn_page_back

 $result->turn_page_back;

Decrement the current page, unless the current page number is already 1.

=head1 NOTES

Note that, due to the essential nature of News API, the size and
contents of a given article set can shift in between page-turns (or
page-size changes).

For example: Say that you create an article set through a call to
L<Web::NewsAPI/"top_articles">, and view the first page of results. If
you call L<"turn_page"> and list the articles again, there is a chance
that one or more articles towards the end of the first page's list now
lead the second page's list. This can occur when I<more news has
happened> in between the first page's query and the second, effectively
causing new entries at the top of the first page and pushing all the
older results down.

This sort of behavior occurs due to the nature of news, and software
using this module should be aware of it.

=head1 AUTHOR

Jason McIntosh (jmac@jmac.org)

