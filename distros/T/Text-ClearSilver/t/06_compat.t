#!perl -w

# This test partly comes from ClearSilver/perl/test.pl

use strict;
use Test::More;

use if !$ENV{TEST_ORIGINAL}, 'Text::ClearSilver::Compat';

use Test::Requires qw(ClearSilver);
use Test::Requires qw(Data::ClearSilver::HDF);


note "Testing with ", exists $INC{'Text/ClearSilver.pm'}
    ? 'Text::ClearSilver'
    : 'the original ClearSilver';

foreach (1 .. 2){
    note($_);
    my $hdf = ClearSilver::HDF->new();
    isa_ok $hdf, "ClearSilver::HDF";

    $hdf->readFile("t/data/basic.hdf");

    my $lev2 = $hdf->getObj("TopNode.2nd1");
    ok $lev2, "get_obj";

    is $lev2->objName, "2nd1", "obj_name";

    my $lev3 = $lev2->objChild;
    ok $lev3, "obj_child";

    is $lev3->objName,  "Entry1";
    is $lev3->objValue, "value1", "obj_value";

    my $next = $lev3->objNext;
    ok $next, "obj_next";

    is $next->objName, "Entry2";
    is $next->objValue, "value2";

    $lev2 = $hdf->getChild("TopNode.2nd1");
    ok $lev2, "get_child";

    $hdf->setValue("Data.1", "Value1");
    is $hdf->getValue("Data.1", ''), "Value1", "set_value/get_value";

    is $hdf->getValue("No_Such_Value", ''), '', "no such node";
    is $hdf->getValue("No_Such_Value", "default"), "default", "no such node/default value";

    my $copy = ClearSilver::HDF->new();
    $copy->copy("", $hdf);

    is $hdf->getValue("Data.1", ''), "Value1", "copy";

    $copy->setSymlink("BottomNode", "TopNode");

    ok $copy->getObj("BottomNode.2nd1"), "set_symlink";
    ok !$hdf->getObj("BottomNode.2nd1"), "the original is not affected";

    $copy->removeTree("TopNode");
    ok !$copy->getObj("TopNode"), "remove_tree";
    ok !$copy->getObj("TopNode.2nd1");

    my $data = $hdf->getObj("Sort.Data");

    sub cmp_func {
        return $_[0]->objValue <=> $_[1]->objValue;
    }
    sub cmp_func_rev {
        return $_[1]->objValue <=> $_[0]->objValue;
    }

    $data->sortObj('cmp_func');
    is $data->objChild->objName, "entry3", "sort_obj";

    $data->sortObj('cmp_func_rev');
    is $data->objChild->objName, "entry1", "sort_obj";

    my $cs = ClearSilver::CS->new($hdf);
    isa_ok $cs, "ClearSilver::CS";

    $cs->parseString("<?cs var:TopNode.2nd1.Entry3 ?>");

    {
        no warnings 'uninitialized'; # the origina render() produces warnings :(
        is $cs->render, "value3", "parse_string & render";
        is $cs->render, "value3", "parse_string & render (again)";
    }

    $cs = ClearSilver::CS->new($hdf);
    $cs->parseString("foo <?cs var:TopNode.2nd1.Entry3 ?> bar");

    {
        no warnings 'uninitialized'; # the origina render() produces warnings :(
        is $cs->render, "foo value3 bar";
    }

    $cs = ClearSilver::CS->new($hdf);
    $cs->parseFile("t/data/basic.tcs");

    my $result = do {
        local $/;
        open my $in, "<", "t/data/basic.gold" or die $!;
        <$in>;
    };

    {
        no warnings 'uninitialized'; # the origina render() produces warnings :(
        is $cs->render, $result, "parse_file & render";
    }

    # D::CS::HDF
    $hdf = Data::ClearSilver::HDF->hdf({ foo => 'bar' });
    isa_ok $hdf, 'ClearSilver::HDF', 'Data::ClearSilver::HDF->hdf';
    is $hdf->getObj('foo')->objValue, 'bar';
}

done_testing;
