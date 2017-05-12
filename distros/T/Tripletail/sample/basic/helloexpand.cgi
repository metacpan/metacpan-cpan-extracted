#!/usr/bin/perl

use strict;
use warnings;

use Tripletail q(helloexpand.ini);

$TL->startCgi(
	      -main => \&main,
	     );


sub main {
  my $t = $TL->newTemplate('helloexpand.html');


  # テンプレートオブジェクトの expand メソッドを使用して
  # テンプレート中の <&XXX> タグを展開できます．
  # タグは自動的にエスケープされて出力されます．
  # （エスケープせずに出力する場合は，Template#setAttr メソッドを使用します．）
  # 日本語文字列はソースコード上では UTF-8 ですが，出力時に
  # Shift_JIS コードへと変換されます．
  
  my $timestr = scalar(localtime);
  $t->expand(TIME => $timestr,
	     TAGTEST => '<TAG>',
	     JAPANESE => '日本語文字列',
	    );
  
  $t->flush;

}



