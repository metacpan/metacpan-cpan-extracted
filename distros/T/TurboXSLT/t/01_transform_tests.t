use strict;
use warnings;
use Test::More;
use Encode;

use TurboXSLT;

my $TestsFolder = "t/internal-data";

opendir TESTSDIR, $TestsFolder;

my @XSLs;
for (readdir(TESTSDIR)){
	push @XSLs,$1 if /(.+)\.xsl$/;
}
closedir TESTSDIR;

@XSLs = sort {$b cmp $a} @XSLs;


plan(tests => (scalar @XSLs) + 2);

ok(@XSLs > 0, "Tests loaded");

my $engine = new TurboXSLT;
isa_ok($engine, 'TurboXSLT', "XSLT init");

for my $XSL (@XSLs){
	my $XSLFile = "$TestsFolder/$XSL.xsl";
	my $XMLFile = "$TestsFolder/$XSL.xml";
	my $Expectance = "$TestsFolder/$XSL.out";
	subtest $XSL => sub {
		plan tests => 13;
		for my $Multithreads (0,4){
			my $ctx = $engine->LoadStylesheet($XSLFile);
			isa_ok($ctx, 'TurboXSLT::Stylesheet', "Stylesheet $XSL.xsl load");

			if ($Multithreads){
				$ctx->CreateThreadPool(4);
				pass("CreateThreadPool(4) - no die");
			}

			my $XML;
			open(XMLFILE, "<", $XMLFile) or die "Can't open $XMLFile";
			read(XMLFILE, $XML, -s $XMLFile);
			close XMLFILE;
			$XML = Encode::decode_utf8($XML);

			my $doc = $engine->Parse($XML);

			isa_ok($doc, 'TurboXSLT::Node', "Parse $XSL.xml document".($Multithreads?" (threads=$Multithreads)":''));

			my $res = $ctx->Transform($doc);
			isa_ok($res, 'TurboXSLT::Node', "DOM after $XSL transform".($Multithreads?" (threads=$Multithreads)":''));

			my $Out = $ctx->Output($res);
			unless (Encode::is_utf8($Out)) {
				$Out = Encode::decode_utf8($Out);
			}
			ok($Out, "Some text output from $XSLFile transform".($Multithreads?" (threads=$Multithreads)":''));
			$Out = Cleanup($Out);

			my $ExpectedOut;
			open OUTFILE, "<", $Expectance;
			read(OUTFILE, $ExpectedOut, -s $Expectance);
			close OUTFILE;
			$ExpectedOut = Encode::decode_utf8($ExpectedOut);
			$ExpectedOut  = Cleanup($ExpectedOut);

			cmp_ok($Out, 'eq', $ExpectedOut, "One-time transformation $XSL works as expected".($Multithreads?" (threads=$Multithreads)":''));
			for (0..10){
				my $FakeRes = $ctx->Output($ctx->Transform($doc));
			}
			my $FinalRes = $ctx->Output($ctx->Transform($doc));
			unless (Encode::is_utf8($FinalRes)) {
				$FinalRes = Encode::decode_utf8($FinalRes);
			}

			$FinalRes  = Cleanup($FinalRes);

			cmp_ok($FinalRes, 'eq', $ExpectedOut, "10-time transformation $XSL works as expected".($Multithreads?" (threads=$Multithreads)":''));
		}
	}
}

sub Cleanup {
	$_ = shift;
	s/^\s+|\s+$//g;
	s/\s+/ /g;
	return $_;
}

exit;
