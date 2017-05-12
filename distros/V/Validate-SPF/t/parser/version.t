use Test::Spec;
use Validate::SPF::Parser;
use t::lib::Parser;

my @positive = t::lib::Parser->positive_for( 'version', { type => 'ver' } );
my @negative = t::lib::Parser->negative_for( 'version', { text => ignore() } );

describe "Validate::SPF::Parser [version]" => sub {
    my ( $parser );

    before all => sub {
        $parser = Validate::SPF::Parser->new;
    };

    while ( my ( $case, $result ) = splice @positive, 0, 2 ) {
        describe "positive for '$case'" => sub {

            it "should return correct result" => sub {
                cmp_deeply( $parser->parse( $case ), [ $result ] );
            };
        };
    }

    while ( my ( $case, $result ) = splice @negative, 0, 2 ) {
        describe "negative for '$case'" => sub {

            before sub {
                $parser->parse( $case );
            };

            it "should return correct error" => sub {
                cmp_deeply( $parser->error, $result );
            };
        };
    }
};

runtests unless caller;
