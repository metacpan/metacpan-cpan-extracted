#!perl -T

use Data::Dumper;

use Test::More tests => 1;

#BEGIN {
#    use_ok( 'lib::remote' ) || print "Bail out!\n";
#}

warn "Runtime start";

#~ =pod
use lib::remote
	'Module::Stubber'=>{
		url=>'http://api.metacpan.org/source/MNUNBERG/Module-Stubber-0.03/lib/Module/Stubber.pm',
		#~ import=>[[qw(some symbols),],  ],
		import=>[qw(Unavailable::Module::As::Stub), [], ],
		debug=>0,
	},
	
	;
my $stub = Unavailable::Module::As::Stub->new;
use Module::Stubber 'Unavailable::Module::As::Stub2' => [qw(some symbols)], 'silent'=>1,;#qw(some symbols)
my $stub2 = Unavailable::Module::As::Stub2->new;
#~ some();

use lib::remote
	'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib',
	{debug=>1,},
	#~ 'Module::Hash'=>{
		#~ url=>'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib/Module/Hash.pm', 
		#~ import=>[{prefix => "Math"}],
		#~ debug=>1,
	#~ };
	;

my $MOD;
#~ use Module::Hash;
use Module::Hash $MOD; # OK
tie my %MOD, "Module::Hash"; # OK
my $num2 = 
	$MOD{"Math::BigInt"}->new(24_000_000_000_000_000)->bsqrt()
	+ 
	$MOD->{"Math::BigInt"}->new(42_000_000_000_000_001)->blog()
;

my $disp = lib::remote->new({debug=>1});
#~ my $disp2 = lib::remote->new(debug=>0);

#~ warn $disp, $disp2;# eq

warn "Load the remote module: ", $disp->module('XXX'=>{url=>'http://api.metacpan.org/source/INGY/XXX-0.18/lib/XXX.pm', import=>[-with => 'Data::Dumper']});

#~ my $disp = 
lib::remote->config('http://api.metacpan.org/source/INGY/Scalar-Random-PP-0.11/lib',);

#~ warn $disp, $disp2;# eq
#~ lib::remote::module('Scalar::Random::PP'=>{debug=>1}) - НЕ ИДЕТ
my $rand = lib::remote->module('Scalar::Random::PP'=>{debug=>1})->randomize(1000); # cant =>{import=>[qw(randomize)]}

Scalar::Random::PP::randomize(my $rand2, 2000);
my $rand3 = $rand2->randomize(3000);
#~ XXX::WWW($rand, "=[$rand]", $rand2, "=[$rand2]", $rand3, "=[$rand3]",);


ok($stub && $stub2 && $num2 && $rand && $rand2 && $rand3, 'Test failed');
diag( "Testing lib::remote Module::Stubber($Module::Stubber::VERSION)=[$stub]&[$stub2] Module::Hash($Module::Hash::VERSION)::Math::BigInt=[$num2] Scalar::Random::PP->randomize(1000)=[$rand]\n",  );#Dumper(\%INC)



warn "Runtime stop";

#~ __END__
#~ =cut

=pod
use lib::remote
	'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib',
	'Module::Hash'=>{
		#~ url=>'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib/Module/Hash000.pm', 
		#~ require=>0,
	};
#~ use Module::Hash; #dont need 
 
tie my %MOD, "Module::Hash";
#~ warn $MOD;
my $num = $MOD{"Math::BigInt"}->new(42_000_000_000_000_000)->bsqrt();

ok($num, 'Test Module::Hash');

diag( "Testing lib::remote Module::Hash [$Module::Hash::VERSION] Math::BigInt::bsqrt(42_000_000_000_000_000)=[$num]\n", );# Dumper(\%INC)

=cut

=pod
#~ my $MOD = my $MOD2 = {};
use lib::remote
	'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib',
	'Module::Hash'=>{
		#~ url=>'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib/Module/Hash.pm', 
		#~ import=>[$MOD],
	};
	;
#~ use Module::Hash;
#~ require Module::Hash;
my $MOD2;
use Module::Hash $MOD2;
tie my %MOD, "Module::Hash";
#~ 'Module::Hash'->import($MOD, $MOD2);
#~ warn $MOD;
my $num2 = 
	$MOD2->{"Math::BigInt"}->new(24_000_000_000_000_000)->bsqrt()
	+ 
	$MOD{"Math::BigInt"}->new(42_000_000_000_000_001)->blog()
;

ok($num2, 'Test Module::Hash');
diag( "Testing lib::remote Module::Hash [$Module::Hash::VERSION] Math::BigInt=[$num2]\n", );# Dumper(\%INC)
=cut
