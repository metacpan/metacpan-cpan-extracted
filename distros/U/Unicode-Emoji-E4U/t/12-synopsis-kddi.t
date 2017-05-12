use strict;
use warnings;
use Test::More;
use Encode;
use utf8;

plan tests => 20;

# ------------------------------------------------------------------------
    use Unicode::Emoji::E4U;
    my $e4u = Unicode::Emoji::E4U->new;
    my $kddi = $e4u->kddi;

    my $e;
    $e = $kddi->list->[0];
    my $e0 = $e;
    $e = $kddi->find(unicode => 'E488');
    #print "name_ja: ", $e->name_ja, "\n";
    #print "number: ",  $e->number, "\n";
    #print "unicode: ", $e->unicode, "\n";

    my $ke = $e->kddi_emoji;
    #print "is_alt: ",         $ke->is_alt, "\n";
    #print "unicode_string: ", $ke->unicode_string, "\n";
    #print "unicode_octets: ", $ke->unicode_octets, "\n";
    #print "cp932_string: ",   $ke->cp932_string, "\n";
    #print "cp932_octets: ",   $ke->cp932_octets, "\n";

    my $kwe = $e->kddiweb_emoji;
    #print "is_alt: ",         $kwe->is_alt, "\n";
    #print "unicode_string: ", $kwe->unicode_string, "\n";
    #print "unicode_octets: ", $kwe->unicode_octets, "\n";
    #print "cp932_string: ",   $kwe->cp932_string, "\n";
    #print "cp932_octets: ",   $kwe->cp932_octets, "\n";
# ------------------------------------------------------------------------

ok( ref $e4u,     'Unicode::Emoji::E4U' );
ok( ref $kddi,    'Unicode::Emoji::DoCoMo' );

ok( scalar(@{$kddi->list}), 'scalar list' );
ok( ref $e0, 'list' );
ok( ref $e,  'find' );
is( $e->name_ja, '太陽', 'name_ja' );
is( $e->number,  '44',   'number' );
is( $e->unicode, 'E488', 'unicode' );

ok( ref $ke, 'kddi_emoji' );
ok( ! $ke->is_alt, 'is_alt' );
is( $ke->unicode_string, "\x{E488}", 'unicode_string' );
is( $ke->unicode_octets, encode_utf8("\x{E488}"), 'unicode_octets' );
is( encode(CP932=>$ke->cp932_string), "\xF6\x60", 'cp932_string' );
is( $ke->cp932_octets, "\xF6\x60", 'cp932_octets' );

ok( ref $kwe, 'kddiweb_emoji' );
ok( ! $kwe->is_alt, 'is_alt' );
is( $kwe->unicode_string, "\x{EF60}", 'unicode_string' );
is( $kwe->unicode_octets, encode_utf8("\x{EF60}"), 'unicode_octets' );
is( encode(CP932=>$kwe->cp932_string), "\xF6\x60", 'cp932_string' );
is( $kwe->cp932_octets, "\xF6\x60", 'cp932_octets' );

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｂｙ　ＵＴＦ－８
