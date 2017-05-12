use strict;
use warnings;
use Test::More;
use Encode;
use utf8;

plan tests => 23;

# ------------------------------------------------------------------------
    use Unicode::Emoji::E4U;
    my $e4u = Unicode::Emoji::E4U->new;
    my $google = $e4u->google;

    my $e;
    $e = $google->list->[0];
	my $e0 = $e;
    $e = $google->find(google => 'FE000');
    #print "id: ",            $e->id, "\n";
    #print "name: ",          $e->name, "\n";
    #print "desc: ",          $e->desc, "\n";
    #print "text_fallback: ", $e->text_fallback, "\n";
    #print "in_proposal: ",   $e->in_proposal, "\n";

    my $de = $e->docomo_emoji;      # Unicode::Emoji::DoCoMo::Emoji
    my $ke = $e->kddi_emoji;        # Unicode::Emoji::KDDI::Emoji
    my $se = $e->softbank_emoji;    # Unicode::Emoji::SoftBank::Emoji
    my $ge = $e->google_emoji;      # Unicode::Emoji::Google::Emoji
    my $ue = $e->unicode_emoji;     # Unicode::Emoji::Unicode::Emoji

    #print "is_alt: ",         $ge->is_alt, "\n";
    #print "unicode_string: ", $ge->unicode_string, "\n";
    #print "unicode_octets: ", $ge->unicode_octets, "\n";
# ------------------------------------------------------------------------

ok( ref $e4u,       'Unicode::Emoji::E4U' );
ok( ref $google,    'Unicode::Emoji::Google' );

ok( scalar(@{$google->list}), 'scalar list' );
ok( ref $e0, 'list' );
ok( ref $e,  'find' );

is( $e->id,            '000', 'id' );
is( $e->name,          'BLACK SUN WITH RAYS', 'name' );
my $e1 = $google->find(google => 'FE006');
is( $e1->text_fallback, '[霧]', 'text_fallback' );
like( $e->desc,        qr/clear weather/i, 'desc' );
ok( ! $e->in_proposal, 'not in_proposal' );

ok( ref $de, 'docomo_emoji' );
ok( ref $ke, 'kddi_emoji' );
ok( ref $se, 'softbank_emoji' );
ok( ref $ge, 'google_emoji' );
ok( ref $ue, 'unicode_emoji' );

ok( ! $ge->is_alt,     'not is_alt' );
is( $ge->unicode_string, "\x{FE000}", 'unicode_string' );
is( $ge->unicode_octets, encode_utf8("\x{FE000}"), 'unicode_octets' );

is( $de->unicode_string, "\x{E63E}",  'docomo_emoji unicode_string' );
is( $ke->unicode_string, "\x{E488}",  'kddi_emoji unicode_string' );
is( $se->unicode_string, "\x{E04A}",  'softbank_emoji unicode_string' );
is( $ge->unicode_string, "\x{FE000}", 'google_emoji unicode_string' );
is( $ue->unicode_string, "\x{2600}",  'unicode_emoji unicode_string' );

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｂｙ　ＵＴＦ－８
