use strict;
use warnings;
use Test::More tests => 5;
use URI;
use URI::Unredirect;

can_ok(URI->new('http://example.com/'), 'unredirect');

my %tests = (
    'http://example.com/' => 'http://example.com/',
    'http://example.com/a?b=c&d=f' => 'http://example.com/a?b=c&d=f',
    'http://example.com/r?url=http://example.net/path/' =>
        'http://example.net/path/',
    'http://example.com/r?u=http%3A%2F%2Fexample.net%2Fpath%2F' =>
        'http://example.net/path/',
);

while (my ($before, $after) = each %tests) {
    my $uri = URI->new($before);
    $uri = $uri->unredirect;
    is($uri->as_string, $after, 'unredirect');
}
