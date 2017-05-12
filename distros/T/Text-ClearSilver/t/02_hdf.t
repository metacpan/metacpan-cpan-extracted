#!perl -w

use strict;
use Test::More;

use Text::ClearSilver;

foreach (1 .. 2){
    note("[$_]");

    my $hdf = Text::ClearSilver::HDF->new({foo => ['bar', 'baz', { x => 42 }, 'qux']});
    ok $hdf, 'new HDF from Perl data';

    is $hdf->get_value("foo.0"), "bar";
    is $hdf->get_value("foo.1"), "baz";
    is $hdf->get_value("foo.2.x"), 42;
    is $hdf->get_value("foo.3"),   "qux";

    my $copy = Text::ClearSilver::HDF->new( $hdf->dump );
    ok $copy, 'new HDF from string';

    is $copy->get_value("foo.0"), "bar";
    is $copy->get_value("foo.1"), "baz";
    is $copy->get_value("foo.2.x"), 42;
    is $copy->get_value("foo.3"),   "qux";

    my $buff = '';
    $copy->write_file(\$buff);
    like $buff, qr/\b foo \b/xms, "write_file with :scalar";
    is $buff, $copy->dump;

    my $cs = Text::ClearSilver::CS->new({ foo => 'bar' });
    ok $cs, "new CS from Perl data";

    $cs->parse_string('<?cs var: foo ?>');

    is $cs->render(), 'bar', 'render';

    $hdf = Text::ClearSilver::HDF->new({
            rows => { widget => { pickup_apps => [1, 2, 3] } },
            widget => { data => { pickup_apps => { rows => [4, 5, 6]  }} },
    });
    is $hdf->get_value("rows.widget.pickup_apps.1"), 2;
    is $hdf->get_value("widget.data.pickup_apps.rows.1"), 5;
}

{
    my $pair = { foo => 'bar' };
    my @data = ($pair, $pair);

    my $hdf = Text::ClearSilver::HDF->new(\@data);

    is $hdf->get_value("0.foo"), "bar";
    is $hdf->get_value("1.foo"), "bar";
}

{
    my $parent = { value => 'PARENT' };
    my $child  = { value => 'CHILD'  };

    $parent->{child} = $child;
    $child->{parent} = $parent;

    my $hdf = Text::ClearSilver::HDF->new([ $parent, $child ]);

    is $hdf->get_value("0.value"),        "PARENT";
    is $hdf->get_value("0.child.value"),  "CHILD";

    is $hdf->get_value("1.value"),        "CHILD";
    is $hdf->get_value("1.parent.value"), "PARENT";

    is $hdf->get_value("0.child.parent.value"), "PARENT";
}

done_testing;
