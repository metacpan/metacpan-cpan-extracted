package Win32::Watir::Table;

use strict;
use vars qw($VERSION $warn);
$VERSION = '0.5c';

sub new {
	my $class = shift;
	my $self  = { };
	$self->{element}   = undef;
	$self->{parent}    = undef;
	$self->{table} = undef;
	$self->{row} = undef;
	$self->{cell} = undef;
	$self = bless ($self, $class);
	return $self;
}

sub rows {
	my ($self, $row_num) = @_;
	my @rows;
	if ($row_num){
		my $table_object = Win32::Watir::Table->new();
		$table_object->{parent} = $self->{parent};
		$table_object->{row} = $self->{table}->rows($row_num - 1);
		return $table_object if $table_object->{row};
	} else {
		my $rows_coll = $self->{table}->rows;
		foreach (my $n = 0; $n < $rows_coll->length; $n++){
			my $table_object = Win32::Watir::Table->new();
			$table_object->{parent} = $self->{parent};
			$table_object->{row} = $rows_coll->item($n);
			push (@rows, $table_object) if $table_object->{row};
		}
		return @rows;
	}
}

sub cells {
	my ($self, $cell_num) = @_;
	my @cells;
	if ($cell_num){
		my $table_object = Win32::Watir::Table->new();
		$table_object->{parent} = $self->{parent};
		$table_object->{cell} = $self->{row}->cells($cell_num - 1);
		return $table_object if $table_object->{cell};
	} else {
		my $cells_coll = $self->{row}->cells;
		foreach (my $n = 0; $n < $cells_coll->length; $n++){
			my $table_object = Win32::Watir::Table->new();
			$table_object->{parent} = $self->{parent};
			$table_object->{cell} = $cells_coll->item($n);
			push (@cells, $table_object) if $table_object->{cell};
		}
		return @cells;
	}
}

sub tableCells {
	my ($self, $row_num, $col_num) = @_;
	my @cells;
	if ($row_num && $col_num){
		my $row = $self->rows($row_num);
		my $cell = $row->cells($col_num) if $row;
		return $cell if $cell;
	} else {
		my $cells_coll = $self->{table}->cells;
		foreach (my $n = 0; $n < $cells_coll->length; $n++){
			my $table_object = Win32::Watir::Table->new();
			$table_object->{parent} = $self->{parent};
			$table_object->{cell} = $cells_coll->item($n);
			push (@cells, $table_object) if $table_object->{cell};
		}
		return @cells;
	}
}
	

sub getRowHavingText {
	my ($self, $string) = @_;
	my $regex_flag = 1 if ($string =~ /^?-xism:/);
	my @rows = $self->rows;
	foreach my $row (@rows){
		my @cells = $row->cells;
		foreach my $cell (@cells){
			if ($regex_flag){
				return $row if ($cell->cellText =~ $string);
			} else {
				return $row if ($cell->cellText eq $string);
			}
		}
	}
	return undef;		
}

sub cellText {
	my $self = shift;
	my $text = $self->{cell}->outertext;
	return trim_white_spaces($text);
}

sub getLink {
	my ($self, $how, $what) = @_;
	return __getElement($self, $how, $what, "a");
}

sub getImage {
	my ($self, $how, $what) = @_;
	return __getElement($self, $how, $what, "img");
}

sub getButton {
	my ($self, $how, $what) = @_;
	return __getElement($self, $how, $what, "input", "button");
}

sub getRadio {
	my ($self, $how, $what) = @_;
	return __getElement($self, $how, $what, "input", "radio");
}

sub getCheckbox {
	my ($self, $how, $what) = @_;
	return __getElement($self, $how, $what, "input", "checkbox");
}

sub getSelectList {
	my ($self, $how, $what) = @_;
	return __getElement($self, $how, $what, "select", "select-one|select-multiple");
}

sub getTextBox {
	my ($self, $how, $what) = @_;
	return __getElement($self, $how, $what, "input", "text|password");
}

sub getTextArea {
	my ($self, $how, $what) = @_;
	return __getElement($self, $how, $what, "textarea", "textarea");
}

sub __getElement {
	my ($self, $how, $what, $tag, $type) = @_;
	my $cell = $self->{cell};
	my $collection = $cell->all->tags($tag);
	my $target_element = &Win32::Watir::__getObject($collection, $how, $what, $type) if ($collection);
	my $element_object;
	if ($target_element){
		$element_object = Win32::Watir::Element->new();
		$element_object->{element} = $target_element;
		$element_object->{parent} = $self->{parent};
	} else {
		$element_object = undef;
		print "WARNING: No element is  present in the document with your specified option $how $what\n" if $warn;
	}
	return $element_object;
}
	
sub trim_white_spaces {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

1;
__END__ 
