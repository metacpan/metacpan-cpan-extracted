######################################## SOH ###########################################
## Function : Additional Tk Class for Listbox-type HList with Data per Item, Sorting
##
## Copyright (c) 2002-2013 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History  : V1.00	10-Dec-2002 	Class adopted from ExtListbox. MK
##            V1.01 10-Jan-2003 	Added -databackground(color). MK
##            V1.02 19-Jan-2004 	Added numeric sorting for column 2. MK
##            V1.1  13-May-2005 	Added missing data for sorting in column 2. MK
##            V1.2  23-Oct-2008 	Bugfix: Deleting the first entry messed the reverse func. MK
##            V2.0  11-Sep-2009 	Rewrite: Added multi-Column and Header support. MK
##            V2.1  14-Sep-2009 	Bugfix: Solved problems with memory leak due Itemstyle. MK
##            V2.2  08-Apr-2013 	Bugfix: Retrieval of data this is a ref-to-* is lost (flattened in return-list). MK
##
######################################## EOH ###########################################
package Tk::DHList;

##############################################
### Use
##############################################
use Tk::HList;
use Tk::ItemStyle;
use Tk qw(Ev);

use strict;
use Carp;

use vars qw ($VERSION);
$VERSION = '2.2';

use base qw (Tk::Derived Tk::HList);

use constant DEFAULT_COLUMN_SEPARATOR	=> '|';
########################################################################
Construct Tk::Widget 'DHList';

# Class Variables
my ($DataStyles, $HeaderStyle);

#---------------------------------------------
# internal Setup function
#---------------------------------------------
sub ClassInit
{
    my ($class, $window) = @_;

    $class->SUPER::ClassInit($window);

	# Note these keyboard-Keys are only usable, if the widget gets 'focus'
	$window->bind ($class, '<Control-Key-bracketleft>', [\&viewtype, 'withdata']);
	$window->bind ($class, '<Control-Key-bracketright>', [\&viewtype, 'normal']);
	# Update the view after mapping
	$window->bind ($class, '<Map>', \&map_cb);
}

#---------------------------------------------
# internal Setup function
#---------------------------------------------
sub CreateArgs
{
    my ($class, $window, $args) = @_;

	# Convenience function - calculate coulncount from the headline
	if ($args->{-headline} and not $args->{-columns}) {
		my $columnseparator = $args->{-columnseparator} || DEFAULT_COLUMN_SEPARATOR();
		my $pattern = quotemeta $columnseparator;
		@_ = split(/$pattern/, $args->{-headline});
	    $args->{-columns} = scalar @_;
	}

 	# Necessarily Set/Patch Column-Count to accept a multi-purpose data-column
	$args->{-columns} = 1 unless $args->{-columns};
	$args->{-columns}++;
	
	$class->SUPER::CreateArgs($window, $args);
}

