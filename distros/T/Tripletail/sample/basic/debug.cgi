#!/usr/bin/perl

use strict;
use warnings;

use Tripletail q(debug.ini);

$TL->startCgi(
	      -main => \&main,
	     );


sub main {
  my $t = $TL->newTemplate('debug.html');
  
  foreach my $key (sort $CGI->getKeys) {
    $t->node('formitem')
      ->add(KEY => $key,
	    VALUE => $CGI->get($key),
	   );
  }

  if($CGI->get('submit')) {
    $t->setForm($CGI);
  }

  $t->flush;

  # ログファイルにデータを書き出します．
  # iniファイルで log_popup=1 と指定してあれば，
  # ポップアップウィンドウでも確認できます．

  $TL->log(GROUPNAME => 'ログの出力テスト');
  
  # $CGI の内容をダンプします．
  
  $TL->dump(CGIVAR => $CGI);

  # 変数 $i，@data の内容をウォッチし，更新を通知します．

  my $i;
  my @data;
  $TL->watch(VAR_a => \$i);
  $TL->watch(VAR_data => \@data);
  for($i = 0; $i < 3; $i++)
    {
      push(@data, $i);
    }
  
}



