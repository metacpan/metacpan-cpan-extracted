# $Id: noaccessors.t 121 2006-08-20 21:00:28Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 7;
}

lives_ok( sub {
    use classes name=>'NoAccess', new=>'classes::new_only', attrs=>['foo'], noaccessors=>1;
    use classes name=>'Access', new=>'classes::new_only', attrs=>['foo'];
}, 'noaccessors');
isa_ok my $o1 = NoAccess->new, 'NoAccess'; 
isa_ok my $o2 = Access->new, 'Access'; 
ok( !$o1->can('set_foo'));
ok( !$o1->can('get_foo'));
can_ok $o2, 'set_foo';
can_ok $o2, 'get_foo';

