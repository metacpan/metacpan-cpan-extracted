#!/ford/thishost/unix/div/ap/bin/perl -w

use blib;
use strict;

use X11::Motif;
use X11::Xbae;

my $label_font = '-*-helvetica-bold-r-*-*-*-180-*-*-*-*-*-*';
my $input_font = '-*-courier-medium-r-*-*-*-180-*-*-*-*-*-*';

my $num_columns = 26;
my $num_rows = 100;
my $default_column_width = 15;

my $cur_row = 0;
my $cur_col = 0;

my $toplevel;
my $formula_label;
my $formula;
my $table;

my @cell = ();

# --------------------------------------------------------------------------------

package ValueCell;

use Carp;

my $keep_history = 0;
my $downstream_cell;

sub new {
    my($self) = shift;
    my($class) = ref($self) || $self;
    my($col, $row) = @_;

    bless { 'feeds' => [],
	    'value' => "",
	    'row' => $row,
	    'col' => $col,
	    'formula' => "''",
	    'active' => 0,
	    'thunk' => undef }, $class;
}

sub is_active {
    my($self) = shift;
    $self->{'active'};
}

sub set_active {
    my($self) = shift;
    $self->{'active'} = $_[0];
}

sub value {
    my($self) = shift;
    $self->{'value'};
}

sub formula {
    my($self) = shift;
    $self->{'formula'};
}

sub feeds {
    my($self) = shift;
    push @{$self->{'feeds'}}, $_[0];
}

sub recompute {
    my($self) = shift;
    if (defined $self->{'thunk'}) {
	eval { $self->{'value'} = &{$self->{'thunk'}}() };
	foreach my $other (@{$self->{'feeds'}}) {
	    $other->recompute();
	}
    }
    X::bae::XbaeMatrixSetCell($table, $self->{'row'}, $self->{'col'}, $self->{'value'});
}

sub set_formula {
    my($self) = shift;
    my($f) = @_;
    my($v, $t);

    if ($f =~ m|^\s*=|) {
	$t = $f;
	$t =~ s|^\s*=\s*||;
	$t = eval "sub { $t }";
	if (defined $t) {
	    $keep_history = 1;
	    $downstream_cell = $self;
	    eval { $v = &{$t}() };
	    $keep_history = 0;
	}
	if (!defined $v) {
	    $v = 'undef';
	}
    }
    elsif ($f =~ m|^\s*[+-]?\.?\d|) {
	$f = $f + 0;
	$v = $f;
    }
    elsif ($f =~ m|^\s*\'|) {
	$v = $f;
	$v =~ s|^\s*\'||;
	$v =~ s|(.*)\'\s*$|$1|;
    }
    else {
	$v = $f;
	$f = "'$f'";
    }

    $self->{'formula'} = $f;
    $self->{'thunk'} = $t;
    $self->{'value'} = $v;

    foreach my $other (@{$self->{'feeds'}}) {
	$other->recompute();
    }

    $v;
}

sub canonicalize_cell_id {
    my($col, $row) = @_;

    if (!defined $row) {
	if ($col =~ /^-?(\w)(\d+)$/) {
	    $col = ord(uc $1) - ord('A');
	    $row = $2;
	}
	else {
	    croak "bad cell name";
	}
    }
    else {
	if ($col =~ /^-?([a-zA-Z])$/) {
	    $col = ord(uc $1) - ord('A');
	}
	else {
	    $col = -$col if ($col < 0);
	}
	$row = -$row if ($row < 0);
    }

    ($col, $row);
}

sub V {
    my($col, $row) = @_;

    ($col, $row) = canonicalize_cell_id($col, $row);
    if ($keep_history) {
	$cell[$col][$row]->feeds($downstream_cell);
    }

    $cell[$col][$row]->value;
}

sub sum {
    my($from, $to) = @_;

    my($from_col, $from_row) = canonicalize_cell_id($from);
    my($to_col, $to_row) = canonicalize_cell_id($to);

    my $t = 0;
    my $col;
    my $row;

    for ($col = $from_col; $col <= $to_col; ++$col) {
	for ($row = $from_row; $row <= $to_row; ++$row) {
	    $t += V($col, $row);
	}
    }

    $t;
}

# --------------------------------------------------------------------------------

package main;

$toplevel = X::Toolkit::initialize("Example");
change $toplevel -title => 'Perl/Xbae Spreadsheet';

$toplevel->set_inherited_resources("*fontList" => $label_font,
				   "*XmTextField.fontList" => $input_font);

my $form = give $toplevel -Form, -horizontalSpacing => 5, verticalSpacing => 5;

