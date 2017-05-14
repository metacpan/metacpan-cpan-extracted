use v6-perlito;

class Main {
    use Perlito6::Test;

    Perlito6::Test::plan 1;
    Perlito6::Test::ok( 1==1, "Perlito6::Test works");
}
