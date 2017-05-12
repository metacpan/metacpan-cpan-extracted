
use Test::More;

#license_ok   => { base=> $ENV{PWD} =~ m#\/t$#  ? '..' : '.' , actions=>['fix']} ,
#copyright_ok => { base=> $ENV{PWD} =~ m#\/t$#  ? '..' : '.' , actions=>['fix']} ,
use Test::Legal -core => { base=> $ENV{PWD} =~ m#\/t$#  ? '..' : '.' , actions=>['fix']}  ;

BEGIN { can_ok 'main',$_   for qw/ license_ok copyright_ok / }

BEGIN{
	use namespace::clean;
	no namespace::clean;
}

use Test::More;

BEGIN { ok ! UNIVERSAL::can( 'main',$_ ),  "removed $_"  for qw/ copyright_ok license_ok / }
BEGIN { $::dir  = $ENV{PWD} =~ m#\/t$#  ? '..' : '.' ; }

use Test::Legal  'copyright_ok',
	             'license_ok',
                 defaults     => { base=> $::dir, actions => [qw/ fix /] }
;         

can_ok 'main',$_   for qw/ license_ok copyright_ok/;

license_ok;
copyright_ok;;
