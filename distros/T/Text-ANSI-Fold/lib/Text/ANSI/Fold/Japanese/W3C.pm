package Text::ANSI::Fold::Japanese::W3C;

use v5.14;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(%prohibition);

# https://www.w3.org/TR/jlreq/
# Requirements for Japanese Text Layout
# 日本語組版処理の要件
# W3C Working Group Note 11 August 2020

my %character_class = (

# A.1 Opening brackets
cl_01 => <<'END',
Character	UCS	Name	Common name	Remarks
‘	2018	LEFT SINGLE QUOTATION MARK	左シングル引用符，左シングルクォーテーションマーク	used in horizontal composition
“	201C	LEFT DOUBLE QUOTATION MARK	左ダブル引用符，左ダブルクォーテーションマーク	used in horizontal composition
(	0028	LEFT PARENTHESIS	始め小括弧，始め丸括弧
（	FF08	FULLWIDTH LEFT PARENTHESIS	始め小括弧，始め丸括弧
〔	3014	LEFT TORTOISE SHELL BRACKET	始めきっこう（亀甲）括弧
[	005B	LEFT SQUARE BRACKET	始め大括弧，始め角括弧
［	FF3B	FULLWIDTH LEFT SQUARE BRACKET	始め大括弧，始め角括弧
{	007B	LEFT CURLY BRACKET	始め中括弧，始め波括弧
｛	FF5B	FULLWIDTH LEFT CURLY BRACKET	始め中括弧，始め波括弧
〈	3008	LEFT ANGLE BRACKET	始め山括弧
《	300A	LEFT DOUBLE ANGLE BRACKET	始め二重山括弧
「	300C	LEFT CORNER BRACKET	始めかぎ括弧
『	300E	LEFT WHITE CORNER BRACKET	始め二重かぎ括弧
【	3010	LEFT BLACK LENTICULAR BRACKET	始めすみ付き括弧
⦅	2985	LEFT WHITE PARENTHESIS	始め二重パーレン，始め二重括弧
｟	FF5F	FULLWIDTH LEFT WHITE PARENTHESIS	始め二重パーレン，始め二重括弧
〘	3018	LEFT WHITE TORTOISE SHELL BRACKET	始め二重きっこう（亀甲）括弧
〖	3016	LEFT WHITE LENTICULAR BRACKET	始めすみ付き括弧（白）
«	00AB	LEFT-POINTING DOUBLE ANGLE QUOTATION MARK	始め二重山括弧引用記号，始めギュメ
〝	301D	REVERSED DOUBLE PRIME QUOTATION MARK	始めダブルミニュート	used in vertical composition
END

# A.2 Closing brackets
cl_02 => <<'END',
Character	UCS	Name	Common name	Remarks
’	2019	RIGHT SINGLE QUOTATION MARK	右シングル引用符，右シングルクォーテーションマーク	used in horizontal composition
”	201D	RIGHT DOUBLE QUOTATION MARK	右ダブル引用符，右ダブルクォーテーションマーク	used in horizontal composition
)	0029	RIGHT PARENTHESIS	終わり小括弧，終わり丸括弧
）	FF09	FULLWIDTH RIGHT PARENTHESIS	終わり小括弧，終わり丸括弧
〕	3015	RIGHT TORTOISE SHELL BRACKET	終わりきっこう（亀甲）括弧
]	005D	RIGHT SQUARE BRACKET	終わり大括弧，終わり角括弧
］	FF3D	FULLWIDTH RIGHT SQUARE BRACKET	終わり大括弧，終わり角括弧
}	007D	RIGHT CURLY BRACKET	終わり中括弧，終わり波括弧
｝	FF5D	FULLWIDTH RIGHT CURLY BRACKET	終わり中括弧，終わり波括弧
〉	3009	RIGHT ANGLE BRACKET	終わり山括弧
》	300B	RIGHT DOUBLE ANGLE BRACKET	終わり二重山括弧
」	300D	RIGHT CORNER BRACKET	終わりかぎ括弧
』	300F	RIGHT WHITE CORNER BRACKET	終わり二重かぎ括弧
】	3011	RIGHT BLACK LENTICULAR BRACKET	終わりすみ付き括弧
⦆	2986	RIGHT WHITE PARENTHESIS	終わり二重パーレン，終わり二重括弧
｠	FF60	FULLWIDTH RIGHT WHITE PARENTHESIS	終わり二重パーレン，終わり二重括弧
〙	3019	RIGHT WHITE TORTOISE SHELL BRACKET	終わり二重きっこう（亀甲）括弧
〗	3017	RIGHT WHITE LENTICULAR BRACKET	終わりすみ付き括弧（白）
»	00BB	RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK	終わり二重山括弧引用記号，終わりギュメ
〟	301F	LOW DOUBLE PRIME QUOTATION MARK	終わりダブルミニュート	used in vertical composition
END

# A.3 Hyphens
cl_03 => <<'END',
Character	UCS	Name	Common name	Remarks
‐	2010	HYPHEN	ハイフン（四分）	quarter em width
〜	301C	WAVE DASH	波ダッシュ
゠	30A0	KATAKANA-HIRAGANA DOUBLE HYPHEN	二重ハイフン，二分二重ダッシュ	half-width
–	2013	EN DASH	二分ダーシ，ダッシュ（二分）	half-width
END
    
# A.4 Dividing punctuation marks
cl_04 => <<'END',
Character	UCS	Name	Common name	Remarks
!	0021	EXCLAMATION MARK	感嘆符
！	FF01	FULLWIDTH EXCLAMATION MARK	感嘆符
?	003F	QUESTION MARK	疑問符
？	FF1F	FULLWIDTH QUESTION MARK	疑問符
‼	203C	DOUBLE EXCLAMATION MARK	感嘆符二つ
⁇	2047	DOUBLE QUESTION MARK	疑問符二つ
⁈	2048	QUESTION EXCLAMATION MARK	疑問符感嘆符
⁉	2049	EXCLAMATION QUESTION MARK	感嘆符疑問符
END
    
# A.5 Middle dots
cl_05 => <<'END',
Character	UCS	Name	Common name	Remarks
・	30FB	KATAKANA MIDDLE DOT	中点
:	003A	COLON	コロン
：	FF1A	FULLWIDTH COLON	コロン
;	003B	SEMICOLON	セミコロン	used in horizontal composition
；	FF1B	FULLWIDTH SEMICOLON	セミコロン	used in horizontal composition
END
    
# A.6 Full stops
cl_06 => <<'END',
Character	UCS	Name	Common name	Remarks
。	3002	IDEOGRAPHIC FULL STOP	句点
.	002E	FULL STOP	ピリオド	used in horizontal composition
．	FF0E	FULLWIDTH FULL STOP	ピリオド	used in horizontal composition
END
    
# A.7 Commas
cl_07 => <<'END',
Character	UCS	Name	Common name	Remarks
、	3001	IDEOGRAPHIC COMMA	読点
,	002C	COMMA	コンマ	used in horizontal composition
，	FF0C	FULLWIDTH COMMA	コンマ	used in horizontal composition
END
    
# A.8 Inseparable characters
cl_08 => <<'END',
Character	UCS	Name	Common name	Remarks
—	2014	EM DASH	ダッシュ（全角）	Some systems implement U+2015 HORIZONTAL BAR very similar behavior to U+2014 EM DASH
…	2026	HORIZONTAL ELLIPSIS	三点リーダ
‥	2025	TWO DOT LEADER	二点リーダ
〳	3033	VERTICAL KANA REPEAT MARK UPPER HALF	くの字点上	used in vertical composition U+3035 follows this
〴	3034	VERTICAL KANA REPEAT WITH VOICED SOUND MARK UPPER HALF	くの字点上（濁点）	used in vertical composition U+3035 follows this
〵	3035	VERTICAL KANA REPEAT MARK LOWER HALF	くの字点下	used in vertical composition
END

# A.9 Iteration marks
cl_09 => <<'END',
Character	UCS	Name	Common name	Remarks
ヽ	30FD	KATAKANA ITERATION MARK	片仮名繰返し記号
ヾ	30FE	KATAKANA VOICED ITERATION MARK	片仮名繰返し記号（濁点）
ゝ	309D	HIRAGANA ITERATION MARK	平仮名繰返し記号
ゞ	309E	HIRAGANA VOICED ITERATION MARK	平仮名繰返し記号（濁点）
々	3005	IDEOGRAPHIC ITERATION MARK	繰返し記号
〻	303B	VERTICAL IDEOGRAPHIC ITERATION MARK	二の字点，ゆすり点
END

# A.10 Prolonged sound mark
cl_10 => <<'END',
Character	UCS	Name	Common name	Remarks
ー	30FC	KATAKANA-HIRAGANA PROLONGED SOUND MARK	長音記号
END

# A.11 Small kana
cl_11 => <<'END',
Character	UCS	Name	Common name	Remarks
ぁ	3041	HIRAGANA LETTER SMALL A	小書き平仮名あ
ぃ	3043	HIRAGANA LETTER SMALL I	小書き平仮名い
ぅ	3045	HIRAGANA LETTER SMALL U	小書き平仮名う
ぇ	3047	HIRAGANA LETTER SMALL E	小書き平仮名え
ぉ	3049	HIRAGANA LETTER SMALL O	小書き平仮名お
ァ	30A1	KATAKANA LETTER SMALL A	小書き片仮名ア
ィ	30A3	KATAKANA LETTER SMALL I	小書き片仮名イ
ゥ	30A5	KATAKANA LETTER SMALL U	小書き片仮名ウ
ェ	30A7	KATAKANA LETTER SMALL E	小書き片仮名エ
ォ	30A9	KATAKANA LETTER SMALL O	小書き片仮名オ
っ	3063	HIRAGANA LETTER SMALL TU	小書き平仮名つ
ゃ	3083	HIRAGANA LETTER SMALL YA	小書き平仮名や
ゅ	3085	HIRAGANA LETTER SMALL YU	小書き平仮名ゆ
ょ	3087	HIRAGANA LETTER SMALL YO	小書き平仮名よ
ゎ	308E	HIRAGANA LETTER SMALL WA	小書き平仮名わ
ゕ	3095	HIRAGANA LETTER SMALL KA	小書き平仮名か
ゖ	3096	HIRAGANA LETTER SMALL KE	小書き平仮名け
ッ	30C3	KATAKANA LETTER SMALL TU	小書き片仮名ツ
ャ	30E3	KATAKANA LETTER SMALL YA	小書き片仮名ヤ
ュ	30E5	KATAKANA LETTER SMALL YU	小書き片仮名ユ
ョ	30E7	KATAKANA LETTER SMALL YO	小書き片仮名ヨ
ヮ	30EE	KATAKANA LETTER SMALL WA	小書き片仮名ワ
ヵ	30F5	KATAKANA LETTER SMALL KA	小書き片仮名カ
ヶ	30F6	KATAKANA LETTER SMALL KE	小書き片仮名ケ
ㇰ	31F0	KATAKANA LETTER SMALL KU	小書き片仮名ク
ㇱ	31F1	KATAKANA LETTER SMALL SI	小書き片仮名シ
ㇲ	31F2	KATAKANA LETTER SMALL SU	小書き片仮名ス
ㇳ	31F3	KATAKANA LETTER SMALL TO	小書き片仮名ト
ㇴ	31F4	KATAKANA LETTER SMALL NU	小書き片仮名ヌ
ㇵ	31F5	KATAKANA LETTER SMALL HA	小書き片仮名ハ
ㇶ	31F6	KATAKANA LETTER SMALL HI	小書き片仮名ヒ
ㇷ	31F7	KATAKANA LETTER SMALL HU	小書き片仮名フ
ㇸ	31F8	KATAKANA LETTER SMALL HE	小書き片仮名ヘ
ㇹ	31F9	KATAKANA LETTER SMALL HO	小書き片仮名ホ
ㇺ	31FA	KATAKANA LETTER SMALL MU	小書き片仮名ム
ㇻ	31FB	KATAKANA LETTER SMALL RA	小書き片仮名ラ
ㇼ	31FC	KATAKANA LETTER SMALL RI	小書き片仮名リ
ㇽ	31FD	KATAKANA LETTER SMALL RU	小書き片仮名ル
ㇾ	31FE	KATAKANA LETTER SMALL RE	小書き片仮名レ
ㇿ	31FF	KATAKANA LETTER SMALL RO	小書き片仮名ロ
ㇷ゚	<31F7, 309A>	<KATAKANA LETTER SMALL HU, COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK>	小書き半濁点付き片仮名フ
END
    
# A.12 Prefixed abbreviations
cl_12 => <<'END',
Character	UCS	Name	Common name	Remarks
¥	00A5	YEN SIGN	円記号
￥	FFE5	FULLWIDTH YEN SIGN	円記号
$	0024	DOLLAR SIGN	ドル記号
＄	FF04	FULLWIDTH DOLLAR SIGN	ドル記号
£	00A3	POUND SIGN	ポンド記号
￡	FFE1	FULLWIDTH POUND SIGN	ポンド記号
#	0023	NUMBER SIGN	番号記号，井げた
＃	FF03	FULLWIDTH NUMBER SIGN	番号記号，井げた
€	20AC	EURO SIGN	ユーロ記号
№	2116	NUMERO SIGN	全角NO
END
    
# A.13 Postfixed abbreviations
cl_13 => <<'END',
Character	UCS	Name	Common name	Remarks
°	00B0	DEGREE SIGN	度	proportionally-spaced
′	2032	PRIME	分	proportionally-spaced
″	2033	DOUBLE PRIME	秒	proportionally-spaced
℃	2103	DEGREE CELSIUS	セ氏度記号
¢	00A2	CENT SIGN	セント記号
￠	FFE0	FULLWIDTH CENT SIGN	セント記号
%	0025	PERCENT SIGN	パーセント
％	FF05	FULLWIDTH PERCENT SIGN	パーセント
‰	2030	PER MILLE SIGN	パーミル
㏋	33CB	SQUARE HP	HP， ホースパワー（馬力）
ℓ	2113	SCRIPT SMALL L	リットル
㌃	3303	SQUARE AARU	全角アール
㌍	330D	SQUARE KARORII	全角カロリー
㌔	3314	SQUARE KIRO	全角キロ
㌘	3318	SQUARE GURAMU	全角グラム
㌢	3322	SQUARE SENTI	全角センチ
㌣	3323	SQUARE SENTO	全角セント
㌦	3326	SQUARE DORU	全角ドル
㌧	3327	SQUARE TON	全角トン
㌫	332B	SQUARE PAASENTO	全角パーセント
㌶	3336	SQUARE HEKUTAARU	全角ヘクタール
㌻	333B	SQUARE PEEZI	全角ページ
㍉	3349	SQUARE MIRI	全角ミリ
㍊	334A	SQUARE MIRIBAARU	全角ミリバール
㍍	334D	SQUARE MEETORU	全角メートル
㍑	3351	SQUARE RITTORU	全角リットル
㍗	3357	SQUARE WATTO	全角ワット
㎎	338E	SQUARE MG	全角MG
㎏	338F	SQUARE KG	全角KG
㎜	339C	SQUARE MM	全角MM
㎝	339D	SQUARE CM	全角CM
㎞	339E	SQUARE KM	全角KM
㎡	33A1	SQUARE M SQUARED	全角M2
㏄	33C4	SQUARE CC	全角CC
END

# A.14 Full-width ideographic space
cl_14 => <<'END',
Character	UCS	Name	Common name	Remarks
　	3000	IDEOGRAPHIC SPACE
END

);

sub class_chars {
    join '', map { /^(?![A-Z])(\X)/mg } @character_class{@_};
}

our %prohibition = (
    head        => class_chars( qw(cl_02 cl_03 cl_04 cl_05 cl_06 cl_07 cl_09 cl_10 cl_11) ),
    end         => class_chars( qw(cl_01) ),
    prefix      => class_chars( qw(cl_12) ),
    postfix     => class_chars( qw(cl_13) ),
    inseparable => class_chars( qw(cl_08) ),
    );

1;
