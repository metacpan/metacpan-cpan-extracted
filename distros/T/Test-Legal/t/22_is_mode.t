#use Test::t ;

use Test::More;

use Test::Legal license_ok=>{ base=> ($ENV{PWD} =~ m#\/t$#)  ? '..' : '.',
                              actions => [qw/ noop /] ,
                 } ,           
;                

*_values = \& Test::Legal::_values ;
*_in_mode = \& Test::Legal::_in_mode ;

can_ok 'Test::Legal','_in_mode' ;

my ($mode,$arg) = license_ok;

ok _in_mode($arg,'noop');
ok ! _in_mode($arg,'fix');
ok ! _in_mode($arg,'');
ok ! _in_mode($arg,'something strange');
ok ! _in_mode($arg,);
