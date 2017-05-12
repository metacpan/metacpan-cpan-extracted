#!perl -w

use strict;

use constant HAS_ISWEAK => eval q{ use Scalar::Util qw(isweak); 1 };

use Test::More;

BEGIN{
	if(HAS_ISWEAK){
		plan tests => 3;
	}
	else{
		plan skip_all => 'requires Scalar::Util::isweak()';
	}
}

use WeakRef::Auto;

my $ref = [];
my $var = $ref;

ok !isweak($var);

autoweaken $var;
ok isweak($var);

$var = $var;
ok isweak($var);
