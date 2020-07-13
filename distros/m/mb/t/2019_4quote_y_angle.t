# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

use vars qw($MSWin32_MBCS);
$MSWin32_MBCS = ($^O =~ /MSWin32/) and (qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/);

@test = (
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 1
y<1>!1!
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q!1!,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 2
y<1>"1"
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q"1",'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 3
y<1>$1$
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q$1$,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 4
y<1>%1%
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q%1%,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 5
y<1>&1&
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q&1&,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 6
y<1>'1'
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 7
y<1>)1)
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q)1),'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 8
y<1>*1*
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q*1*,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 9
y<1>+1+
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q+1+,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 10
y<1>,1,
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q,1,,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 11
y<1>-1-
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q-1-,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 12
y<1>.1.
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q.1.,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 13
y<1>/1/
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q/1/,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 14
y<1>:1:
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q:1:,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 15
y<1>;1;
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q;1;,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 16
y<1>=1=
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q=1=,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 17
y<1>>1>
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q>1>,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 18
y<1>?1?
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q?1?,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 19
y<1>@1@
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q@1@,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 20
y<1>\1\
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q\1\,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 21
y<1>]1]
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q]1],'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 22
y<1>^1^
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q^1^,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 23
y<1>`1`
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q`1`,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 24
y<1>|1|
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q|1|,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 25
y<1>}1}
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q}1},'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 26
y<1>~1~
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q~1~,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 27
y<1> !1!
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q!1!,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 28
y<1> "1"
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q"1",'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 29
y<1> $1$
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q$1$,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 30
y<1> %1%
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q%1%,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 31
y<1> &1&
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q&1&,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 32
y<1> '1'
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 33
y<1> )1)
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q)1),'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 34
y<1> *1*
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q*1*,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 35
y<1> +1+
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q+1+,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 36
y<1> ,1,
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q,1,,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 37
y<1> -1-
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q-1-,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 38
y<1> .1.
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q.1.,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 39
y<1> /1/
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q/1/,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 40
y<1> :1:
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q:1:,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 41
y<1> ;1;
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q;1;,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 42
y<1> =1=
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q=1=,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 43
y<1> >1>
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q>1>,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 44
y<1> ?1?
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q?1?,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 45
y<1> @1@
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q@1@,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 46
y<1> \1\
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q\1\,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 47
y<1> ]1]
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q]1],'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 48
y<1> ^1^
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q^1^,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 49
y<1> `1`
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q`1`,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 50
y<1> |1|
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q|1|,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 51
y<1> }1}
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q}1},'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 52
y<1> ~1~
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q~1~,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 53
y <1>!1!
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q!1!,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 54
y <1>"1"
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q"1",'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 55
y <1>$1$
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q$1$,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 56
y <1>%1%
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q%1%,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 57
y <1>&1&
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q&1&,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 58
y <1>'1'
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 59
y <1>)1)
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q)1),'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 60
y <1>*1*
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q*1*,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 61
y <1>+1+
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q+1+,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 62
y <1>,1,
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q,1,,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 63
y <1>-1-
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q-1-,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 64
y <1>.1.
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q.1.,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 65
y <1>/1/
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q/1/,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 66
y <1>:1:
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q:1:,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 67
y <1>;1;
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q;1;,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 68
y <1>=1=
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q=1=,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 69
y <1>>1>
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q>1>,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 70
y <1>?1?
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q?1?,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 71
y <1>@1@
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q@1@,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 72
y <1>\1\
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q\1\,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 73
y <1>]1]
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q]1],'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 74
y <1>^1^
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q^1^,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 75
y <1>`1`
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q`1`,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 76
y <1>|1|
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q|1|,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 77
y <1>}1}
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q}1},'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 78
y <1>~1~
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q<1>,q~1~,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 79
y <1> !1!
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q!1!,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 80
y <1> "1"
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q"1",'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 81
y <1> $1$
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q$1$,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 82
y <1> %1%
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q%1%,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 83
y <1> &1&
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q&1&,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 84
y <1> '1'
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 85
y <1> )1)
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q)1),'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 86
y <1> *1*
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q*1*,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 87
y <1> +1+
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q+1+,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 88
y <1> ,1,
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q,1,,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 89
y <1> -1-
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q-1-,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 90
y <1> .1.
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q.1.,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 91
y <1> /1/
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q/1/,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 92
y <1> :1:
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q:1:,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 93
y <1> ;1;
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q;1;,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 94
y <1> =1=
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q=1=,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 95
y <1> >1>
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q>1>,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 96
y <1> ?1?
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q?1?,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 97
y <1> @1@
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q@1@,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 98
y <1> \1\
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q\1\,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 99
y <1> ]1]
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q]1],'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 100
y <1> ^1^
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q^1^,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 101
y <1> `1`
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q`1`,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 102
y <1> |1|
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q|1|,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 103
y <1> }1}
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q}1},'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 104
y <1> ~1~
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} {$1.mb::tr($2,q<1>,q~1~,'r')}eg
END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

sub regexp {
    local($_) = @_;
    if (qr// eq '(?^:)') {
        s{\(\?-xism:}{(?^:}g;
    }
    return $_;
}

__END__
