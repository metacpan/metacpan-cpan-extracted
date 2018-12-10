use Sympatic;
use Test::More;
my $sin;

BEGIN {
    note "foo is evaluated in the begin block so we can test that the 'fun' works.";
    eval 'fun foo ($who="world") { "hello, $who" }';
    if ( ok !$@ , "use of fun ($@)" ) {
        eval q{
            is foo
            , 'hello, world'
            , 'foo (declared with fun) is available'};
    }
    done_testing;
}
