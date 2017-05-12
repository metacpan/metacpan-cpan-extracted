######################################## SOH ###########################################
## Function : Alternate version for Tk:HList with sorting and filtering of columns
##
## Copyright (c) 2013 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History : V0.1	06-Feb-2013 	Class created. MK
##           V0.2	10-Feb-2013 	Added code for feature 'column resizing' (w/o headerresizebutton!). MK
##           V0.3	13-Feb-2013 	Added configure/cget access. Updated Pod documentation. MK
##           V0.4	26-Feb-2013 	Added wrapper/easier func 'advheaderCreate(). Updated Pod documentation. MK
###
######################################## EOH ###########################################
package Tk::Treeplus;

##############################################
### Use
##############################################
use strict;
use vars qw($VERSION);
$VERSION = '0.4';

# standards
use Carp;
use Time::HiRes qw(usleep);

# Tk related
use Tk;
use Tk qw(Ev);
use Tk::Derived;
use Tk::ItemStyle;
use Tk::Compound;
use Tk::DialogBox;
use Tk::LabEntry;


#--------------------------------------------------------------------------------------------------
#use base  qw(Tk::Derived Tk::Tree);
use base  qw(Tk::Derived Tk::Tree);
Tk::Widget->Construct ('Treeplus');

#--------------------------------------------------------------------------------------------------
my (%IconData, %Icons);
# Several internal constants
use constant MAX_HISTORY_SIZE				=> '10';
#
use constant DEFAULT_CLIPBOARD_SEPARATOR	=> '|';
#
use constant _HL_INDICATOR_NONE 			=> '0';
use constant _HL_INDICATOR_OPEN 			=> '1';
use constant _HL_INDICATOR_CLOSED			=> '2';

#--------------------------------------------------------------------------------------------------
# Setup Bitmaps
$IconData{Up} = <<'up_EOP';
	/* XPM */
	static char *Up[] = {
	"6 3 2 1",
	". c none",
	"X c black",
	"..XX..",
	".XXXX.",
	"XXXXXX",
};
up_EOP

$IconData{Down} = <<'down_EOP';
	/* XPM */
	static char *Down[] = {
	"6 3 2 1",
	". c none",
	"X c black",
	"XXXXXX",
	".XXXX.",
	"..XX..",
};
down_EOP

$IconData{Filter} = <<'filter_EOP';
	/* XPM */
	static char *Filter[] = {
	"12 7 3 1",
	". c none",
	"X c black",
	"X c grey",
	"..XXXXXXXX..",
	"...XXXXXX...",
	"....XXXX....",
	".....XX.....",
	".....XX.....",
	".....XX.....",
	".....XX.....",
	};
filter_EOP

#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
sub ClassInit
{
	my ($class, $window) = (@_);
	$class->SUPER::ClassInit($window);
}

#--------------------------------------------------------------------------------------------------
sub Populate
{
	my ($this, $args) = @_;

	# Setup a default Headerstyle
	$this->{__TP_HeaderInfo}{Style} = delete $args->{-headerstyle} ||
						$this->ItemStyle('window', -padx => '0', -pady => '0', -anchor => 'nw');

	# Create the movable ColumnBar
	$this->{__TP_ResizeInfo}{ColumnBar} = $this->Frame(
			-background  => delete $args->{-trimbackground} || 'white',
			-relief      => 'raised',
			-borderwidth => 2,
			-width       => 2,
	);

	$this->SUPER::Populate($args);

	$this->ConfigSpecs(
		#
        -wrapsearch 	 		=> ['PASSIVE', 'wrapsearch', 'Wrapsearch', 0 ],
        #
		-maxselhistory 	 		=> ['PASSIVE', 'maxselhistory', 'Maxselhistory', MAX_HISTORY_SIZE ],
		#
        -clipboardseparator		=> ['PASSIVE', 'clipboardseparator', 'Clipboardseparator', DEFAULT_CLIPBOARD_SEPARATOR ],
		#
		-headerminwidth 		=> ['PASSIVE', 'minwidth', 'MinWidth', 20 ],
		-headerclosedwidth		=> ['PASSIVE', 'closedwidth', 'ClosedMinWidth', 5 ],
        #
		-headerforeground 		=> ['PASSIVE', 'headerForeground', 'HeaderForeground', 'black'],
        -headerbackground 		=> ['PASSIVE', 'headerBackground', 'HeaderBackground', '#d9d9d9'],
        -headeractiveforeground => ['PASSIVE', 'headerActiveforeground', 'HeaderActiveforeground', 'black'],
        -headeractivebackground => ['PASSIVE', 'headerActivebackground', 'HeaderActivebackground', 'gray'],
		#
		# Internal, activates the headers for convenience
		-header 		 		=> ['SELF', 'header', 'Header', 1 ],

	);
	# Initialize the 'Auto-add-HeaderColumn' counter
	$this->{__TP_LastColumn} = 0;
}

#----------------------------------------------------------------------
#              Add-ons for misc functions
#----------------------------------------------------------------------

sub activateEntry
{
	# Parameter
	my ($this, $path) = @_;

	# Locals
	my ($sep_char, $parent, $browsecmd);

	# Delete any previous selection
	$this->selectionClear;

	if ($this->infoExists($path)) {
		# Take care of hidden parents
		$sep_char = quotemeta($this->cget('-separator'));
		if ($path =~ /$sep_char/o) {
			$parent = $path;
			while (($parent = $this->infoParent($parent))) {
				$this->open($parent);
			}
		}
		$this->see($path);
		$this->selectionSet($path);
		# avoid any secondary selection
		$this->anchorClear;

		# Finally continue with the official callback
		$browsecmd = $this->cget('-browsecmd');
		$browsecmd->Call($path) if $browsecmd;	    
	}
# 	else {
# 	    print "DBG: activateEntry() Called with >@_< by >", caller, "< , path [$path] is NOT a valid entry in this list.\n";
# 	}
}



#----------------------------------------------------------------------
#              Add-ons for the new '_Sort & _Filter' Header function
#----------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
# Add-on: new function for refreshing the primary sorting after the
# list has been completely filled
#--------------------------------------------------------------------------------------------------
sub initSort
{    
	# Parameters
	my ($this, $column) = @_;

	if (defined $column) {
		$this->ChangeSortColumn($column)
	}
	else {
	    $this->ReorderContent('sort')
	}
}

#--------------------------------------------------------------------------------------------------
# OVERRIDE: std ADD function
#--------------------------------------------------------------------------------------------------
sub add 
{    
	# Parameters
	my ($this, $path, %args) = @_;
	
	croak __PACKAGE__ . '::add(PATH, %args)  ***Error: Invalid empty PATH detected!' unless $path;

	# Start storing 'create-time' infos
	$this->{__TP_EntryInfo}{$path}{CreateParms} = \%args;

	# Create a new entry
	$this->SUPER::add($path, %args);
}

#--------------------------------------------------------------------------------------------------
# OVERRIDE: std ADDCHILD function
#--------------------------------------------------------------------------------------------------
sub addchild 
{    
	# Parameters
	my ($this, $parentpath, %args) = @_;

	# Locals
	my ($path);

	# Create a new entry
	$path = $this->SUPER::addchild($parentpath, %args);

	# Start storing 'create-time' infos
	$this->{__TP_EntryInfo}{$path}{CreateParms} = \%args if $path;

	return $path
}
#--------------------------------------------------------------------------------------------------
# OVERRIDE: std item-create function
#--------------------------------------------------------------------------------------------------
sub itemCreate { shift->item('create', @_) }
sub itemConfigure { shift->item('configure', @_) }
sub item 
{
	# Parameters
	my ($this, $cmd, $path, $column, %args) = @_;

	# Add/update the colum related settings
	if ($path and $cmd =~ /create|configure/io) {
		# Check for special sorting feature
		# SFXSort stores a String or Array/Hash/Ref that is given
		# to the sort-func instead of the -text value during colum-based sorting
		my $sfx_sort = delete $args{-sortitem};
		$this->{__TP_EntryInfo}{$path}{SortItem}{$column} = $sfx_sort if $sfx_sort;
		map { $this->{__TP_EntryInfo}{$path}{Columns}{$column}{$_} = $args{$_} } keys %args;
	}
	if ($path and $cmd =~ /delete/io) {
		delete $this->{__TP_EntryInfo}{$path}{Columns}{$column};
	}
	$this->SUPER::item($cmd, $path, $column, %args);
}


#--------------------------------------------------------------------------------------------------
# OVERRIDE: std DELETE function
#--------------------------------------------------------------------------------------------------
sub delete
{
	# Parameters
	my ($this, $what, $path) = @_;

	if ($what eq 'all') {
		# Clear the internal storage
		$this->{__TP_EntryInfo} = {};	
		# Delete it
		$this->SUPER::delete($what);
	}
	else {
		# Delete it from internal storage list
		delete $this->{__TP_EntryInfo}{$path};
		# Delete it
		$this->SUPER::delete($what, $path);
	}
}



