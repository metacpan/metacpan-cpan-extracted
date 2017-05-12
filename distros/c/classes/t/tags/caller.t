# $Id: caller.t 147 2008-03-08 16:04:33Z rmuhle $

no strict;
no warnings;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 16;
}

lives_ok( sub {
    package caller_test1;
    use classes new=>'classes::new_only';
});

# less common, but still valid
lives_ok( sub {
    package caller_test2;
    use classes new=>'classes::new_only', type=>'dynamic';
    classes();
});

use classes::Test ':all';
for (1..2) { is_classes 'caller_test'.$_ } 

# possible misuse does not defin caller and also 'name'ed class
lives_ok( sub {
    package caller_test3;
    use classes name=>'someother', new=>'classes::new_only';
});

is_classes someother;
ok !caller_test3->can('new');