my $menubar = give $form -MenuBar;
my $menu = give $menubar -Menu, -name => 'File';
	give $menu -Button, -text => 'Save', -command => \&do_save_file;
	give $menu -Button, -text => 'Load', -command => \&do_load_file;
	give $menu -Separator;
	give $menu -Button, -text => 'Quit', -command => sub { exit };

$formula_label = give $form -Label,
			-text => 'V(0, 0):',
			-width => 100,
			-recomputeSize => X::False,
			-alignment => X::Motif::XmALIGNMENT_END;

$formula = give $form -Field,
			-command => \&do_set_formula;

{
    my @column_labels = ();
    my @column_widths = ();
    my @column_alignments = ();
    my @row_labels = ();
    my $col;
    my $row;

    for ($row = 0; $row < $num_rows; ++$row) {
	push @row_labels, $row;
    }

    for ($col = 0; $col < $num_columns; ++$col) {
	push @column_labels, chr($col + ord('A'));
	push @column_widths, $default_column_width;
	push @column_alignments, 'alignment_center';

	for ($row = 0; $row < $num_rows; ++$row) {
	    $cell[$col][$row] = new ValueCell($col, $row);
	}
    }

    $table = give $form -Matrix,
			-labelFont => $label_font,
			-fontList => $input_font,

			-rows => $num_rows,
			-visibleRows => 8,
			-rowLabels => join(', ', @row_labels),
			-horizontalScrollBarDisplayPolicy => X::bae::XmDISPLAY_STATIC,

			-columns => $num_columns,
			-visibleColumns => 4,
			-columnLabels => join(', ', @column_labels),
			-columnWidths => join(', ', @column_widths),
			-columnLabelAlignments => join(', ', @column_alignments),
			-verticalScrollBarDisplayPolicy => X::bae::XmDISPLAY_STATIC,

			-cellHighlightThickness => 2,
			-cellShadowThickness => 2,
			-cellMarginWidth => 0,
			-cellMarginHeight => 3,
			-gridType => 'grid_shadow_out',

			-enterCellCallback => \&do_enter_cell,
			-leaveCellCallback => \&do_leave_cell;
}

my $exit_button = give $form -Button,
			-text => ' Exit ',
			-command => sub { exit };

constrain $menubar -top => [-form, 0], -left => [-form, 0], -right => [-form, 0];
constrain $formula_label -top => $menubar, -left => -form;
constrain $formula -top => $menubar, -left => $formula_label, -right => -form;
constrain $table -top => $formula, -left => -form, -right => -form, -bottom => $exit_button;
constrain $exit_button -right => -form, -bottom => -form;

handle $toplevel;

# --------------------------------------------------------------------------------

sub do_set_formula {
    my($w, $client, $call) = @_;

    my $obj = $cell[$cur_col][$cur_row];

    if ($obj && $obj->is_active) {
	X::bae::XbaeMatrixSetCell($table, $cur_row, $cur_col,
				  $obj->set_formula(query $w -text));
	$obj->set_active(0);
    }
}

sub do_enter_cell {
    my($w, $client, $call) = @_;

    $cur_col = $call->column;
    $cur_row = $call->row;

    my $obj = $cell[$cur_col][$cur_row];
    my $f = $obj->formula;

    change $formula_label -text => "V($cur_col,$cur_row):";
    change $formula -text => $f;

    X::bae::XbaeMatrixSetCell($w, $cur_row, $cur_col, $f);

    $obj->set_active(1);
}

sub do_leave_cell {
    my($w, $client, $call) = @_;

    $cur_col = $call->column;
    $cur_row = $call->row;

    my $obj = $cell[$cur_col][$cur_row];

    if ($obj->is_active) {
	$call->value($obj->set_formula($call->value));
	$obj->set_active(0);
    }
}

sub do_save_file {
    my $col;
    my $row;
    my $obj;

    if (open(OUTPUT, "> data/sc.dat")) {
	for ($col = 0; $col < $num_columns; ++$col) {
	    for ($row = 0; $row < $num_rows; ++$row) {
		$obj = $cell[$col][$row];
		if ($obj && $obj->formula ne "''") {
		    print OUTPUT "$col,$row,", $obj->formula, "\n";
		}
	    }
	}
	close(OUTPUT);
    }
}

sub do_load_file {
    my $col;
    my $row;

    if (open(INPUT, "< data/sc.dat")) {
	while (<INPUT>) {
	    if (/(\d+),(\d+),(.*)/) {
		$col = $1;
		$row = $2;
		X::bae::XbaeMatrixSetCell($table, $row, $col, $cell[$col][$row]->set_formula($3));
	    }
	}
	close(INPUT);
    }
}