#---------------------------------------------
# internal Setup function
#---------------------------------------------
sub Populate
{
	# Parameters
    my ($this, $args) = @_;		

	# Locals
	my ($headline, $headerforeground, $headerbackground,$headerfont, $headerrelief,
		$data_background, $datastyle, $headerstyle);

	$headline			= delete $args->{-headline}; $args->{-header} = 1 if $headline; # Convenience
	$headerforeground	= delete $args->{-headerforeground};
	$headerbackground	= delete $args->{-headerbackground};
	$headerfont 		= delete $args->{-headerfont} || 'Helvetica -10';
	$headerrelief		= delete $args->{-headerrelief} || 'groove';

	$data_background = delete $args->{-databackground};
	$data_background = $this->cget ('-background') unless defined $data_background;
	
	# Unique Style generation
	$datastyle = delete $args->{-datastyle};
	$datastyle = $this->toplevel->ItemStyle('text', -anchor => 'e', -background => $data_background) unless $datastyle;
	$headerstyle = delete $args->{-headerstyle};
	$headerstyle = $this->toplevel->ItemStyle('window', -padx => 0, -pady => 0) unless $headerstyle;

	# Check whether we want numeric sorting
	$this->{m_numeric_primary_sort}   = delete $args->{-numeric_primary_sort} || 0;
	$this->{m_numeric_secondary_sort} = delete $args->{-numeric_secondary_sort} || 0;
	
	# Reroute any size_call_back
	my $sizecmd = delete $args->{-sizecmd} || sub { 1 };
	$args->{-sizecmd} = [\&resize_cb, $this ];

	#INvoke Superclass fill func
    $this->SUPER::Populate($args);

	$this->ConfigSpecs(
	#default listbox options
 		-highlightthickness		=> [['SELF', 'PASSIVE'], 'HighlightThickness', 'highlightthickness', '2'],
		-pady					=> [['SELF', 'PASSIVE'], 'pady', 'Pad', '0'],
    	-sizecmd_cb 	        => ['CALLBACK',undef, undef, $sizecmd],
	# new, additional optiona
		-viewtype				=> ['METHOD', 'ViewType', 'viewType', undef],		
 		-datastyle				=> [['SELF', 'PASSIVE'], 'DataStyle', 'datastyle', $datastyle],
 		-columnseparator		=> [['SELF', 'PASSIVE'], 'ColumnSeparator', 'columnseparator', DEFAULT_COLUMN_SEPARATOR],
		-databackground 		=> [['SELF','METHOD'], 'databackground', 'dataBackground', undef],		
	# define a compound setting to adress BG-changes to both, the normal AND the data column
		-bg 			  		=> [{-background => $this, -databackground => $this}, 'background', 'Background', undef],		
	);

	if ($headline) {
		### NOTE: For whatever reasons the filling of an appropriate Header-BG (and some ->cget())
		### will only work if it is done deferred ...
		$this->afterIdle( sub {
			my ($columnseparator, $pattern, $data_pos, @line, $col);
			$columnseparator = $this->cget('-columnseparator');
			$pattern = quotemeta $columnseparator;
			$data_pos  = $this->cget('-columns') - 1; 
			@line = split(/$pattern/, $headline, $data_pos);
			if (@line) {
				# Take care, if the headline is too short
				if (@line < $data_pos+1) {
					for ($col = @line; $col <= $data_pos; $col++) {
						$line[$col] = '';
					}
				}
				# Add a dummy Header Label for the DataColumn
				$line[-1] = 'DATA'; $col = 0;

				# now add ALL columns to the header-line
				foreach $pattern (@line) {
					my $headerlabel = $this->Label( -text => $pattern, -font => $headerfont,
									(-foreground => $headerforeground ? $headerforeground : $this->cget('-background')),
									$headerbackground ? (-background => $headerbackground) : () );
					$this->headerCreate($col++,
									-style => $headerstyle,
									-itemtype => 'window',
									-widget => $headerlabel, -relief => $headerrelief,
									$headerbackground ? (-headerbackground => $headerbackground) : () );
				}	
			}
		});
	}
	
	# Internal Presets
	$this->{m_viewtype} 	= 'none';	
	$this->{m_backlist} 	= {};	
	$this->{m_index} 		= 0;	
}

#---------------------------------------------
# OVERRIDE: new ADD function
#---------------------------------------------
sub add 
{    
	# Parameters
	my ($this, $path, %args) = @_;

	# Locals
	my ($data, $datastyle, @line, $col, $data_pos, $pattern);
	
	# Do we have anything at all to insert ?
	return unless defined $path;

	$this->{m_backlist}{$path} = {
				args		=> { %args },
				index		=> ++$this->{m_index},
	};

	# Prepare the data and it's style
	$data		= delete $args{-data};
	$datastyle	= delete $args{-datastyle} || $this->cget('-datastyle');
	# Some local shortcuts
	$data_pos   = $this->cget('-columns') - 1; 
	$pattern	= quotemeta $this->cget('-columnseparator');
	$col		= 0;

	# Eventually split into additional columns
	@line = split(/$pattern/, $args{-text}||'', $data_pos);

	# Create a new entry
	$this->SUPER::add($path, -data => $data);
	# now add ALL columns to the entry
	foreach $pattern (@line) {
		$args{-text} = $pattern;
		if ($col > 0) {
			delete $args{-image};
			$args{-itemtype} = 'text';
		}
		$this->SUPER::itemCreate($path, $col++, %args);
	}	

	# and a trailing column for the data
	$this->SUPER::itemCreate($path, $data_pos,
					-itemtype => 'text',
					-text => '' . ($data||''), # Note the first ''. which is necessary to cast the data ptr to text
					-style => $datastyle,
	);
	
	# Install the 'normal view after we have something on the screen
	$this->viewtype($this->{m_viewtype});
}

