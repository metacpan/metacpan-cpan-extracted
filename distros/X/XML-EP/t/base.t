# -*- perl -*-

use strict;
$^W = $| = 1;

my @packages = (qw(XML::EP::Config
                   XML::EP::Error
                   XML::EP::Response
                   XML::EP::Install
                   XML::EP::Test
                   XML::EP
                   XML::EP::Control
                   XML::EP::Producer::File
                   XML::EP::Formatter::HTML
                   XML::EP::Request::CGI
                   XML::EP::Processor::EmbPerl
                   XML::EP::Processor::XSLT
                   XML::EP::Processor::XSLTParser
                  ));

print "1..", scalar(@packages), "\n";
my $i = 0;
foreach my $package (@packages) {
    ++$i;
    eval "require $package";
    if ($@) {
	print "not ok $i\n";
	print "$@\n";
    } else {
	print "ok $i\n";
    }
}