#--------------------------------------------------------------------------------------------------
# OVERRIDE: new header function
#--------------------------------------------------------------------------------------------------
sub headerCreate { shift->header('create', @_) }
sub headerCget { shift->header('cget', @_) }
sub headerDelete { shift->header('delete', @_) }
sub header 
{
    # print "DBG: reached function [".((caller(0))[3])."] with >@_<, called by >", caller, "<\n";
	# Parameters
	my ($this, $cmd, $column, @args) = @_;

	# Note that we process here only the create command
	if ($cmd eq 'create') {
		my (%args, %hlist_args, $key, $headerbttn);
		%args = @args;
	 	if (($args{-itemtype}||'') eq 'advancedheader') {
			# Failsafe activate the headers, if not yet done
			$this->configure('-header', 1) unless $this->cget('-header');
 			$args{-background} = delete $args{-headerbackground} if $args{-headerbackground};
			# Rip off all irrelevant options
			foreach $key (qw(-itemtype -widget -style)) {
				$hlist_args{$key} = delete $args{$key} if $args{$key};
			}
			# Create a new Header Button
			$headerbttn = $this->AddHeaderColumn($column, %args);
			
			# Add options for parent class setup
			$hlist_args{-itemtype} = 'window';
			$hlist_args{-widget} = $headerbttn;
			$hlist_args{-style} = $this->{__TP_HeaderInfo}{Style} unless $hlist_args{-style};
			$hlist_args{-relief} = 'groove' unless $hlist_args{-relief};
 			$hlist_args{-headerbackground} = $headerbttn->cget('-background');

			# pass on as new args for parental class
			@args = %hlist_args;
		}
	}
	elsif ($cmd eq 'configure') {
		if ($args[0] eq '-command') {
			$this->{__TP_HeaderInfo}{$column}{Command} = $args[1];
		}
		elsif ($args[0] eq '-is_primary_column') {
			$this->ChangeSortColumn($column) if $args[1] # Change only, if really set			
		}
		elsif ($args[0] eq '-sort_numeric') {
			$this->{__TP_HeaderInfo}{$column}{SortNumeric} = $args[1] ? 1 : 0;
			$this->{__TP_HeaderInfo}{$column}{SortDirection} = 0;
			unless ($this->{__TP_HeaderInfo}{$column}{CustomSort}) {
				$this->{__TP_HeaderInfo}{$column}{SortFuncCB} = ($args[1] ?
#					 (sub { $a->[1] <=> $b->[1] }) : (sub { ($a->[1]||'') cmp ($b->[1]||'') }))		    
					 (sub { ($a->[1]||0) <=> ($b->[1]||0) }) : (sub { ($a->[1]||'') cmp ($b->[1]||'') }))		    
			}			
		}
		elsif ($args[0] eq '-sort_func_cb') {
			if ($args[1]) {
				croak "Not a Code Reference!" unless ref($args[1]) eq 'CODE';
				$this->{__TP_HeaderInfo}{$column}{CustomSort} = 1;			
				$this->{__TP_HeaderInfo}{$column}{SortFuncCB} = $args[1];			    
			}
			else {
				$this->{__TP_HeaderInfo}{$column}{CustomSort} = 0;			
				$this->{__TP_HeaderInfo}{$column}{SortFuncCB} = (
					$this->{__TP_HeaderInfo}{$column}{SortNumeric} ?
					 (sub { ($a->[1]||0) <=> ($b->[1]||0) }) : (sub { ($a->[1]||'') cmp ($b->[1]||'') }))		    
			    
			}
			$this->{__TP_HeaderInfo}{$column}{SortDirection} = 0;
		}
		elsif ($args[0] eq '-resize_column') {
			$this->{__TP_ResizeInfo}{$column}{TrimActive} = $args[1] ? 1 : 0;
		}
		elsif ($args[0] eq '-filter_column') {
			$this->{__TP_PatternFilterInfo} = {} unless $this->{__TP_PatternFilterInfo};
			my $fpinfo = $this->{__TP_PatternFilterInfo};
			if ($args[1]) {
				$fpinfo->{Active}{$column}		= 1;
				$fpinfo->{Pattern}{$column} 	= $args[1];
				$fpinfo->{PatternRE}{$column}	= qr/$args[1]/;
				$this->RefreshColumnHeader($column);
				$this->ExecutePatternFilter($column, 'FILTER')
			}
			else {
				$fpinfo->{Active}{$column}		= 0;
			}
		}
		else {
			# all other requests are processed as 'button args'
			return $this->{__TP_HeaderInfo}{$column}{Widget}->configure(@args);
		}
		return
	} 
	elsif ($cmd eq 'cget') {
		if ($args[0] eq '-widget') {
			return $this->{__TP_HeaderInfo}{$column}{Widget};
		}
		elsif ($args[0] eq '-command') {
			return $this->{__TP_HeaderInfo}{$column}{Command};
		}
		elsif ($args[0] eq '-sort_numeric') {
			return $this->{__TP_HeaderInfo}{$column}{SortNumeric};
		}
		elsif ($args[0] eq '-resize_column') {
			return $this->{__TP_ResizeInfo}{$column}{TrimActive};
		}
		elsif ($args[0] eq '-filter_column') {
			return $this->{__TP_PatternFilterInfo}{Pattern}{$column}||'';
		}
		else {
			# all other requests are processed as 'button args'
			return $this->{__TP_HeaderInfo}{$column}{Widget}->cget(@args);
		}
	} 
	elsif ($cmd eq 'delete') {
		croak "Header-Delete() is currently not supported. Try to find a w/a!"
	}
	# Install the 'normal view after we have something on the screen..
	if (defined $column) {
		return $this->SUPER::header($cmd, $column, @args);
	}
	else {
		return $this->SUPER::header($cmd);
	}
}

#--------------------------------------------------------------------------------------------------
#
# advancedHeaderCreate()
# 
# Function: Easy header-column creation (traces the last free col automatically) 
# Parms:    Same as headerCreate(), w/o column, w/o '-itemtype'
#
#--------------------------------------------------------------------------------------------------
sub advancedHeaderCreate
{
	my $this = shift;
	$this->header('create', $this->{__TP_LastColumn}++,
				qw(-autocol 1 -itemtype advancedheader), @_)
}

#--------------------------------------------------------------------------------------------------
#
# AddHeaderColumn()
# 
# Create a header element based on the given parms
# 
# Parms:
# mandatory:
# 		column 					Column Number, where to insert
# 		-text	 				Visible Text for Column Header.
# 
# optional:
# 		-is_primary_column		Mark this column as the one that is usedfor sorting this list
# 		-foreground 	 		forground color for the header
# 		-background 	 		background color for the header
# 		-activeforeground		active forground color for the active header
# 		-activebackground		active background color for the active header
# 		-headerminwidth			minimum size of the current column during custom column resizing operation
# 		-headerclosedwidth		the size of the current column in case it is rendered 'CLOSED'
# 		-sort_numeric			Mark this column to use a NUMERIC sort (default is to use
#								ALPHANUMERIC sort)
# 		-sort_func_cb 			Custom sort: Callbackfunction to be executed in case the list
#								should be sorted according this column (internal default:
#								{ my ($a, $b) = @_; $a->[1] cmp $b->[1] } )
# 		-command				Custom Callbackfunction to be executed, if a columnheader
#								is clicked (AND 'released' on the header!)		
# 		-resize_column			boolean decides whether this column is resizable
#--------------------------------------------------------------------------------------------------
sub AddHeaderColumn
{
	#print "reached CreateListSelectHeader with >@_<\n";
	# Parameters
	my ($this, $column, %args) = @_;
	
	# Locals
	my ($text, $is_primary_column, $sort_numeric, $resize_column, $headerparent,
		$headerbttn, $headbttn, $trim_widget);
	
	croak "No column defined!" unless defined $column;
	croak "No label with '-text' defined!" unless $args{-text};
	$text = $args{-text};

	# Fill Args with defaults if necessary
	$args{-foreground}  	  = $args{-foreground} || $this->cget('-headerforeground');
	$args{-background}  	  = $args{-background} || $this->cget('-headerbackground');
	$args{-activeforeground}  = $args{-activeforeground} || $this->cget('-headeractiveforeground');
	$args{-activebackground}  = $args{-activebackground} || $this->cget('-headeractivebackground');
	# Special check for 'not highlighting' 'empty' headers
	if ($text =~ /--/io) {
		delete $args{-activeforeground};
		delete $args{-activebackground}
	}

	# Trace the last column number (keep up-to-date for alternate use of 'advancedHeaderCreate()')
	$this->{__TP_LastColumn}++ unless delete $args{-autocol};

	# Set some locals
	$this = $this->Subwidget('scrolled') if (ref $this) =~ /Frame/io;
	$is_primary_column	= delete $args{-is_primary_column};
	$sort_numeric		= delete $args{-sort_numeric};
	$resize_column		= delete $args{-resize_column};
	# Create a 'collection' frame
	$headerparent = $this->Frame(-background => $args{-background});

	#-------------------------------------------------------------------
	# Store misc Header-Infos
	$this->{__TP_HeaderInfo}{$column}{CustomSort} = 1 if $args{-sort_func_cb};
	$this->{__TP_HeaderInfo}{$column}{SortFuncCB} = delete $args{-sort_func_cb} || 
#		($sort_numeric ? (sub { print "INT_NUM: a=>$a<>" . join(',',@$a) . "<\n"; $a->[1] <=> $b->[1] }) :
#						 (sub { print "INT_ALP: a=>$a<>" . join(',',@$a) . "<\n"; $a->[1] cmp $b->[1] }));
		($sort_numeric ? (sub { ($a->[1]||0) <=> ($b->[1]||0) }) : (sub { ($a->[1]||'') cmp ($b->[1]||'') }));
	$this->{__TP_HeaderInfo}{$column}{SortNumeric} = $sort_numeric;
	$this->{__TP_HeaderInfo}{$column}{SortDirection} = 0;
	$this->{__TP_HeaderInfo}{$column}{ForegroundColor} = $args{-foreground};
	$this->{__TP_HeaderInfo}{$column}{ActiveForegroundColor} = $args{-activeforeground};
	$this->{__TP_HeaderInfo}{$column}{Command} = delete $args{-command};
	# Store Reszing related infos
	$this->{__TP_ResizeInfo}{$column}{ColumnMinWidth} = delete $args{-headerminwidth} || $this->cget('-headerminwidth');
	$this->{__TP_ResizeInfo}{$column}{ColumnClosedWidth} = delete $args{-headerclosedwidth} || $this->cget('-headerclosedwidth');
  
	#-------------------------------------------------------------------
	#Initialize the select-history storage 
	if ($column == 0) {
		$this->InitializeSelectHistory();
		$is_primary_column = 1; # Set the first column to be the 'primary' by default
		#-------------------------------------------------------------------
		my $legacy_menu = delete $args{-legacy_menu};
		if ($legacy_menu) {
			# Add special Meny Symbol fora anchoring the special capability menu at column 0 
			my ($image, $help_balloon);
			($image, $help_balloon) = @$legacy_menu if ref($legacy_menu) =~ /ARRAY/io;
			$headerbttn = $headerparent->Button(
				-class => 'HListHeader',
				-relief => 'flat', -borderwidth => '0', 
				-background => $args{-background},
				-foreground => $args{-foreground},
				-text => '+',
				($image ? (-image => $image) : ()),
				-command => sub { $this->RMBPopUpMenu() },
				-padx => -1, -pady => -1,
			)->pack(qw(-side left -fill both -anchor w)); # Place the bttn in the frame
			$help_balloon->attach($headerbttn, -balloonmsg => 'List Operations ...') if $help_balloon;		    
		}
	}
	$this->{__TP_HeaderInfo}{PrimaryColumn} = $column if $is_primary_column;

	#-------------------------------------------------------------------
	# Create a Action-Button
	$headerbttn = $headerparent->Button(
		-class => 'HListHeader',
		-relief => 'flat', -borderwidth => '0',
		-padx => '-1', -pady => '-1',
		-highlightthickness => '0',
		-command => sub { $this->ChangeSortColumn($column);
						  # Invoke custom hook, if any
						  my $cb = $this->{__TP_HeaderInfo}{$column}{Command};
						  &$cb($this, $column) if $cb },

		# Apply promoted 'button-style(!)' args
		%args,
	)->pack(qw(-side left -expand 1 -fill both -anchor w)); # Place the bttn in the frame;;
	# Store Headerbutton-Info
	$this->{__TP_HeaderInfo}{$column}{Widget} = $headerbttn;

	#-------------------------------------------------------------------
	# Initialize the RMB Menu
	$headerbttn->bind('<ButtonRelease-3>', sub { $this->RMBPopUpMenu($column) } );
	# Make the 'ALL Column" menu available everywhere
	$headerbttn->bind('<ButtonRelease-2>', sub { $this->RMBPopUpMenu() } );
	#-------------------------------------------------------------------

	#-------------------------------------------------------------------
	# Add header separator for dynamic column resizing
	$trim_widget = $headerparent->Frame(
			-class => 'HListHeader',
			-relief => 'flat', -borderwidth => '0', 
			-background => $headerbttn->cget('-background'),
			#-borderwidth => 1,
			-width       => 1,
	)->place(
		-bordermode => 'outside',
		-relheight => '1.0',
		-anchor	=> 'ne',
		-relx  	=> '1.0',
	);
	$this->{__TP_ResizeInfo}{$column}{TrimWidget} = $trim_widget;
	$trim_widget->bind('<ButtonRelease-3>', sub { $this->RMBPopUpMenu($column) } );
	# Although we create the trim sensors for all new columns we activate it only on-demand (or via pop-up menu)
	$this->{__TP_ResizeInfo}{$column}{TrimActive} = $resize_column ? 1 : 0;
	$this->TrimEnable($column, 1) if $resize_column;

	#-------------------------------------------------------------------
	# Store this column (name) for the 'find-by' search
	$this->{__TP_SearchInfo}{Columns}{$column} = $text;

	#-------------------------------------------------------------------
	# Mark-up this column, if it is the primary-search-column
	$this->RefreshColumnHeader($column) if $is_primary_column;

	return $headerparent
}


