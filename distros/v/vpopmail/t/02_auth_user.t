use vpopmail;

sub ok {
  print "ok\n";
}

sub notok {
  print "not ok\n";
}
print "1..1\n";

#
if ( vauth_user('username', 'vpopmail.com', 'p@ssw0rd', 0))
  {  ok(); } else { notok() }

