#!/usr/bin/perl

use strict;
use warnings;

use Tripletail q(upload.ini);

$TL->startCgi(
	      -main => \&main,
	     );


sub main {
  my $t = $TL->newTemplate('upload.html');

  # データは通常のフォームと同様に入ってきますが，
  # 文字コードの自動変換は行われません．
  # ファイル名は，->getFilename メソッドで取得できます．
  
  if($CGI->getFileName('file')) {
    my $fh = $CGI->getFile('file');
    $t->node('file')
      ->add(FILENAME => $CGI->getFileName('file'),
	    FILEDATA => join('', <$fh>),
	   );
  }
  
  $t->flush;

}



