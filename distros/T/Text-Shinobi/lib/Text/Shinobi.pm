package Text::Shinobi;
use 5.010001;
use utf8;
use strict;
use warnings;
our $VERSION = "0.01";

use Exporter 'import';
use Unicode::Normalize qw/NFD NFC/;
use Lingua::JA::Regular::Unicode;

our @EXPORT_OK = qw/shinobi/;

use constant {
    DUO     => 1 <<  0,
    MONO    => 1 <<  1,
    JIS     => 1 <<  2, # JIS X 0208 + JIS X 0212 OR JIS X 0213
    UTF8MB3 => 1 <<  3, # as utf-8 encoding
    Y2016   => 1 << 10, # almost viewable in 2016 (Mac10.11, Win10, iOS9, Andoid5
};

our $ENCODE = Y2016; # this version's default mask

our $map = [
    { char => 'い', code => "\x{682C}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    #          ろ
    #          は
    { char => 'に', code => "\x{92AB}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'ほ', code => "\x{23D0A}",        flag => MONO },
    { char => 'へ', code => "\x{2021C}",        flag => MONO },
    { char => 'と', code => "\x{28246}",        flag => MONO },
    { char => 'ち', code => "\x{68C8}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    #          り
    { char => 'ぬ', code => "\x{57E5}",         flag => MONO | UTF8MB3 |       Y2016 },
    { char => 'る', code => "\x{9306}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'を', code => "\x{6E05}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'わ', code => "\x{5029}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    #          か
    { char => 'よ', code => "\x{6A2A}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'た', code => "\x{71BF}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'れ', code => "\x{58B4}",         flag => MONO | UTF8MB3 |       Y2016 },
    { char => 'そ', code => "\x{9404}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'つ', code => "\x{6F62}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'ね', code => "\x{50D9}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'な', code => "\x{28287}",        flag => MONO },
    #          ら
    { char => 'む', code => "\x{7103}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'う', code => "\x{212FD}",        flag => MONO |           JIS | Y2016 },
    { char => 'ゐ', code => "\x{4932}",         flag => MONO | UTF8MB3 |       Y2016 },
    { char => 'の', code => "\x{6D7E}",         flag => MONO | UTF8MB3 |       Y2016 },
    #          お
    #          く
    { char => 'や', code => "\x{67CF}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'ま', code => "\x{241E2}",        flag => MONO |                 Y2016 },
    { char => 'け', code => "\x{2129A}",        flag => MONO },
    { char => 'ふ', code => "\x{9251}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'こ', code => "\x{6CCA}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    { char => 'え', code => "\x{4F2F}",         flag => MONO | UTF8MB3 | JIS | Y2016 },
    #          て
    { char => 'あ', code => "\x{23638}",        flag => MONO |           JIS | Y2016 },
    { char => 'さ', code => "\x{3DF5}",         flag => MONO | UTF8MB3 |       Y2016 },
    #          き
    { char => 'ゆ', code => "\x{28B46}",        flag => MONO |                 Y2016 },
    { char => 'め', code => "\x{6F76}",         flag => MONO | UTF8MB3 |       Y2016 },
    { char => 'み', code => "\x{20381}",        flag => MONO |           JIS | Y2016 },
    { char => 'し', code => "\x{28282}",        flag => MONO |           JIS | Y2016 },
    { char => 'ゑ', code => "\x{6A74}",         flag => MONO | UTF8MB3 |       Y2016 },
    #          ひ
    #          も
    #          せ
    #          す
    #          ん
    
    { char => 'い', code => "\x{2F4A}\x{2F8A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ろ', code => "\x{2F55}\x{2F8A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'は', code => "\x{2F1F}\x{2F8A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'に', code => "\x{2FA6}\x{2F8A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ほ', code => "\x{6C35}\x{2F8A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'へ', code => "\x{4EBB}\x{2F8A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'と', code => "\x{2F9D}\x{2F8A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ち', code => "\x{2F4A}\x{2ED8}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'り', code => "\x{2F55}\x{2ED8}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ぬ', code => "\x{2F1F}\x{2ED8}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'る', code => "\x{2FA6}\x{2ED8}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'を', code => "\x{6C35}\x{2ED8}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'わ', code => "\x{4EBB}\x{2ED8}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'か', code => "\x{2F9D}\x{2ED8}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'よ', code => "\x{2F4A}\x{2EE9}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'た', code => "\x{2F55}\x{2EE9}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'れ', code => "\x{2F1F}\x{2EE9}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'そ', code => "\x{2FA6}\x{2EE9}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'つ', code => "\x{6C35}\x{2EE9}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ね', code => "\x{4EBB}\x{2EE9}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'な', code => "\x{2F9D}\x{2EE9}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ら', code => "\x{2F4A}\x{2F9A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'む', code => "\x{2F55}\x{2F9A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'う', code => "\x{2F1F}\x{2F9A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ゐ', code => "\x{2FA6}\x{2F9A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'の', code => "\x{6C35}\x{2F9A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'お', code => "\x{4EBB}\x{2F9A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'く', code => "\x{2F9D}\x{2F9A}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'や', code => "\x{2F4A}\x{2F69}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ま', code => "\x{2F55}\x{2F69}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'け', code => "\x{2F1F}\x{2F69}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ふ', code => "\x{2FA6}\x{2F69}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'こ', code => "\x{6C35}\x{2F69}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'え', code => "\x{4EBB}\x{2F69}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'て', code => "\x{2F9D}\x{2F69}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'あ', code => "\x{2F4A}\x{9ED2}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'さ', code => "\x{2F55}\x{9ED2}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'き', code => "\x{2F1F}\x{9ED2}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ゆ', code => "\x{2FA6}\x{9ED2}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'め', code => "\x{6C35}\x{9ED2}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'み', code => "\x{4EBB}\x{9ED2}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'し', code => "\x{2F9D}\x{9ED2}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ゑ', code => "\x{2F4A}\x{7D2B}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ひ', code => "\x{2F55}\x{7D2B}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'も', code => "\x{2F1F}\x{7D2B}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'せ', code => "\x{2FA6}\x{7D2B}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'す', code => "\x{6C35}\x{7D2B}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
    { char => 'ん', code => "\x{4EBB}\x{7D2B}", flag => DUO |  UTF8MB3 | JIS | Y2016 },
];

my $encode = {};
my $decode = {};
my $decode_re = join '|', map { $_->{code} } reverse @$map;
   $decode_re = qr/($decode_re)/;

for my $v (@$map) {
    my $list = $encode->{ $v->{char} } ||= [];
    push @$list, $v;
    
    $decode->{$v->{code}} = $v->{char};
}

sub _encode {
    my $char = shift;
    my $list = $encode->{$char} // [];
    for my $v (@$list) {
        if ($v->{flag} & $ENCODE) {
            $char = $v->{code};
            last;
        }
    }

    $char;
}

sub normalize {
    my $text = shift // "";
    
    # decomposition for 濁点s
    $text =~ s/(\p{InHiragana}|\p{InKatakana})/NFD($1)/ge;
    
    # katakana to hiragana
    $text = katakana2hiragana(katakana_h2z($text));
    
    # upper ぁぃぅぇぉっゃゅょゎゕゖㇾㇷㇶㇸㇲㇹㇱㇼㇳㇰㇿㇻㇺㇵㇽㇴ
    $text =~ tr[\x{3041}\x{3043}\x{3045}\x{3047}\x{3049}\x{3063}\x{3083}\x{3085}\x{3087}\x{308E}\x{3095}\x{3096}\x{31FE}\x{31F7}\x{31F6}\x{31F8}\x{31F2}\x{31F9}\x{31F1}\x{31FC}\x{31F3}\x{31F0}\x{31FF}\x{31FB}\x{31FA}\x{31F5}\x{31FD}\x{31F4}]
               [\x{3042}\x{3044}\x{3046}\x{3048}\x{304A}\x{3064}\x{3084}\x{3086}\x{3088}\x{308F}\x{304B}\x{3051}\x{30EC}\x{30D5}\x{30D2}\x{30D8}\x{30B9}\x{30DB}\x{30B7}\x{30EA}\x{30C8}\x{30AF}\x{30ED}\x{30E9}\x{30E0}\x{30CF}\x{30EB}\x{30CC}];
    
    $text;
}

sub encode {
    my $class = shift;
    my $text = shift // "";
    
    $text = normalize($text);
    $text =~ s{(.)}{_encode($1)}ge;
    $text;
}

sub decode {
    my $class = shift;
    my $text = shift // "";
    
    $text =~ s/$decode_re/$decode->{$1}/ge;
    $text =~ s/(\p{InHiragana}+)/NFC($1)/ge;
    $text;
}

sub shinobi {
    Text::Shinobi->encode(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Shinobi - 忍びいろは (Ninja Alphabet) encoding

=head1 SYNOPSIS

    use Text::Shinobi qw/shinobi/;

    print shinobi('しのび'); # => 𨊂浾⽕紫゙

=head1 DESCRIPTION

"Shinobi Iroha" is a method to encrypt message that Ninja used.
This substitution cipher maps Japanese Kana characters to Kanji.

Text::Shinobi encoding table is based on 萬川集海 the Ninja technique encyclopedia; compiled in 1676.
The exact character table has not been revealed in the book (as strictly confidential).
This module adopted table "generally known" in current Ninjalogy.

=begin html

<img src="https://shinobi.life/shinobi-iroha.jpg">

=end html

=head1 METHODS

=head2 encode()

    Text::Shinobi->encode('あいう！'); # 𣘸栬𡋽！

Returns encrypted input text (unicode string).
Only Hiragana and Katakana are converts, other characters are left.

=head3 $Text::Shinobi::ENCODE

By default, C<encode()> select a Kanji character following rules:

=over

=item 1.

use single character if same shape unicode exists.

=item 2.

viewable in major browser version. (device fonts supported)

=back

So this module's default might change in the future.

You can change encode option by C<$Text::Shinobi::ENCODE> class variable with below constants.

    # DUO: double character only
    local $Text::Shinobi::ENCODE = Text::Shinobi::DUO;
    Text::Shinobi->encode('あいう'); # => ⽊黒⽊⾊⼟⾚

    # UTF8MB3: exclude 4 bytes code as utf-8
    local $Text::Shinobi::ENCODE = Text::Shinobi::UTF8MB3;
    Text::Shinobi->encode('あいう'); # => ⽊黒栬⼟⾚

=head2 decode()

    Text::Shinobi->decode('𣘸栬𡋽？'); # あいう？

Returns text to try decode input text (unicode string).

=head1 EXPORTS

No exports by default.

=head2 shinobi()

    use Text::Shinobi qw/shinobi/;

    shinobi('...');

Shortcut to C<< Text::Shinobi->encode(...) >>.

=head1 ADVANCED USAGE

Romaji to shinobi iroha: use L<Lingua::JA::Kana>;

    use Lingua::JA::Kana;

    shinobi(romaji2hiragana('ninja!'));

=head1 REFERENCES

=over

=item *

中島篤巳 (2015) 完本 万川集海
<https://www.amazon.co.jp/dp/4336057672/>

=item *

うみほたる Nishiki-teki+01 Shinobi Iroha 
L<http://d.hatena.ne.jp/Umihotaru/20111216/1324033352>

=back

=head1 AUTHOR

Naoki Tomita aka "Tomimaru" E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Naoki Tomita.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=for stopwords unicode shinobi iroha Nishiki-teki+01

=cut
