use vpopmail;

sub ok {
  print "ok\n";
}

sub notok {
  print "not ok\n";
}
print "1..1\n";
my @list = vlistusers("vpopmail.com");

if ( scalar(@list) == 2 )
  {  ok(); } else { notok() }
