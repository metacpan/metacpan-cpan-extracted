use strict ;

use Test::More tests => 15 ;
BEGIN { use_ok('autorequire') } 


use autorequire sub {
	my ($this, $f) = @_ ;
	if ($f eq 't/scalar'){
		return "package scalar ;\nsub a{1} 1 ;" ;
	}
	return undef ;
} ;

use autorequire sub {
	my ($this, $f) = @_ ;
	if ($f eq 't/file'){
		return "t/lib/t/file.pm" ;
	}
	return undef ;
} ;

BEGIN {
	my $ar = new autorequire(sub {
		my ($this, $f) = @_ ;
		if ($f eq 't/ref'){
			my $code = "package ref ;\nsub a{1} 1 ;" ;
			return \$code ;
		}
		return undef ;
	}) ;
	$ar->insert(0) ;
}

use autorequire 'main::handle' ;
BEGIN {
	eval "use handle" ;
	like($@, qr/^Can't locate/) ; #'
}
	


require 't/scalar' ;
is(scalar::a(), 1) ;
require 't/file' ;
is(file::a(), 1) ;
require 't/ref' ;
is(ref::a(), 1) ;
require t::handle ;
is(handle::a(), 1) ;

# Delete first
my $ar = $INC[0] ;
$ar->delete() ;
isnt($INC[0], $ar) ;
# Delete last
$ar = $INC[-1] ;
$ar->delete() ;
isnt($INC[-1], $ar) ;

# Now only the two first objects remain.
$ar = $INC[-2] ;
delete $INC{'t/scalar'} ;
$ar->disable() ;
eval {
	require 't/scalar' ;
} ;
like($@, qr/^Can't locate/) ; #'
pop @INC ;
{
	local $^W ;
	$ar->insert(10000) ;
	$ar->enable() ;
	require 't/scalar' ;
}


ok(autorequire->is_loaded('Test/More.pm')) ;
ok(! autorequire->is_loaded('some/module/not/loaded.pm')) ;

ok(autorequire->is_installed('Test/More.pm')) ;
ok(! autorequire->is_installed('some/module/not/installed.pm')) ;

isa_ok(autorequire->is_loaded('Test/More.pm', open => 1), 'IO::Handle') ;
like(autorequire->is_loaded('Test/More.pm', slurp => 1), qr/package\s+Test::More/) ;



sub handle {
	my ($this, $f) = @_ ;
	if ($f eq 't/handle.pm'){
		open(my $h, "<t/lib/$f") or die("Can't open 't/lib/$f' for reading: $!'") ;
		return $h ;
	}
	return undef ;
}
