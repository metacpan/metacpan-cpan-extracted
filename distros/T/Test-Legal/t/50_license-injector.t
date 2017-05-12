use Test::More 'no_plan';
use Expect;

my $dir     = $ENV{PWD} =~ m#\/t$#  ? '../script' : 'script';
my $tgt     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

$Expect::Log_Stdout = 0;
my $e;


$e = new Expect;
ok $e->spawn( "$dir/license-injector.pl", "-h") or die $!;
ok $e->expect(2,'Display documentation') ;
$e->soft_close;

$e = new Expect;
ok $e->spawn( "$dir/license-injector.pl", "-l") or die $!;
ok $e->expect(2,'-re','LGPL_2_1\s+None\s+SSLeay') ;
$e->soft_close;

$e = new Expect;
ok $e->spawn( "$dir/license-injector.pl", "$tgt/bak") or die $!;
ok $e->expect(2,'-re', qr/Aborting.../i ) ;

$e = new Expect;
ok $e->spawn( "$dir/license-injector.pl", "$tgt", '-d') or die $!;
ok $e->expect(2, 'LICENSE ....  not found') ;
ok $e->expect(2, 'META ....  found') ;
ok $e->expect(2, 'extracting license type ....  Perl_5') ;
ok $e->expect(2, 'license type is valid ....  yes') ;
ok $e->expect(2, 'authors ....  Ioannis Tambouras') ;
ok $e->expect(2, 'license text is available ....  yes') ;
#say $e->before;

$e = new Expect;
ok $e->spawn( "$dir/license-injector.pl", "$tgt", '-d', 't') or die $!;
ok $e->expect(2, 'Scanning ') ;
ok $e->expect(2, 'not ok 1 - dist contains LICENSE file');
ok $e->expect(2, 'ok 2 - META mentions license');

$e = new Expect;
ok $e->spawn( "$dir/license-injector.pl", "$tgt/../..") or die $!;
ok $e->expect(2,'-re', qr/....  found/io) ;
#say $e->before();
