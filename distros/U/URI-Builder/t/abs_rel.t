use strict;
use warnings;

use Test::More tests => 2;
use URI::Builder;

my $uri = URI::Builder->new(uri => 'http://localhost/foo/bar/baz');

my $rel = $uri->rel('http://localhost/foo/');
is $rel, 'bar/baz', 'rel';

my $abs = $rel->abs('http://localhost/qux/');
is $abs, 'http://localhost/qux/bar/baz', 'abs';
