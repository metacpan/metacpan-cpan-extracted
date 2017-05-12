use strict;
use warnings;

use utf8;
use Test::Base;
use LWP::Online ":skip_all";
plan skip_all => "BROKEN";

plan tests => 2 + 2 * blocks;

use_ok "WWW::MobileCarrierJP::Softbank::Display";

my $res;
if ($ENV{YAML}) {
    require YAML;
    $res = YAML::LoadFile($ENV{YAML});
} else {
    $res = WWW::MobileCarrierJP::Softbank::Display->scrape();
    if ( $ENV{DEBUG_DUMP} ) {
        use Data::Dumper;
        Data::Dumper->import;
        warn Dumper($res);
    }
}

cmp_ok scalar(@$res), '>', 100, 'thirdforce has many phones';

filters { info => [qw/yaml/] };
run {
    my $block = shift;
    check($block->info);
};

sub check {
    my ($info) = @_;
    my ($model) = grep { $_->{model} eq $info->{model} } @$res;
    ok $model, "got a $info->{model} phone info";
    is_deeply $model => $info, "check the $info->{model}";
}

__END__

===
--- info
appli_fontsize: 
  - 
    orientation: 縦
    size_table: 
      - 
        width: 12
        resolution: QQVGA
        height: 12
      - 
        width: 20
        resolution: QVGA
        height: 20
      - 
        width: 20
        resolution: WQVGA
        height: 20
      - 
        width: 40
        resolution: VGA
        height: 40
      - 
        width: 40
        resolution: WVGA
        height: 40
      - 
        width: 40
        resolution: FWVGA
        height: 40
  - 
    orientation: 横
    size_table: 
      - 
        width: 20
        resolution: WQVGA
        height: 20
      - 
        width: 40
        resolution: WVGA
        height: 40
      - 
        width: 40
        resolution: FWVGA
        height: 40
appli_pixels: 
  - 
    orientation: 縦
    size_table: 
      - 
        height: 130
        resolution: QQVGA
        width: 120
      - 
        height: 260
        resolution: QVGA
        width: 240
      - 
        height: 320
        resolution: WQVGA
        width: 240
      - 
        height: 520
        resolution: VGA
        width: 480
      - 
        height: 640
        resolution: WVGA
        width: 480
      - 
        height: 742
        resolution: FWVGA
        width: 480
  - 
    orientation: 横
    size_table: 
      - 
        height: 224
        resolution: WQVGA
        width: 400
      - 
        height: 448
        resolution: WVGA
        width: 800
      - 
        height: 448
        resolution: FWVGA
        width: 854
browser_characters: 
  - 
    orientation: 縦
    size_table: 
      - 
        cols: 16
        extra: ~
        rows: 12
        size_label: 最大
      - 
        cols: 20
        extra: ~
        rows: 15
        size_label: 大
      - 
        cols: 24
        extra: ~
        rows: 18
        size_label: やや大
      - 
        cols: 30
        extra: デフォルト
        rows: 23
        size_label: 中
      - 
        cols: 40
        extra: ~
        rows: 30
        size_label: やや小
      - 
        cols: 48
        extra: ~
        rows: 36
        size_label: 小
      - 
        cols: 80
        extra: ~
        rows: 56
        size_label: 最小
  - 
    orientation: 横
    size_table: 
      - 
        cols: 28
        extra: ~
        rows: 5
        size_label: 最大
      - 
        cols: 35
        extra: ~
        rows: 7
        size_label: 大
      - 
        cols: 42
        extra: ~
        rows: 8
        size_label: やや大
      - 
        cols: 53
        extra: デフォルト
        rows: 11
        size_label: 中
      - 
        cols: 71
        extra: ~
        rows: 14
        size_label: やや小
      - 
        cols: 85
        extra: ~
        rows: 17
        size_label: 小
      - 
        cols: 142
        extra: ~
        rows: 27
        size_label: 最小
