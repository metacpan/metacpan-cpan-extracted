#!/ford/thishost/unix/div/ap/bin/perl -w

use blib;

use strict;
use X11::Motif;
use Data::Dumper;

my $toplevel = X::Toolkit::initialize("Eval");

my $form = give $toplevel -Form;

my $input = give $form -Field, -command => \&do_eval;
my $output = give $form -Text,
		-editable => X::False,
		-rows => '10',
		-columns => 80,
		-editMode => X::Motif::XmMULTI_LINE_EDIT;

sub do_eval {
    my $v = query $input -text;
    change $output -text => join("\n", Dumper(eval $v));
}

constrain $input  -top => -form,  -bottom => -none, -left => -form, -right => -form;
constrain $output -top => $input, -bottom => -form, -left => -form, -right => -form;

handle $toplevel;
