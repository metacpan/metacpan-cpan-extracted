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
tr!1!1!
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q!1!,q!1!,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 2
tr"1"1"
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q"1",q"1",'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 3
tr$1$1$
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q$1$,q$1$,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 4
tr%1%1%
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q%1%,q%1%,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 5
tr&1&1&
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q&1&,q&1&,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 6
tr'1'1'
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'1',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 7
tr)1)1)
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q)1),q)1),'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 8
tr*1*1*
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q*1*,q*1*,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 9
tr+1+1+
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q+1+,q+1+,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 10
tr,1,1,
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q,1,,q,1,,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 11
tr-1-1-
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q-1-,q-1-,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 12
tr.1.1.
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q.1.,q.1.,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 13
tr/1/1/
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q/1/,q/1/,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 14
tr:1:1:
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q:1:,q:1:,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 15
tr;1;1;
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q;1;,q;1;,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 16
tr=1=1=
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q=1=,q=1=,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 17
tr>1>1>
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q>1>,q>1>,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 18
tr?1?1?
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q?1?,q?1?,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 19
tr@1@1@
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q@1@,q@1@,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 20
tr\1\1\
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q\1\,q\1\,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 21
tr]1]1]
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q]1],q]1],'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 22
tr^1^1^
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q^1^,q^1^,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 23
tr`1`1`
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q`1`,q`1`,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 24
tr|1|1|
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q|1|,q|1|,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 25
tr}1}1}
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q}1},q}1},'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 26
tr~1~1~
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q~1~,q~1~,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 27
tr !1!1!
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q!1!,q!1!,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 28
tr "1"1"
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q"1",q"1",'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 29
tr $1$1$
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q$1$,q$1$,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 30
tr %1%1%
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q%1%,q%1%,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 31
tr &1&1&
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q&1&,q&1&,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 32
tr '1'1'
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'1',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 33
tr )1)1)
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q)1),q)1),'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 34
tr *1*1*
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q*1*,q*1*,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 35
tr +1+1+
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q+1+,q+1+,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 36
tr ,1,1,
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q,1,,q,1,,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 37
tr -1-1-
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q-1-,q-1-,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 38
tr .1.1.
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q.1.,q.1.,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 39
tr /1/1/
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q/1/,q/1/,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 40
tr 21212
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q212,q212,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 41
tr A1A1A
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,qA1A,qA1A,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 42
tr _1_1_
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q_1_,q_1_,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 43
tr :1:1:
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q:1:,q:1:,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 44
tr ;1;1;
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q;1;,q;1;,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 45
tr =1=1=
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q=1=,q=1=,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 46
tr >1>1>
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q>1>,q>1>,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 47
tr ?1?1?
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q?1?,q?1?,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 48
tr @1@1@
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q@1@,q@1@,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 49
tr \1\1\
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q\1\,q\1\,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 50
tr ]1]1]
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q]1],q]1],'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 51
tr ^1^1^
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q^1^,q^1^,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 52
tr `1`1`
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q`1`,q`1`,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 53
tr |1|1|
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q|1|,q|1|,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 54
tr }1}1}
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q}1},q}1},'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 55
tr ~1~1~
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q~1~,q~1~,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 56
tr/1/1/
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q/1/,q/1/,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 57
tr/1/1/c
END1
s{(\G${mb::_anchor})((?:(?![1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q/1/,q/1/,'cr')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 58
tr/1/1/d
END1
s{(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q/1/,q/1/,'dr')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 59
tr/1/1/s
END1
s{[\x00-\xFF]*}{mb::tr($&,q/1/,q/1/,'sr')}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 60
tr/1/1/cds
END1
s{[\x00-\xFF]*}{mb::tr($&,q/1/,q/1/,'cdsr')}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 61
tr A1A1A
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,qA1A,qA1A,'r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 62
tr A1A1Ac
END1
s {(\G${mb::_anchor})((?:(?![1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,qA1A,qA1A,'cr')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 63
tr A1A1Ad
END1
s {(\G${mb::_anchor})((?:(?=[1])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,qA1A,qA1A,'dr')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 64
tr A1A1As
END1
s {[\x00-\xFF]*}{mb::tr($&,qA1A,qA1A,'sr')}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 65
tr A1A1Acds
END1
s {[\x00-\xFF]*}{mb::tr($&,qA1A,qA1A,'cdsr')}e
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
