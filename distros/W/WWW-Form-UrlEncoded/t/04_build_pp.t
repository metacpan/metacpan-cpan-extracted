use strict;
use warnings;
use Test::More;
use WWW::Form::UrlEncoded::PP qw/build_urlencoded build_urlencoded_utf8/;
use JSON;

my @data = (
    ['a'=>'b'] => 'a=b',
    [['a'=>'b']] => 'a=b',
    [{'a'=>'b'}] => 'a=b',
    ['a'=>['b','c']] => 'a=b&a=c',
    [['a'=>['b','c']]] => 'a=b&a=c',
    [{'a'=>['b','c']}] => 'a=b&a=c',
    ['a'=>'b','c'=>'d'] => 'a=b&c=d',
    [' a '=>' b '] => '+a+=+b+',
    ['a'=>'b','c'=>'d',';'] => 'a=b;c=d',
    [['a'=>['b','c']],';'] => 'a=b;a=c',
    [{'a'=>['b','c']},';'] => 'a=b;a=c',
    ['a'=>'b','c'=>'d',';&'] => 'a=b;&c=d',
    [['a'=>['b','c']],';&'] => 'a=b;&a=c',
    [{'a'=>['b','c']},';&'] => 'a=b;&a=c',
    ['a'=>'b','c'=> undef,';'] => 'a=b;c=',
    ['a'] => 'a=',
    ['a'=>undef] => 'a=',
    [undef] => '=',
    [] => '',
);

while ( @data ) {
    my $data = shift @data;
    my $test = shift @data;
    is( build_urlencoded(@$data), $test, JSON::encode_json($data));
}

is( build_urlencoded([ foo => "\xE5", bar => "\x{263A}" ]), 'foo=%E5&bar=%E2%98%BA'); 
is( build_urlencoded_utf8([ foo => "\xE5", bar => "\x{263A}" ]), 'foo=%C3%A5&bar=%E2%98%BA'); 
is( build_urlencoded_utf8([ "\xE5" => "foo", "\x{263A}" => "bar" ]), '%C3%A5=foo&%E2%98%BA=bar'); 
is( build_urlencoded_utf8([ foo => "\x{263A}", bar => "\x{263A}" ],"\xE5"), 'foo=%E2%98%BAåbar=%E2%98%BA'); 

for (1..10){
  like( build_urlencoded({aa => [ 1, undef, 3 ],bb => [ 1, 2, 3 ]}), qr!(aa=1&aa=&aa=3&bb=1&bb=2&bb=3|bb=1&bb=2&bb=3&aa=1&aa=&aa=3)!);
  like( build_urlencoded_utf8({aa => [ 1, undef, 3 ],bb => [ 1, 2, 3 ]}), qr!(aa=1&aa=&aa=3&bb=1&bb=2&bb=3|bb=1&bb=2&bb=3&aa=1&aa=&aa=3)!);
}

done_testing;

