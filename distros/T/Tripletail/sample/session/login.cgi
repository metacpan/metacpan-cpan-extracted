#!/usr/bin/perl

use strict;
use warnings;

use Tripletail q(login.ini);

$TL->startCgi(
	      -main => \&main,
	      -DB => 'DB',
	      -Session => 'Session',
	     );


sub main {

  my $t = $TL->newTemplate('login.html');

  my $session = $TL->getSession('Session');

  if($CGI->exists('id')) {
    # 全角数字を半角数字に直し，数字以外の文字を取り除きます．
    my $id = $TL->newValue($CGI->get('id'))->convNarrow->forceNumber->get;
    
    if($id ne '') {
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

  # flush はセッションの操作を全て終えた後に行わなければならない．
  
  $t->flush;
}