#--------------------------------------------------------------------------------------------------
# 
#  ChangeSortColumn()
# 
# Change the given filter to a new value
# 
#--------------------------------------------------------------------------------------------------
sub ChangeSortColumn
{
	# Parameters
	my ($this, $column) = @_;
	
	# Locals
	my ($last_primary_column);

	$last_primary_column = $this->{__TP_HeaderInfo}{PrimaryColumn};
	$last_primary_column = -1 unless defined $last_primary_column;
	if ($last_primary_column == $column) {
		# We stay in the same column, We just reverse the ordering
		$this->{__TP_HeaderInfo}{$column}{SortDirection} =
					not $this->{__TP_HeaderInfo}{$column}{SortDirection};
		# Reverse the list
		$this->ReorderContent('reverse');
	}
	else {
		$this->{__TP_HeaderInfo}{PrimaryColumn} = $column;
		# Sort the list
		$this->ReorderContent('sort');
	}
	# Mark-up this column, eventually remove assignment from previous primary-column
	$this->RefreshColumnHeader($last_primary_column) if $last_primary_column != -1;
	$this->RefreshColumnHeader($column);
}

#--------------------------------------------------------------------------------------------------
# 
# ReorderContent()
# 
# Changes the content to a new sort-order
# 
#--------------------------------------------------------------------------------------------------
sub ReorderContent
{
	# Parameters
	my ($this, $mode) = @_;

	# Locals
	my ($entry_info, %hidden, %indicator, @all_children, $sep_char, $qsep_char,
		$path, $indicator, $ptr, $level, $column, $parent, %stack);

	# Some Helper variables
	$entry_info = $this->{__TP_EntryInfo};

	# failsafe-check - stop on lists with '' as path
	#my @tmp = $this->infoChildren('');
	#return if (not @tmp or not $tmp[0]);
	
	#-------------------------------------------------------------------
	# Snapshot the existing layout
	$this->__collect_children(\@all_children);
	# print 'DBG: variable [\@all_children] = '; ETC::Universal::print_var(\@all_children, 1);

	%hidden = map { ($_->[0], $_->[1]) } @all_children;
	%indicator = map { ($_->[0], $_->[2]) } @all_children;
	@all_children = map { $_->[0] } @all_children;
	$sep_char = $this->cget('-separator');

	#-------------------------------------------------------------------
	# sort / reorder
	if ($mode =~ /reverse/io) {
		@all_children = reverse @all_children;
	}
	elsif ($mode =~ /sort/io) {
		my ($column, $sortfunction, $custom_sort, @sort_map);
		$column = $this->{__TP_HeaderInfo}{PrimaryColumn};
		$sortfunction = $this->{__TP_HeaderInfo}{$column}{SortFuncCB};
		$custom_sort = $this->{__TP_HeaderInfo}{$column}{CustomSort};
		# Here we use the Schwartz-Transformation to sort mapped items
		# s. "Programmieren in Perl" S. 815, 2. Aufl.
		@all_children = map { $_->[0] }
						sort $sortfunction
						map { [ $_, $entry_info->{$_}{Columns}{$column}{-text},
								(($custom_sort) ? ($entry_info->{$_}{CreateParms}{-data}) : ())
							  ] } @all_children;
		# Optionally we have to reverse the sorting result, if user set this
		@all_children = reverse @all_children if $this->{__TP_HeaderInfo}{$column}{SortDirection};
	}
	else {
		croak "SortChildren(): Unknown 'Sort-mode [$mode], skipping!\n"
	}

	#-------------------------------------------------------------------
	# rebuild the list/tree according new calculated order based on cached content
	$this->delete('all');
	$qsep_char = quotemeta($sep_char);
	local (@_) = @all_children;
	while (@_) {
		$path = shift;
# 		print 'DBG: variable [$path] = >' . $path . "<\n";
		($parent = $path) =~ s/^(.*)$qsep_char.*/$1/;
		if ($this->infoExists($parent) or $parent eq $path) {
			$ptr = $entry_info->{$path};
			$this->add($path, %{$ptr->{CreateParms}});
			foreach $column (keys %{$ptr->{Columns}}) {
				$this->itemCreate($path, $column, %{$ptr->{Columns}{$column}});
			}
			$indicator = $indicator{$path};
			if ($indicator) {
				if ($indicator == _HL_INDICATOR_OPEN) {
					$this->_indicator_image($path, 'minus');
				}
				else { ### _HL_INDICATOR_CLOSED
					$this->_indicator_image($path, 'plus');
				}
			}
			else { # _HL_INDICATOR_NONE -> '0'
				$this->_indicator_image($path, undef);
			}
 			$this->hide('entry', $path) if $hidden{$path};
			# Process those items that have been queued
			if ($stack{$path}) {
# 				print "DBG: Insert again [".join(', ', @{$stack{$path}})."] at parent [$path]\n";
			    unshift @_, @{delete $stack{$path}};
			}
		}
		else {
# 			print "DBG: Stacked >$path<, since parent n/a\n";
			push @{$stack{$parent}}, $path
		}
	}
# 	my @tmp;
# 	$this->__collect_children(\@tmp);
# 	print 'DBG: variable [\@tmp] = '; ETC::Universal::print_var(\@tmp, 1);
}

#--------------------------------------------------------------------------------------------------
# 
#  __collect_children()
# 
# Collects information about all entries of the current list or tree
# 
#--------------------------------------------------------------------------------------------------
sub __collect_children
{
	# Locals
    my ($this, $all_children, $path) = @_;
	# Locals
	my ($child, $indicator_images, $indicator);

	foreach $child ($this->infoChildren($path)) {
		#--------------------------------------
		# Note: In diference to 'getmode()' we need to store
		#       the CURRENT mode, not the 'NEXT ONE TO BE' !
		if ($this->indicatorExists($child)) {
			$indicator_images = $this->privateData(); # for speed 
		    if ($indicator_images->{$child} =~ /^(?:plus|plusarm)$/io) {
		        $indicator = _HL_INDICATOR_CLOSED
		    }
			else {
			    $indicator = _HL_INDICATOR_OPEN
			}
		}
		else {
		    $indicator = _HL_INDICATOR_NONE # --> 0
		}
		#--------------------------------------
		push @$all_children, [$child, $this->infoHidden($child), $indicator];
		$this->__collect_children($all_children, $child) if $this->infoChildren($child);
	}
}

