#!/usr/bin/perl

use strict;
use warnings;

use Tripletail q(seoform.ini);

# SEO対策がされたリンクのフォームを解析するため，
# 入力フィルタを追加します．
# 入力フィルタは startCgi 前に設定します．

$TL->setInputFilter(['Tripletail::InputFilter::SEO', 999]);

$TL->startCgi(
	      -main => \&main,
	     );


sub main {
  # 出力時にSEO対策の自動変換を行うため，
  # 出力フィルタを追加します．

  $TL->setContentFilter(['Tripletail::Filter::SEO', 1001]);

  # 出力時のSEO対策URLで，どの順序でフォームデータを
  # 出力するかを指定します．
  # 指定しなかった場合や，指定していないキーがあった場合は，
  # 文字コード順に出力されます．
  
  $TL->getContentFilter(1001)->setOrder(qw(checkbox radio));
  
  my $t = $TL->newTemplate('seoform.html');

  foreach my $key (sort $CGI->getKeys) {
    $t->node('formitem')
      ->add(KEY => $key,
	    VALUE => $CGI->get($key),
	   );
  }

  if($CGI->get('submit')) {
    $t->setForm($CGI);


    # SEO=1 のデータを含むリンクが SEO対策の対象になります．
    my $seoform = $CGI->clone;
    $seoform->set(SEO => 1);

    my $seolink = $TL->getContentFilter(1001)
      ->toLink($seoform);
    
    $t->node('formlink')->add(FORMLINK => $CGI->toLink,
			      SEOFORMLINK => $seoform->toLink,
			      SEOFORMLINKSTR => $seolink);
  }
  
  $t->flush;

}



