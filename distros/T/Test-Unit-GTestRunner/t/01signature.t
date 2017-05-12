# -*- perl -*-
# vim:tabstop=4:
# $Id: 01signature.t,v 1.1 2005/11/04 01:18:04 guido Exp $

print "1..1\n";

if (! -s 'SIGNATURE') {
	print "ok 1 # skip No signature file found\n";
} elsif (!eval { require Module::Signature; 1 }) {
	print "ok 1 # skip ",
		"Next time around, consider install Module::Signature, ",
		"so you can verify the integrity of this distribution.\n";
} elsif (!eval { require Socket; Socket::inet_aton('pgp.mit.edu') }) {
	print "ok 1 # skip Cannot connect to the keyserver\n";
} else {
	(Module::Signature::verify() == Module::Signature::SIGNATURE_OK())
		or print "not ";
	print "ok 1 # Valid signature\n";
}

__END__

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
tab-width: 4
End:

