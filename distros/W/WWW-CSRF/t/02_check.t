use Test::More tests => 7;

use WWW::CSRF qw(check_csrf_token);

is(check_csrf_token("id", "secret",
                    "5df5e9f17c929a45af5d33624ec052903599958f," .
                    "112233445566778899aabbccddeeff0011223344," .
                    "1234567890",
                    { MaxAge => -1 }),
   WWW::CSRF::CSRF_OK,
   "check simple token");

is(check_csrf_token("id", "secret",
                    "0000000000000000000000000000000000000000," .
                    "112233445566778899aabbccddeeff0011223344," .
                    "1234567890",
                    { MaxAge => -1 }),
   WWW::CSRF::CSRF_INVALID_SIGNATURE,
   "check simple invalid token");

is(check_csrf_token("id", "secret",
                    "5df5e9f17c929a45af5d33624ec052903599958f," .
                    "112233445566778899aabbccddeeff0011223344"),
   WWW::CSRF::CSRF_MALFORMED_TOKEN,
   "check simple malformed token (missing time)");

is(check_csrf_token("id", "secret",
                    "5df5e9f17c929a45af5d33624ec052903599958f," .
                    "112233445566778899aabbccddeeff0011223344," .
                    "1234567890", {
                        Time => 1234567895,
                        MaxAge => 10
                    }),
   WWW::CSRF::CSRF_OK,
   "check with maxage");

is(check_csrf_token("id", "secret",
                    "5df5e9f17c929a45af5d33624ec052903599958f," .
                    "112233445566778899aabbccddeeff0011223344," .
                    "1234567890", {
                        Time => 1234567895,
                        MaxAge => 3
                    }),
   WWW::CSRF::CSRF_EXPIRED,
   "check expired with maxage");

is(check_csrf_token("id", "secret",
                    "5df5e9f17c929000000000000000000000000000," .
                    "112233445566778899aabbccddeeff0011223344," .
                    "1234567890", {
                        Time => 1234567895,
                        MaxAge => 3
                    }),
   WWW::CSRF::CSRF_INVALID_SIGNATURE,
   "expired is not given for an invalid signature");

is(check_csrf_token("id", "secret",
                    "5df5e9f17c929a45af5d33624ec052903599958f," .
                    "112233445566778899aabbccddeeff0011223344," .
                    "1234567894", {
                        Time => 1234567895,
                        MaxAge => 10
                    }),
   WWW::CSRF::CSRF_INVALID_SIGNATURE,
   "check falsified timestamp");
