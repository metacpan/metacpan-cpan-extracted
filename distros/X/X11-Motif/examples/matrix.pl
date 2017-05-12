#!/ford/thishost/unix/div/ap/bin/perl -w

use blib;

use strict;
use X11::Motif;
use X11::Xbae;

my $label_font = '-*-helvetica-bold-r-*-*-*-180-*-*-*-*-*-*';
my $input_font = '-*-courier-medium-r-*-*-*-180-*-*-*-*-*-*';

my $toplevel = X::Toolkit::initialize("Example");

change $toplevel -title => 'Duct File Uploader';

$toplevel->set_inherited_resources("*fontList" => $label_font,
				   "*XmTextField.fontList" => $input_font);

my $form = give $toplevel -Form, -horizontalSpacing => 5, verticalSpacing => 5;

my $part_num_label = give $form -Label,
			-text => ' Part Number:',
			-alignment => X::Motif::XmALIGNMENT_END;
my $part_desc_label = give $form -Label,
			-text => 'Description:',
			-rightOffset => 0,
			-alignment => X::Motif::XmALIGNMENT_END;

my $part_num = give $form -Field;
my $part_desc = give $form -Field,
			-traversalOn => X::False,
			-editable => X::False,
			-cursorPositionVisible => X::False;

my $find_button = give $form -Button,
			-text => ' Find Part ',
			-command => \&do_find_part;

my $table = give $form -Matrix,
			-rows => 15,
			-visibleRows => 5,
			-columns => 2,
			-columnLabels => 'Part In Assembly, Duct File',
			-columnWidths => '30, 50',
			-labelFont => $label_font,
			-fontList => $input_font,
			-cellHighlightThickness => 2,
			-cellShadowThickness => 2,
			-cellMarginWidth => 0,
			-cellMarginHeight => 3,
			-gridType => 'grid_shadow_out',
			-verticalScrollBarDisplayPolicy => X::bae::XmDISPLAY_STATIC,
			-defaultActionCallback => \&do_choose_duct_file;

my $exit_button = give $form -Button,
			-text => ' Exit ',
			-command => sub { exit };
my $upload_button = give $form -Button,
			-text => ' Upload Duct Files ',
			-command => \&do_upload_duct_files;

constrain $part_num_label -top => -form, -left => -form;
constrain $find_button -top => -form, -right => -form;
constrain $part_desc_label -top => $part_num, -left => -form, -align_right => $part_num_label ;

constrain $part_num -top => -form, -left => $part_num_label, -right => $find_button;
constrain $part_desc -top => $part_num, -left => $part_num_label, -right => -form;

constrain $table -top => $part_desc, -left => -form, -right => -form, -bottom => $upload_button;

constrain $upload_button -right => -form, -bottom => -form;
constrain $exit_button -right => $upload_button, -bottom => -form;

handle $toplevel;

sub do_find_part {
    my($w) = @_;
}

sub do_upload_duct_files {
    my($w) = @_;
}

sub do_choose_duct_file {
    my($w, $client, $call) = @_;

    if (defined($call)) {
	print "clicked on cell [", $call->row, ", ", $call->column, "]\n";
    }
}
