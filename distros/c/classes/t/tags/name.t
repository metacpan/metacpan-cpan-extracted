# $Id: name.t 113 2006-08-13 05:42:19Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 29;
}

lives_ok( sub {
    use classes type=>'dynamic';
    classes name=>'name4', new=>'classes::new_only';
    classes {name=>'name6', new=>'classes::new_only'};
    use classes name=>'name1', new=>'classes::new_only';
    use classes; classes name=>'name2', new=>'classes::new_only';
    use classes name=>'name3', new=>'classes::new_only';
    use classes {name=>'name5', new=>'classes::new_only'};
    use classes {'name'=>'name7', new=>'classes::new_only'};
} );

use classes::Test ':all';
for (1..7) { is_classes 'name'.$_ } 



