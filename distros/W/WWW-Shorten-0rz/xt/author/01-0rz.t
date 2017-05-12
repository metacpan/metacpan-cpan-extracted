use strict;
use warnings;
use Try::Tiny qw(try catch);
use WWW::Shorten::0rz;
use Test::More;

my $url = 'https://metacpan.org/pod/WWW::Shorten::0rz';
my $prefix = 'http://0rz.tw/';

{
    my $err = try { makeashorterlink(); } catch { $_ };
    ok($err, 'makeashorterlink: proper error response');
    $err = undef;

    $err = try { makealongerlink(); } catch { $_ };
    ok($err, 'makealongerlink: proper error response');
    $err = undef;
}

# shorter
my $code = '';
my $short = makeashorterlink($url);
is($WWW::Shorten::0rz::_error_message, '', 'makeashorterlink: no errors');
if ($short && $short =~ /(\w+)$/) {
    $code = $1;
}
is($short, 'http://0rz.tw/jPDQH', 'makeashorterlink: proper response');
is($code, 'jPDQH', 'makeashorterlink: proper code');
is($short, $prefix.$code, 'makeashorterlink: URL exactly as we expected');

# longer
my $longer = makealongerlink($prefix.$code);
is($WWW::Shorten::0rz::_error_message, '', 'makealongerlink: no errors');
is($longer, $url, 'makealongerlink: proper response');

$longer = undef;
$longer = makealongerlink($code);
is($WWW::Shorten::0rz::_error_message, '', 'makealongerlink: no errors');
is($longer, $url, 'makealongerlink: proper response');

done_testing();
