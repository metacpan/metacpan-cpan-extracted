package WWW::KGS::GameArchives::Result;
use Moo;

has 'summary' => ( is => 'ro', predicate => 1 );

has 'games' => (
    is => 'ro',
    predicate => 1,
    coerce => sub {
        my $games = shift;
        [ map { WWW::KGS::GameArchives::Result::Game->new($_) } @$games ];
    },
);

has 'zip_uri' => ( is => 'ro', predicate => 1 );
has 'tgz_uri' => ( is => 'ro', predicate => 1 );

has 'calendar' => ( is => 'ro', predicate => 1 );

1;
