package Treex::PML::Schema::CDATA;

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.24'; # version template
}
no warnings 'uninitialized';
use Carp;

use Treex::PML::Schema::Constants;
use base qw( Treex::PML::Schema::Decl );

=head1 NAME

Treex::PML::Schema::CDATA - implements cdata declaration.

=head1 INHERITANCE

This class inherits from L<Treex::PML::Schema::Decl>.

=head1 METHODS

See the super-class for the complete list.

=over 3

=item $decl->is_atomic ()

Returns 1.

=item $decl->get_decl_type ()

Returns the constant PML_CDATA_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'cdata'.

=item $decl->get_format ()

Return identifier of the data format.

=item $decl->set_format (format)

Set format to a given format identifier.

=item $decl->check_string_format (string, format-id?)

If the C<format-id> argument is specified, return 1 if the string
confirms to the given format.  If the C<format-id> argument is
omitted, return 1 if the string conforms to the format specified in
the type declaration in the PML schema. Otherwise return 0.

=item $decl->validate_object($object)

See C<validate_object()> in L<Treex::PML::Schema>.

=item $decl->supported_formats

Returns a list of formats for which the current implementation
of C<validate_object> provides a reasonable validator. 

Currently all formats defined in the PML Schema specification revision
1.1.2 are supported, namely:

any, anyURI, base64Binary, boolean, byte, date, dateTime, decimal,
double, duration, float, gDay, gMonth, gMonthDay, gYear, gYearMonth,
hexBinary, ID, IDREF, IDREFS, int, integer, language, long, Name,
NCName, negativeInteger, NMTOKEN, NMTOKENS, nonNegativeInteger,
nonPositiveInteger, normalizedString, PMLREF, positiveInteger, short,
string, time, token, unsignedByte, unsignedInt, unsignedLong,
unsignedShort

=item $decl->get_content_decl ()

Returns undef.

=back


=cut

sub is_atomic { 1 }
sub get_decl_type { return PML_CDATA_DECL; }
sub get_decl_type_str { return 'cdata'; }
sub get_content_decl { return(undef); }
sub get_format { return $_[0]->{format} }
sub set_format { $_[0]->{format} = $_[1] }
sub init {
  my ($self,$opts)=@_;
  $self->{-parent}{-decl} = 'cdata';
}

