#!perl
use strict;
use Test::More;

use URI::Encode::XS qw/uri_encode uri_encode_utf8 uri_decode uri_decode_utf8/;

pass 'imported module';

subtest encode => sub {
  is uri_encode(''), '';
  is uri_encode("something"), 'something';
  is uri_encode(" "), '%20';
  is uri_encode("%%20"), '%25%2520';
  is uri_encode("|abcå"), "%7Cabc%C3%A5";
  is uri_encode("~*'()"), "~%2A%27%28%29";
  is uri_encode("<\">"), "%3C%22%3E";
  is uri_encode("ABC\x00DEF"), "ABC%00DEF", 'constains encoded null character';
  {
    use utf8;
    is uri_encode("åäö"), '%E5%E4%F6', 'native characters (Latin1)';
  }
};

subtest encode_utf8 => sub {
  is uri_encode_utf8(''), '';
  is uri_encode_utf8("something"), 'something';
  {
    use utf8;
    is uri_encode_utf8("åäö"), '%C3%A5%C3%A4%C3%B6', 'native characters (Latin1)';
    is uri_encode_utf8("\x{1F63C}"), '%F0%9F%98%BC', 'unicode character';
  }
};

subtest decode => sub {
  is uri_decode(''), '';
  is uri_decode("something"), 'something';
  is uri_decode("something%"), 'something%', 'invalid sequences are copied';
  is uri_decode('something%a'), 'something%a', 'invalid sequences are copied';
  is uri_decode('something%Z/'), 'something%Z/', 'invalid sequences are copied';
  is uri_decode('%20'), ' ';
  is uri_decode('%25%2520'), "%%20";
  is uri_decode("%7Cabc%C3%A5"), "|abcå";
  is uri_decode("~%2A%27%28%29"), "~*'()";
  is uri_decode("%3C%22%3E"), "<\">";
  is uri_decode("ABC%00DEF"), "ABC\x00DEF", 'constains decoded null character';
};

subtest decode_utf8 => sub {
  is uri_decode_utf8(''), '';
  is uri_decode_utf8("something"), 'something';
  {
    use utf8;
    is uri_decode_utf8('%C3%A5%C3%A4%C3%B6'), "åäö", 'native characters (Latin1)';
    is uri_decode_utf8('%F0%9F%98%BC'), "\x{1F63C}", 'unicode character';
  }
};

subtest exceptions => sub {
  eval { URI::Encode::XS::uri_encode(undef) };
  like $@, qr/uri_encode\(\) requires a scalar argument to encode!/, 'croak on undef';
  eval { URI::Encode::XS::uri_encode("\x{263A}") };
  like $@, qr/Wide character in octet string/, 'croak on non-octet string';
  eval { URI::Encode::XS::uri_decode(undef) };
  like $@, qr/uri_decode\(\) requires a scalar argument to decode!/, 'croak on undef';
  eval { URI::Encode::XS::uri_decode("\x{263A}") };
  like $@, qr/Wide character in octet string/, 'croak on non-octet string';
  eval { URI::Encode::XS::uri_decode_utf8("%C0%C2") };
  like $@, qr/Can't decode ill-formed UTF-8 octet sequence <C0>/, 'croak on ill-formed utf8';
  eval { URI::Encode::XS::uri_encode_utf8(do { no warnings 'utf8'; pack 'U' , 0x200000 }) };
  like $@, qr/Can't represent super code point \\x\{200000\}/, 'croak on non-unicode codepoints';
  eval { URI::Encode::XS::uri_encode_utf8(do { no warnings 'utf8'; pack 'U' , 0xDC00 }) };
  like $@, qr/Can't represent surrogate code point U\+DC00/, 'croak on surrogate codepoints';
};

done_testing();