#---------------------------------------------
# OVERRIDE: new DELETE function
#---------------------------------------------
sub delete
{
	# Parameters
	my ($this, $what, $path) = @_;

	if ($what eq 'all') {
		# Clear the internal storage
		$this->{m_index} = 0;	
		# Delete it
		$this->SUPER::delete($what);
	}
	else {
		# Delete it from internal storage list
		delete $this->{m_backlist}{$path};
		# Delete it
		$this->SUPER::delete($what, $path);
	}
}

#---------------------------------------------
# ADD-ON: reordering function
#---------------------------------------------
sub reverse
{
	# Parameters
	my $this = shift;
	$this->_rebuild_list('reverse');
}

#---------------------------------------------
# ADD-ON: sorting function
#---------------------------------------------
sub sort
{
	# Parameters
	my ($this, $mode) = @_;

	# Locals
	my ($sort_func, $backlist, $i, $path);

	# safety check
	return unless $this->infoChildren;
	$mode = 'ascending' unless $mode;

	# Shortcut for speed
	$backlist = $this->{m_backlist};

	# sort it
	if ($mode =~ /ascending/i) {
		if ($mode =~ /data|secondary/i) {
			if ($this->{m_numeric_secondary_sort}) {
				$sort_func = sub { $backlist->{$a}{args}{-data} <=> $backlist->{$b}{args}{-data} };
			}
			else {
				$sort_func = sub { $backlist->{$a}{args}{-data} cmp $backlist->{$b}{args}{-data} };
			}
		}
		else {
			if ($this->{m_numeric_primary_sort}) {
				$sort_func = sub { $backlist->{$a}{args}{-text} <=> $backlist->{$b}{args}{-text} };
			}
			else {
				$sort_func = sub { $backlist->{$a}{args}{-text} cmp $backlist->{$b}{args}{-text} };
			}
		}
	}
	elsif ($mode =~ /descending/i) {
		if ($mode =~ /data|secondary/i) {
			if ($this->{m_numeric_secondary_sort}) {
				$sort_func = sub { $backlist->{$b}{args}{-data} <=> $backlist->{$a}{args}{-data} };
			}
			else {
				$sort_func = sub { $backlist->{$b}{args}{-data} cmp $backlist->{$a}{args}{-data} };
			}
		}
		else {
			if ($this->{m_numeric_primary_sort}) {
				$sort_func = sub { $backlist->{$b}{args}{-text} <=> $backlist->{$a}{args}{-text} };
			}
			else {
				$sort_func = sub { $backlist->{$b}{args}{-text} cmp $backlist->{$a}{args}{-text} };
			}
		}
	}
	else {
		return;
	}
	
	# sort it
	foreach $path (sort $sort_func keys %$backlist) {
		$backlist->{$path}{index} = ++$i;
	}

	# apply sorting to the list
	$this->_rebuild_list();
}

