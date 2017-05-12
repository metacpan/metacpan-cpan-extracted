#!perl -w

# This test partly comes from ClearSilver/perl/test.pl

use strict;
use Test::More;

use Text::ClearSilver;

foreach (1 .. 2){
    note($_);
    my $hdf = Text::ClearSilver::HDF->new();
    isa_ok $hdf, "Text::ClearSilver::HDF";

    $hdf->read_file("t/data/basic.hdf");

    isnt $hdf->dump, '', '$hdf->dump';

    my $lev2 = $hdf->get_obj("TopNode.2nd1");
    ok $lev2, "get_obj";

    is $lev2->obj_name, "2nd1", "obj_name";

    my $lev3 = $lev2->obj_child;
    ok $lev3, "obj_child";

    is $lev3->obj_name,  "Entry1";
    is $lev3->obj_value, "value1", "obj_value";

    my $next = $lev3->obj_next;
    ok $next, "obj_next";

    is $next->obj_name, "Entry2";
    is $next->obj_value, "value2";

    $lev2 = $hdf->get_child("TopNode.2nd1");
    ok $lev2, "get_child";

    $hdf->set_value("Data.1", "Value1");
    is $hdf->get_value("Data.1"), "Value1", "set_value/get_value";

    is $hdf->get_value("No_Such_Value"), undef, "no such node";
    is $hdf->get_value("No_Such_Value", "default"), "default", "no such node/default value";

    my $copy = Text::ClearSilver::HDF->new();
    $copy->copy("", $hdf);

    is $hdf->get_value("Data.1"), "Value1", "copy";

    $copy->set_symlink("BottomNode", "TopNode");

    ok $copy->get_obj("BottomNode.2nd1"), "set_symlink";
    ok !$hdf->get_obj("BottomNode.2nd1"), "the original is not affected";

    $copy->remove_tree("TopNode");
    ok !$copy->get_obj("TopNode"), "remove_tree";
    ok !$copy->get_obj("TopNode.2nd1");

    my $data = $hdf->get_obj("Sort.Data");

    $data->sort_obj(sub{ $_[0]->obj_value <=> $_[1]->obj_value });
    is $data->obj_child->obj_name, "entry3", "sort_obj";

    $data->sort_obj(sub{ $_[1]->obj_value <=> $_[0]->obj_value });
    is $data->obj_child->obj_name, "entry1", "sort_obj";

    my $cs = Text::ClearSilver::CS->new($hdf);
    isa_ok $cs, "Text::ClearSilver::CS";

    $cs->parse_string("<?cs var:TopNode.2nd1.Entry3 ?>");

    is $cs->render, "value3", "parse_string & render";
    is $cs->render, "value3", "parse_string & render (again)";

    $cs = Text::ClearSilver::CS->new($hdf);
    $cs->parse_string("foo <?cs var:TopNode.2nd1.Entry3 ?> bar");

    my $buff = '';
    open my($sout), '>', \$buff;

    $cs->render($sout);
    close $sout;

    is $buff, "foo value3 bar", "render to filehandle";

    isnt $cs->dump, "", '$cs->dump';

    $cs = Text::ClearSilver::CS->new($hdf);
    $cs->parse_file("t/data/basic.tcs");

    my $result = do {
        local $/;
        open my $in, "<", "t/data/basic.gold" or die $!;
        <$in>;
    };
    
    is $cs->render, $result, "parse_file & render";
}

done_testing;
