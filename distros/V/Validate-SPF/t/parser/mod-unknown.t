use Test::Spec;
use Validate::SPF::Parser;
use t::lib::Parser;

my $mod = 'unknown';

my @positive = t::lib::Parser->positive_for( $mod );
my @negative = t::lib::Parser->negative_for( $mod, { text => ignore() } );

describe "Validate::SPF::Parser modifier [$mod]" => sub {
    my ( $parser, $val );

    before all => sub {
        $parser = Validate::SPF::Parser->new;
    };

    while ( my ( $case ) = splice @positive, 0, 2 ) {
        describe "positive for '$case'" => sub {

            it "should return correct result" => sub {
                cmp_deeply( $parser->parse( $case ), [] );
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