#---------------------------------------------
# INTERNAL: rebuild list function
#---------------------------------------------
sub _rebuild_list 
{
	# Parameters
	my ($this, $reverse_mode) = @_;

	# Locals
	my ($path, $backlist, $sort_func);

	# safety check
	return unless $this->infoChildren;

	# Store the backlist
	$backlist = $this->{m_backlist};
	$this->{m_backlist} = {};

	# Retrieve the current visability statets
	foreach $path (keys %$backlist) {
		$backlist->{$path}{hidden} = $this->infoHidden($path);
	}

	# delete it
	$this->delete('all');

	# Define a reverse-sort func
	if ($reverse_mode) {
		$sort_func = sub { $backlist->{$b}{index} <=> $backlist->{$a}{index} }
	}
	else { # just follow the indexing
	    $sort_func = sub { $backlist->{$a}{index} <=> $backlist->{$b}{index} }
	}

	# Std/Reverse refill it
	foreach $path (sort $sort_func keys %$backlist) {
		$this->add($path, %{$backlist->{$path}{args}});
		$this->hide('entry', $path) if $backlist->{$path}{hidden};
	}
}


#---------------------------------------------
# ADD-ON: do add. background changes -
# optionally update the data background too
#---------------------------------------------
sub databackground
{
	# Parameters
	my ($this, $new_background)  = @_;

	# Fetch the existing background
	my $datastyle = $this->_cget('-datastyle');
	my $background = $datastyle->cget('-background');
	$datastyle->configure('-background', $new_background) if $new_background;
	return $background;
}


#---------------------------------------------
# ADD-ON: trace any viewtype updates
# supported values are 'normal', 'withdata'
#---------------------------------------------
sub viewtype
{
	# Parameters
	my ($this, $viewtype)  = @_;

	# if we're not in a cget we might consider changing the value
	if (defined $viewtype) {
		# allow only 'normal' &  'withdata'...
		if ($viewtype =~ /withdata/i ) {
			$viewtype = 'withdata';
		}
		else {
			$viewtype = 'normal';
		}
		#print "internal viewtype is $this->{m_viewtype}\n";
		if ($this->{m_viewtype} ne $viewtype) {
			$this->{m_viewtype} = $viewtype;
			$this->setup_view();
		}
	}
	# needed for cget
	return $this->{m_viewtype};
}

#---------------------------------------------
# ADD-ON: setup_view: display function
#---------------------------------------------
sub setup_view 
{
	# Parameters
	my $this = shift;

	# Locals
	my (@bb, $needsize, $data_col, $col_size, $col);

	return unless $this->infoChildren;
	$data_col = $this->cget('-columns') - 1;

	if ($this->{m_viewtype} eq 'withdata' ) {
		$this->columnWidth($data_col, '');
		$needsize = $this->columnWidth($data_col);
		@bb = $this->infoBbox(($this->infoChildren)[0]);
		if (@bb) {
			$col_size = 0;
			for ($col = 1; $col < $data_col; $col++) {
				$col_size += $this->columnWidth($col);
			}
			$col_size = $bb[2] - $bb[0] - $col_size - $needsize;
			$col_size = 20 if $col_size < 20;
			$this->columnWidth(0, $col_size);
		}
	}
	else {
		$this->columnWidth($data_col, 0);
		$this->columnWidth(0, '');
	}
}


#---------------------------------------------
# ADD-ON: new resizxing function
#---------------------------------------------
sub resize_cb
{
	# Parameters
    my $this = shift;
	# Locals
	my (@bb, $needsize, $data_col, $col_size, $col);

	return unless $this->viewable;
	return unless $this->infoChildren;

	# Adopt the column Widths
	$this->setup_view();

	# invoke any given callback
	$this->Callback(-sizecmd_cb => $this);
}


#---------------------------------------------
# CALLBACK: update the view (type 'normal')
#           means Data-Column is invisible
#---------------------------------------------
sub map_cb
{
	# Parameters
	my $this = shift;
	$this->setup_view();
}

