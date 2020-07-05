package Text::ANSI::Fold::Japanese::Wikipedia;

use v5.14;
use warnings;
use utf8;

our %prohibition = do {
    no warnings 'qw';
    (head => join('', # from wikipedia
		  qw@
		  ,)]｝、〕〉》」』】〙〗〟\’\”｠»'
		  ゝゞー
		  ァィゥェォッャュョヮヵヶ
		  ぁぃぅぇぉっゃゅょゎゕゖ
		  ㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇷ゚ㇺㇻㇼㇽㇾㇿ
		  々〻
		  ‐゠–〜～
		  ?!‼⁇⁈⁉
		  ・:;/
		  。.
		  @, # not in wikipedia
		  qw@
		  ，）］
		  -～=＝
		  ？！
		  @),
     end  => join('', # from wikipedia
		  qw@
		  ([｛〔〈《「『【〘〖〝‘“｟«
		  @, # not in wikipedia
		  qw@
		  （［
		  @),
    );
};

1;
