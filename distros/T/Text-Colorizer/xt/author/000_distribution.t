
# module contents test

use strict ;
use warnings ;

 use Test::More;

BEGIN 
{
eval {
	require Test::Distribution;
	};

if($@) 
	{
	plan skip_all => 'Test::Distribution not installed';
	}
else 
	{
	import Test::Distribution;
	}
}
