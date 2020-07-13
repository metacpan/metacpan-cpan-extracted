# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
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
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 1
---
'ァ'
END1
---
'ァ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 2
'ア'
END1
'ア'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 3
'ィ'
END1
'ィ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 4
'イ'
END1
'イ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 5
'ゥ'
END1
'ゥ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 6
'ウ'
END1
'ウ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 7
'ェ'
END1
'ェ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 8
'エ'
END1
'エ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 9
'ォ'
END1
'ォ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 10
'オ'
END1
'オ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 11
'カ'
END1
'カ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 12
'ガ'
END1
'ガ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 13
'キ'
END1
'キ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 14
'ギ'
END1
'ギ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 15
'ク'
END1
'ク'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 16
'グ'
END1
'グ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 17
'ケ'
END1
'ケ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 18
'ゲ'
END1
'ゲ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 19
'コ'
END1
'コ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 20
'ゴ'
END1
'ゴ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 21
'サ'
END1
'サ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 22
'ザ'
END1
'ザ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 23
'シ'
END1
'シ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 24
'ジ'
END1
'ジ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 25
'ス'
END1
'ス'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 26
'ズ'
END1
'ズ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 27
'セ'
END1
'セ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 28
'ゼ'
END1
'ゼ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 29
'ソ'
END1
'ソ\'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 30
'ゾ'
END1
'ゾ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 31
'タ'
END1
'タ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 32
'ダ'
END1
'ダ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 33
'チ'
END1
'チ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 34
'ヂ'
END1
'ヂ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 35
'ッ'
END1
'ッ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 36
'ツ'
END1
'ツ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 37
'ヅ'
END1
'ヅ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 38
'テ'
END1
'テ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 39
'デ'
END1
'デ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 40
'ト'
END1
'ト'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 41
'ド'
END1
'ド'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 42
'ナ'
END1
'ナ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 43
'ニ'
END1
'ニ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 44
'ヌ'
END1
'ヌ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 45
'ネ'
END1
'ネ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 46
'ノ'
END1
'ノ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 47
'ハ'
END1
'ハ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 48
'バ'
END1
'バ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 49
'パ'
END1
'パ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 50
'ヒ'
END1
'ヒ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 51
'ビ'
END1
'ビ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 52
'ピ'
END1
'ピ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 53
'フ'
END1
'フ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 54
'ブ'
END1
'ブ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 55
'プ'
END1
'プ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 56
'ヘ'
END1
'ヘ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 57
'ベ'
END1
'ベ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 58
'ペ'
END1
'ペ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 59
'ホ'
END1
'ホ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 60
'ボ'
END1
'ボ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 61
'ポ'
END1
'ポ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 62
'マ'
END1
'マ'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 63
'ミ'
END1
'ミ'
END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
