use strict;
use warnings;
use utf8;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use WWW::Crawler::Mojo;
use WWW::Crawler::Mojo::ScraperUtil 'resolve_href';
use Test::More tests => 74;

my $base;
my $tmp;

# Resolve RFC 1808 examples
$base = Mojo::URL->new('http://a/b/c/d?q#f');
is resolve_href($base, 'g'),       'http://a/b/c/g',       'right url';
is resolve_href($base, './g'),     'http://a/b/c/g',       'right url';
is resolve_href($base, 'g/'),      'http://a/b/c/g/',      'right url';
is resolve_href($base, '//g'),     'http://g',             'right url';
is resolve_href($base, '?y'),      'http://a/b/c/d?y',     'right url';
is resolve_href($base, 'g?y'),     'http://a/b/c/g?y',     'right url';
is resolve_href($base, 'g?y/./x'), 'http://a/b/c/g?y/./x', 'right url';
is resolve_href($base, '#s'),      'http://a/b/c/d?q',     'right url';
is resolve_href($base, 'g#s'),     'http://a/b/c/g',       'right url';
is resolve_href($base, 'g#s/./x'), 'http://a/b/c/g',       'right url';
is resolve_href($base, 'g?y#s'),   'http://a/b/c/g?y',     'right url';
is resolve_href($base, '.'),       'http://a/b/c',         'right url';
is resolve_href($base, './'),      'http://a/b/c/',        'right url';
is resolve_href($base, '..'),      'http://a/b',           'right url';
is resolve_href($base, '../'),     'http://a/b/',          'right url';
is resolve_href($base, '../g'),    'http://a/b/g',         'right url';
is resolve_href($base, '../..'),   'http://a/',            'right url';
is resolve_href($base, '../../'),  'http://a/',            'right url';
is resolve_href($base, '../../g'), 'http://a/g',           'right url';

$base = Mojo::URL->new('http://example.com');
is resolve_href($base, '/hoge.html'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, './hoge.html'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, '#a'), 'http://example.com', 'right url';

$base = Mojo::URL->new('http://example.com');
is resolve_href($base, 'http://example2.com/hoge.html'),
  'http://example2.com/hoge.html', 'right url';
is resolve_href($base, 'http://example2.com//hoge.html'),
  'http://example2.com//hoge.html', 'right url';

$base = Mojo::URL->new('http://example.com/dir/');
is resolve_href($base, './hoge.html'), 'http://example.com/dir/hoge.html',
  'right url';
is resolve_href($base, '../hoge.html'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, '../../hoge.html'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, '/hoge.html'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, '/'),   'http://example.com/',        'right url';
is resolve_href($base, ''),    'http://example.com/dir/',    'right url';
is resolve_href($base, 'foo'), 'http://example.com/dir/foo', 'right url';

$base = Mojo::URL->new('http://example.com/dir/');
is resolve_href($base, './hoge.html/?a=b'),
  'http://example.com/dir/hoge.html/?a=b', 'right url';
is resolve_href($base, '../hoge.html/?a=b'),
  'http://example.com/hoge.html/?a=b', 'right url';
is resolve_href($base, '../../hoge.html/?a=b'),
  'http://example.com/hoge.html/?a=b', 'right url';
is resolve_href($base, '/hoge.html/?a=b'),
  'http://example.com/hoge.html/?a=b', 'right url';

$base = Mojo::URL->new('http://example.com/dir/');
is resolve_href($base, './hoge.html#fragment'),
  'http://example.com/dir/hoge.html', 'right url';
is resolve_href($base, '../hoge.html#fragment'),
  'http://example.com/hoge.html', 'right url';
is resolve_href($base, '../../hoge.html#fragment'),
  'http://example.com/hoge.html', 'right url';
is resolve_href($base, '/hoge.html#fragment'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, '/#fragment'),  'http://example.com/',     'right url';
is resolve_href($base, './#fragment'), 'http://example.com/dir/', 'right url';
is resolve_href($base, '#fragment'),   'http://example.com/dir/', 'right url';

