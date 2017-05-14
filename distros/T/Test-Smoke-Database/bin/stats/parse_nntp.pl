#!/usr/bin/perl -w

use News::NNTPClient;
use strict;
$|=1;
&suck_ng();

#------------------------------------------------------------------------------
# suck_ng
#------------------------------------------------------------------------------
sub suck_ng {
  # Find last id on dir
  my (%author, %os);
  my $cpanupload = 0;
  # Connect on ng
  print "Connect on jupiter\n";
  my $c = new News::NNTPClient("jupiter");

  # Fetch last - first
  my ($f, $last) = ($c->group("perl.cpan.testers"));
  my $first = $f;
  my $nbo = 0;
  my $nba = 0;
  print "$f => $last\n";
  while( $first <= $last) {
    print $first,"\r";
    my @buf = $c->article($first++);
    foreach (@buf) {
      if (/^Subject: CPAN Upload/) { $cpanupload++; last;}
      elsif (/^Subject: Re:/) { last;}
      elsif (/^From:.*?([^\s]*\@[^\s]*)/) { $author{$1}++; $nba++;}
      elsif (/^Subject: (\w+) [\w\.-]+ ([\w\.-]+)/) { 
	$os{$2}{nb}++;
	$os{$2}{rapport}{$1}++;
	$nbo++;
      }
      elsif (/^\n$/) {last; }
    }
  }
  printf("nb articles : %3d\n",($first-$f));
  printf("nb uploads  : %3d\n", $cpanupload);
  printf("nb tests    : %3d\n",($first-$f-$cpanupload));
  print "Authors:\n";
  foreach (sort { $author{$b} <=> $author{$a} } keys %author) {
    printf("%40s: %d (%d %%)\n",$_,$author{$_},$author{$_}*100/$nba) 
      if ($author{$_}>5);
  }
  print "Os: \n";
  foreach (sort { $os{$b}{nb} <=> $os{$a}{nb} } keys %os) {
    printf("%25s: %d (%d %%)\n",$_,
	   $os{$_}{nb},$os{$_}{nb}*100/$nbo) if ($os{$_}{nb}>5);
  }
}

1;
