#!/usr/bin/perl


# このCGIは，mode=doubleのサンプルです．
# https://，http:// の両方にサンプルを設置し，
# 実行してください．
# 
# セッションの値の設定は https からのみ行え，
# http，https の両方で参照できます．
# 
# http，https でセッションIDは異なるため，http の
# セッションIDを盗まれても，https 領域に影響を
# 与えることはありません．


use strict;
use warnings;

use Tripletail q(logindouble.ini);

$TL->startCgi(
	      -main => \&main,
	      -DB => 'DB',
	      -Session => 'Session',
	     );


sub main {

  my $t = $TL->newTemplate('logindouble.html');

  my $session = $TL->getSession('Session');

  if($CGI->exists('id')) {
    # 全角数字を半角数字に直し，数字以外の文字を取り除きます．
    my $id = $TL->newValue($CGI->get('id'))->convNarrow->forceNumber->get;
    
    if($id ne '') {
      # セッションにセットできるバイト数を減らすため，pack します．
      $session->setValue($id);
    }
  }
  
  my $sid = $session->get;
  my $id = $session->getValue;
  if($id) {
    $t->node('session')->add(SESSIONID => $sid,
			     SESSIONDATA => $id);
  } else {
    $t->node('nosession')->add;
  }
  
  $t->flush;
}



