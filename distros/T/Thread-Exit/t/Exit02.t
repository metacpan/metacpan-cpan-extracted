use Thread::Exit ();
print "1..1\n";
eval {exit()}; # eval in case Thread::Exit's exit() exits/dies for other reason
$notok = 1;
print "not ok 1\n";
END { print "ok 1\n" unless $notok; }
