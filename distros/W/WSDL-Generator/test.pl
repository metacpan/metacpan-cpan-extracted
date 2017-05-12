use lib qw (./lib);
use WSDL::Generator;
use Test::Simple tests => 3;

my $param = {
				'param1' => 'toto',
				'param2' => [ { key1 => 'a',
				                key3 => 'complexe'
				               },
				              { key1 => 'mykey1',
				                key2 => 'mykey2' },
				            ],
			};

my $wsdl_param = {
					'schema_namesp' => 'http://www.itrelease.net/ITReleaseWSDLTest.xsd',
		  			'services'      => 'ITRelease',
					'service_name'  => 'WSDLTest',
					'target_namesp' => 'http://www.itrelease.net/SOAP/',
					'documentation' => 'Test of WSDL::Generator',
					'location'      => 'http://pics.work-itrelease.net/SOAP/WSDLTest'
				 };
my $wsdl = WSDL::Generator->new($wsdl_param);
ok(ref $wsdl eq 'WSDL::Generator', 'Init from Class::Hook');
my $test = WSDLTest->new($param);
$test->test1('hello');
$test->test2('world');
my $result = $wsdl->get('WSDLTest');

my @lines_tst = split /\n/, $result;
my $result_tst = join "\n", sort @lines_tst;

my @lines_ref;
open my $wsdl_fh, 'WSDLTest.wsdl';
while (<$wsdl_fh>) {
  chomp;
  push @lines_ref, $_;
}
close $wsdl_fh;
my $result_ref = join "\n", sort @lines_ref;



ok($result_tst eq $result_ref, 'WSDL generation');
my @classes = $wsdl->get_all;
ok($classes[0] eq 'WSDLTest', 'Class registered');
