use strict;
use warnings;
use Try::Tiny qw(try catch);
use WWW::Shorten::TinyURL;
use Test::More;

BEGIN { $ENV{'WWW-SHORTEN-TESTING'} = 1; };

my $url = 'https://metacpan.org/release/WWW-Shorten';
my $prefix = 'http://tinyurl.com/';

{
    my $err = try { makeashorterlink(); } catch { $_ };
    ok($err, 'makeashorterlink: proper error response');
    $err = undef;

    $err = try { makealongerlink(); } catch { $_ };
    ok($err, 'makealongerlink: proper error response');
    $err = undef;

    $err = makeashorterlink('http://www.google.com');
    is($err, undef, 'makeashorterlink: proper error with wrong testing URL');
    is($WWW::Shorten::TinyURL::_error_message, 'Incorrect URL for testing purposes', 'makeashorterlink: proper error message');
    $err = undef;

    $err = makealongerlink('http://www.google.com');
    is($err, undef, 'makealongerlink: proper error with wrong testing URL');
    is($WWW::Shorten::TinyURL::_error_message, 'Incorrect URL for testing purposes', 'makealongerlink: proper error message');
    $err = undef;
}

# shorter
my $code = '';
my $short = makeashorterlink($url);
is($WWW::Shorten::TinyURL::_error_message, '', 'makeashorterlink: no errors');
if ($short && $short =~ /(\w+)$/) {
    $code = $1;
}
is($short, 'http://tinyurl.com/abc12345', 'makeashorterlink: proper response');
is($code, 'abc12345', 'makeashorterlink: proper code');
is($short, $prefix.$code, 'makeashorterlink: URL exactly as we expected');

# longer
my $longer = makealongerlink($prefix.$code);
is($WWW::Shorten::TinyURL::_error_message, '', 'makealongerlink: no errors');
is($longer, $url, 'makealongerlink: proper response');

$longer = undef;
$longer = makealongerlink($code);
is($WWW::Shorten::TinyURL::_error_message, '', 'makealongerlink: no errors');
is($longer, $url, 'makealongerlink: proper response');

done_testing();
