use XML::RSSLite;
print "1..2\n";

if( open(RSS, "t/sampleRSS.xml") ){
  my(%result, $str);
  $str = do{ local $/; <RSS>};
  close(RSS);
  parseRSS(\%result, \$str);
  print 'not ' unless $result{image}->[1]->{width} == 176;
  print "ok 1 #IMG width # $result{image}->[1]->{width} == 176\n";
}
else{
  print "ok 1 #skipped Could not open t/sampleRSS.xml:$!\n";
}

if( open(RSS, "t/journal.rss") ){
  my(%result, $str);
  $str = do{ local $/; <RSS>};
  close(RSS);
  parseRSS(\%result, \$str);
  print 'not ' unless $result{items}->[0]->{title} eq 'gizmo_mathboy (2002.05.03 13:41)';
  print "ok 2 #Title     # '$result{items}->[0]->{title}' eq 'gizmo_mathboy (2002.05.03 13:41)'\n";
}
else{
  print "ok 2 #skipped Could not open t/rss: $!\n";
}

1;