{
  our %format_re = (
    any => sub { 1 }, # to make it appear in the list of supported formats
    nonNegativeInteger => qr(^\s*(?:[+]?\d+|-0+)\s*$),
    positiveInteger => qr(^\s*[+]?\d*[1-9]\d*\s*$), # ? is zero allowed lexically
    negativeInteger => qr(^\s*-\d*[1-9]\d*\s*$), # ? is zero allowed lexically
    nonPositiveInteger => qr(^\s*(?:-\d+|[+]?0+)\s*$),
    decimal => qr(^\s*[+-]?\d+(?:\.\d*)?\s*$),
    boolean => qr(^(?:[01]|true|false)$),
  );

  my $BaseChar = '\x{0041}-\x{005A}\x{0061}-\x{007A}\x{00C0}-\x{00D6}\x{00D8}-\x{00F6}'.
      '\x{00F8}-\x{00FF}\x{0100}-\x{0131}\x{0134}-\x{013E}\x{0141}-\x{0148}\x{014A}-\x{017E}'.
      '\x{0180}-\x{01C3}\x{01CD}-\x{01F0}\x{01F4}-\x{01F5}\x{01FA}-\x{0217}\x{0250}-\x{02A8}'.
      '\x{02BB}-\x{02C1}\x{0386}\x{0388}-\x{038A}\x{038C}\x{038E}-\x{03A1}\x{03A3}-\x{03CE}'.
      '\x{03D0}-\x{03D6}\x{03DA}\x{03DC}\x{03DE}\x{03E0}\x{03E2}-\x{03F3}\x{0401}-\x{040C}'.
      '\x{040E}-\x{044F}\x{0451}-\x{045C}\x{045E}-\x{0481}\x{0490}-\x{04C4}\x{04C7}-\x{04C8}'.
      '\x{04CB}-\x{04CC}\x{04D0}-\x{04EB}\x{04EE}-\x{04F5}\x{04F8}-\x{04F9}\x{0531}-\x{0556}'.
      '\x{0559}\x{0561}-\x{0586}\x{05D0}-\x{05EA}\x{05F0}-\x{05F2}\x{0621}-\x{063A}\x{0641}-'.
      '\x{064A}\x{0671}-\x{06B7}\x{06BA}-\x{06BE}\x{06C0}-\x{06CE}\x{06D0}-\x{06D3}\x{06D5}\x{06E5}-'.
      '\x{06E6}\x{0905}-\x{0939}\x{093D}\x{0958}-\x{0961}\x{0985}-\x{098C}\x{098F}-\x{0990}\x{0993}-'.
      '\x{09A8}\x{09AA}-\x{09B0}\x{09B2}\x{09B6}-\x{09B9}\x{09DC}-\x{09DD}\x{09DF}-\x{09E1}\x{09F0}-'.
      '\x{09F1}\x{0A05}-\x{0A0A}\x{0A0F}-\x{0A10}\x{0A13}-\x{0A28}\x{0A2A}-\x{0A30}\x{0A32}-'.
      '\x{0A33}\x{0A35}-\x{0A36}\x{0A38}-\x{0A39}\x{0A59}-\x{0A5C}\x{0A5E}\x{0A72}-\x{0A74}\x{0A85}-'.
      '\x{0A8B}\x{0A8D}\x{0A8F}-\x{0A91}\x{0A93}-\x{0AA8}\x{0AAA}-\x{0AB0}\x{0AB2}-\x{0AB3}\x{0AB5}-'.
      '\x{0AB9}\x{0ABD}\x{0AE0}\x{0B05}-\x{0B0C}\x{0B0F}-\x{0B10}\x{0B13}-\x{0B28}\x{0B2A}-\x{0B30}'.
      '\x{0B32}-\x{0B33}\x{0B36}-\x{0B39}\x{0B3D}\x{0B5C}-\x{0B5D}\x{0B5F}-\x{0B61}\x{0B85}-'.
      '\x{0B8A}\x{0B8E}-\x{0B90}\x{0B92}-\x{0B95}\x{0B99}-\x{0B9A}\x{0B9C}\x{0B9E}-\x{0B9F}\x{0BA3}-'.
      '\x{0BA4}\x{0BA8}-\x{0BAA}\x{0BAE}-\x{0BB5}\x{0BB7}-\x{0BB9}\x{0C05}-\x{0C0C}\x{0C0E}-'.
      '\x{0C10}\x{0C12}-\x{0C28}\x{0C2A}-\x{0C33}\x{0C35}-\x{0C39}\x{0C60}-\x{0C61}\x{0C85}-'.
      '\x{0C8C}\x{0C8E}-\x{0C90}\x{0C92}-\x{0CA8}\x{0CAA}-\x{0CB3}\x{0CB5}-\x{0CB9}\x{0CDE}\x{0CE0}-'.
      '\x{0CE1}\x{0D05}-\x{0D0C}\x{0D0E}-\x{0D10}\x{0D12}-\x{0D28}\x{0D2A}-\x{0D39}\x{0D60}-'.
      '\x{0D61}\x{0E01}-\x{0E2E}\x{0E30}\x{0E32}-\x{0E33}\x{0E40}-\x{0E45}\x{0E81}-\x{0E82}\x{0E84}'.
      '\x{0E87}-\x{0E88}\x{0E8A}\x{0E8D}\x{0E94}-\x{0E97}\x{0E99}-\x{0E9F}\x{0EA1}-\x{0EA3}\x{0EA5}'.
      '\x{0EA7}\x{0EAA}-\x{0EAB}\x{0EAD}-\x{0EAE}\x{0EB0}\x{0EB2}-\x{0EB3}\x{0EBD}\x{0EC0}-\x{0EC4}'.
      '\x{0F40}-\x{0F47}\x{0F49}-\x{0F69}\x{10A0}-\x{10C5}\x{10D0}-\x{10F6}\x{1100}\x{1102}-'.
      '\x{1103}\x{1105}-\x{1107}\x{1109}\x{110B}-\x{110C}\x{110E}-\x{1112}\x{113C}\x{113E}\x{1140}'.
      '\x{114C}\x{114E}\x{1150}\x{1154}-\x{1155}\x{1159}\x{115F}-\x{1161}\x{1163}\x{1165}\x{1167}'.
      '\x{1169}\x{116D}-\x{116E}\x{1172}-\x{1173}\x{1175}\x{119E}\x{11A8}\x{11AB}\x{11AE}-\x{11AF}'.
      '\x{11B7}-\x{11B8}\x{11BA}\x{11BC}-\x{11C2}\x{11EB}\x{11F0}\x{11F9}\x{1E00}-\x{1E9B}\x{1EA0}-'.
      '\x{1EF9}\x{1F00}-\x{1F15}\x{1F18}-\x{1F1D}\x{1F20}-\x{1F45}\x{1F48}-\x{1F4D}\x{1F50}-'.
      '\x{1F57}\x{1F59}\x{1F5B}\x{1F5D}\x{1F5F}-\x{1F7D}\x{1F80}-\x{1FB4}\x{1FB6}-\x{1FBC}\x{1FBE}'.
      '\x{1FC2}-\x{1FC4}\x{1FC6}-\x{1FCC}\x{1FD0}-\x{1FD3}\x{1FD6}-\x{1FDB}\x{1FE0}-\x{1FEC}'.
      '\x{1FF2}-\x{1FF4}\x{1FF6}-\x{1FFC}\x{2126}\x{212A}-\x{212B}\x{212E}\x{2180}-\x{2182}\x{3041}-'.
      '\x{3094}\x{30A1}-\x{30FA}\x{3105}-\x{312C}\x{AC00}-\x{D7A3}';
  my $Ideographic = '\x{4E00}-\x{9FA5}\x{3007}\x{3021}-\x{3029}';
  my $Letter = "$BaseChar$Ideographic";
  my $Digit =
       '\x{0030}-\x{0039}\x{0660}-\x{0669}\x{06F0}-\x{06F9}\x{0966}-\x{096F}\x{09E6}-\x{09EF}'.
       '\x{0A66}-\x{0A6F}\x{0AE6}-\x{0AEF}\x{0B66}-\x{0B6F}\x{0BE7}-\x{0BEF}\x{0C66}-\x{0C6F}'.
       '\x{0CE6}-\x{0CEF}\x{0D66}-\x{0D6F}\x{0E50}-\x{0E59}\x{0ED0}-\x{0ED9}\x{0F20}-\x{0F29}';
  my $CombiningChar =
      '\x{0300}-\x{0345}\x{0360}-\x{0361}\x{0483}-\x{0486}\x{0591}-\x{05A1}\x{05A3}-\x{05B9}'.
      '\x{05BB}-\x{05BD}\x{05BF}\x{05C1}-\x{05C2}\x{05C4}\x{064B}-\x{0652}\x{0670}\x{06D6}-\x{06DC}'.
      '\x{06DD}-\x{06DF}\x{06E0}-\x{06E4}\x{06E7}-\x{06E8}\x{06EA}-\x{06ED}\x{0901}-\x{0903}'.
      '\x{093C}\x{093E}-\x{094C}\x{094D}\x{0951}-\x{0954}\x{0962}-\x{0963}\x{0981}-\x{0983}\x{09BC}'.
      '\x{09BE}\x{09BF}\x{09C0}-\x{09C4}\x{09C7}-\x{09C8}\x{09CB}-\x{09CD}\x{09D7}\x{09E2}-\x{09E3}'.
      '\x{0A02}\x{0A3C}\x{0A3E}\x{0A3F}\x{0A40}-\x{0A42}\x{0A47}-\x{0A48}\x{0A4B}-\x{0A4D}\x{0A70}-'.
      '\x{0A71}\x{0A81}-\x{0A83}\x{0ABC}\x{0ABE}-\x{0AC5}\x{0AC7}-\x{0AC9}\x{0ACB}-\x{0ACD}\x{0B01}-'.
      '\x{0B03}\x{0B3C}\x{0B3E}-\x{0B43}\x{0B47}-\x{0B48}\x{0B4B}-\x{0B4D}\x{0B56}-\x{0B57}\x{0B82}-'.
      '\x{0B83}\x{0BBE}-\x{0BC2}\x{0BC6}-\x{0BC8}\x{0BCA}-\x{0BCD}\x{0BD7}\x{0C01}-\x{0C03}\x{0C3E}-'.
      '\x{0C44}\x{0C46}-\x{0C48}\x{0C4A}-\x{0C4D}\x{0C55}-\x{0C56}\x{0C82}-\x{0C83}\x{0CBE}-'.
      '\x{0CC4}\x{0CC6}-\x{0CC8}\x{0CCA}-\x{0CCD}\x{0CD5}-\x{0CD6}\x{0D02}-\x{0D03}\x{0D3E}-'.
      '\x{0D43}\x{0D46}-\x{0D48}\x{0D4A}-\x{0D4D}\x{0D57}\x{0E31}\x{0E34}-\x{0E3A}\x{0E47}-\x{0E4E}'.
      '\x{0EB1}\x{0EB4}-\x{0EB9}\x{0EBB}-\x{0EBC}\x{0EC8}-\x{0ECD}\x{0F18}-\x{0F19}\x{0F35}\x{0F37}'.
      '\x{0F39}\x{0F3E}\x{0F3F}\x{0F71}-\x{0F84}\x{0F86}-\x{0F8B}\x{0F90}-\x{0F95}\x{0F97}\x{0F99}-'.
      '\x{0FAD}\x{0FB1}-\x{0FB7}\x{0FB9}\x{20D0}-\x{20DC}\x{20E1}\x{302A}-\x{302F}\x{3099}\x{309A}';

  my $Extender =
      '\x{00B7}\x{02D0}\x{02D1}\x{0387}\x{0640}\x{0E46}\x{0EC6}\x{3005}\x{3031}-\x{3035}\x{309D}-'.
      '\x{309E}\x{30FC}-\x{30FE}';

  our $NameChar   = "[-._:$Letter$Digit$CombiningChar$Extender]";
  our $NCNameChar = "[-._$Letter$Digit$CombiningChar$Extender]";
  our $Name       = "(?:[_:$Letter]$NameChar*)";
  our $NCName     = "(?:[_$Letter]$NCNameChar*)";
  our $NmToken    = "(?:$NameChar+)";

  $format_re{ID} = $format_re{IDREF} = $format_re{NCName} = qr(^$NCName$)o;
  $format_re{PMLREF} = qr(^$NCName(?:\#$NCName)?$)o;
  $format_re{Name} = qr(^$Name$)o;
  $format_re{NMTOKEN} = qr(^$NameChar+$)o;
  $format_re{NMTOKENS} = qr(^$NmToken(?:\x20$NmToken)*$)o;
  $format_re{IDREFS} = qr(^\s*$NCName(?:\s+$NCName)*\s*$)o;

  our $Space = '[\x20]';
  our $TokChar = '(?:[\x21-\x{D7FF}]|[\x{E000}-\x{FFFD}]|[\x{10000}-\x{10FFFF}])'; # [\x10000-\x10FFFF]
  our $NoNorm = '\x09|\x0a|\x0d';

  our $NormChar = "(?:$Space|$TokChar)";
  our $Char = "(?:$NoNorm|$NormChar)";

  $format_re{string} = qr(^$Char*$)o;
  $format_re{normalizedString} = qr(^$NormChar*$)o;
  # Token :no \x9,\xA,\xD, no leading/trailing space,
  # no internal sequence of two or more spaces
  $format_re{token} = qr(^(?:$TokChar(?:$TokChar*(?:$Space$TokChar)?)*)?$)o;

  our $B64          = '[A-Za-z0-9+/]';
  our $B16          = '[AEIMQUYcgkosw048]';
  our $B04          = '[AQgw]';
  our $B04S         = "$B04\x20?";
  our $B16S         = "$B16\x20?";
  our $B64S         = "$B64\x20?";
  our $Base64Binary =  "(?:(?:$B64S$B64S$B64S$B64S)*(?:(?:$B64S$B64S$B64S$B64)|(?:$B64S$B64S$B16S=)|(?:$B64S$B04S=\x20?=)))?";
  $format_re{base64Binary} = qr(^$Base64Binary$)o;

  # URI (RFC 2396, RFC 2732)
  our $digit    = '[0-9]';
  our $upalpha  = '[A-Z]';
  our $lowalpha = '[a-z]';
  our $alpha        = "(?:$lowalpha | $upalpha)";
  our $alphanum     = "(?:$alpha | $digit)";
  our $hex          = "(?:$digit | [A-Fa-f])";
  our $escaped      = "(?:[%] $hex $hex)";
  our $mark         = "[-_.!~*'()]";
  our $unreserved   = "(?:$alphanum | $mark)";
  our $reserved     = '(?:[][;/?:@&=+] | [\$,])';
  our $uric         = "(?:$reserved | $unreserved | $escaped)";
  our $fragment     = "(?:$uric*)";
  our $query        = "(?:$uric*)";
  our $pchar        = "(?:$unreserved | $escaped | [:@&=+\$,])";
  our $param        = "(?:$pchar*)";
  our $segment      = "(?:$pchar* (?: [;] $param )*)";
  our $path_segments= "(?:$segment (?: [/] $segment )*)";
  our $port         = "(?:$digit*)";
  our $IPv4_address = "(?:${digit}{1,3} [.] ${digit}{1,3} [.] ${digit}{1,3} [.] ${digit}{1,3})";
  our $hex4    = "(?:${hex}{1,4})";
  our $hexseq  = "(?:$hex4 (?: : hex4)*)";
  our $hexpart = "(?:$hexseq | $hexseq :: $hexseq ? | ::  $hexseq ?)";
  our $IPv6prefix   = "(?:$hexpart / ${digit}{1,2})";
  our $IPv6_address = "(?:$hexpart (?: : IPv4address )?)";
  our $ipv6reference ="(?:[[](?:$IPv6_address)[]])";
  our $toplabel     = "(?:$alpha | $alpha (?: $alphanum | [-] )* $alphanum)";
  our $domainlabel  = "(?:$alphanum | $alphanum (?: $alphanum | [-] )* $alphanum)";
  our $hostname     = "(?:(?: ${domainlabel} [.] )* $toplabel (?: [.] )?)";
  our $host         = "(?:$hostname | $IPv4_address | $ipv6reference)";
  our $hostport     = "(?:$host (?: [:] $port )?)";
  our $userinfo     = "(?:(?: $unreserved | $escaped | [;:&=+\$,] )*)";
  our $server       = "(?:(?: (?: ${userinfo} [@] )? $hostport )?)";
  our $reg_name     = "(?:(?: $unreserved | $escaped | [\$,] | [;:@&=+] )+)";
  our $authority    = "(?:$server | $reg_name)";
  our $scheme       = "(?:$alpha (?: $alpha | $digit | [-+.] )*)";
  our $rel_segment  = "(?:(?: $unreserved | $escaped | [;@&=+\$,] )+)";
  our $abs_path     = "(?: /  $path_segments)";
  our $rel_path     = "(?:$rel_segment (?: $abs_path )?)";
  our $net_path     = "(?: // $authority (?: $abs_path )?)";
  our $uric_no_slash= "(?:$unreserved | $escaped | [;?:@] | [&=+\$,])";
  our $opaque_part  = "(?:$uric_no_slash $uric*)";
  our $path         = "(?:(?: $abs_path | $opaque_part )?)";
  our $hier_part    = "(?:(?: $net_path | $abs_path ) (?: [?] $query )?)";
  our $relativeURI  = "(?:(?: $net_path | $abs_path | $rel_path ) (?: [?] $query )?)";
  our $absoluteURI  = "(?:${scheme} [:] (?: $hier_part | $opaque_part ))";
  our $URI_reference = "(?:$absoluteURI|$relativeURI)?(?:[#]$fragment)?";

  $format_re{anyURI} = qr(^ $URI_reference $)x;

  $format_re{hexBinary} = qr(^(?:$hex$hex)*$)o;
  $format_re{language} = qr(^(?:[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*)$)o; 

  sub _parse_real {
    my ($value,$exp) = @_;
    return 0 unless
      ($value ne q{} and 
       $value =~ /
            ^
            (?:[+-])?           # sign
            (?:
              (?:INF)           # infinity
            | (?:NaN)           # not a number
            | (?:\d+(?:\.\d+)?) # mantissa
              (?:[eE]           # exponent
                ([+-])?         # sign   ($1)
                (\d+)           # value  ($2)
              )?
            )
            $
        /x);
    # TODO: need to test bounds of mantissa ( < 2^24 )
    $$exp = ($1 || '') . ($2 || '') if ref($exp);
    return 1;
  }

  $format_re{double} = sub {
    my $exp;
    return 0 unless _parse_real(shift,\$exp);
    return 0 if $exp && ($exp < -1075 || $exp > 970);
    return 1;
  };
  $format_re{float} = sub {
    my $exp;
    return 0 unless _parse_real(shift,\$exp);
    return 0 if $exp && ($exp < -149 || $exp > 104);
    return 1;
  };

  $format_re{duration} = sub {
    my $value = shift;
    return 0 
      unless length $value and $value =~ /
            ^
            -?                  # sign
            P                   # date
             (?:\d+Y)?          # years
             (?:\d+M)?          # months
             (?:\d+D)?          # days
            (?:T                # time
             (?:\d+H)?          # hours
             (?:\d+M)?          # minutes
             (?:\d(?:\.\d+)?S)? # seconds
            )?
            $ 
        /x;
  };
  
  my $integer = $format_re{integer} = qr(^\s*[+-]?\d+\s*$);
  $format_re{long} = sub {
    my $val = shift;
    return ($val =~ $integer and
            $val >= -9223372036854775808 and
            $val <=  9223372036854775807) ? 1 : 0;
  };
  $format_re{int} = sub {
    my $val = shift;
    return ($val =~ $integer and
            $val >= -2147483648 and
            $val <=  2147483647) ? 1 : 0;
  };
  $format_re{short} = sub {
    my $val = shift;
    return ($val =~ $integer and
            $val >= -32768 and
            $val <=  32767) ? 1 : 0;
  };
  $format_re{byte} = sub {
    my $val = shift;
    return ($val =~ $integer and
            $val >= -128 and
            $val <=  127) ? 1 : 0;
  };
  my $nonNegativeInteger=$format_re{nonNegativeInteger};
  $format_re{unsignedLong} = sub {
    my $val = shift;
    return ($val =~ $nonNegativeInteger and
            $val <= 18446744073709551615)
  };
  $format_re{unsignedInt} = sub {
    my $val = shift;
    return ($val =~ $nonNegativeInteger and
            $val <= 4294967295)
  };
  $format_re{unsignedShort} = sub {
    my $val = shift;
    return ($val =~ $nonNegativeInteger and
            $val <= 65535)
  };
  $format_re{unsignedByte} = sub {
    my $val = shift;
    return ($val =~ $nonNegativeInteger and
            $val <= 255)
  };

  sub _check_time {
    my $value = shift;
    my $no_hour24 = shift;
    return 
      ((length($value) and 
      $value =~ m(^
         (\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?  # hour:min:sec
         (?:Z|[-+]\d{2}:\d{2})?      # zone
      $)x and
       ((!$no_hour24 and $1 == 24 and $2 == 0 and $3 == 0 and $4 == 0) or
        0 <= $1 and $1 <= 23 and
        0 <= $2 and $2 <= 59 and 
        0 <= $3 and $3 <= 59)
      ) ? 1 : 0);
  }
  sub _check_date {
    my $value = shift;
    return 
      (length($value) and 
       $value =~ /
         ^
           [-+]?                 # sign
           (?:[1-9]\d{4,}|\d{4}) # year
           -(\d{2})              # month ($1)
           -(\d{2})              # day ($2)
         $
       /x
      and $1>=1 and $1<=12
      and $2>= 1 and $2<=31
      ) ? 1 : 0;
  }

  $format_re{time} = \&_check_time;
  $format_re{date} = \&_check_date;
  $format_re{dateTime} = sub {
    my $value = shift;
    return 0 unless length $value;
    return 0 unless $value =~ /^(.*)T(.*)$/;
    my ($date,$time)=($1,$2);
    return _check_date($date) && _check_time($time,1) ? 1 : 0;
  };
  $format_re{gYearMonth} = sub {
    my $value = shift;
    return 
      (length($value) and 
       $value =~ /
         ^
           [-+]?                  # sign
           (?:[1-9]\d{4,}|\d{4})  # year
           -(\d{2})               # month ($1)
         $
       /x
      and $1>=1 and $1<=12
      ) ? 1 : 0;
  };
  $format_re{gYear} = sub {
    my $value = shift;
    return 
      (length($value) and 
       $value =~ /
         ^
           [-+]?                  # sign
           (?:[1-9]\d{4,}|\d{4})  # year
         $
       /x) ? 1 : 0;
  };
  $format_re{gMonthDay} = sub {
    my $value = shift;
    return 
      (length($value) and 
       $value =~ /^--(\d{2})-(\d{2})$/ # --MM-DD
       and $1>=1 and $1<=12
       and $2>= 1 and $2<=31
      ) ? 1 : 0;
  };
  $format_re{gDay} = sub {
    my $value = shift;
    return 
      (length($value) and 
       $value =~ /^---(\d{2})$/ # ---DD
       and $1>= 1 and $1<=31
      ) ? 1 : 0;
  };
  $format_re{gMonth} = sub {
    my $value = shift;
    return 
      (length($value) and 
       $value =~ /^--(\d{2})$/ # --MM
       and $1>=1 and $1<=12
      ) ? 1 : 0;
  };
  sub _get_format_checker { return $format_re{ $_[1] || $_[0]->{format} } }
  sub supported_formats {
    return sort keys %format_re;
  }
}


sub check_string_format {
  my ($self, $string, $format) = @_;
  $format ||= $self->get_format;
  return 1 if $format eq 'any';
  my $re = $self->_get_format_checker($format);
  if (defined $re) {
    if ((ref($re) eq 'CODE' and !$re->($string))
         or (ref($re) ne 'CODE' and $string !~ $re)) {
      return 0
    }
  } else {
    # warn "format $format not supported ??";
  }
  return 1;
}

sub validate_object {
  my ($self, $object, $opts) = @_;
  my $err = undef;
  my $format = $self->get_format;
  if (ref($object)) {
    $err = "expected CDATA, got: ".ref($object);
  } elsif (!$self->check_string_format($object,$format)) {
    $err = "CDATA value not formatted as $format: '$object'";
  }
  if ($err and ref($opts) and ref($opts->{log})) {
    my $path = $opts->{path};
    my $tag = $opts->{tag};
    $path.="/".$tag if $tag ne q{};
    push @{$opts->{log}}, "$path: ".$err;
  }
  return $err ? 0 : 1;
}


1;
__END__

=head1 SEE ALSO

L<Treex::PML::Schema::Decl>, L<Treex::PML::Schema>. L<Treex::PML::Schema::Choice>, L<Treex::PML::Schema::Constant>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

