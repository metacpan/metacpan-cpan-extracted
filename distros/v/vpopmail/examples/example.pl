# $Id: example.pl,v 1.4 2001/08/11 15:49:39 sps Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; }
END {print "not ok 1\n" unless $loaded;}
use vpopmail;
use File::stat;
$loaded = 1;
######################### End of black magic.

print "running vpopmail v", vpopmail::vgetversion(), "\n";
#print "QMAILDIR => '", vpopmail::QMAILDIR, "'\n";
#print "VPOPMAILDIR => '", vpopmail::VPOPMAILDIR, "'\n";
#print "VPOPMAILUID => '", vpopmail::VPOPMAILUID, "'\n";
#print "VPOPMAILGID => '", vpopmail::VPOPMAILGID, "'\n";
#print "VPOPUSER => '", vpopmail::VPOPUSER, "'\n";
#print "VPOPGROUP => '", vpopmail::VPOPGROUP, "'\n";

adddomain("yeatbubba.net");
vadduser("postmaster", "yeatbubba.net", "foo", "Postmaster User", 0);
vadduser("sps", "yeatbubba.net", "foo", "regular guy", 0);

foreach my $domain (vlistdomains()) {

  print "$domain:\n";

  foreach my $u (vlistusers($domain)) {

    print "\t$u->{pw_name} ($u->{pw_gecos})\n";

  }
  print "\n\n";
}

vaddalias("sps", "yeatbubba.net", "elron");

vaddforward("sean.scanlon", "yeatbubba.net", 'sps@bluedot.net');

system(sprintf("/bin/ls -l %s", vgetdomaindir("yeatbubba.net") ));

$foo = vauth_getpw("sps",  "yeatbubba.net");



print "gecos: ", vauth_getpw("sps",  "yeatbubba.net")->{pw_gecos}, "\n";

$foo->{pw_gecos} = "Sean P. Scanlon";

vpopmail::vauth_setpw($foo, "yeatbubba.net");

print "gecos: ", vauth_getpw("sps",  "yeatbubba.net")->{pw_gecos}, "\n";

vdeldomain("yeatbubba.net");