#--------------------------------------------------------------------------------------------------
# 
#  RefreshColumnHeader()
# 
# Provides special assigment marker for the
# primary column
# 
#--------------------------------------------------------------------------------------------------
use constant STD	=> '0';
use constant ACT	=> '1';
sub RefreshColumnHeader
{   # print "DBG: reached function [".((caller(0))[3])."] with >@_<, called by >", caller, "<\n";

	# Parameters
	my ($this, $column) = @_;

	# Locals
	my ($hcolptr, $headerbttn, $sort_direction, $fg_color, $afg_color, $primary_images,
		$filter_images, $image);

	# Some Helper variables
	$hcolptr 		= $this->{__TP_HeaderInfo}{$column};	
	$headerbttn 	= $hcolptr->{Widget};
	$sort_direction = $hcolptr->{SortDirection} || 0;
	$fg_color		= $hcolptr->{ForegroundColor} || $headerbttn->cget('-foreground');
	$afg_color		= $hcolptr->{ActiveForegroundColor} || $headerbttn->cget('-activeforeground');

	#-------------------------------------------------------------------
	# Step 1: Check if this is the PRIMARY column
	if ($column == $this->{__TP_HeaderInfo}{PrimaryColumn}) {
		# sort_direction == 0 -> Up, != 0 -> Down
		$primary_images = $hcolptr->{Image}{Primary}{$sort_direction};
		unless ($primary_images) {
			my ($arrow_data, $image_data);
			$arrow_data = $sort_direction ? $IconData{Down} : $IconData{Up};
			#-------------------------------------
			# Create a 'Standard' Arrow
			($image_data = $arrow_data) =~ s/black/$fg_color/io;
			$primary_images->[STD] = $headerbttn->Pixmap(-data => $image_data);
			#-------------------------------------
			# Create an 'Active' Arrow
			($image_data = $arrow_data) =~ s/black/$afg_color/io;
			$primary_images->[ACT] = $headerbttn->Pixmap(-data => $image_data);
			#-------------------------------------
			# Store the new images
			$hcolptr->{Image}{Primary}{$sort_direction} = $primary_images
		}
	}
	#-------------------------------------------------------------------
	# Step 2: Check if this is the FILTERED column
	if ($this->{__TP_PatternFilterInfo}{Active}{$column}) {
		$filter_images = $hcolptr->{Image}{Filter};
		unless ($filter_images) {
			my ($image_data);
			#-------------------------------------
			# Create a 'Standard' Filter
			($image_data = $IconData{Filter}) =~ s/black/$fg_color/io;
			$filter_images->[STD] = $headerbttn->Pixmap(-data => $image_data);
			#-------------------------------------
			# Create an 'Active' Filter
			($image_data = $IconData{Filter}) =~ s/black/$afg_color/io;
			$filter_images->[ACT] = $headerbttn->Pixmap(-data => $image_data);
			#-------------------------------------
			# Store the new images
			$hcolptr->{Image}{Filter} = $filter_images
		}
	}

	#-------------------------------------------------------------------
	# Step 3: Build together
	if ($primary_images or $filter_images) {
		my ($compound_images, $i, $color, $image, $old_bind);
		$compound_images = $hcolptr->{Image}{Compound};
		if ($compound_images) { # Remove existing images
			$compound_images->[STD]->delete;
			$compound_images->[ACT]->delete
		}
		#-------------------------------------
		# Create a new 'Standard' + 'Active' Compound Image
		$i = STD;
		foreach $color ($fg_color, $afg_color) {
			$image = $headerbttn->Compound(-padx => 1, -pady => 1, -foreground => $color,
										 -background => $headerbttn->cget('-background'));
			# Line 1
			if ($primary_images) {
				$image->Image(-image => $primary_images->[$i], -anchor => 'n');
				$image->Space(-height => 1)
			}
			# Line 2
			$image->Line;
			$image->Text(-text => $headerbttn->cget('-text'),
							-wraplength => ($this->{__TP_ResizeInfo}{$column}{WrapLength}||0));
			if ($filter_images) {
				$image->Space(-width => 3);
				$image->Image(-image => $filter_images->[$i], -anchor => 'e');
			}
			#-------------------------------------
			# Store the new images
			$hcolptr->{Image}{Compound}[$i++] = $image		    
		}
		#-------------------------------------
		# Supply to the Headerbutton
		$headerbttn->configure(-image => $hcolptr->{Image}{Compound}[STD]);
		# Setup IMG change for 'active' state
		$old_bind = $headerbttn->bind('<Enter>', sub { my $this = $_[0];
										$this->configure(-image => $hcolptr->{Image}{Compound}[ACT])
												 if $this->cget('-state') ne 'disabled' } );
		$hcolptr->{EnterCB} = $old_bind unless $hcolptr->{EnterCB};
		#
		$old_bind = $headerbttn->bind('<Leave>', sub { my $this = $_[0];
										$this->configure(-image => $hcolptr->{Image}{Compound}[STD])
												 if $this->cget('-state') ne 'disabled' } );
		$hcolptr->{LeaveCB} = $old_bind unless $hcolptr->{LeaveCB};
	}
	else {
		# We shall remove all special markers
		$headerbttn->configure(-image => undef);
		$headerbttn->bind ('<Enter>', $hcolptr->{EnterCB} );
		$headerbttn->bind ('<Leave>', $hcolptr->{LeaveCB} );
	}
}


#--------------------------------------------------------------------------------------------------
# 
#  Trim/Resize related functions
# 
#--------------------------------------------------------------------------------------------------

#--------------------------------------
# CALLED IF WE ENTER THE TRIM AREA
#--------------------------------------
sub TrimEnable
{
	# Parameters
	my ($this, $column, $enable) = @_;
	# Locals
	my ($rszinfo, $trim_widget);

	# Shortcuts
	$rszinfo = $this->{__TP_ResizeInfo}{$column};
	$trim_widget = $rszinfo->{TrimWidget};

	if ($enable) {
		$rszinfo->{Bind_ButtonRelease_1} = 
				$trim_widget->bind( '<ButtonRelease-1>' =>
						sub { $this->TrimButtonRelease($column, 1) } ) unless $rszinfo->{Bind_ButtonRelease_1};
		$rszinfo->{Bind_ButtonPress_1} = 
				$trim_widget->bind( '<ButtonPress-1>' =>
						sub { $this->TrimButtonPress($column, 1) } ) unless $rszinfo->{Bind_ButtonPress_1};
		$rszinfo->{Bind_Motion} = 
				$trim_widget->bind( '<Motion>' =>
						sub { $this->MoveColumnBar($column) } ) unless $rszinfo->{Bind_Motion};
		$rszinfo->{Bind_Enter} = 
				$trim_widget->bind( '<Enter>' =>
						sub { $this->TrimEnter($column) } ) unless $rszinfo->{Bind_Enter}; 
		$rszinfo->{Bind_Leave} = 
				$trim_widget->bind( '<Leave>' =>
						sub { $this->TrimLeave() } ) unless $rszinfo->{Bind_Leave};
		$trim_widget->configure(-cursor => 'sb_h_double_arrow');
	}
	else {
	    $trim_widget->bind( '<ButtonRelease-1>' => $rszinfo->{Bind_ButtonRelease_1} );
	    $trim_widget->bind( '<ButtonPress-1>'	=> $rszinfo->{Bind_ButtonPress_1} );
	    $trim_widget->bind( '<Motion>'   		=> $rszinfo->{Bind_Motion} );
	    $trim_widget->bind( '<Enter>'			=> $rszinfo->{Bind_Enter} );
	    $trim_widget->bind( '<Leave>'			=> $rszinfo->{Bind_Leave} );
		$trim_widget->configure(-cursor => undef);
		# safely disable
		$this->HideTrimColumnBar();
		# deactivate any non-std columnwidth
		$this->SetColumnWidth($column, 'Auto');
	}
}

#--------------------------------------
# CALLED IF WE ENTER THE TRIM AREA
#--------------------------------------
sub TrimEnter
{
	# Parameters
	my ($this, $column) = @_;
	# Locals
	my ($trim_widget);
	
	$trim_widget = $this->{__TP_ResizeInfo}{$column}{TrimWidget};
	if ($column == $this->cget('-columns') - 1) {
		$trim_widget->configure(-cursor => undef);
	}
	else {
		$trim_widget->configure(-cursor => 'sb_h_double_arrow');
#		$this->TrimUpdate($column, 1);
		$this->MoveColumnBar($column, 1);
	}
}

#--------------------------------------
# CALLED IF WE LEAVE THE TRIM AREA
#--------------------------------------
sub TrimLeave
{
 	$_[0]->HideTrimColumnBar()
}

#--------------------------------------
# Move a column bar which displays on top of the HList widget
# to indicate the eventual size of the column.
#--------------------------------------
sub MoveColumnBar
{
	# Parameters
	my ($this, $column) = @_;
	# Lcoals
	my ($trim_widget, $height, $x);

	if ($this->IsValidEdge($column))	{
		$trim_widget = $this->{__TP_ResizeInfo}{$column}{TrimWidget};
		$height = $this->height() - $trim_widget->height();
		$x  	= $this->pointerx() - $this->rootx() + 1; # +1 for move right into gap

		$this->{__TP_ResizeInfo}{ColumnBar}->place(
			'-x'      => $x,
			'-height' => $height - 5,
			'-y'      => $trim_widget->height() + 5,
		) if $column != $this->cget('-columns') - 1;
		$this->{__TP_ResizeInfo}{ColumnBarVisible} = 1;
	}
}

#--------------------------------------
# REMOVES IT FROM DISPLAY without destroying it
#--------------------------------------
sub HideTrimColumnBar
{
	# Parameters
	my $this = $_[0];
	if ($this->{__TP_ResizeInfo}{ColumnBarVisible}) {
    	$this->{__TP_ResizeInfo}{ColumnBarVisible} = 0;
		$this->{__TP_ResizeInfo}{ColumnBar}->placeForget();
	}
}

#--------------------------------------
# RESIZE ACTIONS
#--------------------------------------
sub TrimButtonPress
{
	# Parameters
	my ($this, $column, $activate_trim_flag) = @_;
	# Locals
	my ($trim_widget);

	$trim_widget = $this->{__TP_ResizeInfo}{$column}{TrimWidget};
	if ($this->IsValidEdge($column) or $activate_trim_flag) {
		$this->{__TP_ResizeInfo}{XStart} = $trim_widget->pointerx() - $trim_widget->rootx();
	}
	else {
		$this->{__TP_ResizeInfo}{XStart} = -1
	}
}
sub TrimButtonRelease
{
	# Parameters
	my ($this, $column, $activate_trim_flag) = @_;
	
	# Immediately hiode it
	$this->HideTrimColumnBar();

	if ($this->{__TP_ResizeInfo}{XStart} >= 0) {
		my ($trim_widget, $min_width, $old_width, $new_width, $headerbttn);
		
		$trim_widget	= $this->{__TP_ResizeInfo}{$column}{TrimWidget};
		$min_width	= $this->{__TP_ResizeInfo}{$column}{ColumnMinWidth} || 5;
		$old_width	= $this->columnWidth($column);
		# Calculate new width
		$new_width	= $old_width + ( $trim_widget->pointerx() - $trim_widget->rootx() );
		$new_width	= $min_width if $new_width < $min_width;

		$this->SetColumnWidth($column, 'Custom', $new_width)
	}
	$this->{__TP_ResizeInfo}{XStart} = -1;
}

#--------------------------------------
# CHECK IF THE RESIZE CONTROL IS SELECTED
#--------------------------------------
sub IsValidEdge
{
	my ($this, $column) = @_;
	return (($column == ($this->cget('-columns') - 1)) ? 0 : 1);
}

#--------------------------------------
# Supply a new ColumnWidth
#--------------------------------------
sub SetColumnWidth
{
	# Parameters
	my ($this, $column, $cmd, $value) = @_;
	# Locals
	my ($rszinfo, $old_width, $old_anchor, $old_wraplength, $new_width, $headerbttn, $anchor, $wrap_length);

	# Shortcuts
	$rszinfo = $this->{__TP_ResizeInfo}{$column};
	$headerbttn = $this->{__TP_HeaderInfo}{$column}{Widget};

	# Store the last value
	$old_width		= $this->columnWidth($column);
	$old_anchor		= $headerbttn->cget('-anchor');
	$old_wraplength	= $headerbttn->cget('-wraplength')||0;
	# Store the 'Auto' / Default settings
	$rszinfo->{AnchorOrg}		= $old_anchor unless defined $rszinfo->{AnchorOrg};
	$rszinfo->{WrapLengthOrg}	= $old_wraplength unless defined $rszinfo->{WrapLengthOrg};

	# Configure the behavior for 'user controlled sizes'
	if ($cmd =~ /auto|default/io) {
	    $anchor 		= $rszinfo->{AnchorOrg};
		$wrap_length	= $rszinfo->{WrapLengthOrg};
	    $new_width		= ''
	}
	elsif ($cmd =~ /min/io) {
		$anchor 		= 'w';
		$wrap_length	= 0;
	    $new_width		= $rszinfo->{ColumnMinWidth}
	}
	elsif ($cmd =~ /close/io) {
		$anchor 		= $rszinfo->{AnchorOrg};
		$wrap_length	= 0;
	    $new_width		= $rszinfo->{ColumnClosedWidth}
	}
	elsif ($cmd =~ /last/io) {
	    $anchor 		= $rszinfo->{ColumLastAnchor};
		$wrap_length	= $rszinfo->{ColumLastWrapLength};
	    $new_width		= $rszinfo->{ColumLastWidth} || $old_width;
	}
	elsif ($cmd =~ /custom/io) {
		$anchor 		= 'w';
		$wrap_length	= $value;
	    $new_width		= $value
	}
	else {
		croak "Unknown cmd [$cmd] for SetColumnWidth()! [called by >", caller, "<]\n"
	}
	# Apply it
	$this->columnWidth($column, $new_width);

	# Store infos for next cycle
	$rszinfo->{ColumnWidth} 		= $new_width;
	$rszinfo->{WrapLength}			= $wrap_length;
	$rszinfo->{ColumLastWidth}		= $old_width;
	$rszinfo->{ColumLastAnchor} 	= $old_anchor;
	$rszinfo->{ColumLastWrapLength} = $old_wraplength;
	$rszinfo->{Mode}				= $cmd;
	#print "DBG: variable [\$new_width, \$anchor, \$wrap_length] = >$new_width< >$anchor< >$wrap_length<\n";
	#-------------------------------------------------------------------
	# Some Postprocessing
	# Modify the Header ResizeBttn attr to be better visable
	$headerbttn->configure(-anchor => $anchor, -wraplength => $wrap_length);	
	$this->RefreshColumnHeader($column); # Necessary to rebuild Compound images
}


