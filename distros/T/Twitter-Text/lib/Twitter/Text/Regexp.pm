package
    Twitter::Text::Regexp; # hide from PAUSE
use strict;
use warnings;
use utf8;
use Twitter::Text::Util qw(load_yaml);

# internal use only, do not use this module directly.

sub regex_range {
    my ($from, $to) = @_;

    if (defined $to) {
        return pack('U', $from) . '-' . pack('U', $to);
    } else {
        return pack('U', $from);
    }
}

our $TLDS = load_yaml("tld_lib.yml")->[0];
our $PUNCTUATION_CHARS = '!"#$%&\'()*+,-./:;<=>?@\[\]^_\`{|}~';
our $SPACE_CHARS = " \t\n\x0B\f\r";
our $CTRL_CHARS = "\x00-\x1F\x7F";
our $INVALID_CHARACTERS = join '', map { pack 'U', $_ } (
    0xFFFE, 0xFEFF, # BOM
    0xFFFF,         # Special
);
our $UNICODE_SPACES = join '', map { pack 'U*', $_ } (
    (0x0009..0x000D),  # White_Space # Cc   [5] <control-0009>..<control-000D>
    0x0020,          # White_Space # Zs       SPACE
    0x0085,          # White_Space # Cc       <control-0085>
    0x00A0,          # White_Space # Zs       NO-BREAK SPACE
    0x1680,          # White_Space # Zs       OGHAM SPACE MARK
    0x180E,          # White_Space # Zs       MONGOLIAN VOWEL SEPARATOR
    (0x2000..0x200A), # White_Space # Zs  [11] EN QUAD..HAIR SPACE
    0x2028,          # White_Space # Zl       LINE SEPARATOR
    0x2029,          # White_Space # Zp       PARAGRAPH SEPARATOR
    0x202F,          # White_Space # Zs       NARROW NO-BREAK SPACE
    0x205F,          # White_Space # Zs       MEDIUM MATHEMATICAL SPACE
    0x3000,          # White_Space # Zs       IDEOGRAPHIC SPACE
);

our $DIRECTIONAL_CHARACTERS = join '', map { pack 'U', $_ } (
    0x061C,          # ARABIC LETTER MARK (ALM)
    0x200E,          # LEFT-TO-RIGHT MARK (LRM)
    0x200F,          # RIGHT-TO-LEFT MARK (RLM)
    0x202A,          # LEFT-TO-RIGHT EMBEDDING (LRE)
    0x202B,          # RIGHT-TO-LEFT EMBEDDING (RLE)
    0x202C,          # POP DIRECTIONAL FORMATTING (PDF)
    0x202D,          # LEFT-TO-RIGHT OVERRIDE (LRO)
    0x202E,          # RIGHT-TO-LEFT OVERRIDE (RLO)
    0x2066,          # LEFT-TO-RIGHT ISOLATE (LRI)
    0x2067,          # RIGHT-TO-LEFT ISOLATE (RLI)
    0x2068,          # FIRST STRONG ISOLATE (FSI)
    0x2069,          # POP DIRECTIONAL ISOLATE (PDI)
);
our $DOMAIN_VALID_CHARS = "[^$DIRECTIONAL_CHARACTERS$PUNCTUATION_CHARS$SPACE_CHARS$CTRL_CHARS$INVALID_CHARACTERS$UNICODE_SPACES]";

our $LATIN_ACCENTS = join '', (
    regex_range(0xc0, 0xd6),
    regex_range(0xd8, 0xf6),
    regex_range(0xf8, 0xff),
    regex_range(0x0100, 0x024f),
    regex_range(0x0253, 0x0254),
    regex_range(0x0256, 0x0257),
    regex_range(0x0259),
    regex_range(0x025b),
    regex_range(0x0263),
    regex_range(0x0268),
    regex_range(0x026f),
    regex_range(0x0272),
    regex_range(0x0289),
    regex_range(0x028b),
    regex_range(0x02bb),
    regex_range(0x0300, 0x036f),
    regex_range(0x1e00, 0x1eff)
);
our $latin_accents = qr/[$LATIN_ACCENTS]+/o;

