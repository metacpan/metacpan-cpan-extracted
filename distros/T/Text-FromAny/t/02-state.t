use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec::Functions;
use File::Basename qw(dirname);
use Try::Tiny;

plan tests => 20;
use_ok('Text::FromAny');

my $obj = Text::FromAny->new(file => pathToFile('test-basic.txt'), allowExternal => 0, allowGuess => 1);
isa_ok($obj,'Text::FromAny','Ensure Text::FromAny is correct');

is($obj->allowGuess,1,'allowGuess should be as supplied to constructor');
is($obj->allowExternal,0,'allowExternal should be as supplied to constructor');

# State
is($obj->_readState,undef,'Should have no read state by default');
ok($obj->text,'Text read OK');
is($obj->_readState,'0-1','Read stat should be 0-1');
ok($obj->_content,'(1) Content should exist');
ok($obj->text,'Text re-read OK');

$obj->allowExternal(1);
is($obj->allowExternal,1,'allowExternal should have changed');
is($obj->_readState,'0-1','Read state should be unchanged');
ok($obj->text,'Text read OK');
is($obj->_readState,'1-1','Read state should be changed to 1-1');
ok($obj->_content,'(2) Content should exist');

$obj->allowGuess(0);
is($obj->allowGuess,0,'allowGuess should have changed');
is($obj->_readState,'1-1','Read state should be unchanged');
ok($obj->text,'Text read OK');
is($obj->_readState,'1-0','Read state should be changed to 1-1');
ok($obj->_content,'(3) Content should exist');

# Other
try
{
	$obj->file('null');
	fail('Should not be allowed to change file during runtime');
}
catch
{
	ok(1);
};

sub pathToFile
{
	my $file = shift;
	my @paths = (dirname(__FILE__), $FindBin::RealBin);
	my @subPaths = (curdir(), 'data', catfile('t/data'));
	foreach my $p (@paths)
	{
		foreach my $e (@subPaths)
		{
			my $try = catfile($p,$e,$file);
			if (-e $try)
			{
				return $try;
			}
		}
	}
	return undef;
}
