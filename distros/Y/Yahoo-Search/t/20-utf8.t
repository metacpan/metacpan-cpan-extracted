use strict;

use Test::More tests => 7;
use Data::Dumper;
use Encode;
use utf8;

use Yahoo::Search AppId => "Perl API install test",
                  Count => 10;

# utf8 search string
my $utf8_string = "dudenstraße";
ok Encode::is_utf8($utf8_string, 1), 'is_utf8';
my $count = 2;

for my $UseXmlSimple (0, 1) {
    $Yahoo::Search::UseXmlSimple = $UseXmlSimple;
    note "Testing with Yahoo::Search::UseXmlSimple = $Yahoo::Search::UseXmlSimple\n";

    my @Results = Yahoo::Search->Results(
        Doc => $utf8_string,
        Count => $count,
    );
    SKIP: {
        skip "$@", 3 if !@Results && $@;

        is @Results, $count;
        #print Dumper(\@Results);

        my @Summary = map { $_->Summary } @Results;
        is @Summary, $count, 'got summaries';
        #print Dumper(\@Summary);

        #use DBI; warn DBI::neat_list(\@Summary);
        my @utf8_matches = grep { Encode::is_utf8($_, 1) } @Summary;
        ok @utf8_matches, 'is_utf8 should be true on some';
    }
}
