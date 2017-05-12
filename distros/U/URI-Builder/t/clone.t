use strict;
use warnings;

use Test::More tests => 3;

use URI::Builder;

my $uri = URI::Builder->new(
    uri => 'http://localhost:8080/a/b/c?one=1&two=2#main'
);
my $clone = $uri->clone;

is "$clone", "$uri", 'clone produced identical string';

$uri->path('c/b/a');
is $clone->path, '/a/b/c', 'changing original path did not affect clone';

$uri = URI::Builder->new(host => 'www.cpan.org');
is $uri->clone->as_string, $uri->as_string, 'Extrememly simple URL cloned';
