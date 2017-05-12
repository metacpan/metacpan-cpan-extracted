#!/usr/local/bin/perl

package Text::PORE::Table;

use Text::PORE::Object;

@Table::ISA = qw (Object);

###############################
# Constructor
###############################
sub new 
{
        my ($type) = shift;
	my ($self) = new Object(@_);

	bless $self;
	$self;
}

sub init
{
	return new(@_);
}


#############################################
# return the Html Code of this product according to the template
#############################################
sub ToHtml 
{
	my($self) = shift;
	my(%att_table) = @_;
	my $html_code = '';
	my @table_items = {};

	# get attributes 
	$self->LoadAttributes(%att_table);
	my @table_items = @{$self->{table_items}};
	my $direction = $self->GetAttribute('direction');
	if ($direction =~ /^h/i) {
		$direction = 'h';
	}
	else {
		$direction = 'v';  # default is vertical
	}
	my ($bullet, $bold, $cols, $rows);
#	my $bullet = $self->GetAttribute('bullet');
 	my $bold = $self->GetAttribute('bold');
	my $cols = $self->GetAttribute('cols');
	my $rows = $self->GetAttribute('rows');

	my $attr;

	my $table_attributes = "";
	foreach $attr ('border', 'width', 'cellspacing', 'cellpadding') {
	    if ($self->GetAttribute($attr)) {
		$table_attributes .= "$attr=" 
		    . $self->GetAttribute($attr) 
		    . " ";
	    }
	}

	my $row_attributes = "";
	foreach $attr ('align', 'valign') {
	    if ($self->GetAttribute($attr)) {
		$row_attributes .= "$attr=" 
		    . $self->GetAttribute($attr) 
		    . " ";
	    }
	}
	    
	
	if (!$cols && !$rows) {
		if ($direction eq 'h') {
			$rows = 1;
		}
		else {
			$cols = 1;
		}
	}
	if (!$rows) {
		$rows = ($#table_items+1) / $cols;
		$rows = int($rows)+1 if ($rows > int($rows));
	}
	if (!$cols) {
		$cols = ($#table_items+1) / $rows;
		$cols = int($cols)+1 if ($cols > int($cols));
	}

	
	### bullet may be an object ###
	if (%$bullet){ $bullet = $bullet->ToHtml . ' '; }

	######## multiple columns : use table ########
	my $row_start;
	$html_code = "<table $table_attributes>\n";
	my ($i,$j,$index);
	for ($i=0; $i<$rows; $i++) {
	    $html_code .= "<tr $row_attributes>";
	    if ($direction eq 'h') {
		$row_start = $i*$cols;
		if ($row_start > $#table_items) { last; }
	    }
	    for ($j=0; $j<$cols; $j++) {
		if ($direction eq 'v') {
		    $index = $j*$rows+$i;
		}
		else {
		    $index = $row_start + $j;
		}
		if ($index > $#table_items) { last; }
		if ($bold) {
		    $html_code .= "<td>$bullet<b>$table_items[$index]</b>";
		}
		else {
		    $html_code .= "<td>$bullet$table_items[$index]";
		}
	    }
	    $html_code .= "</tr>\n";
	}
	$html_code .= "</table>\n";

	return $html_code;
}       
		
1;
__END__

=head1 NAME

    Table - provides methods to display a table of items via HTML

=head1 KEY ATTRIBUTES

    table_items:	a reference to an array of strings, required
    direction:  h: items listed horizontally
		v: items listed vertically
		default: v
    cols:	number of columns to display 
    rows:	number of rows to display
    bold:	bold font? 0 = no, 1 = yes, default is 0

    border      Standard table attributes
    width
    cellspacing
    cellpadding

    align       Standard cell attributes
    valign

=head1 EXAMPLES

    use Table;

    $table_items = ['item1', 'item2', 'item3'];
    # a reference to an array of strings
   
    $table_items = ['item1', 'item2', 'item3', 'item4', 'item5','item6','item7'];
    $table3 = new Table(	'table_items'=>$table_items,
			'direction'=>'h',
			'cols'=>2, 'rows'=2,
			);
    print $table3->ToHtml;
    ## output:
    ## <table border=0>
    ## <tr><td>item1<td>item2</tr>
    ## <tr><td>item3<td>item4</tr>
    ## </table>

    $table4 = new Table(  'table_items'=>$table_items,
                        'rows'=>3,
                );
    print $table4->ToHtml;
    ## output:
    ## <table border=0>
    ## <tr><td>item1<td>item4<td>item7</tr>
    ## <tr><td>item2<td>item5</tr>
    ## <tr><td>item3<td>item6</tr>
    ## </table>

=cut
