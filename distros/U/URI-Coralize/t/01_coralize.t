use strict;
use warnings;
use Test::More tests => 6;
use URI;
use URI::Coralize;

can_ok(URI->new('http://example.com/'), 'coralize');

my %tests = (
    'http://example.com/'          => 'http://example.com.nyud.net/',
    'http://example.com/a?b=c'     => 'http://example.com.nyud.net/a?b=c',
    'http://example.com:8080/t/'   => 'http://example.com.8080.nyud.net/t/',
    'http://example.com.nyud.net/' => 'http://example.com.nyud.net/',
    'https://example.com/'         => 'https://example.com/',
);

while (my ($before, $after) = each %tests) {
    my $uri = URI->new($before);
    $uri = $uri->coralize;
    is($uri->as_string, $after, "coralize: $before");
}
