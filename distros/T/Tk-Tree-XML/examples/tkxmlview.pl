#!/usr/bin/perl -w

# An XML viewer using Tk::Tree::XML.

# Copyright (c) 2008 José Santos. All rights reserved.
# This program is free software. It can be redistributed and/or modified under 
# the same terms as Perl itself.

use strict;

use Tk;
use Tk::Table;
use Tk::Tree::XML;

die "Syntax: $0 <file.xml>\n" unless (scalar @ARGV == 1);

my $xml_filename = shift;
my ($FOREGROUND, $BACKGROUND) = ("black", "#FFFFFF");
my ($attrs_table, $pcdata_textarea);

my $top = MainWindow->new;

my $xml_tree = $top->ScrolledXML(
	-background => $BACKGROUND, -foreground => $FOREGROUND, -height => 20, 
);
$xml_tree->configure(-browsecmd => sub {
	if ($xml_tree->is_mixed()) {
		# mixed element => update attrs table and clear/disable pcdata text
		update_table($attrs_table, $xml_tree->get_attrs);
		$pcdata_textarea->delete("1.0", "end");
		$pcdata_textarea->configure(-state => "disable");
	} else {
		# pcdata element => clear attrs table and enable/update pcdata text
		update_table($attrs_table, ());
		$pcdata_textarea->configure(-state => "normal");
		$pcdata_textarea->delete("1.0", "end");
		$pcdata_textarea->insert("end", $xml_tree->get_text);
	}
});
$xml_tree->load_xml_file($xml_filename);

# XML attributes (name/value) table (for currently selected element in tree)
$attrs_table = $top->Table(
	-columns => 2, -rows => 3, -scrollbars => 'ne', 
	-background => $BACKGROUND, -foreground => $FOREGROUND, 
);
$attrs_table->put(0, 0, ' ' x 40 . 'Name' . ' ' x 40);
$attrs_table->put(0, 1, ' ' x 40 . 'Value' . ' ' x 40);

# PCDATA text area (for currently selected element in tree if PCDATA)
$pcdata_textarea = $top->Text(
	-height => 10, -background => $BACKGROUND, -foreground => $FOREGROUND, 
);

# bottom area containing the exit button
my $bottom_area = $top->Frame;

# exit button
my $exit_button	= $top->Button(
	-text => 'Exit', #-command => \&exit, 
	-command => sub {exit;}, 
	-background => $BACKGROUND, -foreground => $FOREGROUND, 
);

# pack gui components
$xml_tree->pack(-side => 'top', -fill => 'x', -expand => 1);
$attrs_table->pack(-side => 'top', -fill => 'both', -expand => 0);
$pcdata_textarea->pack(-side => 'top', -fill => 'x', -expand => 0);
$bottom_area->pack(-side => 'top', -fill => 'x', -expand => 0);
$exit_button -> pack(-side => 'right', -in => $bottom_area->parent, 
	-fill => 'none', -expand => 0
);

MainLoop;

sub update_table {	# clear and update table with data
	my ($table, %data) = @_;
	my $row = 0;
	foreach (keys %data) {
		$table->put(++$row, 0, &make_cell($_));
		$table->put($row, 1, &make_cell($data{$_}));
	}
	for ($row + 1 .. $table->totalRows) {
		$table->put($_, 0, '');
		$table->put($_, 1, '');
	}
}

sub make_cell {	# make table cell
	(my $cell = $attrs_table->Entry(-relief => 'sunken'))->insert('end', shift);
	$cell
}
