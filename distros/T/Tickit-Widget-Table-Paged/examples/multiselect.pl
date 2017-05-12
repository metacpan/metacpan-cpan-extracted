
#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Table::Paged;
use Tickit::Widget::VBox;
use Tickit::Widget::Static;

Tickit::Style->load_style(<<'EOF');
Table::Paged {
 fg: "white";
 header-fg: "red";
 header-b: true;
 highlight-fg: "white";
 highlight-b: true;
 highlight-bg: 18;
 scrollbar-fg: "black";
}
EOF
my $output = Tickit::Widget::Static->new(text => 'Hit enter');
my $tbl = Tickit::Widget::Table::Paged->new(
	multi_select => 1,
	on_activate => sub {
		my ($indices, @data) = @_;
		my ($highlight, @selected) = @$indices;
		$output->set_text("Highlight: $highlight, selected: " . join(',', @selected));
	}
);
$tbl->{row_offset} = 0;
$tbl->add_column(
	label => 'Left',
	align => 'left',
	width => 8,
);
$tbl->add_column(
	label => 'Second column',
	align => 'left'
);
$tbl->add_column(
	label => 'Right column',
	align => 'right'
);

$tbl->add_row(sprintf('line%04d', $_), sprintf("col2 line %d", $_), "third column") for 1..200;
my $vbox = Tickit::Widget::VBox->new;
$vbox->add($tbl, expand => 1);
$vbox->add($output);
Tickit->new(root => $vbox)->run;

