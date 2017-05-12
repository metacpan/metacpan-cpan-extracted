#!/usr/bin/perl

use strict;
use warnings;

use Tripletail q(hellonode.ini);

$TL->startCgi(
	      -main => \&main,
	     );


sub main {
  my $t = $TL->newTemplate('hellonode.html');


  # テンプレート中に <!begin:XXX> <!end:XXX> タグを使用することで
  # テンプレートの一部をブロック化することができます．
  # ブロック化した部分をノードと呼び，明示的に出力させない限り
  # 最終的な出力には含まれません．
  # ノードは node メソッドを使用してアクセスでき，
  # ノードに対して add メソッドを呼び出すことで，
  # そのノードが出力されます．
  
  my $timestr = scalar(localtime);
  $t->node('node1')->add(TIME => $timestr);
  $t->node('node1')->add(TIME => $timestr);
  
  $t->flush;

}