#---------------------------------------------
# ADD-ON: get Item and / or ItemData
# returns a scalar(first only) or an array
#---------------------------------------------
sub get_item
{
	# Parameters
	my ($this, $path) = @_;

	# get all information	
	my @items_out = $this->_get_item(3, $path);

	return wantarray ? @items_out : $items_out[0];
}
#---------------------------------------------
sub get_item_text
{
	# Parameters
	my ($this, $path) = @_;

	# get all information	
	my @items_out = $this->_get_item(1, $path);

	return wantarray ? @items_out : $items_out[0];
}
#---------------------------------------------
sub get_item_value
{
	# Parameters
	my ($this, $path) = @_;

	# get all information	
	my @items_out = $this->_get_item(2, $path);

	return wantarray ? @items_out : $items_out[0];
}
#---------------------------------------------
sub _get_item
{
	# Parameters
	my ($this, $mode, $path) = @_;

	# Locals
	my (@items_out);

	if ($mode & 1) {
		push @items_out, $this->{m_backlist}{$path}{args}{-text};
	}
	if ($mode & 2) {
		#push @items_out, $this->infoData($path);
		### NOTE: IF we use above code an existing REF in data is LOST! MKr. 2013-04-08
		my $data = $this->infoData($path);
		push @items_out, $data;
	}
	
	return wantarray ? @items_out : $items_out[0];
}

#---------------------------------------------
# ADD-ON: Get Current Selected Text AND/OR associated Data
#---------------------------------------------
sub getcurselection
{
	# Parameters
	my $this = shift;

	# get all information	
	my @items_out = $this->_getcurselection(3);

	return wantarray ? @items_out : $items_out[0];
}
#---------------------------------------------
sub getcurselection_text
{
	# Parameters
	my $this = shift;

	# get all information	
	my @items_out = $this->_getcurselection(1);

	return wantarray ? @items_out : $items_out[0];
}
#---------------------------------------------
sub getcurselection_value
{
	# Parameters
	my $this = shift;

	# get all information	
	my @items_out = $this->_getcurselection(2);

	return wantarray ? @items_out : $items_out[0];
}

#---------------------------------------------
sub _getcurselection
{
	# Parameters
	my ($this, $mode) = @_;

	# Locals
	my (@items_out, @selitems, $path);

	# get index information	
	@selitems = $this->infoSelection;
 	foreach $path (@selitems) {
		push @items_out, $this->_get_item($mode, $path);
 	}
	return wantarray ? @items_out : $items_out[0];
}


########################################################################
1;
__END__


=head1 NAME

Tk::DHList - A HList widget with a visible/hidden data column

=head1 SYNOPSIS

    use Tk;
    use Tk::DHList

    my $mw = MainWindow->new();


    #my $listbox = $mw->DHList(
    my $listbox = $mw->Scrolled('DHList', 
        -scrollbars          => 'e',
        -cursor              => 'right_ptr',
        -relief              => 'sunken',
        -borderwidth         => '2',
        -width               => '10',  # columns
        -height              => '15',  # lines
        -background          => 'orange',
        -selectmode          => 'single',
		-sizecmd             => \&size_cb,
		#new options
        -viewtype            => 'withdata',
		-datastyle           => $datastyle;
		-databackground      => 'skyblue',
        -numeric_primary_sort   => '0',
        -numeric_secondary_sort => '1',
    )->pack;

	
    Tk::MainLoop;
	
    sub add_data
    {
        # 1) insert a complete array with texts and data, keys become 'visible' entry,
        # values are stored as data and are shown in transient column.
        $listbox->add($key, -data => 'i02',
					-itemtype => 'imagetext',
					-text => 'Dummy',
					-image => $xpms{dummy},
					#-datastyle => $datastyle,
		);
   }
   sub size_cb
   {
      print "we have resized\n";
   }

=head1 DESCRIPTION

A HList derived widget that offers several add-on functions like sorting, reordering and inserting/retrieving of item text & data, 
suitable for perl Tk800.x (developed with Tk800.024).

You can insert item-texts or item-text/-value pair/s into the DHList widget with
the standard-like  B<add()> method .
The B<delete> removes visible list-items as well as the associated data.

