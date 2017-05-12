use vpopmail;

sub ok {
  print "ok\n";
}

sub notok {
  print "not ok\n";
}
print "1..1\n";

my $h = vauth_getpw('username', 'vpopmail.com');

if (exists($h->{pw_name})) 
  {  ok(); } else { notok() }
