#!perl

use Test::More tests => 6;

BEGIN {
    use_ok( 'Web::oEmbed::Common' ) || print "Bail out!
";
}

is( Web::oEmbed::Common->_compile_url('http://www.google.com/'), 'http://www\.google\.com\/', "Plain URL" );

is( Web::oEmbed::Common->_compile_url('http://(www.)google.com/'), 'http://google\.com\/|http://www\.google\.com\/', "Optional element" );

is( Web::oEmbed::Common->_compile_url('http://(|www.)google.com/'), 'http://google\.com\/|http://www\.google\.com\/', "Empty alternative" );

is( Web::oEmbed::Common->_compile_url('http://(www.|web.)google.com/'), 'http://www\.google\.com\/|http://web\.google\.com\/', "Explicit alternatives" );

is( Web::oEmbed::Common->_compile_url('http://(www.|web.)google(.com|.org)/'), 'http://www\.google\.com\/|http://www\.google\.org\/|http://web\.google\.com\/|http://web\.google\.org\/', "Double alternatives" );

