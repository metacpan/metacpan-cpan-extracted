use strict;
use warnings;

use Test::More tests => 3;

use Test::Run::Base;

package MyTestRun::Plug::Iface;

package MyTestRun::Pluggable;

use Moose;
extends("Test::Run::Base::PlugHelpers");

use MRO::Compat;

sub BUILD
{
    my $self = shift;

    $self->register_pluggable_helper(
        {
            id => "myplug",
            base => "MyTestRun::Plug::Base",
            collect_plugins_method => "_my_plugin_collector",
        }
    );
}

sub _my_plugin_collector
{
    return
    [
        "MyTestRun::Plug::P::One",
        "MyTestRun::Plug::P::Two",
    ];
}

sub helpers_base_namespace
{
    my $self = shift;

    return "MyTestRun::Pluggable::Helpers";
}

package main;

use lib "./t/lib";

{
    my $main_obj = MyTestRun::Pluggable->new({});

    my $obj = $main_obj->create_pluggable_helper_obj(
        {
            id => "myplug",
            args =>
            {
                first => "Aharon",
                'last' => "Smith",
            },
        }
    );

    # TEST
    isa_ok ($obj, $main_obj->calc_helpers_namespace("myplug"));

    # TEST
    is ($obj->my_calc_first(),
        "First is {{{Aharon}}}",
    );

    # TEST
    is ($obj->my_calc_last(),
        "If you want the last name, it is: Smith"
    );
}
