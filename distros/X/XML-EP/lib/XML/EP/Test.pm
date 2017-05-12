# -*- perl -*-

use strict;
require Exporter;

package XML::EP::Test;

@XML::EP::Test::ISA = qw(Exporter);
@XML::EP::Test::EXPORT_OK = qw(Test XmlCmp);

$XML::EP::Test::VERSION = '0.01';

my $currentTest = 0;
sub Test {
    my $result = shift; my $msg = shift;
    $msg = "" unless defined $msg;
    $msg = " $msg" unless $msg eq "";
    ++$currentTest;
    if ($result) {
	print "ok $currentTest$msg\n";
    } else {
	print "not ok $currentTest$msg\n";
    }
    $result;
}

sub XmlCmp {
    my $a = shift;  my $b = shift;  my $attr = { @_ };
    unless ($attr->{'keepws'}) {
	$a =~ s/^\s+//mg;
	$a =~ s/\s+$//mg;
	$b =~ s/^\s+//mg;
	$b =~ s/\s+$//mg;
    }
    Test($a eq $b) or print "Expected:\n$b\nGot:\n$a\n";
}


1;
