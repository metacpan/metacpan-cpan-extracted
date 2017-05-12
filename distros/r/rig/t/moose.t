use Test::More;
use strict;

eval { require Moose };
plan skip_all => "Moose not installed" if $@; 

BEGIN {
    sub rig::task::t_moose::rig {
        { use => [ 'Moose', ] }
    };
}

package TMoose; {
	use rig 't_moose';
	has 'name' => ( is=>'rw', isa=>'Str' );
}

package main;
my $obj = TMoose->new(name=>'test');
is( $obj->name, 'test', 'moose attrib ok' );

done_testing;