#--------------------------------------------------------------------------------------------------
# 
#  RMBPopUpMenu()
# 
# IN : I<-listwidget, I<current_column>
# 
# OUT: I<--->
# 
# B<Description>: 
# Creates a Pop-up Menu for the given list
# for single column OR multiple list operations
# 
#--------------------------------------------------------------------------------------------------
sub RMBPopUpMenu
{
	# Parameters
	my ($this, $current_column) = @_;

	# Locals
	my ($search_info, $col_search, @all_columns, $single_column, @used_columns, $menu, $find_submenu,
		$accelerator1, $accelerator2, $column, $filter_submenu, $submenu,
		$resize_submenu, $submenu2, $submenu3, $xclip_submenu);

	#------------------------------------------------------------------------
	# Shortcuts
	$search_info	= $this->{__TP_SearchInfo};
	$col_search 	= $search_info->{Columns};
	@all_columns	= sort { $a <=>$b } keys %$col_search;
	$single_column	= (defined $current_column) ? 1 : 0; # make the following checks easier
	@used_columns	= $single_column ? ($current_column) : (@all_columns);

	#------------------------------------------------------------------------
	$menu = $this->{__TP_PopUpListOperationsMenu};
	if ($menu) {
		$menu->delete(0, 'end');
	}
	else {
		$menu = $this->{__TP_PopUpListOperationsMenu} = $this->Menu(
				-tearoff => '0',
				#-disabledforeground => $this->cget('-foreground')
		);
	}
	#------------------------------------------------------------------------					
	if ($single_column) {
		$find_submenu = $menu 
	}
	else {
		$find_submenu = $menu->cascade(
			-label => 'Find',
			-tearoff => '0',
		)
	}
	# Some Shortcuts
	$accelerator1 	= 'Ctrl-f';
	$accelerator2 	= 'Ctrl-h';
	foreach $column (@used_columns) {
		my ($column_name, $last_pattern, $is_numeric_col, $column_curr);
		$column_name	= $col_search->{$column};
		$last_pattern	= $search_info->{SearchPattern}{$column};
		$is_numeric_col = $this->{__TP_HeaderInfo}{$column}{SortNumeric};
		$column_curr	= $column; # Closure !

		if ($last_pattern and not $is_numeric_col) {
			$submenu = $find_submenu->cascade(
					-label => ($single_column ? 'Find' : ucfirst($column_name)),
					-tearoff => '0',
			);
			$submenu->command(
					-label => 'Find ...',
					-command => sub { $this->__find_hlentry($column_curr) },
					-accelerator => $accelerator1
			);
			$submenu->command(
					-label => 'Find NEXT [' . $last_pattern . ']',
					-command => sub {	$this->__find_hlentry($column_curr, 'NEXT');
										$this->bind('<Control-h>' =>
													sub { $this->__find_hlentry($column_curr, 'NEXT') } )
									},
					-accelerator => $accelerator2
			);
			$accelerator2 = undef;
		}
		else {
#			if ($find_submenu->index('end') !~ /none/io) {
			if ($is_numeric_col) {
				$find_submenu->separator unless $accelerator1; # Already at least one column before ID-col
				$accelerator1 = 'Ctrl-F';
			}
			$find_submenu->command(
							-label => ($single_column ? 'Find ...' : ucfirst($column_name)),
							-command => sub { $this->__find_hlentry($column_curr) },
							-accelerator => $accelerator1
			);
		}
		$accelerator1 = undef;
	}
	#------------------------------------------------------------------------					
	$menu->separator;
	if ($single_column and not $this->{__TP_PatternFilterInfo}{Active}{$current_column}) {
		$menu->command(
				-label => 'Filter ...',
				-command => sub { $this->ExecutePatternFilter($current_column, 'ASK') },
		);
	}
	else {
		$filter_submenu = $menu->cascade(
				-label => 'Filter',
				-tearoff => '0',
		);
		#-------------------------------------
		foreach $column (@used_columns) {
			my $column_name = $col_search->{$column};
			my $column_curr = $column; # Closure !
			if ($single_column) {
				$submenu = $filter_submenu 
			}
			else {
				$submenu = $filter_submenu->cascade(
					-label => ucfirst($column_name),
					-tearoff => '0',
				);
			}
			$submenu->command(
					-label => 'Set ...',
					-command => sub { $this->ExecutePatternFilter($column_curr, 'ASK') },
			);
			$submenu->command(
					-label => 'Remove',
					-command => sub { $this->ExecutePatternFilter($column_curr, 'REMOVE') },
			)
		}
	}
	unless ($single_column) {
		$filter_submenu->separator;
		$filter_submenu->command(
			-label => 'Remove ALL',
			-command => sub { $this->ExecutePatternFilter(0, 'REMOVE_ALL') },
		);
	}
	#------------------------------------------------------------------------
	if ($this->{__TP_SelectHistory} and (@used_columns > 1 or $current_column == 0)) {
		# Step 1: Refresh the selection list (might have changed/invalid due to delete/refresh/insert list entries)
		my ($sel_hist, $path, @valid_sel_histories);
		foreach $sel_hist (@{$this->{__TP_SelectHistory}}) { 
			$path = $sel_hist->[2];
			if ($this->infoExists($path)) {
				push @valid_sel_histories, $sel_hist;
			}
		}
		$this->{__TP_SelectHistory} = \@valid_sel_histories;
		# Step 2: Show valid selections
		if (@valid_sel_histories) {
			$menu->separator;
			my $select_submenu = $menu->cascade(
					-label => 'Selection History',
					-tearoff => '0',
					-state => 'normal',
			);
			foreach my $sel_hist (@valid_sel_histories) { # NOTE the 'my' CLOSURE!!! MKr
				#print "DBG: set menu [\$sel_hist] = "; ETC::Universal::print_var($sel_hist, 1);
				$select_submenu->command(
						-label => "<Re>Select '" . $sel_hist->[0] ."'",
						-command => sub {	my $path = $sel_hist->[2];
											$this->selectionClear;
											$this->selectionSet($path);
											$this->see($path);
											$this->anchorClear;
											$sel_hist->[1]->Call($path) },
				);
			}
			$select_submenu->separator;
			$select_submenu->command(
						-label => 'Clear History',
						-command => sub { $this->{__TP_SelectHistory} = [] },
			);
		}
	}


	#------------------------------------------------------------------------
	$menu->separator;
	$resize_submenu = $menu->cascade(
			-label => 'Column Size',
			-tearoff => '0',
	);
	#-------------------------------------
	foreach $column (@used_columns) {
		my $column_name = $col_search->{$column};
		my $var = $this->{__TP_ResizeInfo}{$column}{TrimActive}; # Closure !
		my $column_curr = $column; # Closure !

		if ($single_column) {
		   $submenu = $resize_submenu 
		}
		else {
			$submenu = $resize_submenu->cascade(
					-label => ucfirst($column_name),
					-tearoff => '0',
			);
		}
		$submenu->checkbutton(
#				-label => ($single_column ? 'Dynamic Column-Resizing' : ucfirst($column_name)),
				-label => 'Dynamic Column-Resizing',
				-command => sub {	$this->{__TP_ResizeInfo}{$column_curr}{TrimActive} = $var;
									$this->TrimEnable($column_curr, $var);
								},
				-variable => \$var,
		);
		$submenu2 = $submenu->cascade(
				-label => 'Column Width',
				-tearoff => '0',
				-state => $this->{__TP_ResizeInfo}{$column}{TrimActive} ? 'normal' : 'disabled',
		);
		$submenu2->command(
				-label => 'Auto',
				-command => sub { $this->SetColumnWidth($column_curr, 'Auto') },
				-accelerator => $accelerator1
		);
		$submenu2->command(
				-label => 'Last',
				-command => sub { $this->SetColumnWidth($column_curr, 'Last') },
		);
		$submenu2->command(
				-label => 'Min',
				-command => sub { $this->SetColumnWidth($column_curr, 'Min') },
		);
		$submenu2->command(
				-label => 'Closed',
				-command => sub { $this->SetColumnWidth($column_curr, 'Close') },
		)
	}
	#-------------------------------------
	unless ($single_column) {
		$resize_submenu->separator;
		$resize_submenu->command(
				-label => 'Restore DEFAULT',
				-command => sub { map { $this->SetColumnWidth($_, 'Auto') } @all_columns },
		)	    
	}
	#------------------------------------------------------------------------
	$menu->separator;
	$xclip_submenu = $menu->cascade(
			-label => 'X-ClipBoard',
			-tearoff => '0',
	);
	$xclip_submenu->command(
					-label => 'Export Selected Entry(ies)',
					-command => sub { $this->__copy_selection_to_clipboard() },
					-accelerator => 'Ctrl-c'
	);
	$xclip_submenu->command(
					-label => 'Export Selection + Column Headers',
					-command => sub { $this->__copy_selection_to_clipboard('use_header_info') },
					-accelerator => 'Ctrl-C'
	);

	# Set some default bindings
	$this->bind('<Control-c>' => sub { $this->__copy_selection_to_clipboard() } );
	$this->bind('<Control-C>' => sub { $this->__copy_selection_to_clipboard('use_header_info') } );
 	$this->bind('<Control-f>' => sub { $this->__find_hlentry(0) } );


	#------------------------------------------------------------------------
 	$menu->Popup(-popover => 'cursor', -popanchor => 'nw');
}