our $HASHTAG_LETTERS_AND_MARKS = '\p{L}\p{M}' .
    "\N{U+037f}\N{U+0528}-\N{U+052f}\N{U+08a0}-\N{U+08b2}\N{U+08e4}-\N{U+08ff}\N{U+0978}\N{U+0980}\N{U+0c00}\N{U+0c34}\N{U+0c81}\N{U+0d01}\N{U+0ede}\N{U+0edf}" .
    "\N{U+10c7}\N{U+10cd}\N{U+10fd}-\N{U+10ff}\N{U+16f1}-\N{U+16f8}\N{U+17b4}\N{U+17b5}\N{U+191d}\N{U+191e}\N{U+1ab0}-\N{U+1abe}\N{U+1bab}-\N{U+1bad}\N{U+1bba}-" .
    "\N{U+1bbf}\N{U+1cf3}-\N{U+1cf6}\N{U+1cf8}\N{U+1cf9}\N{U+1de7}-\N{U+1df5}\N{U+2cf2}\N{U+2cf3}\N{U+2d27}\N{U+2d2d}\N{U+2d66}\N{U+2d67}\N{U+9fcc}\N{U+a674}-" .
    "\N{U+a67b}\N{U+a698}-\N{U+a69d}\N{U+a69f}\N{U+a792}-\N{U+a79f}\N{U+a7aa}-\N{U+a7ad}\N{U+a7b0}\N{U+a7b1}\N{U+a7f7}-\N{U+a7f9}\N{U+a9e0}-\N{U+a9ef}\N{U+a9fa}-" .
    "\N{U+a9fe}\N{U+aa7c}-\N{U+aa7f}\N{U+aae0}-\N{U+aaef}\N{U+aaf2}-\N{U+aaf6}\N{U+ab30}-\N{U+ab5a}\N{U+ab5c}-\N{U+ab5f}\N{U+ab64}\N{U+ab65}\N{U+f870}-\N{U+f87f}" .
    "\N{U+f882}\N{U+f884}-\N{U+f89f}\N{U+f8b8}\N{U+f8c1}-\N{U+f8d6}\N{U+fa2e}\N{U+fa2f}\N{U+fe27}-\N{U+fe2d}\N{U+102e0}\N{U+1031f}\N{U+10350}-\N{U+1037a}" .
    "\N{U+10500}-\N{U+10527}\N{U+10530}-\N{U+10563}\N{U+10600}-\N{U+10736}\N{U+10740}-\N{U+10755}\N{U+10760}-\N{U+10767}" .
    "\N{U+10860}-\N{U+10876}\N{U+10880}-\N{U+1089e}\N{U+10980}-\N{U+109b7}\N{U+109be}\N{U+109bf}\N{U+10a80}-\N{U+10a9c}" .
    "\N{U+10ac0}-\N{U+10ac7}\N{U+10ac9}-\N{U+10ae6}\N{U+10b80}-\N{U+10b91}\N{U+1107f}\N{U+110d0}-\N{U+110e8}\N{U+11100}-" .
    "\N{U+11134}\N{U+11150}-\N{U+11173}\N{U+11176}\N{U+11180}-\N{U+111c4}\N{U+111da}\N{U+11200}-\N{U+11211}\N{U+11213}-" .
    "\N{U+11237}\N{U+112b0}-\N{U+112ea}\N{U+11301}-\N{U+11303}\N{U+11305}-\N{U+1130c}\N{U+1130f}\N{U+11310}\N{U+11313}-" .
    "\N{U+11328}\N{U+1132a}-\N{U+11330}\N{U+11332}\N{U+11333}\N{U+11335}-\N{U+11339}\N{U+1133c}-\N{U+11344}\N{U+11347}" .
    "\N{U+11348}\N{U+1134b}-\N{U+1134d}\N{U+11357}\N{U+1135d}-\N{U+11363}\N{U+11366}-\N{U+1136c}\N{U+11370}-\N{U+11374}" .
    "\N{U+11480}-\N{U+114c5}\N{U+114c7}\N{U+11580}-\N{U+115b5}\N{U+115b8}-\N{U+115c0}\N{U+11600}-\N{U+11640}\N{U+11644}" .
    "\N{U+11680}-\N{U+116b7}\N{U+118a0}-\N{U+118df}\N{U+118ff}\N{U+11ac0}-\N{U+11af8}\N{U+1236f}-\N{U+12398}\N{U+16a40}-" .
    "\N{U+16a5e}\N{U+16ad0}-\N{U+16aed}\N{U+16af0}-\N{U+16af4}\N{U+16b00}-\N{U+16b36}\N{U+16b40}-\N{U+16b43}\N{U+16b63}-" .
    "\N{U+16b77}\N{U+16b7d}-\N{U+16b8f}\N{U+16f00}-\N{U+16f44}\N{U+16f50}-\N{U+16f7e}\N{U+16f8f}-\N{U+16f9f}\N{U+1bc00}-" .
    "\N{U+1bc6a}\N{U+1bc70}-\N{U+1bc7c}\N{U+1bc80}-\N{U+1bc88}\N{U+1bc90}-\N{U+1bc99}\N{U+1bc9d}\N{U+1bc9e}\N{U+1e800}-" .
    "\N{U+1e8c4}\N{U+1e8d0}-\N{U+1e8d6}\N{U+1ee00}-\N{U+1ee03}\N{U+1ee05}-\N{U+1ee1f}\N{U+1ee21}\N{U+1ee22}\N{U+1ee24}" .
    "\N{U+1ee27}\N{U+1ee29}-\N{U+1ee32}\N{U+1ee34}-\N{U+1ee37}\N{U+1ee39}\N{U+1ee3b}\N{U+1ee42}\N{U+1ee47}\N{U+1ee49}" .
    "\N{U+1ee4b}\N{U+1ee4d}-\N{U+1ee4f}\N{U+1ee51}\N{U+1ee52}\N{U+1ee54}\N{U+1ee57}\N{U+1ee59}\N{U+1ee5b}\N{U+1ee5d}\N{U+1ee5f}" .
    "\N{U+1ee61}\N{U+1ee62}\N{U+1ee64}\N{U+1ee67}-\N{U+1ee6a}\N{U+1ee6c}-\N{U+1ee72}\N{U+1ee74}-\N{U+1ee77}\N{U+1ee79}-" .
    "\N{U+1ee7c}\N{U+1ee7e}\N{U+1ee80}-\N{U+1ee89}\N{U+1ee8b}-\N{U+1ee9b}\N{U+1eea1}-\N{U+1eea3}\N{U+1eea5}-\N{U+1eea9}" .
    "\N{U+1eeab}-\N{U+1eebb}";

