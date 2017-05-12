use vpopmail;

sub ok {
  print "ok\n";
}

sub notok {
  print "not ok\n";
}
print "1..1\n";

#
if ( ( adddomain('vpopmail.com' ) ) == 0 ) 
  {  ok(); } else { notok() }
