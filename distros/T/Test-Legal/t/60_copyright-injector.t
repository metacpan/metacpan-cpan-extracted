use Test::More 'no_plan';
use Expect;

my $dir     = $ENV{PWD} =~ m#\/t$#  ? '../script' : 'script';
my $tgt     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

$Expect::Log_Stdout = 0;
my $e;
$e = new Expect;
ok $e->spawn( "$dir/copyright-injector.pl", "-h") or die $!;
ok $e->expect(2,'Display documentation') ;
$e->soft_close;

$e = new Expect;
ok $e->spawn( "$dir/copyright-injector.pl", "-l") or die $!;
ok $e->expect(2,'-re','LGPL_2_1\s+None\s+SSLeay') ;
#$e->soft_close;

$e = new Expect;
ok $e->spawn( "$dir/copyright-injector.pl", "$tgt/bak") or die $!;
ok $e->expect(2,'-re', qr/Aborting.../i ) ;

$e = new Expect;
ok $e->spawn( "$dir/copyright-injector.pl", "$tgt", '-d') or die $!;
ok $e->expect(2,'-re', qr/Using copyright:/io) ;
