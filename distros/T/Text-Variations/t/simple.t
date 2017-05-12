use strict;
use Test::More tests => 7;

use_ok 'Text::Variations';

{
    pass "-- single string --";
    my $tv = Text::Variations->new("simple test");
    is $tv->generate, "simple test", "generate";
    is "$tv", "simple test", "stringification";
}

{
    pass "-- single array --";
    my $tv = Text::Variations->new( "simple", " test" );
    is $tv->generate, "simple test", "generate";
    is "$tv", "simple test", "stringification";
}
