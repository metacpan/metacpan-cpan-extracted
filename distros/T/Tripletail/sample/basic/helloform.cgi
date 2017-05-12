#!/usr/bin/perl

use strict;
use warnings;

use Tripletail q(helloform.ini);

$TL->startCgi(
	      -main => \&main,
	     );


sub main {
  my $t = $TL->newTemplate('helloform.html');

  # フォームデータは $CGI 変数にフォームクラスのインスタンスとして
  # 自動的にセットされます．
  # このとき，文字コードは UTF-8 に自動変換されます．
  # ここでは全てのキーを取り出し，それぞれをノードに出力しています．

  foreach my $key (sort $CGI->getKeys) {
    $t->node('formitem')
      ->add(KEY => $key,
	    VALUE => $CGI->get($key),
	   );
  }

  # setForm で，受け渡されたデータをフォームに設定します．
  # submitボタンが押された場合のみ，フォームに設定しています．
  
  if($CGI->get('submit')) {
    $t->setForm($CGI);
  }
  
  $t->flush;

}