$base = Mojo::URL->new('https://example.com/');
is resolve_href($base, '//example2.com/hoge.html'),
  'https://example2.com/hoge.html', 'right url';

$base = Mojo::URL->new('https://example.com/');
is resolve_href($base, '//example2.com:8080/hoge.html'),
  'https://example2.com:8080/hoge.html', 'right url';

$base = Mojo::URL->new('http://example.com/org');
is resolve_href($base, '/hoge.html'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, './hoge.html'), 'http://example.com/hoge.html',
  'right url';

$base = Mojo::URL->new('http://example.com/org');
is resolve_href($base, 'http://example2.com/hoge.html'),
  'http://example2.com/hoge.html', 'right url';
is resolve_href($base, 'http://example2.com//hoge.html'),
  'http://example2.com//hoge.html', 'right url';

$base = Mojo::URL->new('http://example.com/dir/org');
is resolve_href($base, './hoge.html'), 'http://example.com/dir/hoge.html',
  'right url';
is resolve_href($base, '../hoge.html'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, '../../hoge.html'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, '/hoge.html'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, '/'),   'http://example.com/',        'right url';
is resolve_href($base, ''),    'http://example.com/dir/org', 'right url';
is resolve_href($base, 'foo'), 'http://example.com/dir/foo', 'right url';

$base = Mojo::URL->new('http://example.com/dir/org');
is resolve_href($base, './hoge.html/?a=b'),
  'http://example.com/dir/hoge.html/?a=b', 'right url';
is resolve_href($base, '../hoge.html/?a=b'),
  'http://example.com/hoge.html/?a=b', 'right url';
is resolve_href($base, '../../hoge.html/?a=b'),
  'http://example.com/hoge.html/?a=b', 'right url';
is resolve_href($base, '/hoge.html/?a=b'),
  'http://example.com/hoge.html/?a=b', 'right url';

$base = Mojo::URL->new('http://example.com/dir/org');
is resolve_href($base, './hoge.html#fragment'),
  'http://example.com/dir/hoge.html', 'right url';
is resolve_href($base, '../hoge.html#fragment'),
  'http://example.com/hoge.html', 'right url';
is resolve_href($base, '../../hoge.html#fragment'),
  'http://example.com/hoge.html', 'right url';
is resolve_href($base, '/hoge.html#fragment'), 'http://example.com/hoge.html',
  'right url';
is resolve_href($base, '/#fragment'),  'http://example.com/',     'right url';
is resolve_href($base, './#fragment'), 'http://example.com/dir/', 'right url';
is resolve_href($base, '#fragment'), 'http://example.com/dir/org', 'right url';

$base = Mojo::URL->new('https://example.com/org');
is resolve_href($base, '//example2.com/hoge.html'),
  'https://example2.com/hoge.html', 'right url';

$base = Mojo::URL->new('https://example.com/org');
is resolve_href($base, '//example2.com:8080/hoge.html'),
  'https://example2.com:8080/hoge.html', 'right url';

$base = 'http://www.eclipse.org/forums/index.php/f/48/';
is resolve_href($base, '//www.eclipse.org/forums/'),
  'http://www.eclipse.org/forums/', 'right url';

$base = 'https://www.eclipse.org/forums/index.php/f/48/';
is resolve_href($base, '//www.eclipse.org/forums/'),
  'https://www.eclipse.org/forums/', 'right url';

# Additional real world use case
$base = 'https://example.com/';
is resolve_href($base, ' foo'), 'https://example.com/foo', 'right url';
is resolve_href($base, 'foo '), 'https://example.com/foo', 'right url';
is resolve_href($base, 'foo bar'), 'https://example.com/foo%20bar',
  'right url';
is resolve_href($base, "foo\nbar"), 'https://example.com/foobar', 'right url';
