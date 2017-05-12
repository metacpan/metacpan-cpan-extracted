#!perl
use strict;
use Test::More;

use URI::Encode::XS qw/uri_encode uri_decode/;pass 'imported module';

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

subtest exceptions => sub {
  eval { URI::Encode::XS::uri_encode(undef) };
  like $@, qr/uri_encode\(\) requires a scalar argument to encode!/, 'croak on undef';
  eval { URI::Encode::XS::uri_encode("\x{263A}") };
  like $@, qr/Wide character in octet string/, 'croak on non-octet string';
  eval { URI::Encode::XS::uri_decode(undef) };
  like $@, qr/uri_decode\(\) requires a scalar argument to decode!/, 'croak on undef';
  eval { URI::Encode::XS::uri_decode("\x{263A}") };
  like $@, qr/Wide character in octet string/, 'croak on non-octet string';
};

done_testing();
