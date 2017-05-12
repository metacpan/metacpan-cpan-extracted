#!perl -w
#
# $Id: 01-compat.t,v 0.2 2009/03/24 14:24:09 dankogai Exp $
#
# Original as URI-1.35/t/escape.t
#

use URI::Escape::XS qw/uri_escape uri_unescape/;
use Test::More tests => 7;

{
use bytes;
is uri_escape("|abc\xE5"),       "%7Cabc%E5", qq{uri_escape("|abc?")};
is  uri_escape("abc", "b-d"), "a%62%63",   qq{uri_escape("abc", "b-d")};
ok !defined(uri_escape(undef)),            qq{uri_escape(undef)};
is uri_unescape("%7Cabc%e5"),  "|abc\xE5"  ,  qq{uri_unescape("%7Cabc%e5")}; ;
is join(":", uri_unescape("%40A%42", "CDE", "F%47H")), '@AB:CDE:FGH',
    qq{uri_unescape("%40A%42", "CDE", "F%47H")};
}
eval { my $escaped = uri_escape("abc" . chr(300)) };
ok !$@, qq{uri_escape("abc".chr(300)) does NOT croak};
is uri_escape(chr(0xFFF)), "%E0%BF%BF", qq{uri_escape(chr(0xFFF))};