#--------------------------------------------------------------------------------------------------
# 
#  InitializeSelectHistory()
# 
# IN : I<-listwidget => list-widget>,  I<-event_binding => alternate pop-up-event>
# 
# OUT: I<--->
# 
# B<Description>: 
	# Add an interceptor for the browsecommand callback to store the last 10 selections 
# 
#--------------------------------------------------------------------------------------------------
sub InitializeSelectHistory
{
 	#print "called AddPopUpListOperations with >@_< from ", caller, "<\n";
	# Parameter
	my $this = $_[0];
	# Locals
	my ($browsecmd);

	#------------------------------------------------------------------------
	# Rough Check
	return if $this->{__TP_SelectHistoryEngaged};

	#------------------------------------------------------------------------
	$browsecmd = $this->cget('-browsecmd'); #print "DBG: variable [\$browsecmd] = >$browsecmd<\n";
	if ($browsecmd) {
		$this->{__TP_SelectHistoryEngaged} = 1;
		$this->configure(-browsecmd =>
			 sub {  #print "DBG: reached function [browsecmd-interceptor] with >@_<, called by >", caller, "<\n";
					#Parameters
					my ($path, @args) = @_;
					# Locals
					my ($this_id, $select_history, $parent, @path, $entry_txt);

					# FailSafe: Avoid circular invocations
					return if $this->{BrowseCmdOngoing};
					local $this->{BrowseCmdOngoing} = 1;

					unless (@args) {
						$this_id = $this->id;
						$this->{__TP_SelectHistory} = [] unless $this->{__TP_SelectHistory};
						$select_history = $this->{__TP_SelectHistory};

						# Latch only different calls
						unless (grep m/^$path$/, map {$_->[2]} @$select_history) {
							$parent = $this->infoParent($path);
							if ($parent) {
								@path = $this->itemCget($path, 0, '-text');
								while ($parent) {
								    push @path, $this->itemCget($parent, 0, '-text');
									$parent = $this->infoParent($parent);
								}
								$entry_txt = join('/', reverse @path);
							}
							else {
								$entry_txt = $this->itemCget($path, 0, '-text')
							}
							#print "DBG: variable [\$entry_txt, \$path] = >$entry_txt, $path<\n";
							push  @$select_history, [$entry_txt, $browsecmd, $path ];
							shift @$select_history if @$select_history > $this->cget('-maxselhistory');
						}
					}
					# Finally continue with the official callback
					$browsecmd->Call(@_)
				 }
		);
	}
}

#--------------------------------------------------------------------------------------------------
# 
#  ExecutePatternFilter()
# 
# IN : I<dialog_class>, I<list-widget>, I<SEarchColumn-Num>, I<$mode>, I<$filter_pattern>
# 
# OUT: I<$filter-hash>
# 
# B<Description>: 
# Maintains the Pattern Filter for Columns.
# CMDs: Set/Remove/Pattern/Filter
# 
#--------------------------------------------------------------------------------------------------
sub ExecutePatternFilter
{
	# Parameters
	my ($this, $column, $cmd) = @_;
	# Locals
	my ($fpinfo);

	return unless defined $column;

	# Define some shortcuts
	$this->{__TP_PatternFilterInfo} = {} unless $this->{__TP_PatternFilterInfo};
	$fpinfo = $this->{__TP_PatternFilterInfo};

	if ($cmd =~ /ASK/io) {
		my ($column_name, $headerbttn, $old_pattern, $new_pattern);
		$column_name	= $this->headerCget($column, '-text');
		$old_pattern	= $fpinfo->{Pattern}{$column}; $old_pattern = '' unless defined $old_pattern;
		($new_pattern, $cmd) = $this->EnterStringDlg(
			-default_button => 'Set',
			-value => $old_pattern,
			-buttons => ['Set', ($fpinfo->{Active}{$column} ? ('Clear') : ()), 'Cancel'],
			-title => 'Column Filter for [' . $column_name . ']',
			-label => 'FilterPattern: ',
			-validatecommand => sub { return $_[1] =~ /[\w\:?\*\.\-\+\^\$\[\]\(\)\{\}\\\|\s]/o },
		);
		# Filter out invalid keys that would be undeletable otherwise
		$new_pattern =~ s/\'|\"//go;

		if ($cmd =~ /Set/io) {
			$fpinfo->{Active}{$column}		= 1;
			$fpinfo->{Pattern}{$column} 	= $new_pattern;
			$fpinfo->{PatternRE}{$column}	= qr/$new_pattern/;
			#-------------------------------------------------
			# Adopt the Column Headers
			$this->RefreshColumnHeader($column);
			#-------------------------------------------------
			# Filter the displayed-List
			$cmd = 'FILTER';
		}
	}
	if ($cmd =~ /REMOVE|CLEAR/io) {
		my ($del_column, @columns);
		if ($cmd =~ /ALL/io) {
			@columns = keys %{$fpinfo->{Active}}		    
		}
		else {
			@columns = $column  
		}		
		foreach $del_column (@columns) {
			# Clear the active -flag but keep the pattern for convenience
			delete $fpinfo->{Active}{$del_column};
			#-------------------------------------------------
			# Adopt the Column Headers
			$this->RefreshColumnHeader($del_column)
		}
		#-------------------------------------------------
		# Filter the displayed-List
		$cmd = 'FILTER';
	}

	# Second Cycle: Take care of the cmd-changes of ASK-/Remove-mode
	if ($cmd =~ /FILTER|REFRESH/io) {
		#  Clear it to avoid accumulation of enabled filters
		my $filter_info = $fpinfo->{Filter} = {};
		# Rebuild the current pattern matrix
		foreach $column (sort {$a<=>$b} keys %{$fpinfo->{Active}}) {
			$filter_info->{$column} = $fpinfo->{PatternRE}{$column} if $fpinfo->{Active}{$column}
		}
		# Execute the filter
		$this->__filter_hlentry_r($filter_info, '')
	}
}


#-----------------------------------------------------------------
# Very internal related function, NOT to be invoked by user apps 
#-----------------------------------------------------------------
# Transfers the current selected entries of the given
# widget into the common X11-Clipboard.
sub __copy_selection_to_clipboard
{
    #print "DBG: reached function [__copy_selection_to_clipboard] with >@_<, called by >", caller, "<\n";
	# Parameter
	my ($this, $use_header_info) = @_;

	# Locals
	my (@selitems, $selectforeground, $selectbackground, $text, $clip_txt,
		$wclass, $col_cnt, $clipboard_column_separator, $column, $entry);

	return unless $this;
	@selitems = $this->infoSelection();
	if (@selitems) {
		$selectforeground = $this->cget('-selectforeground');
		$selectbackground = $this->cget('-selectbackground');
		
		$wclass = ref $this; $clip_txt = '';
		$col_cnt = $this->cget('-columns');
		$clipboard_column_separator = $this->cget('-clipboardseparator');
		if ($wclass =~ /HList|Tree/io and $use_header_info and $this->cget('-header')) {
			for ($column = 0; $column < $col_cnt; $column++) {
				$clip_txt .= $clipboard_column_separator if $clip_txt;
				$clip_txt .= $this->headerCget($column, '-text');
			}
			#print "DBG: header: [\$clip_txt] = >$clip_txt<\n";
		}
		# REtrieve all selected items
		foreach (@selitems) {
			if ($wclass =~ /TList/io) {
				$text = $this->entrycget($_, '-text');
			}
			elsif ($wclass =~ /HList|Tree/io) {
				$text = '';
				for ($column = 0; $column < $col_cnt; $column++) {
					$text .= $clipboard_column_separator if length $text;
					$entry  = $this->itemCget($_, $column, '-text'); $entry  = '' unless defined $entry;
					$text .= $entry;
				}
			}
			else {
				last; # don't do anything on unspecific widget types
			}
			$clip_txt .= "\n" if $clip_txt;
			$clip_txt .= $text;
		}
		if ($clip_txt) {
			# Update the global (unix) Clipboard
			$this->clipboardClear();
			$this->clipboardAppend($clip_txt);		    
			$this->configure( -selectforeground => 'black',
								-selectbackground => ($use_header_info ? 'lawngreen' : 'darkgreen'),
			);
			#print "DBG: Copied Entries [$clip_txt] from Widget [$wclass] to global X-clipboard.\n"
		}
		else {
			$this->clipboardClear();
			$this->clipboardAppend($clip_txt);		    
			$this->configure( -selectforeground => 'white',
								-selectbackground => 'darkred',
			);
			carp "Internal Warning: Failed to copy Entries from Widget [$wclass] to global X-clipboard!\n"
		}
		$this->update;
 		usleep(900000);
		$this->configure( -selectforeground => $this->cget('-foreground'),
							-selectbackground => $this->cget('-background'),
		);
		$this->update;
		usleep(300000);

		# Restore original settings
		$this->configure(
							-selectforeground => $selectforeground,
							-selectbackground => $selectbackground,
		);
		$this->update;
	}
}

