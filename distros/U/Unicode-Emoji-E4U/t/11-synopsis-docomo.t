use strict;
use warnings;
use Test::More;
use Encode;
use utf8;

plan tests => 15;

# ------------------------------------------------------------------------
    use Unicode::Emoji::E4U;
    my $e4u = Unicode::Emoji::E4U->new;
    my $docomo = $e4u->docomo;

    my $e;
    $e = $docomo->list->[0];
	my $e0 = $e;
    $e = $docomo->find(unicode => 'E63E');
    #print "jis: ",     $e->jis, "\n";
    #print "name_en: ", $e->name_en, "\n";
    #print "name_ja: ", $e->name_ja, "\n";
    #print "unicode: ", $e->unicode, "\n";

    my $de = $e->docomo_emoji;
    #print "is_alt: ",         $de->is_alt, "\n";
    #print "unicode_string: ", $de->unicode_string, "\n";
    #print "unicode_octets: ", $de->unicode_octets, "\n";
    #print "cp932_string: ",   $de->cp932_string, "\n";
    #print "cp932_octets: ",   $de->cp932_octets, "\n";
# ------------------------------------------------------------------------

ok( ref $e4u,       'Unicode::Emoji::E4U' );
ok( ref $docomo,    'Unicode::Emoji::DoCoMo' );

ok( scalar(@{$docomo->list}), 'scalar list' );
ok( ref $e0, 'list' );
ok( ref $e,  'find' );
is( $e->jis,     '7541', 'jis' );
is( $e->name_en, 'Fine', 'name_en' );
is( $e->name_ja, '晴れ', 'name_ja' );
is( $e->unicode, 'E63E', 'unicode' );

ok( ref $de, 'docomo_emoji' );
ok( ! $de->is_alt, 'is_alt' );
is( $de->unicode_string, "\x{E63E}", 'unicode_string' );
is( $de->unicode_octets, encode_utf8("\x{E63E}"), 'unicode_octets' );
is( encode(CP932=>$de->cp932_string), "\xF8\x9F", 'cp932_string' );
is( $de->cp932_octets, "\xF8\x9F", 'cp932_octets' );

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｂｙ　ＵＴＦ－８
