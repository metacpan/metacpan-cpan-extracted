use strict;
use warnings;

use Test::More tests => 7;                      # last test to print

use WWW::Ohloh::API;
use Exception::Class;

eval {
   WWW::Ohloh::API->get_projects( sort => 'foo' );
};

ok( Exception::Class->caught( 'OIO::Args' ), "wrong sort type throws exception" );

SKIP: {
    skip <<'END_REASON', 6 unless $ENV{OHLOH_KEY};
set the environment variable OHLOH_KEY to your api key to enable these tests
END_REASON

    my $ohloh = WWW::Ohloh::API->new( api_key => $ENV{OHLOH_KEY} );

    my $projects = $ohloh->get_projects( max => 42 );

    ok $projects->next->isa( 'WWW::Ohloh::API::Project' ), 
        "returns projects";

    my @p = $projects->next( 13 );
    is scalar( @p ) => 13, 'next($i) returns right number of projects';

    my $i;
    $i++ while $projects->next;

    is $i => 42 - 13 - 1, '"max" constructor argument';

    my $j;
    while( $_ = <$projects> ) {
        $j++ if $_->isa( 'WWW::Ohloh::API::Project' );
    }
    is $j => 42, '<> override';

    # let's try to load all projects
    $projects = $ohloh->get_projects;

    eval { $projects->all };
    ok !!$@, 'all() without "max" triggers exception';

    $projects = $ohloh->get_projects( max => 43 );
    @p = $projects->all;
    is scalar( @p ) => 43, 'all()';

}