#-----------------------------------------------------------------
# Very internal related function, NOT to be invoked by user apps 
#-----------------------------------------------------------------
sub __find_hlentry
{
	# Parameter
	my ($this, $column, $find_next_flag) = @_;
	
	# Locals
	my ($search_info, $is_numeric_col, $search_item, $path, $parent, $answer);
	
	# Some shortcuts
	$is_numeric_col = $this->{__TP_HeaderInfo}{$column}{SortNumeric};
	$search_info	= $this->{__TP_SearchInfo};
	$search_item	= $search_info->{SearchPattern}{$column};

	#----------------------------------------------------------------------------------------------					
	if ($find_next_flag and $search_item) {
		$answer = 'Find Next';
	}
	else {
		my $column_name = $search_info->{Columns}{$column};

		($search_item, $answer) = $this->EnterStringDlg(
							-default_button => 'Find',
							-value => $search_item,
							-buttons => ['Find', 
									(($column_name and $search_item and not $is_numeric_col) 
										? ('Find Next') : ()), 'Cancel'],
							-title => 'Enter Search Item [' . $column_name . ']',
							-label => "Find '$column_name': ",
							-validatecommand => sub {	my $value = $_[1]||'';
														if ($column_name eq 'ID') {
															return $value =~ /[\d\-]/o
												  		}
														else {
												 			return $value =~ /[\w\?\*\.\-\+\^\$\[\]\(\)\\\|\s]/o
														}
													},
		);
		return if $answer eq 'Cancel';
	}
	#print "DBG: variable [\$search_item] = >$search_item< [\$answer] = >$answer<  [\$column_name] = >$column_name< \n";
	if ($search_item) {
		$this->update;
		$this->Busy(-recurse => 1);

		#----------------------------------------------------------------------------------------------					
		# Store pattern for potential 'NEXT' Search
		$search_info->{SearchPattern}{$column} = $search_item;

		#----------------------------------------------------------------------------------------------					
		# Support perl's regexes
		$search_item = '\b' . $search_item . '\b' if $is_numeric_col;	    
		$search_item = qr($search_item);
		
		# Clear the Search StartPoint for Starting the Search at the very Beginning
		$search_info->{LastHLEntry} = '' if $answer !~ /Next/io or $is_numeric_col;
		
		# NOTE: We have to pass a reference to the startposition-path to be able to reset it GLOBALLY, if we detect the last stop
		$path = __find_hlentry_r($this, $search_item, $column, '', \$search_info->{LastHLEntry});
		$this->Unbusy();
		if ($path) {
			# Prepare for the next match
			$this->bind('<Control-f>' => sub { $this->__find_hlentry($column) } );
			$this->bind('<Control-h>' => sub { $this->__find_hlentry($column, 'NEXT') } );
			#print "Found path [$path]\n";
			# Store for potential 'NEXT'
			$search_info->{LastHLEntry} = $path;
			$this->show('entry', $path) if $this->infoHidden($path);
			if ($path =~ m/\./o) {
				$parent = $path;
				while (($parent = $this->infoParent($parent))) {
					$this->open($parent);
				}
			}
			$this->focus;
			$this->selectionClear;
			$this->see($path);
			$this->selectionSet($path);
			$this->anchorClear;
 			$this->Callback(-browsecmd => $path);
		}
		else {
			if ($this->cget('-wrapsearch')) {
				$answer = $this->messageBox(
								-title => '(List) Search Operation',
								-message => "No Matching Entry found!\nContinue search from begin of list ?",
								-icon => 'question',
								-popover => 'cursor',
								-type => 'YesNo',
								-default => 'No'
				);		    
			    if ($answer =~ /YES/io) {
			     	$this->afterIdle(sub { $this->__find_hlentry($column, 'NEXT') });   
			    }
			}
			else {
				$this->messageBox(	-title => '(List) Search Operation',
								-message => "No Matching Entry found!",
								-icon => 'info',
								-popover => 'cursor',
								-type => 'OK',
							)		    
			}
			# Assume we want Start another find from scratch next time means wrap-around back to start
			delete $search_info->{LastHLEntry};
		}	    
	}
}
#-----------------------------------------------------------------
# Very internal related function, NOT to be invoked by user apps 
#-----------------------------------------------------------------
sub __find_hlentry_r
{
    #print "DBG: reached function [__find_hlentry_r] with >@_<, called by >", caller, "<\n";
	# Parameters
 	my ($this, $search_item, $column_number, $path, $startpath) = @_;

	# Locals
	my ($result, $child, $data, $id);

	#$result = __test_entry($this, $search_item, $column_number, $path) if $path;
	$result = $path if $path and $this->itemCget($path, $column_number, '-text') =~ /$search_item/;

	#print "DBG: FOUND a MATCH [\$result] = >$result< on >$_< (1)\n" if $result;
	# Skip Search Results until were at the ('NEXT') StartPoint after the last match
	if ($$startpath and $path) {
		$result = undef;
		$$startpath = undef if $$startpath eq $path; # LAST Round : Ignore 1st match, since it WAS the last match
	}
	unless ($result) {
		foreach ($this->infoChildren($path)) {
			#$result = __test_entry($this, $search_item, $column_number, $_);
			$result = $_ if ($this->itemCget($_, $column_number, '-text') =~ /$search_item/);
			#print "DBG: FOUND a MATCH [\$result] = >$result< on >$_< (2)\n" if $result;
			# Skip Search Results until were at the ('NEXT') StartPoint after the last match
			if ($$startpath and $result) {
				$$startpath = undef if $$startpath eq $result; # LAST Round : Ignore 1st match, since it WAS the last match
				$result = undef;
			}
			#print "DBG: --------> [\$result] = >$result< on >$_<\n";
			unless ($result) {
				foreach $child ($this->infoChildren($_)) {
 					$result = __find_hlentry_r($this, $search_item, $column_number, $child, $startpath);
					last if $result;
				}
			}
			last if $result;
		}
	}
	return $result;
}

#-----------------------------------------------------------------
# Very internal related function, NOT to be invoked by user apps 
#-----------------------------------------------------------------
sub __filter_hlentry_r
{
    #print "DBG: reached function [__filter_hlentry_r] with >@_<, called by >", caller, "<\n";
	# Parameters
 	my ($this, $filter_info, $path) = @_;

	# Locals
	my ($needed, @children, $filter_pattern, $column_number, $show_entry,
		$child, $grand_child, @grand_children, $tree_look);
	#print 'DBG: variable [$filter_info] = '; ETC::Universal::print_var($filter_info, 1);

	$needed = 0;
	# Check for Level -1 below (this is because Top-Start $path == "")
	@children = $this->infoChildren($path);
	$this->open($path) if $path and @children and $this->getmode($path) ne 'none';

	foreach $child (@children) {
		$tree_look = $this->getmode($child) ne 'none' ? 1 : 0;
		@grand_children = $this->infoChildren($child);
		if (@grand_children) {
			$this->Activate($child, 'open') if $tree_look;
			foreach $grand_child ($this->infoChildren($child)) {
				$needed |= $this->__filter_hlentry_r($filter_info, $grand_child);
			}
#			$this->Activate($child, 'close') unless $needed;
			$this->Activate($child, 'close') if $tree_look and not $needed;
		}
		else {
			$show_entry = 1;
			foreach $column_number (keys %$filter_info) {
				$filter_pattern = $filter_info->{$column_number};
				if (($this->itemCget($child, $column_number, '-text')||'') !~ /$filter_pattern/) {
		    		$show_entry = 0; last
				}
			}
			if ($show_entry) {
				$needed = 1;		    
				$this->show('entry', $child)
			}
			else {
		    	$this->hide('entry', $child)
			}
		}
	}
	#print 'DBG: Sub-result [$needed] = >' . $needed . "<\n";
	#-------------------------------------------------------------------------------
	# Check for Level -1 immediate (this is for level 2++ $path == "")
	if ($path) {
		if (@children) {
			$this->Activate($path, 'close') unless $needed;
		}
		else {
			$show_entry = 1;
			foreach $column_number (keys %$filter_info) {
				$filter_pattern = $filter_info->{$column_number};
				if (($this->itemCget($path, $column_number, '-text')||'') !~ /$filter_pattern/) {
		    		$show_entry = 0; last
				}
			}
			if ($show_entry) {
				$needed = 1;		    
				$this->show('entry', $path)
			}
			else {
		    	$this->hide('entry', $path)
			}
		}
	}
	#print 'DBG: Final-result [$needed] = >' . $needed . "<\n";
	return $needed
}

#--------------------------------------------------------------------------------------------------
# 
# =for html <hr>  
# 
#  EnterStringDlg()
# 
# IN : I<DialogArgs>
# 
# OUT: I<--->
# 
# B<Description>: 
# Creates & diplays an 'enter-a-string' dialog.
# The entered scalar value is returned. if the
# user presses I<CANCEL> an empty string is returned.
# 
#--------------------------------------------------------------------------------------------------
sub EnterStringDlg
{
	# Parameters
	my ($this, %args) = @_;

	# Locals
	my ($label_text, $new_entry, $buttons, $dbox, $db_frame, $db_entry, $answer, $okstr);

	# Retrieve them and / or assign defaults
	$new_entry			= $args{-value}|| '';
	$buttons			= $args{-buttons} || ['Ok', 'Cancel'];

	# Create the GUI
	$dbox = $this->DialogBox(
		-title => ($args{-title} || 'String Request'),
		-buttons => $buttons,
		-default_button => ($args{-default_button} || 'Ok'),
		-popover => 'cursor',
	);
	$dbox->protocol('WM_DELETE_WINDOW' => sub { $dbox->Exit } );
	$db_frame = $dbox->add('Frame')->pack(qw(-side top -expand  1 -fill x -anchor center));
	$db_frame->Label(-text => "")->pack(-side => 'right');
	$db_frame->Button(
		-text => 'Clear',
		-command => sub { $new_entry = '' },
		-padx => -1, -pady => -1,
	)->pack(qw(-side right -padx 2));
	$db_frame->Label(-text => ($args{-label} || 'Please Enter'))->pack(qw(-side left -anchor w));
	$db_entry = $db_frame->Entry(
		-textvariable => \$new_entry,
		-width => 25,
		-validate => 'key',
		-validatecommand => ($args{-validatecommand} || sub { 1 }),
	)->pack(qw(-side right -expand 1 -fill x -anchor w ));

	if ($new_entry) {
		# SELECT the complete old content and position the cursor to the begin of chars 'anchor'
		$db_entry->selectionClear();
		$db_entry->selectionFrom(0);  #<- set 'anchor'
		$db_entry->selectionTo('end');
		$db_entry->selectionRange(0, 'end'); # <- make it look selected
	}
	$db_entry->focus;
	
	# Present it
	$answer = $dbox->Show();
	$okstr = $buttons->[0];	
	$dbox->destroy;
	$this->idletasks;

	# Must be invoked here(!) after destroy() 
	# to avoid calling 'validate' again
	$new_entry = '' if @$buttons == 2 and $answer !~ /$okstr/i;
	
	# In case of special buttons, return also which Button was pressed
	return wantarray ? ($new_entry, $answer) : [$new_entry, $answer]
}

########################################################################
1;
__END__


=head1 NAME

Tk::Treeplus - A Tree (and/or HList) replacement that supports I<Sorting>, I<Filtering> and I<Resizing> of columns

