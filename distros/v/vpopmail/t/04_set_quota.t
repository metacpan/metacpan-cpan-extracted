use vpopmail;

sub ok {
  print "ok\n";
}

sub notok {
  print "not ok\n";
}
print "1..1\n";

if ( ( vsetuserquota('username', 'vpopmail.com', '5M') ) == 0 )
	{ ok(); } else { notok(); }