browser_pixels: 
  - 
    height: 738
    orientation: 縦
    width: 480
  - 
    height: 352
    orientation: 横
    width: 854
flash: 
  height: 738
  width: 480
model: 945SH
widget_homescreen: ~
widget: 
  - 
    height: 738
    orientation: 縦
    width: 480
  - 
    height: 352
    orientation: 横
    width: 854

===
--- info
appli_fontsize: 
  - 
    orientation: 縦
    size_table: 
      - 
        width: 12
        resolution: QQVGA
        height: 12
      - 
        width: 20
        resolution: QVGA
        height: 20
      - 
        width: 20
        resolution: WQVGA
        height: 20
      - 
        width: 40
        resolution: VGA
        height: 40
      - 
        width: 40
        resolution: WVGA
        height: 40
      - 
        width: 40
        resolution: FWVGA
        height: 40
  - 
    orientation: 横
    size_table: 
      - 
        width: 20
        resolution: WQVGA
        height: 20
      - 
        width: 40
        resolution: WVGA
        height: 40
      - 
        width: 40
        resolution: FWVGA
        height: 40
appli_pixels: 
  - 
    orientation: 縦
    size_table: 
      - 
        height: 130
        resolution: QQVGA
        width: 120
      - 
        height: 260
        resolution: QVGA
        width: 240
      - 
        height: 320
        resolution: WQVGA
        width: 240
      - 
        height: 520
        resolution: VGA
        width: 480
      - 
        height: 640
        resolution: WVGA
        width: 480
      - 
        height: 742
        resolution: FWVGA
        width: 480
  - 
    orientation: 横
    size_table: 
      - 
        height: 224
        resolution: WQVGA
        width: 400
      - 
        height: 448
        resolution: WVGA
        width: 800
      - 
        height: 448
        resolution: FWVGA
        width: 854
browser_characters: 
  - 
    orientation: 縦
    size_table: 
      - 
        cols: 16
        extra: ~
        rows: 12
        size_label: 最大
      - 
        cols: 20
        extra: ~
        rows: 15
        size_label: 大
      - 
        cols: 24
        extra: ~
        rows: 18
        size_label: やや大
      - 
        cols: 30
        extra: ﾃﾞﾌｫﾙﾄ
        rows: 23
        size_label: 中
      - 
        cols: 40
        extra: ~
        rows: 31
        size_label: やや小
      - 
        cols: 48
        extra: ~
        rows: 37
        size_label: 小
      - 
        cols: 80
        extra: ~
        rows: 58
        size_label: 最小
  - 
    orientation: 縦(2分割)
    size_table: 
      - 
        cols: 16
        extra: ~
        rows: 6
        size_label: 最大
      - 
        cols: 20
        extra: ~
        rows: 7
        size_label: 大
      - 
        cols: 24
        extra: ~
        rows: 9
        size_label: やや大
      - 
        cols: 30
        extra: ﾃﾞﾌｫﾙﾄ
        rows: 11
        size_label: 中
      - 
        cols: 40
        extra: ~
        rows: 15
        size_label: やや小
      - 
        cols: 48
        extra: ~
        rows: 18
        size_label: 小
      - 
        cols: 80
        extra: ~
        rows: 28
        size_label: 最小
  - 
    orientation: 横
    size_table: 
      - 
        cols: 28
        extra: ~
        rows: 6
        size_label: 最大
      - 
        cols: 35
        extra: ~
        rows: 8
        size_label: 大
      - 
        cols: 42
        extra: ~
        rows: 9
        size_label: やや大
      - 
        cols: 53
        extra: ﾃﾞﾌｫﾙﾄ
        rows: 12
        size_label: 中
      - 
        cols: 71
        extra: ~
        rows: 16
        size_label: やや小
      - 
        cols: 85
        extra: ~
        rows: 19
        size_label: 小
      - 
        cols: 142
        extra: ~
        rows: 29
        size_label: 最小
  - 
    orientation: 横(2分割)
    size_table: 
      - 
        cols: 16
        extra: ~
        rows: 6
        size_label: 最大
      - 
        cols: 20
        extra: ~
        rows: 8
        size_label: 大
      - 
        cols: 24
        extra: ~
        rows: 9
        size_label: やや大
      - 
        cols: 30
        extra: ﾃﾞﾌｫﾙﾄ
        rows: 12
        size_label: 中
      - 
        cols: 40
        extra: ~
        rows: 16
        size_label: やや小
      - 
        cols: 48
        extra: ~
        rows: 19
        size_label: 小
      - 
        cols: 80
        extra: ~
        rows: 29
        size_label: 最小
