#!/usr/bin/env perl

use Test::More;
use FindBin;
use DateTime;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib");
use NewsAPITestUserAgent;

my $ua = NewsAPITestUserAgent->new;

use_ok "Web::NewsAPI";

my $newsapi = Web::NewsAPI->new(
    api_key => 'bogusKey',
    ua      => $ua,
);

eval {
    my @headlines = $newsapi->top_headlines;
};
like( $@, qr/400/, 'Got expected error from a bad API call' );

{
my @headlines = $newsapi->top_headlines( 'q' => 'foo' );
is ( @headlines, 2, 'Got expected number of top headlines' );
is ( ref $headlines[0], 'Web::NewsAPI::Article', 'Results are article objects' );
is ($headlines[0]->author,
    'Christine Wang',
    'Article objects populated with data OK',
);
is ($newsapi->total_results, 38, 'Total results is correct');
}

{
my @headlines = $newsapi->everything(
    from => DateTime->new( year=> 2010, month=> 6, time_zone=>'UTC' ),
);
is ( @headlines, 2, 'Got expected number of search results' );
is ( ref $headlines[0], 'Web::NewsAPI::Article', 'Results are article objects' );
is ($headlines[0]->author,
    'Jolie Kerr',
    'Article objects populated with data OK'
);
is ($newsapi->total_results, 426, 'Total results is correct');
}

{
my @headlines = $newsapi->everything(
    domains=>['example.com','another.example.com'],
);
is ( @headlines, 2, 'Got expected number of search results' );
is ( ref $headlines[0], 'Web::NewsAPI::Article', 'Results are article objects' );
is ($headlines[0]->author,
    'Jolie Kerr',
    'Article objects populated with data OK'
);
is ($newsapi->total_results, 426, 'Total results is correct');
}

{
my @sources = $newsapi->sources( language => 'en' );
is ( @sources, 5, 'Got expected number of sources' );
is ( ref $sources[0], 'Web::NewsAPI::Source', 'Results are source objects' );
is ($sources[0]->name,
    'Google News (France)',
    'Source objects populated with data OK'
);
}

done_testing();
