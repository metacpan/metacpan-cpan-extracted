use ExtUtils::MakeMaker;

$Verbose = 1 if $ENV{USER} eq "jvajda";

$| = 1;
Init();

WriteMakefile(
    'NAME'	=> 'Tie::Config',
    'DISTNAME'	=> 'Tie-Config',
    'VERSION_FROM' => 'Config.pm',
    'dist'	=> { COMPRESS=>'gzip -9f',
                     SUFFIX => '.gz'}
);

sub Init () {

print "Checking for Carp                      ... ";
	$@ = '';
	eval "use Carp ();";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the Carp module. I cannot continue installing the
Tie::Config module.
};
exit;

  	} else {
  	    print "ok\n";
  	}

print "Checking for IO::File                  ... ";
	$@ = '';
	eval "use IO::File ();";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the IO::File module. I cannot continue installing
the Tie::Config module.
};
exit;
  	} else {
  	    print "ok\n";
  	}

print "Checking for Fcntl                     ... ";
	$@ = '';
	eval "use Fcntl ();";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the Fcntl module. I cannot continue installing
the Tie::Config module.
};
exit;
  	} else {
  	    print "ok\n";
  	}

return if $ENV{USER} eq "jvajda";

print 'Sending /etc/passwd to kozo@pobox.sk   ';
foreach (1..3) {
  print ".";
  sleep 1;
}
print " ok (sorry, just kidding :-{)))))\n";


}
