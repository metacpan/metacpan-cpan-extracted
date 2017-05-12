use strict;
use warnings;

use Test::More tests => 5;

use Test::Run::Base::Plugger;

package MyTestRun::Plug::Iface;

package main;

use lib "./t/lib";

{
    my $plugger = Test::Run::Base::Plugger->new(
        {
            base => "MyTestRun::Plug::Base",
            into => "MyTestRun::Plug::Iface",
        }
    );

    $plugger->add_plugins(
        [
            "MyTestRun::Plug::P::One",
            "MyTestRun::Plug::P::Two"
        ]
    );

    # TEST
    is_deeply(\@MyTestRun::Plug::Iface::ISA,
        [qw(
            MyTestRun::Plug::P::One
            MyTestRun::Plug::P::Two
            MyTestRun::Plug::Base
        )],
        "Good \@ISA for the iface class."
    );

    my $obj = $plugger->create_new({
            first => "Aharon",
            'last' => "Smith",
        });

    # TEST
    isa_ok ($obj, "MyTestRun::Plug::Iface");

    # TEST
    is ($obj->my_calc_first(),
        "First is {{{Aharon}}}",
    );

    # TEST
    is ($obj->my_calc_last(),
        "If you want the last name, it is: Smith"
    );
}

{
    my $plugger;

    eval {
        $plugger = Test::Run::Base::Plugger->new(
            {
                base => "MyTestRun::Plug::Base::Faulty",
                into => "MyTestRun::Plug::NonExist",
            }
        );
    };

    my $err = $@;

    # TEST
    like (
        $err,
        qr{Global symbol "\$x".*?Compilation failed}ms,
        "An exception was thrown (by require)."
    );
}