browser_pixels: 
  - 
    height: 754
    orientation: 縦
    width: 480
  - 
    height: 374
    orientation: )
    width: 480
  - 
    height: 384
    orientation: 横
    width: 854
  - 
    height: 384
    orientation: )
    width: 480
flash: 
  height: 754
  width: 480
model: 923SH
widget_homescreen: ~
widget: ~

===
--- info
appli_fontsize: []

appli_pixels: []

browser_characters: 
  - 
    orientation: 縦
    size_table: 
      - 
        cols: 30
        extra: ~
        rows: 10
        size_label: ~
browser_pixels: 
  - 
    height: 182
    orientation: 縦
    width: 176
flash: ~
model: 702sMO
widget_homescreen: ~
widget: ~

===
--- info
appli_fontsize: 
  - 
    orientation: 縦
    size_table: 
      - 
        width: 12
        resolution: QQVGA
        height: 12
      - 
        width: 20
        resolution: QVGA
        height: 20
appli_pixels: 
  - 
    orientation: 縦
    size_table: 
      - 
        height: 130
        resolution: QQVGA
        width: 120
      - 
        height: 260
        resolution: QVGA
        width: 240
browser_characters: 
  - 
    orientation: 縦
    size_table: 
      - 
        cols: 16
        extra: ~
        rows: 9
        size_label: 最大
      - 
        cols: 20
        extra: ~
        rows: 10
        size_label: 大
      - 
        cols: 23
        extra: ~
        rows: 12
        size_label: 中
      - 
        cols: 29
        extra: ~
        rows: 15
        size_label: 小
      - 
        cols: 39
        extra: ~
        rows: 18
        size_label: 最小
browser_pixels: 
  - 
    height: 270
    orientation: 縦
    width: 240
flash: 
  height: 270
  width: 234
model: 705SH
widget_homescreen: ~
widget: ~

===
--- info
appli_fontsize: 
  - 
    orientation: 縦
    size_table: 
      - 
        width: 12
        resolution: QQVGA
        height: 12
      - 
        width: 20
        resolution: QVGA
        height: 20
      - 
        width: 20
        resolution: WQVGA
        height: 20
      - 
        width: 40
        resolution: VGA
        height: 40
      - 
        width: 40
        resolution: WVGA
        height: 40
      - 
        width: 40
        resolution: FWVGA
        height: 40
      - 
        width: 40
        resolution: HXGA
        height: 40
  - 
    orientation: 横
    size_table: 
      - 
        width: 20
        resolution: WQVGA
        height: 20
      - 
        width: 40
        resolution: WVGA
        height: 40
      - 
        width: 40
        resolution: FWVGA
        height: 40
      - 
        width: 40
        resolution: HXGA
        height: 40
appli_pixels: 
  - 
    orientation: 縦
    size_table: 
      - 
        height: 130
        resolution: QQVGA
        width: 120
      - 
        height: 260
        resolution: QVGA
        width: 240
      - 
        height: 320
        resolution: WQVGA
        width: 240
      - 
        height: 520
        resolution: VGA
        width: 480
      - 
        height: 640
        resolution: WVGA
        width: 480
      - 
        height: 742
        resolution: FWVGA
        width: 480
      - 
        height: 908
        resolution: HXGA
        width: 480
  - 
    orientation: 横
    size_table: 
      - 
        height: 224
        resolution: WQVGA
        width: 400
      - 
        height: 448
        resolution: WVGA
        width: 800
      - 
        height: 448
        resolution: FWVGA
        width: 854
      - 
        height: 448
        resolution: HXGA
        width: 1024