our $HASHTAG_NUMERALS = "\\p{Nd}" .
    "\N{U+0de6}-\N{U+0def}\N{U+a9f0}-\N{U+a9f9}\N{U+110f0}-\N{U+110f9}\N{U+11136}-\N{U+1113f}\N{U+111d0}-\N{U+111d9}\N{U+112f0}-" .
    "\N{U+112f9}\N{U+114d0}-\N{U+114d9}\N{U+11650}-\N{U+11659}\N{U+116c0}-\N{U+116c9}\N{U+118e0}-\N{U+118e9}\N{U+16a60}-" .
    "\N{U+16a69}\N{U+16b50}-\N{U+16b59}";

our $HASHTAG_SPECIAL_CHARS = "_\N{U+200c}\N{U+200d}\N{U+a67e}\N{U+05be}\N{U+05f3}\N{U+05f4}\N{U+ff5e}\N{U+301c}\N{U+309b}\N{U+309c}\N{U+30a0}\N{U+30fb}\N{U+3003}\N{U+0f0b}\N{U+0f0c}\N{U+00b7}";

our $HASHTAG_LETTERS_NUMERALS = "$HASHTAG_LETTERS_AND_MARKS$HASHTAG_NUMERALS$HASHTAG_SPECIAL_CHARS";
our $HASHTAG_LETTERS_NUMERALS_SET = "[$HASHTAG_LETTERS_NUMERALS]";
our $HASHTAG_LETTERS_SET = "[$HASHTAG_LETTERS_AND_MARKS]";

