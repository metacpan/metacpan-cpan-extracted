#!/usr/bin/perl -I..
# 22.10.1999, Sampo Kellomaki <sampo@iki.fi>
#
# Regression tests for smime command line tool. This also regression
# tests the library to considerable extent.
#
# Usage: ./test-smime.pl [-fast]

use filex;

print "Tests will be done inside directory t$$\n";
mkdir "t$$", 0774 or die $!;

if ($ARGV[0] eq '-fast') {
    shift;
    $fast = 1;
}

$|=1;
$n = 11;

filex::barf("t$$/dn$n", <<DN);
countryName=PT
organizationName=Universidade Técnica de Lisboa
organizationalUnitName=IST
commonName=t$n
emailAddress=t$n\@test.com
DN
    ;


$attr = "description=t$n";

print "1. Keygen...";
system "./smime -kg '$attr' pw t$$/r$n.pem <t$$/dn$n >t$$/t$n.pem" and die $?;
print "OK\n";

print "2. Make PKCS12...";
system "./smime -pem-p12 t$n\@test.com pw pw <t$$/t$n.pem >t$$/t$n.p12"
    and die $?;
print "OK\n";

print "3. Read PKCS12...";
system "./smime -p12-pem pw pw <t$$/t$n.p12 >t$$/tt$n.pem" and die $?;
print "OK\n";

print "4. Certification Authority...";
system "./smime -ca t$$/t$n.pem pw $$ <t$$/r$n.pem >t$$/c$n.pem" and die $?;
print "OK\n";

if ($fast) {
    print "Skipping tests 5-9 on fast mode.\n";
} else {
    print "5. Make multipart...";
    system "./smime -m application/octetstream smime <t$$/dn$n >t$$/m$n.mime"
	and die $?;
    print "OK\n";
    
    print "6. Clear sign...";
    system "./smime -cs t$$/tt$n.pem pw <t$$/m$n.mime >t$$/m$n.p7s" and die $?;
    print "OK\n";
    
    print "7. Encrypt...";
    system "./smime -e t$$/tt$n.pem <t$$/m$n.p7s >t$$/m$n.p7m" and die $?;
    print "OK\n";
    
    print "8. Decrypt...";
    system "./smime -d t$$/t$n.pem pw <t$$/m$n.p7m >t$$/mm$n.p7s" and die $?;
    print "OK\n";
    
    print "9. Comparing plain texts...";
    system "diff t$$/m$n.p7s t$$/mm$n.p7s" and die $?;
    print "OK\n";
}

print "10. Sign...";
system "./smime -s t$$/tt$n.pem pw <t$$/dn$n >t$$/s$n.p7m" and die $?;
print "OK\n";

print "11. Verify...";
system "./smime -v t$$/t$n.pem <t$$/s$n.p7m >t$$/ddn$n" and die $?;
print "OK\n";

print "12. Comparing plain texts...";
system "diff -b t$$/dn$n t$$/ddn$n" and die $?;
print "OK\n";

print "13. Query req...";
system "./smime -qr <t$$/r$n.pem >t$$/qr$n" and die $?;
print "OK\n";

print "14. Query cert...";
system "./smime -qc <t$$/t$n.pem >t$$/qc$n" and die $?;
print "OK\n";

print "15. Base64 encode...";
system "./smime -base64 <smime >t$$/f$n.b64" and die $?;
print "OK\n";

print "16. Base64 decode...";
system "./smime -unbase64 <t$$/f$n.b64 >t$$/f$n" and die $?;
print "OK\n";

print "17. Comparing files...";
system "cmp smime t$$/f$n" and die $?;
print "OK\n";

print "18. Querying signature...";
system "./smime -qs <t$$/s$n.p7m" and die $?;
print "OK\n";

print "19. Verifying certificate against CA cert...";
system "./smime -cv t$$/t$n.pem <t$$/t$n.pem" and die $?;
print "OK\n";

#print "9. Checking clear sig...";
#system "./smime -cv <t$$/mm$n.p7s >t$$/sig-dn$n" and die $?;
#print "OK\n";

if (0) {
print "10. ...";
system "./smime" and die $?;
print "OK\n";
}

print "rm -rf t$$";

#EOF
