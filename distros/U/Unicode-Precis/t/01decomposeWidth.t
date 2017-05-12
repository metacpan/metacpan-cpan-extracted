#-*- perl -*-
#-*- coding: utf-8 -*-

use strict;
use warnings;
no utf8;

use Test::More tests => 1;
use Unicode::Precis::Utils qw(decomposeWidth);

my ($comp, $decomp) = do { local $/ = ''; <DATA> };
1 while chomp ($comp, $decomp);
is(decomposeWidth($comp), $decomp, $decomp);

__END__
　！＂＃＄％＆＇（）＊＋，－．／
０１２３４５６７８９：；＜＝＞？
＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯ
ＰＱＲＳＴＵＶＷＸＹＺ［＼］＾＿
｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏ
ｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～｟
｠｡｢｣､･ｦｧｨｩｪｫｬｭｮｯ
ｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿ
ﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏ
ﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝﾞﾟ
ﾠﾡﾢﾣﾤﾥﾦﾧﾨﾩﾪﾫﾬﾭﾮﾯ
ﾰﾱﾲﾳﾴﾵﾶﾷﾸﾹﾺﾻﾼﾽﾾￂ
ￃￄￅￆￇￊￋￌￍￎￏￒￓￔￕￖ
ￗￚￛￜ￠￡￢￣￤￥￦￨￩￪￫￬
￭￮

 !"#$%&'()*+,-./
0123456789:;<=>?
@ABCDEFGHIJKLMNO
PQRSTUVWXYZ[\]^_
`abcdefghijklmno
pqrstuvwxyz{|}~⦅
⦆。「」、・ヲァィゥェォャュョッ
ーアイウエオカキクケコサシスセソ
タチツテトナニヌネノハヒフヘホマ
ミムメモヤユヨラリルレロワン゙゚
ㅤㄱㄲㄳㄴㄵㄶㄷㄸㄹㄺㄻㄼㄽㄾㄿ
ㅀㅁㅂㅃㅄㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎㅏ
ㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟ
ㅠㅡㅢㅣ¢£¬¯¦¥₩│←↑→↓
■○
