BEGIN {
    sub rig::task::t_moose::use {
        { use => [
            'Moose', 'MooseX::HasDefaults::RO', 
        ]
        }
    };
}

use Test::More;
{ package TMoose;
use rig 't_moose';
has 'name' => (  isa=>'Str' );

}

package main;
my $obj = TMoose->new(name=>'test');
is( $obj->name, 'test', 'moose attrib ok' );

done_testing;
