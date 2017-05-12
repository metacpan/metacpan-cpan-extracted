use strict;
use warnings;
use Test::More;
use Encode;
use utf8;

plan tests => 14;

# ------------------------------------------------------------------------
    use Unicode::Emoji::E4U;
    my $e4u = Unicode::Emoji::E4U->new;
    my $softbank = $e4u->softbank;

    my $e;
    $e = $softbank->list->[0];
	my $e0 = $e;
    $e = $softbank->find(unicode => 'E04A');
    #print "name_ja: ", $e->name_ja, "\n";
    #print "number: ",  $e->number, "\n";
    #print "unicode: ", $e->unicode, "\n";

    my $se = $e->softbank_emoji;
    #print "is_alt: ",         $se->is_alt, "\n";
    #print "unicode_string: ", $se->unicode_string, "\n";
    #print "unicode_octets: ", $se->unicode_octets, "\n";
    #print "cp932_string: ",   $se->cp932_string, "\n";
    #print "cp932_octets: ",   $se->cp932_octets, "\n";
# ------------------------------------------------------------------------

ok( ref $e4u,      'Unicode::Emoji::E4U' );
ok( ref $softbank, 'Unicode::Emoji::DoCoMo' );

ok( scalar(@{$softbank->list}), 'scalar list' );
ok( ref $e0, 'list' );
ok( ref $e,  'find' );
is( $e->name_ja, '晴れ', 'name_ja' );
is( $e->number,  '81',   'number' );
is( $e->unicode, 'E04A', 'unicode' );

ok( ref $se, 'softbank_emoji' );
ok( ! $se->is_alt, 'is_alt' );
is( $se->unicode_string, "\x{E04A}", 'unicode_string' );
is( $se->unicode_octets, encode_utf8("\x{E04A}"), 'unicode_octets' );
is( encode(CP932=>$se->cp932_string), "\xF9\x8B", 'cp932_string' );
is( $se->cp932_octets, "\xF9\x8B", 'cp932_octets' );

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｂｙ　ＵＴＦ－８
