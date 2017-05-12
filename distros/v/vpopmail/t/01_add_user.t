use vpopmail;

sub ok {
  print "ok\n";
}

sub notok {
  print "not ok\n";
}
print "1..2\n";


#
if ( ( vadduser('postmaster', 'vpopmail.com', 'p@ssw0rd1', 'The Postmaster', 0 ) ) == 0 ) 
  {  ok(); } else { notok() }

if ( ( vadduser('username', 'vpopmail.com', 'p@ssw0rd', 'Test User', 0 ) ) == 0 ) 
  {  ok(); } else { notok() }