our $HASHTAG = qr/(\A|\N{U+fe0e}|\N{U+fe0f}|[^&$HASHTAG_LETTERS_NUMERALS])(#|＃)(?!\N{U+fe0f}|\N{U+20e3})($HASHTAG_LETTERS_NUMERALS_SET*$HASHTAG_LETTERS_SET$HASHTAG_LETTERS_NUMERALS_SET*)/i;

our $valid_hashtag = qr/$HASHTAG/i;
our $end_hashtag_match = qr/\A(?:[#＃]|:\/\/)/;

our $valid_mention_preceding_chars = qr/(?:[^a-z0-9_!#\$%&*@＠]|^|(?:^|[^a-z0-9_+~.-])[rR][tT]:?)/i;
our $at_signs = qr/[@＠]/;
our $valid_mention_or_list = qr/
    ($valid_mention_preceding_chars)  # $1: Preceeding character
    ($at_signs)                       # $2: At mark
    ([a-z0-9_]{1,20})                             # $3: Screen name
    (\/[a-z][a-zA-Z0-9_\-]{0,24})?                # $4: List (optional)
/ix;
our $valid_reply = qr/^(?:[$UNICODE_SPACES$DIRECTIONAL_CHARACTERS])*$at_signs([a-z0-9_]{1,20})/i;
# Used in Extractor for final filtering
our $end_mention_match = qr/\A(?:$at_signs|$latin_accents|:\/\/)/i;

our $valid_subdomain = qr/(?:(?:$DOMAIN_VALID_CHARS(?:[_-]|$DOMAIN_VALID_CHARS)*)?$DOMAIN_VALID_CHARS\.)/i;
our $valid_domain_name = qr/(?:(?:$DOMAIN_VALID_CHARS(?:[-]|$DOMAIN_VALID_CHARS)*)?$DOMAIN_VALID_CHARS\.)/i;

our $GENERIC_TLDS = join '|', @{$TLDS->{generic}};
our $CC_TLDS = join '|', @{$TLDS->{country}};

our $valid_gTLD = qr{
    (?:
    (?:$GENERIC_TLDS)
    (?=[^0-9a-z@+-]|$)
    )
}ix;

our $valid_ccTLD = qr{
    (?:
    (?:$CC_TLDS)
    (?=[^0-9a-z@+-]|$)
    )
}ix;
our $valid_punycode = qr/(?:xn--[0-9a-z]+)/i;

our $valid_domain = qr/(?:
    $valid_subdomain*$valid_domain_name
    (?:$valid_gTLD|$valid_ccTLD|$valid_punycode)
)/ix;

# This is used in Extractor
our $valid_ascii_domain = qr/
    (?:(?:[a-z0-9\-_]|$latin_accents)+\.)+
    (?:$valid_gTLD|$valid_ccTLD|$valid_punycode)
/ix;

# This is used in Extractor for stricter t.co URL extraction
our $valid_tco_url = qr/^https?:\/\/t\.co\/([a-z0-9]+)/i;

our $valid_port_number = qr/[0-9]+/;

our $valid_url_preceding_chars = qr/(?:[^A-Z0-9@＠\$#＃$INVALID_CHARACTERS]|[$DIRECTIONAL_CHARACTERS]|^)/i;
our $invalid_url_without_protocol_preceding_chars = qr/[-_.\/]$/;

our $valid_general_url_path_chars = qr/[a-z\p{Cyrillic}0-9!\*';:=\+\,\.\$\/%#\[\]\p{Pd}_~&\|$LATIN_ACCENTS]/i;
# Allow URL paths to contain up to two nested levels of balanced parens
#  1. Used in Wikipedia URLs like /Primer_(film)
#  2. Used in IIS sessions like /S(dfd346)/
#  3. Used in Rdio URLs like /track/We_Up_(Album_Version_(Edited))/
our $valid_url_balanced_parens = qr/
    \(
    (?:
        $valid_general_url_path_chars+
        |
        # allow one nested level of balanced parentheses
        (?:
        $valid_general_url_path_chars*
        \(
            $valid_general_url_path_chars+
        \)
        $valid_general_url_path_chars*
        )
    )
    \)
/ix;
# Valid end-of-path chracters (so /foo. does not gobble the period).
#   1. Allow =&# for empty URL parameters and other URL-join artifacts
our $valid_url_path_ending_chars = qr/[a-z\p{Cyrillic}0-9=_#\/\+\-$LATIN_ACCENTS]|(?:$valid_url_balanced_parens)/i;
our $valid_url_path = qr/(?:
    (?:
    $valid_general_url_path_chars*
    (?:$valid_url_balanced_parens $valid_general_url_path_chars*)*
    $valid_url_path_ending_chars
    )|(?:$valid_general_url_path_chars+\/)
)/ix;
our $valid_url_query_chars = qr/[a-z0-9!?\*'\(\);:&=\+\$\/%#\[\]\-_\.,~|@]/i;
our $valid_url_query_ending_chars = qr/[a-z0-9_&=#\/\-]/i;
our $valid_url = qr{
  (                                                                         #   $1 total match
    ($valid_url_preceding_chars)                                            #   $2 Preceeding chracter
    (                                                                       #   $3 URL
      (https?:\/\/)?                                                        #   $4 Protocol (optional)
      ($valid_domain)                                                       #   $5 Domain(s)
      (?::($valid_port_number))?                                            #   $6 Port number (optional)
      (/$valid_url_path*)?                                                  #   $7 URL Path and anchor
      (\?$valid_url_query_chars*$valid_url_query_ending_chars)?             #   $8 Query String
    )
  )}ix;

our $cashtag = qr/[a-z]{1,6}(?:[._][a-z]{1,2})?/i;
our $valid_cashtag = qr/(^|[$UNICODE_SPACES$DIRECTIONAL_CHARACTERS])(\$)($cashtag)(?=$|\s|[$PUNCTUATION_CHARS])/i;

# These URL validation pattern strings are based on the ABNF from RFC 3986
our $validate_url_unreserved = qr/[a-z\p{Cyrillic}0-9\p{Pd}._~]/i;
our $validate_url_pct_encoded = qr/(?:%[0-9a-f]{2})/i;
our $validate_url_sub_delims = qr/[!\$&'()*+,;=]/i;
our $validate_url_pchar = qr/(?:
    $validate_url_unreserved|
    $validate_url_pct_encoded|
    $validate_url_sub_delims|
    [:\|@]
)/ix;

our $validate_url_scheme = qr/(?:[a-z][a-z0-9+\-.]*)/i;
our $validate_url_userinfo = qr/(?:
    $validate_url_unreserved|
    $validate_url_pct_encoded|
    $validate_url_sub_delims|
    :
)*/ix;

our $validate_url_dec_octet = qr/(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9]{2})|(?:2[0-4][0-9])|(?:25[0-5]))/i;
our $validate_url_ipv4 =
    qr/(?:$validate_url_dec_octet(?:\.$validate_url_dec_octet){3})/ix;

# Punting on real IPv6 validation for now
our $validate_url_ipv6 = qr/(?:\[[a-f0-9:\.]+\])/i;

# Also punting on IPvFuture for now
our $validate_url_ip = qr/(?:
    $validate_url_ipv4|
    $validate_url_ipv6
)/ix;

# This is more strict than the rfc specifies
our $validate_url_subdomain_segment = qr/(?:[a-z0-9](?:[a-z0-9_\-]*[a-z0-9])?)/i;
our $validate_url_domain_segment = qr/(?:[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)/i;
our $validate_url_domain_tld = qr/(?:[a-z](?:[a-z0-9\-]*[a-z0-9])?)/i;
our $validate_url_domain = qr/(?:(?:$validate_url_subdomain_segment\.)*
                                (?:$validate_url_domain_segment\.)
                                $validate_url_domain_tld)/ix;

our $validate_url_host = qr/(?:
    $validate_url_ip|
    $validate_url_domain
)/ix;

# Unencoded internationalized domains - this doesn't check for invalid UTF-8 sequences
our $validate_url_unicode_subdomain_segment =
    qr/(?:(?:[a-z0-9]|[^\x00-\x7f])(?:(?:[a-z0-9_\-]|[^\x00-\x7f])*(?:[a-z0-9]|[^\x00-\x7f]))?)/ix;
our $validate_url_unicode_domain_segment =
    qr/(?:(?:[a-z0-9]|[^\x00-\x7f])(?:(?:[a-z0-9\-]|[^\x00-\x7f])*(?:[a-z0-9]|[^\x00-\x7f]))?)/ix;
our $validate_url_unicode_domain_tld =
    qr/(?:(?:[a-z]|[^\x00-\x7f])(?:(?:[a-z0-9\-]|[^\x00-\x7f])*(?:[a-z0-9]|[^\x00-\x7f]))?)/ix;
our $validate_url_unicode_domain = qr/(?:(?:$validate_url_unicode_subdomain_segment\.)*
                                        (?:$validate_url_unicode_domain_segment\.)
                                        $validate_url_unicode_domain_tld)/ix;

our $validate_url_unicode_host = qr/(?:
    $validate_url_ip|
    $validate_url_unicode_domain
)/ix;

our $validate_url_port = qr/[0-9]{1,5}/;

our $validate_url_unicode_authority = qr{
    (?:($validate_url_userinfo)@)?     #  $1 userinfo
    ($validate_url_unicode_host)       #  $2 host
    (?::($validate_url_port))?         #  $3 port
}ix;

our $validate_url_authority = qr{
    (?:($validate_url_userinfo)@)?     #  $1 userinfo
    ($validate_url_host)               #  $2 host
    (?::($validate_url_port))?         #  $3 port
}ix;

our $validate_url_path = qr{(/$validate_url_pchar*)*}i;
our $validate_url_query = qr{($validate_url_pchar|/|\?)*}i;
our $validate_url_fragment = qr{($validate_url_pchar|/|\?)*}i;

# Modified version of RFC 3986 Appendix B
our $validate_url_unencoded = qr{
    \A                                #  Full URL
    (?:
    ([^:/?#]+)://                  #  $1 Scheme
    )?
    ([^/?#]*)                        #  $2 Authority
    ([^?#]*)                         #  $3 Path
    (?:
    \?([^#]*)                      #  $4 Query
    )?
    (?:
    \#(.*)                         #  $5 Fragment
    )?\z
}ix;

1;