B<get_item()>, B<get_item_text()>, B<get_item_value()> retrieve either a scalar or lists,
depending on the context it was invoked. In scalar mode they return
the first item only (/first item-text/-text/-value/). In list context
they return the text AND the belonging data.

B<getcurselection()>, B<getcurselection_text()>, B<getcurselection_value()>,
and B<getcurselection_index()> also retrieve either a scalar or a list,
depending on the context but for the currently selected listitem. 
For scalar mode same rule applies as for B<get_item>.

B<reverse()> reverses the whole list and all item values.

B<sort()> sorts the whole list (alpha)numerical and reorders all entries.
Depending on the sortmode either the first column content or the data column content is used as
the searchkey. 

B<viewtype()> might be invoked directly or via I<configure> to switch between
'withdata' or 'normal' listbox view.

If the Listbox has the input focus the key 'B<Control-Key-[>' makes the data-list
visible and 'B<Control-Key-]>' hides it.

=head1 METHODS

=over 4

=item B<add()>

'add($path, <options> )' inserts item text & data
in the list. Inserting without '-data' just uses the HList the with a 
default 'undef'-data per item.


=item B<delete()>

'delete(what [, $path] )' removes item text & data
from/to the specified positions in the list
-acts as the default delete().


=item B<get_item()>

'get_item($path )' retrieves item text & data
from/to the specified positions in the list. 
B<get_item_text()> and B<get_item_value()> work analogous but for
texts/values only


=item B<getcurselection()>

'getcurselection()' retrieves item-text & -data from the current selected
position in the list.
B<getcurselection_text()>, B<getcurselection_value()> and B<getcurselection_index()>
work anlogous but for texts/values only


=item B<reverse()>

'reverse()' reverses the whole list and all belonging item values.


=item B<sort()>

'sort($sortmode)' sorts the whole list (alpha)numerical. 
Available Sortmodes are:  B<ascending>, B<descending>, B<ascending data'> or
 B<descending data'> (case-insensitiv, order of sortmode-keywords does not matter).
 


=item B<viewtype()>

'viewtype()' switches the listbox' visible area between the 'normal' view and
the extended one 'withdata', that shows a second column with all the belonging data.

=back


=head1 OPTIONS


=over 4

=item B<viewtype>

'-viewtype()' switches the listbox' visible area between the 'normal' view and
the extended one 'withdata', that shows a second column with all the belonging data.

=item B<datastyle>

'-datastyle()' allows to specify an ItemStyle for the data column (see Tk::ItemStyle for details).

=item B<databackground>

'-databackground()' allows to specify just a different background color for the data column.
Note that it still uses the build-in ItemStyle (beside bg-color) for the data column.

=item B<numeric_primary_sort>

'-numeric_primary_sort()' allows to enable numeric ordering for the internal sort()
function (numeric on primary keys / first column).

=item B<numeric_secondary_sort>

'-numeric_secondary_sort()' allows to enable numeric ordering for the internal sort()
function (numeric on secondary keys / data column).

=item B<columnseparator>

'-columnseparator' allows to specify a different column separator char (default is '|')
If a multicolumn layout is desired simply specify B<'-columns'> option and supply a combined
string (-text) to the add() function
$list->add( -text => 'Entry|Col2|col3|col4', ... );


=item B<headline>

'-headline' allows to specify a I<combined string> for all column headers (uses the column separator)


=item B<headerforeground>

'-headerforeground' allows to specify a different HeaderFOREground (default is List's I<Background> color)


=item B<headerbackground>

'-headerbackground' allows to specify a different HeaderBACKground (default is NO color)


=item B<headerfont>

'-headerfont' allows to specify a different HeaderFONT (default is 'Helvetica -10')


=item B<headerrelief>

'-headerrelief' allows to specify a different HeaderRELIEF (default is 'groove')



=back

=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net

This code may be distributed under the same conditions as Perl.

V2.1  (C) Sept 2009

=cut

###
### EOF
###

