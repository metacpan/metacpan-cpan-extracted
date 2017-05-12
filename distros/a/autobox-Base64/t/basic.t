use strict;
use warnings;
use utf8;

use Test::More;

use autobox::Base64;

use constant BASE64    => "aGkgdGhlcmUh\n";
use constant PLAINTEXT => 'hi there!';

is "aGkgdGhlcmUh"->decode_base64, PLAINTEXT, 'decode_base64()';
is BASE64()->decode_base64, PLAINTEXT, 'decode_base64()';
is BASE64()->from_base64,   PLAINTEXT, 'from_base64()';

is 'hi there!'->encode_base64, BASE64, 'encode_base64()';
is PLAINTEXT()->encode_base64, BASE64, 'encode_base64()';
is PLAINTEXT()->to_base64,     BASE64, 'to_base64()';

done_testing;
