#!/usr/bin/perl

# ソースコードは UTF-8 で記述します．

use strict;
use warnings;

# TLフレームワークでは，use 時に ini ファイルの位置を指定します．
# 全てデフォルト値の場合でも，指定が必要です．

use Tripletail q(hello.ini);

# $TL->startCgi の -main 引数で，CGIリクエストを処理する
# 関数を指定します．
# TLフレームワークは，フォームのデコードなどの処理を
# 行った上で，-main 関数を呼び出します．

$TL->startCgi(
	      -main => \&main,
	     );


sub main {

  # TLフレームワーク用のクラスは，$TL->newXXX メソッドで
  # インスタンスを作成します．
  # （個別にuseする必要はありません．）
  # 以下ではテンプレートクラスを利用して，hello.html を読み込み，
  # そのまま出力しています．
  
  my $t = $TL->newTemplate('hello.html');
  $t->flush;

}