browser_characters: 
  - 
    orientation: 縦
    size_table: 
      - 
        cols: 16
        extra: ~
        rows: 13
        size_label: 最大
      - 
        cols: 20
        extra: ~
        rows: 17
        size_label: 大
      - 
        cols: 24
        extra: ~
        rows: 20
        size_label: やや大
      - 
        cols: 30
        extra: デフォルト
        rows: 25
        size_label: 中
      - 
        cols: 40
        extra: ~
        rows: 34
        size_label: やや小
      - 
        cols: 48
        extra: ~
        rows: 41
        size_label: 小
      - 
        cols: 80
        extra: ~
        rows: 63
        size_label: 最小
  - 
    orientation: 横
    size_table: 
      - 
        cols: 34
        extra: ~
        rows: 5
        size_label: 最大
      - 
        cols: 42
        extra: ~
        rows: 7
        size_label: 大
      - 
        cols: 51
        extra: ~
        rows: 8
        size_label: やや大
      - 
        cols: 64
        extra: デフォルト
        rows: 11
        size_label: 中
      - 
        cols: 85
        extra: ~
        rows: 14
        size_label: やや小
      - 
        cols: 102
        extra: ~
        rows: 17
        size_label: 小
      - 
        cols: 170
        extra: ~
        rows: 27
        size_label: 最小
browser_pixels: 
  - 
    height: 824
    orientation: 縦
    width: 480
  - 
    height: 352
    orientation: 横
    width: 1024
flash: 
  height: 824
  width: 480
model: 941SH
widget_homescreen: 
  - 
    height: 824
    orientation: 縦
    width: 480
  - 
    height: 352
    orientation: 横
    width: 1024
widget: 
  - 
    height: 824
    orientation: 縦
    width: 480
  - 
    height: 352
    orientation: 横
    width: 1024

===
--- info
appli_fontsize: 
  - 
    orientation: 縦
    size_table: 
      - 
        width: 12
        resolution: QQVGA
        height: 12
      - 
        width: 18
        resolution: QVGA
        height: 18
      - 
        width: 18
        resolution: WQVGA
        height: 18
      - 
        width: 18
        resolution: WQVGA(独自ｻｲｽﾞ)
        height: 18
      - 
        width: 36
        resolution: VGA
        height: 36
      - 
        width: 36
        resolution: WVGA
        height: 36
      - 
        width: 36
        resolution: WVGA(独自ｻｲｽﾞ)
        height: 36
appli_pixels: 
  - 
    orientation: 縦
    size_table: 
      - 
        height: 130
        resolution: QQVGA
        width: 120
      - 
        height: 260
        resolution: QVGA
        width: 240
      - 
        height: 320
        resolution: WQVGA
        width: 240
      - 
        height: 340
        resolution: WQVGA(独自ｻｲｽﾞ)
        width: 240
      - 
        height: 520
        resolution: VGA
        width: 480
      - 
        height: 640
        resolution: WVGA
        width: 480
      - 
        height: 680
        resolution: WVGA(独自ｻｲｽﾞ)
        width: 480
browser_characters: 
  - 
    orientation: 縦
    size_table: 
      - 
        cols: 18
        extra: ~
        rows: 9
        size_label: 大
      - 
        cols: 18
        extra: ~
        rows: 11
        size_label: 中
      - 
        cols: 23
        extra: ~
        rows: 13
        size_label: 小さめ
      - 
        cols: 26
        extra: ~
        rows: 18
        size_label: 小
      - 
        cols: 39
        extra: ~
        rows: 28
        size_label: 極小
browser_pixels: 
  - 
    height: 339
    orientation: 縦
    width: 234
flash: 
  height: 341
  width: 236
model: 920T
widget_homescreen: ~
widget: ~

