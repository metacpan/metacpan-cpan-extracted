use strict;
use Smart::Comments '###';

sub setup {

   my @rel = grep { /\w/  } split (/\n/, '
t/tmp/00.txt
t/tmp/01.txt
t/tmp/02.txt
t/tmp/subdir/03.txt
t/tmp/subdir/04.txt
t/tmp/subdir/05.txt
');

   my $x=1;


   for my $rel(@rel){
      

      $rel=~/\w/ or next;
      $rel=~/(.+)\//;
      my $d = $1;
      mkdir $d;
      -d $d or die("$d not there");
      
      my $content = 'content'x(++$x*2);
      ## $content

      `echo '$content' > $rel`;
      sleep 1; # need to do that to get diff times
   }
   
   wantarray ? @rel : [@rel];

}

sub cleanup {
   `rm -rf t/tmp`;
   1
}


1;
