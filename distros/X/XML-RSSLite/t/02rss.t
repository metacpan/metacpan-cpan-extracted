use XML::RSSLite;
print "1..4\n";

if( open(RSS, "t/sampleRSS.xml") ){
  my(%result, $str);
  $str = do{ local $/; <RSS>};
  close(RSS);
  my $str2 = $str;

  parseRSS(\%result, \$str, 1);
  print 'not ' unless $result{image}->[1]->{width} == 176;
  print "ok 1 #IMG width # $result{image}->[1]->{width} == 176\n";

  print 'not ' unless $result{items}->[4]->{title} eq
	'UK bloggers get organised | WtW';
  print "ok 2 #Preprocess no strip\n";

  undef %result;
  parseRSS(\%result, \$str2);
  print 'not ' unless $result{items}->[4]->{title} eq
	'UK bloggers get organised   WtW';
  printf "ok 3 #Preprocess strip [%1]\n", $result{items}->[4]->{title};
}
else{
  print "ok $_ #skipped Could not open t/sampleRSS.xml:$!\n" foreach 1..3;
}



if( open(RSS, "t/journal.rss") ){
  my(%result, $str);
  $str = do{ local $/; <RSS>};
  close(RSS);
  parseRSS(\%result, \$str);
  print 'not ' unless $result{items}->[0]->{title} eq 'gizmo_mathboy (2002.05.03 13:41)';
  print "ok 4 #Title     # '$result{items}->[0]->{title}' eq 'gizmo_mathboy (2002.05.03 13:41)'\n";
}
else{
  print "ok 4 #skipped Could not open t/rss: $!\n";
}

1;
