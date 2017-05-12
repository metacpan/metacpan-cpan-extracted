use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo::Trim;

get '/test_01' => 'test_01';

my $test = Test::Mojo::Trim->new;
$test->get_ok('/test_01')->status_is(200)->content_isnt(after_trim(), 'Original string left in place');
$test->get_ok('/test_01')->status_is(200)->trimmed_content_is(after_trim(), 'Correctly trimmed string');

done_testing;

sub after_trim {
    return qq{This string contains untrimmed whitespace};
}

__DATA__

@@ test_01.html.ep
 This  string

contains  untrimmed	 	whitespace