=head1 SYNOPSIS

 use Tk;
 use Tk::Treeplus;

 my $mw = MainWindow->new();

 # CREATE THE NEW WIDGET
 my $hlist = $mw->Scrolled('Treeplus',
     -columns => 5, 
     -width => 70, height => 30,
    #-browsecmd => sub { print "DBG: browsecmd [".((caller(0))[3])."] with >@_<\n";  },
     -browsecmd => sub {  },
     -wrapsearch => 1,
    #-indicator => 0, # If this is a flat list, we may drop the empty indicator space
 )->pack(-expand => '1', -fill => 'both');

 $hlist->headerCreate(0, 
       -itemtype => 'advancedheader',
       -text => 'ColorName', 
       -activeforeground => 'white',
       -is_primary_column => 1,
 );
 $hlist->headerCreate(1, 
       -itemtype => 'advancedheader',
       -text => 'Red Value', 
       -activebackground => 'orange',
       -resize_column => 1,
 );
 #$hlist->headerCreate(2, 
 #      -itemtype => 'advancedheader',
 $hlist->advancedHeaderCreate(
       -text => 'Green Value', 
       -background => 'khaki',
       -foreground => 'red',
       -command => sub { print("Hello World >@_<, pressed Header #2\n"); },
       -resize_column => 1,
 );
 #$hlist->headerCreate(3, 
 #      -itemtype => 'advancedheader',
 $hlist->advancedHeaderCreate(
       -text => 'Blue Value', 
       -activebackground => 'skyblue',
       # NOTE: The prototyping ($$) is MANDATORY for this search-func to work !!!
       -sort_func_cb => sub ($$) { my ($a, $b) = @_; 
                                   print "EXT: a=>$a<>" . join(',',@$a) . "<\n";
                                   $a->[1] <=> $b->[1] },
 );
 #$hlist->headerCreate(4, 
 #       -itemtype => 'advancedheader',
 $hlist->advancedHeaderCreate(
       -text => 'ColorID', 
       -sort_numeric => 1,
       -resize_column => 1,
 );

 my $image = $hlist->Pixmap(-data => <<'img_demo_EOP'
 /* XPM */
 static char *Up[] = {
 "8 5 3 1",
 ". c none",
 "X c black",
 "Y c red",
 "...YY...",
 "..YXXY..",
 ".YXXXXY.",
 "..YXXY..",
 "...YY...",
 };
 img_demo_EOP
 );
 my $style = $hlist->ItemStyle(qw(imagetext -padx 0 -pady 5 -anchor nw -background forestgreen));
 my $child;
 foreach (qw( orange red green blue purple wheat)) {
     my ($r, $g, $b) = $mw->rgb($_);
     $hlist->add($_, -data => 'data+' . $_, (/blue/ ? (-itemtype => 'imagetext') : ()) );
     $hlist->itemCreate($_, 0, -text => $_, (/blue/ ? (-itemtype => 'imagetext', -image => $image) : ()));
     $hlist->itemCreate($_, 1, -text => sprintf("%#x", $r), style => $style);
     $hlist->itemCreate($_, 2, -text => sprintf("%#x", $g));
     $hlist->itemCreate($_, 3, -text => sprintf("%#x", $b));
     $hlist->itemCreate($_, 4, -text => sprintf("%d", (($r<<16) | ($b<<8) | ($g)) ));
 }
 # Create smoe more dummy entries
 foreach (qw(red green blue)) {
     $child = $hlist->addchild('purple', -data => 'data+purple+' . $_);
     create_columns($child, $_);
 }
 foreach (qw(cyan magenta yellow)) {
     my $gchild = $hlist->addchild($child, -data => 'data+'.$child.'+' . $_);
     create_columns($gchild, $_);
 }

 #-------------------------------------------------------------------
 ### Uncomment either none, #1 or #2 for different scenarios
 #--------------------------------------
 # #1 Test for single closed branch
 #$hlist->setmode($child, 'close');
 #--------------------------------------
 # #2 Test for 'full tree mode'
 $hlist->autosetmode();
 #-------------------------------------------------------------------

 # Refresh the content - sort according primary sort columns
 $hlist->initSort();

 $mw->Button(
     -text => 'Exit',
     -command => sub { exit(0) },
 )->pack(qw(-side bottom -pady 10));

 Tk::MainLoop;

 sub create_columns
 {
     my ($path, $value) = @_;
     my ($r, $g, $b) = $mw->rgb($_);
     $hlist->itemCreate($path, 0, -text => $value);
     $hlist->itemCreate($path, 1, -text => sprintf("%#x", $r));
     $hlist->itemCreate($path, 2, -text => sprintf("%#x", $g));
     $hlist->itemCreate($path, 3, -text => sprintf("%#x", $b));
     $hlist->itemCreate($path, 4, -text => sprintf("%d", (($r<<16) | ($b<<8) | ($g)) ));
 }



=head1 DESCRIPTION

A Tk::Tree (Tk::HList) derived widget that has I<Sortable>, I<Filterable> & I<Resizable> columns.

=head1 METHODS

=over 4

=item B<headerCreate()>

The create command accepts a new, virtual itemtype I<'advancedheader'>, which
will create a header-element with image-based markers for I<sortorder> and current I<filtering> status.
Additionally it has a right-side located optional sensor area for column I<resizing> operations.
Although all options suitable for I<Tk::Buttons> apply, only those related to coloring are recommended,
especially the B<borderwidth> and B<relief> defaults should be B<UNCHANGED>.

In addition, the following options may be specified:

=over 8

=item B<-is_primary_column> 0/1

Mark this column to be the primary one (B<PRIMARYCOLUMN>, s.b.) for any subsequent sort- or filter operation.
This can be changed during runtime by clicking on different columns or via program
by invoking the I<headerConfigure> function (I<headerConfigure($column, -is_primary_column =E<gt> 0/1)>.
Note that I<NO> subsequent call to I<initSort()> is needed to (re)sort the list/tree accordingly,
this is done implicitely.

=item B<-foreground> COLOR

The foreground color used for the column Header in normal state.

=item B<-background> COLOR

The background color used for the column Header in normal state.

=item B<-activeforeground> COLOR

The foreground color used for the column Header during active state (Mouse over Header).

=item B<-activebackground> COLOR

The background color used for the column Header during active state (Mouse over Header).

=item B<-headerminwidth> nnn

Specifies the minimum size of the current column during custom column resizing operation (default: see OPTIONS below)

=item B<-headerclosedwidth> nnn

Specifies the size of the current column in case it is rendered I<closed> (default: see OPTIONS below)


=item B<-sort_numeric> 0/1

Specifies that this column will be sorted B<NUMERIC> (in opposite to the default that is ALPHANUMERIC sorting)

=item B<-sort_func_cb> CB

Specifies that this column will use a custom function specified via B<-sort_func_cb>.
This function gets references for $a and $b. First element is the B<path-id>, second is the text of the currently selected B<PRIMARYCOLUMN>,
and third element is the content of the '-data' element of the current entry.
Note: Due to  internal behavior of perl, it is necessary to define the prototype B<($$)> for this user
search function. Additionally the $a & $b must be pulled of the stack function internally.

 sub sortfunc ($$) { my ($a, $b) = @_; 
                     print "EXT: a=>$a<>" .
                             join(',',@$a) . "<\n";
                     $a->[1] <=> $b->[1]
                   },

Most elegant way is to specify an anonymous sort function in the headerCreate code:

 $hlist->headerCreate(3, 
       -itemtype => 'advancedheader',
       -text => 'Blue Value', 
       -activebackground => 'skyblue',
       # NOTE: The prototyping ($$) is
       # MANDATORY for this search-func to work !!!
       -sort_func_cb =>
           sub ($$) { my ($a, $b) = @_; 
                      print "EXT: a=>$a<>" .
                             join(',',@$a) . "<\n";
                      $a->[1] <=> $b->[1] },
 );


=item B<-command> CB

Specifies a command (function-callback) that becomes executed whenver the column header is
pressed(+released), as for a standard B<'ButtonRelease-1'> event.
See I<headerConfigure()> (below) about how to change this callback at runtime.

=item B<-resize_column> 0/1

This booolean flag decides whether this column is resizable, when the column created.
This can be changed later via I<headerConfigure($column, -resize_column =E<gt> 0/1)>
and probed via I<headerCget()>

=item B<-filter_column> 0/1

Retrieve the current custom I<filter pattern> (perl regex style!) of the given column

=back


=item B<headerConfigure()>

=over 8

=item B<-command> CB

Assign a new I<custom command> to the given column header

=item B<-resize_column> 0/1

Assign a new I<resize status> (0/1) to the given column (header)

=item B<-sort_numeric> 0/1

Change the given sortmode to B<NUMERIC> for the given column
B<Note>: If the given value is 0 and there is no custom sorting the
sortmode switches back to B<ALPHANUMERIC>.

=item B<-sort_func_cb> CB

Assign a new custom I<sort_func> to the given column

=item B<-filter_column> RE

Assign a new custom I<filter pattern> (perl regex style!) to the given column

=back


=item B<headerCget()>

=over 8

=item B<-command>

Retrieve the current I<custom command> assigned to the probed column header

=item B<-resize_column>

Retrieve the current I<resize status> (0/1) of the probed column (header)

=item B<-sort_numeric>

Retrieve the current I<sort_numeric status> (0/1) of the probed column (header)


=item B<-widget> (B<SPECIAL-purpose only>)
 
This command allows with B<-widget> to retrieve the Headerbutton-Widget Reference.
B<NOTE>: This is only useful for very experienced users!

=back

=item B<initSort()>

'initSort( [new_primary_column] )' refreshes the list/tree content
and sorts it according the current settings for the primary sort columns (B<PRIMARYCOLUMN>).
Additionally it takes current filter settings into consideration.

=item B<activateEntry()>

'activateEntry(path)' selects the given entry (if it is existing), opens it (and its parents)
incase it is hidden and executes a potential browsecmd callback on it.
(This is equivalent to clicking an entry in the GUI) 


=item B<advancedHeaderCreate()>

This is an easy-to-use wrapper for
'headerCreate($col++, -itemtype => 'advancedheader', -<...> ... )', it avoids the app to
trace the column numbers and the '-itemtype => 'advancedheader' during headercreate().
Every invocation creates another column header for the next unused column (0,1,...I<n>)
(NB> Max column number I<n> must be set in advance during treeplus item-creation.


=back

=head1 OPTIONS (CreateTime)

=over 4

=item B<-wrapsearch> 0/1

Decides whether the I<Find> search will restart from the begin of the list in case it reaches the end.

=item B<-maxselhistory> nnn

Specifies the maximum number of I<chached> list-selection operations, which can be recalled via the pop-up-menu.

=item B<-clipboardseparator> CHAR

Specifies the B<colum separator character> which is used if the the current selection is export to the X11 Clipboard.
This operation can be done via CTRl-C or via the pop-up-menu. (default char: '|')

=item B<-headerminwidth> nnn

Specifies the minimum size of a column during custom column resizing operation (default: 20px)

=item B<-headerclosedwidth> nnn

Specifies the size of a I<closed> column (default: 5px)


=item B<-headerforeground> COLOR

The foreground color used for the column Header in normal state.

=item B<-headerbackground> COLOR

The background color used for the column Header in normal state.

=item B<-headeractiveforeground> COLOR

The foreground color used for the column Header during active state (Mouse over Header).

=item B<-headeractivebackground> COLOR

The background color used for the column Header during active state (Mouse over Header).



=back

=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net


This code may be distributed under the same conditions as Perl.

V0.4  (C) February 2013

=cut

###
### EOF
###


