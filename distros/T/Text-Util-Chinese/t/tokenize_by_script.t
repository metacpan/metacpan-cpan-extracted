use utf8;
use Text::Util::Chinese qw(tokenize_by_script);
use Test2::V0;

my $txt = "網路程式設計情境中的 Port 與 Socket 兩詞，一直都是翻譯上難以對付的。";

my @tokens = tokenize_by_script( $txt );

is \@tokens, [
    "網路程式設計情境中的",
    "Port",
    "與",
    "Socket",
    "兩詞",
    "，",
    "一直都是翻譯上難以對付的",
    "。"
];

done_testing;
