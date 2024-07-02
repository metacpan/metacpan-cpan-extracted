use Test::More;
use strict;
use warnings;

use_ok "Tradestie::WSBetsAPI";

my $twsb = Tradestie::WSBetsAPI->new;

# Date formatter
is( $twsb->date_formatter( 11, 28, 2022 ),
    "2022-11-28", "Passing integer values into the date function." );
is( $twsb->date_formatter( "01", "26", "2024" ),
    "2024-01-26", "Passing string values into the date function." );
is( $twsb->date_formatter(),
    "2022-11-17",
    "Passing no values into the date function to get back the default date." );

# Reddit Wallstreet Bets
my @redditList = $twsb->reddit;
is( @redditList, 50,
    "Using the default date, the Reddit endpoint should return 50 items" );

my @redditListDate = $twsb->reddit("2022-04-03");
is( @redditListDate, 50,
"Passing a date to the reddit function, the Reddit endpoint should return 50 items"
);

my @redditListMCDate = $twsb->reddit("2024-01-28");
is( @redditListMCDate, 0,
"Passing a date outside of market hours to the reddit function, the Reddit endpoint should return 0 items"
);

# TTM Squeeze Stocks
my @ttmList = $twsb->ttm_squeeze_stocks;
is( @ttmList, 1850,
"Using the default date, the TTM Squeeze Stocks endpoint should return 1,850 items"
);

my @ttmListDate = $twsb->ttm_squeeze_stocks("2024-04-03");
is( @ttmListDate, 2152,
"Passing a date to the ttm_squeeze_stocks function, the TTM Squeeze Stocks endpoint should return 2152 items"
);

my @ttmListMCDate = $twsb->ttm_squeeze_stocks("2024-01-28");
is( @ttmListMCDate, 0,
"Passing a date outside of market hours to the ttm_squeeze_stocks function, the TTM Squeeze Stocks endpoint should return 0 items"
);

done_testing();
