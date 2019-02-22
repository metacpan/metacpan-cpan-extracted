#!/usr/bin/perl -w

use lib qw(.);
use DTA::TokWrap;
use DTA::TokWrap::Utils ':libxml';

push(@ARGV,'-') if (!@ARGV);
my $xmlfile = shift;
my $xmlparser = libxml_parser();
my $xmldoc    = ($xmlfile eq '-' ? $xmlparser->parse_fh(\*STDIN) : $xmlparser->parse_file($xmlfile));
die("$0: load failed for XML file '$xmlfile': $!") if (!$xmldoc);

DTA::TokWrap::Logger->ensureLog();
Log::Log4perl::MDC->put('xmlbase'=>File::Basename::basename($xmlfile));

my $mbx0 = DTA::TokWrap::Processor::mkbx0->new();
$mbx0->sanitize_xmlid($xmldoc);
$mbx0->sanitize_segs($xmldoc);
$mbx0->sanitize_chains($xmldoc);
$xmldoc->toFH(\*STDOUT,0);
