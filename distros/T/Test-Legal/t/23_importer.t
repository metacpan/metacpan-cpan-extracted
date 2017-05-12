use Test::More;

BEGIN { $::dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat' }

use Test::Legal  '-core', 
                 defaults => { };
;

BEGIN{
	can_ok 'main','license_ok';
	can_ok 'main','copyright_ok';
}

use namespace::clean;         
no  namespace::clean;

use Test::Legal  '-core' => { -prefix => 'a_'}, 
;
BEGIN{
	can_ok 'main','a_license_ok';
	can_ok 'main','a_copyright_ok';
}
use namespace::clean;         
no  namespace::clean;

use Test::Legal  '-core'  => { actions=>['noop'],-prefix => 'b_'}, 
	             defaults => { base=>$::dir },
;
BEGIN{
	can_ok 'main','b_license_ok';
	my ($mode,$arg) =b_license_ok;
	is  $arg->{base},$::dir;
	($mode,$arg) =b_copyright_ok;;
	is  $arg->{base},$::dir;
}

use namespace::clean;         
no  namespace::clean;

use Test::Legal  '-core'  => { actions=>['noop'],-prefix => 'c_'}, 
	             defaults => { base=>$::dir , dirs=>[qw/ some /]},
;
BEGIN{
	can_ok 'main','c_license_ok';
	my ($mode,$arg) =c_license_ok;
	is  $arg->{base},$::dir;
	is_deeply  $arg->{dirs},['some'];
	($mode,$arg) =c_copyright_ok;;
	is  $arg->{base},$::dir;
	is_deeply  $arg->{dirs},['some'];
}
