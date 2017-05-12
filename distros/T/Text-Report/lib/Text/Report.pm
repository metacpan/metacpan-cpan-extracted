# ***********************************************************************
# Report                                                                *
#                                                                       *
# Discussion:                                                           *
#                                                                       *
# Input:                                                                *
# Output:                                                               *
# Manager: D. Huggins (email removed)                                   *
# Company: Full-Duplex Communications Corporation                       *
#          http://www.full-duplex.com                                   *
#          http://www.in-brandon.com                                    *
# Start:   Wednesday, 17 January, 2007                                  *
# Version: 1.004                                                        *
# Release: 07.07.09.09:06                                               *
# Status:  PRODUCTION                                                   *
# ***********************************************************************

# All rights reserved by Full-Duplex Communications Corporation
#                  Copyright 2003 - 2007                       
package Text::Report;

$Text::Report::VERSION = '1.004';
@Text::Report::ISA = qw(Text);


BEGIN
{
   eval "use Storable qw(store retrieve dclone)";
   $Text::Report::stor_loaded = $@ ? 0 : 1;
};

use strict;
# use warnings;

use vars qw/ $VERSION @ISA/;

# use Data::Dumper;
use Carp;


our $AUTOLOAD;


my %debug_lev = 
   (
      'off'       => 0,
      'notice'    => 1,
      'warning'   => 2,
      'error'     => 3,
      'critical'  => 4,
   );

1;


# autoindex => 1/0, # Report.pm sets print order of blocks based upon 
#                     creation (defblock()) order; DEFAULT=1 (strongly recommended)
# logfh => *FH
# debug => ['off' | 'notice' | ...] str # Sets debug level; Default is 'critical'
# debugv => 1/0 # carp longmess | shortmess
# autoindex => 1/0 # If set (DEFAULT), Report.pm will index block print 
#                    order in the same order as the block was defblock'd
sub new
{
   my $class = shift;
   my %this = @_;
   
   my $self = {};
   
   $self->{_page}{_index} = 0;
   
   $self->{_page}{_line} = 
      {
         'dotted_line' => '.',
         'dbl_line'    => '=',
         'single_line' => '-',
         'under_line'  => '_',
         'blank_line'  => ' ',
      };
   
   bless $self, $class;
   
   # --- Build the default _report --- #
   $self->_default_report('report');
   
   # --- Changed 'Log' to 'logfh' in v1.003 --- #
   if($this{Log}){$this{logfh} = $this{Log};}
   
   # ---------------------------------------- #
   # --- Either we get a FH or use STDOUT --- #
   # ---------------------------------------- #
   $self->{_log}{_file} = ref $this{logfh} ? $this{logfh} : \*STDOUT;
   $self->{_debug}{_lev} = $this{debug} ? $debug_lev{$this{debug}} : 1;
   $self->{_debug}{_verbose} = $this{debugv} ? 1 : 0;
   
   # ------------------------------------------------ #
   # --- $this{autoindex} can only be set on init --- #
   # ------------------------------------------------ #
   $self->{_page}{_profile}{report}{autoindex} = $this{autoindex} ? $this{autoindex} : 1;
   
   delete $this{logfh}; delete $this{debug}; delete $this{debugv};
   
   # --- Build the default _block --- #
   $self->_default_block('_block');
   
   # ---------------------------------------------------- #
   # --- Build the report page layout w/modifications --- #
   # --- to the default block, if any                 --- #
   # ---------------------------------------------------- #
   $self->configure(%this);

   return $self;
}

# --- Define Report Properties --- #
# width => int, # Report width DEFAULT=80
# asis => 1/0, # Report.pm sets all block titles to caps & adds underline; DEFAULT=0
# debug => [off|notice|error|warning|critical] # Level of debug; DEFAULT='warning'
# debugv => 1/0 # Verbose mode using carp(longmess|shortmess)
# blockPad => {top => int, bottom => int} # Set global block padding
# column => int => {width => int, align => 'left', head => 'str'}
# useColHeaders => 1/0 # Off (DEFAULT) means that no col headers will be printed or auto generated
# sortby => int # Col number to sort 2-dimensional array; Zero for no sort oder
sub configure
{
   my $self = shift;
   
   my %this = @_ ? @_ : return(undef);
   
   my @idx = keys %{$self->{_page}{_profile}{report}};
   
   for(@idx)
   {
      next if /^autoindex$/;
      if(defined $this{$_}){$self->{_page}{_profile}{report}{$_} = $this{$_}}
   }
   
   $self->{_debug}{_lev} = $debug_lev{ $this{debug} } if defined $this{debug} && 
      $this{debug} =~ /^(off|notice|error|warning|critical)$/i;
   $self->{_debug}{_verbose} = $this{debugv} if defined $this{debugv};
   
   
   # --- To use or not to use Headers --- #
   $self->{_block}{_profile}{'_block'}{useColHeaders} = $this{useColHeaders}
      if defined $this{useColHeaders};
   
   # --- Set column to sort by (zero/undef = no sort) --- #
   $self->{_block}{_profile}{'_block'}{sortby} = $this{sortby}
      if defined $this{sortby} && $this{sortby} =~ /^\d+$/;
   
   if(defined $this{width})
   {
      # --- Set default page width --- #
      $self->{_page}{_profile}{report}{width} = $this{width};
      # --- Set default block col width --- #
      $self->{_block}{_profile}{'_block'}{column}{1}{width} = $this{width};
   }
   
   # -------------------------------------------------- #
   # --- Overwrite any existing (eg default _block) --- #
   # --- col def's                                  --- #
   # -------------------------------------------------- #
   if($this{column})
   {
      return undef unless $this{column} =~ /HASH/;
      # --- Test keys - Expect int --- #
      my @int = keys %{$this{column}} || return undef;
      for(@int){return undef unless /^\d+$/;}
      delete $self->{_block}{_profile}{'_block'}{column}; # reset
      
      foreach my $col(keys %{$this{column}})
      {
         $self->setcol('_block', $col, %{$this{column}{$col}});
      }
   }
   
   if(defined $this{blockPad})
   {
      eval{
      for(keys %{$self->{_block}{_profile}{'_block'}{pad}})
      {
         $self->{_block}{_profile}{'_block'}{pad}{$_} = $this{blockPad}{$_}
            if defined $this{blockPad}{$_};
      }};
      
      if($@)
      {
         $self->_debug(4, "configure(pad => {top => int, bottom => int}) syntax - $@");
         return undef;
      }
   }
   
   $self;
}

# --- Define Block Properties --- #
# name => 'sd1', # No name, no define
# title => 'Sample Data One', # DEFAULT - undef
# order => $order_idx++, # Block print order, only used if new(autoindex => 0)
# sortby => 1, # Column to sort. DEFAULT=0 (no sorting)
# sorttype => 'alpha', # DEFAULT: 'alpha' | 'numeric'
# orderby => 'ascending', # DEFAULT: 'ascending' | 'descending'
# useColHeaders => 0, # Set to 1 to display headers & header underlines at col head
# column => {1 => {width => 10, align => 'left',  head => 'ColOne',},}, # head is opt
# cols =>  int GT zero # Tell Report.pm to autocreate x number of cols; Used INSTEAD of columns{}
# pad => {top => int, bottom => int} # Number of blank lines to pad beginning & end of block
# columnWidth => int GT zero # Set block default widths
# columnAlign => [left|right|center] # Set block default alignments
sub defblock # Define Block - New blocks only
{
   my $self = shift;
   my %this = @_;
   
   # -------------------------- #
   # --- Need a block name  --- #
   # -------------------------- #
   unless(defined $this{name})
   {
      $self->_debug(3, 
         "defblock() Attempt to create a block with no \'name\'. ".
         "Modify the default block using setblock() or call defblock() ".
         "using defblock( name => \'block_name\')");
      
      return(undef);
   }
   
   # ------------------------------------------- #
   # --- Use configure() to alter the global --- #
   # --- properties of the default '_block'  --- #
   # ------------------------------------------- #
   if($this{name} =~ /^\_block/)
   {
      $self->_debug(3, 
         "defblock(name => \'_block\') Attempt to create a block with default block name. ".
         "Modify the default block using configure() or call defblock() ".
         "using defblock( name => \'block_name\')");
      
      return(undef);
   }
   
   my $blockname = $this{name};
   
   my $cols;
   
   # ------------------------------------------------ #
   # --- Do  not allow the caller to use defblock --- #
   # --- if it has already been def'd. Send the   --- #
   # --- caller to delblock()                     --- #
   # ------------------------------------------------ #
   if(defined $self->{_block}{_profile}{$blockname})
   {
      $self->_debug(2, 
         "defblock() Attempt to create an already defined block. ".
         "Modify block using setblock() or delete block first using ".
         "delblock(\'block_name\')");
      
      return(undef);
   }
   
   # --------------------------- #
   # --- Assign the defaults --- #
   # --------------------------- #
   unless(defined $self->{_block}{_profile}{$blockname})
   {
      $self->_assign_def_block($blockname);
   }
   
   # ------------------------- #
   # --- Block-end padding --- #
   # ------------------------- #
   eval{
   if(defined $this{pad}{top} && $this{pad}{top} =~ /^\d+$/)
   {
      $self->{_block}{_profile}{$blockname}{pad}{top} = $this{pad}{top};
   }
   else
   {
      $self->{_block}{_profile}{$blockname}{pad}{top} = $self->{_block}{_profile}{'_block'}{pad}{top};
   }
   if(defined $this{pad}{bottom} && $this{pad}{bottom} =~ /^\d+$/)
   {
      $self->{_block}{_profile}{$blockname}{pad}{bottom} = $this{pad}{bottom};
   }
   else
   {
      $self->{_block}{_profile}{$blockname}{pad}{bottom} = $self->{_block}{_profile}{'_block'}{pad}{bottom};
   }};

   # --- Trap incomplete hash --- #
   if($@){$self->_debug(4, "defblock(pad => {top => int, bottom => int}) syntax - $@"); return undef}
   
   # ------------------- #
   # --- Block Title --- #
   # ------------------- #
   $self->{_block}{_profile}{$blockname}{title} = $this{title} || undef;
   
   # -------------------------------------------------- #
   # --- Does caller want us to automatically build --- #
   # --- headers for this block? setcol() handles   --- #
   # --- the rest                                   --- #
   # -------------------------------------------------- #
   if(defined $this{useColHeaders})
   {
      $self->{_block}{_profile}{$blockname}{useColHeaders} = $this{useColHeaders};
   }
   else
   {
       $self->{_block}{_profile}{$blockname}{useColHeaders} = $self->{_block}{_profile}{'_block'}{useColHeaders}
   }
      
   # --------------------------------------------- #
   # --- Did the caller pass default alignment --- #
   # --- &/or col width? If so, get these set  --- #
   # --- before cols are built                 --- #
   # --------------------------------------------- #
   if(defined $this{columnWidth} && $this{columnWidth} =~ /^\d+$/ && $this{columnWidth} > 0)
   {
      $self->{_block}{_profile}{$blockname}{width} = $this{columnWidth};
      
      # ------------------------------------------- #
      # --- Col 1 is pre-defined at 'center'/80 --- #
      # --- Adjust here                         --- #
      # ------------------------------------------- #
      $self->{_block}{_profile}{$blockname}{'column'}{1}{'width'} = $this{columnWidth};
      
   }
   else
   {
      $self->{_block}{_profile}{$blockname}{width} = $self->{_page}{_profile}{report}{width};
   }
   
   if(defined $this{columnAlign} && $this{columnAlign} =~ /^(left|right|center)$/i)
   {
      $self->{_block}{_profile}{$blockname}{align} = lc($this{columnAlign});
      
      # ------------------------------------------- #
      # --- Col 1 is pre-defined at 'center'/80 --- #
      # --- Adjust here                         --- #
      # ------------------------------------------- #
      $self->{_block}{_profile}{$blockname}{'column'}{1}{'align'} = lc($this{columnAlign});
   }
   
   # -------------------------------------------------- #
   # --- Overwrite any existing (eg default _block) --- #
   # --- col def's                                  --- #
   # -------------------------------------------------- #
   if($this{column})
   {
      delete $self->{_block}{_profile}{$blockname}{column}; # reset
      
      foreach my $col(keys %{$this{column}})
      {
         $self->setcol($blockname, $col, %{$this{column}{$col}});
      }
   }
   # ----------------------------------------------------------------------- #
   # --- Allow caller to generate cols using preset default width, align --- #
   # --- Column widths are calc'd by dividing the current page width by  --- #
   # --- number of columns unless we are passed a columnWidth. An       --- #
   # --- attempt is made to use it. If the total width is GT the page    --- #
   # --- width, then we revert to calc'ing using prev formula            --- #
   # ----------------------------------------------------------------------- #
   elsif(defined $this{cols} && $this{cols} =~ /^\d+$/ && $this{cols} > 0)
   {
      # --- Clear existing columns --- #
      delete $self->{_block}{_profile}{$blockname}{column}; # reset
      
      # ----------------------------------------------- #
      # --- Next, make sure all of this is going to --- #
      # --- fit on the report page                  --- #
      # ----------------------------------------------- #
      my $pg_width = $self->{_page}{_profile}{report}{width};
      my $tl_block_width = $this{cols} * ($self->{_block}{_profile}{$blockname}{width});
      
      # ------------------------------- #
      # --- If it doesn't, force it --- #
      # ------------------------------- #
      if($tl_block_width > $pg_width)
      {
         # -------------------------------------------------- #
         # --- Recalc col width based upon the page width --- #
         # --- divided by number of cols requested        --- #
         # -------------------------------------------------- #
         eval{$self->{_block}{_profile}{$blockname}{width} = 
            ($self->{_page}{_profile}{report}{width} / $this{cols});};
         
         # --- $this{cols} is > zero, so shouldn't be a prob --- #
         if($@){$self->_debug(2, "Col width 102 calc err for block ($blockname) - $@");}
         
         # --- Clean up --- #
         $self->{_block}{_profile}{$blockname}{width} = 
            sprintf("%0.0f\n", $self->{_block}{_profile}{$blockname}{width});
         
         # --- Adjust --- #
         $self->{_block}{_profile}{$blockname}{width} -= 2;
         
         $self->_debug(1, "Calculated col width = ".
            "$self->{_block}{_profile}{$blockname}{width} for block ($blockname)");
      }
      
      for(my $i = 1; $i <= $this{cols}; $i++)
      {
         $self->setcol($blockname, $i, 
                        width => $self->{_block}{_profile}{$blockname}{width},
                        align => $self->{_block}{_profile}{$blockname}{align},
                        head => $this{head}->[$i-1],
                        );
      }
   }
   # --- Otherwise use the default:  1 col, center, 80 chars wide --- #
   
   
   # ----------------------------------- #
   # --- Determine block print order --- #
   # ----------------------------------- #
   if($self->{_page}{_profile}{report}{autoindex})
   {
      # --- Add auto print sequence to _order --- #
      $self->{_order}{_block}{$self->{_page}{_index}++} = $blockname;
   }
   else
   {
      unless($this{order} =~ /^\d+$/)
      {
         $self->_debug(3, 
            "defblock(order) Need print order sequence number to process block ".
            "$blockname. Call defblock() using defblock(order => int)");
         
         return(undef);
      }
      
      $self->{_order}{_block}{$this{order}} = $blockname;
   }
   
   # --------------------------------- #
   # --- Define column to sort on  --- #
   # --- The DEFAULT is no sorting --- #
   # --------------------------------- #
   if(defined $this{sortby} && $this{sortby} =~ /^\d+$/)
   {
      $self->{_block}{_profile}{$blockname}{sortby} = $this{sortby};
   }
   
   # --------------------------------- #
   # --- Define sort type          --- #
   # --------------------------------- #
   if(defined $this{sorttype} && $this{sorttype} =~ /^(alpha|numeric)$/i)
   {
      $self->{_block}{_profile}{$blockname}{sorttype} = lc($this{sorttype});
   }
   
   # -------------------------------- #
   # --- Define sort direction    --- #
   # -------------------------------- #
   if(defined $this{orderby} && $this{orderby} =~ /^(ascending|descending)$/i)
   {
      $self->{_block}{_profile}{$blockname}{orderby} = lc($this{orderby});
   }
   
   $self;
}
# --- Alter An Existing Block's Properties --- #
# title => 'Sample Data One', # DEFAULT - undef
# order => $order_idx++, # Block print order, only used if new(autoindex => 0)
# sortby => 1, # Column to sort. DEFAULT=0
# sorttype => 'alpha', # DEFAULT: 'alpha' | 'numeric'
# orderby => 'ascending', # DEFAULT: 'ascending' | 'descending'
# pad => {top => int, bottom => int} # Number of blank lines to pad beginning & end of block
# useColHeaders => 1/0 # Turn on/off column headers & their assoc underlines
sub setblock
{
   my $self = shift;
   
   my %this = @_ ? @_ : return(undef);
   
   my $blockname;
   
   return undef unless $blockname = $this{name};
   
   # ----------------------------------------- #
   # --- Do not modify the default '_block --- #
   # --- here - Use configure()            --- #
   # ----------------------------------------- #
   return undef if $blockname =~ /^\_block$/;
   
   # --------------------------------------------------------- #
   # --- This method is only for modifying existing blocks --- #
   # --------------------------------------------------------- #
   unless(defined $self->{_block}{_profile}{$blockname})
   {
      $self->_debug(3, "setblock() Attempt to modify a non-defined block. ".
         "Create block using defblock()");
      return undef;
   }
   
   # ------------------------- #
   # --- Block-end padding --- #
   # ------------------------- #
   eval{
   if(defined $this{pad}{top} && $this{pad}{top} =~ /^\d+$/)
   {
      $self->{_block}{_profile}{$blockname}{pad}{top} = $this{pad}{top};
   }
   else
   {
      $self->{_block}{_profile}{$blockname}{pad}{top} = $self->{_block}{_profile}{_block}{pad}{top};
   }
   if(defined $this{pad}{bottom} && $this{pad}{bottom} =~ /^\d+$/)
   {
      $self->{_block}{_profile}{$blockname}{pad}{bottom} = $this{pad}{bottom};
   }
   else
   {
      $self->{_block}{_profile}{$blockname}{pad}{bottom} = $self->{_block}{_profile}{_block}{pad}{bottom};
   }};
   
   # --- Trap incomplete hash --- #
   if($@){$self->_debug(4, "setblock(pad => {top => int, bottom => int}) syntax - $@"); return undef}
   
   # ------------------- #
   # --- Block Title --- #
   # ------------------- #
   $self->{_block}{_profile}{$blockname}{title} = $this{title} if defined $this{title};
   
   # ---------------------- #
   # --- Column Headers --- #
   # ---------------------- #
   $self->{_block}{_profile}{$blockname}{useColHeaders} = $this{useColHeaders} if defined $this{useColHeaders};
   
   # ----------------------------------- #
   # --- Determine block print order --- #
   # ----------------------------------- #
   if(defined $this{order} && $this{order} =~ /^\d+$/)
   {
      if($self->{_page}{_profile}{report}{autoindex})
      {
         $self->_debug(2, 'setblock() Cannot set order if Report object init\'d with autoindex. '.
            'Create Text::Report->new(autoindex => 0) the default is on');
      }
      else{$self->{_order}{_block}{$this{order}} = $blockname;}
   }
   
   # --------------------------------- #
   # --- Define column to sort on  --- #
   # --- The DEFAULT is no sorting --- #
   # --------------------------------- #
   if(defined $this{sortby} && $this{sortby} =~ /^\d+$/)
   {
      $self->{_block}{_profile}{$blockname}{sortby} = $this{sortby};
   }
   
   # -------------------------------- #
   # --- Define sort type         --- #
   # -------------------------------- #
   if(defined $this{sorttype} && $this{sorttype} =~ /^(alpha|numeric)$/i)
   {
      $self->{_block}{_profile}{$blockname}{sorttype} = lc($this{sorttype});
   }
   
   # -------------------------------- #
   # --- Define sort direction    --- #
   # -------------------------------- #
   if(defined $this{orderby} && $this{orderby} =~ /^(ascending|descending)$/i)
   {
      $self->{_block}{_profile}{$blockname}{orderby} = lc($this{orderby});
   }
   
   $self;
}
# Set/change Column Properties
# $obj->setcol($blockname, $colnumber, align => [left|right|center], width => int, head => 'str')
# align => [left|right|center] # 
# width => int GT zero # 
# head => 'str' # Column header
sub setcol
{
   my $self = shift;
   my $blockname = shift;
   my $number = shift;
   
   my %this = @_ ? @_ : return(undef);
   
   return undef unless $number =~ /^\d+$/;
   
   unless(defined $blockname){$blockname = '_block';}
   
   
   # ---------------------------------------- #
   # --- If the caller has not def'd this --- #
   # --- $blockname, right back at 'em    --- #
   # ---------------------------------------- #
   unless(defined $self->{_block}{_profile}{$blockname})
   {
      $self->_debug(3, "setcol() Attempt to modify a non-defined block. ".
                        "Create block first using defblock()");
      return undef;
   }
   
   if(defined $this{align} && $this{align} =~ /^(left|right|center)$/i)
   {
      $self->{_block}{_profile}{$blockname}{column}{$number}{align} = lc($this{align});
   }
   else # use our built-in default
   {
      unless(exists $self->{_block}{_profile}{$blockname}{column}{$number}{align})
      {
         $self->{_block}{_profile}{$blockname}{column}{$number}{align} = $self->{_block}{_profile}{$blockname}{align};
         $self->_debug(1, "setcol(align) param not set for col number \"$number\". ".
            "Defining col align as \"$self->{_block}{_profile}{$blockname}{align}\"");
      }
   }
   
   if(defined $this{width} && $this{width} =~ /^\d+$/ && $this{width} > 0)
   {
      $self->{_block}{_profile}{$blockname}{column}{$number}{width} = $this{width};
   }
   else
   {
      unless(exists $self->{_block}{_profile}{$blockname}{column}{$number}{width})
      {
         $self->{_block}{_profile}{$blockname}{column}{$number}{width} = $self->{_block}{_profile}{$blockname}{width};
         $self->_debug(1, "setcol(width) param not set for col number \"$number\". ".
            "Defining col width as \"$self->{_block}{_profile}{$blockname}{width}\"");
      }
   }
   
   if(defined $this{head})
   {
      $self->{_block}{_profile}{$blockname}{column}{$number}{head} = $this{head};
   }
   else
   {
      if($self->{_block}{_profile}{$blockname}{useColHeaders})
      {
         unless(exists $self->{_block}{_profile}{$blockname}{column}{$number}{head})
         {
            $self->{_block}{_profile}{$blockname}{column}{$number}{head} = $number;
            $self->_debug(1, "setcol(\'block_name\', col_num, head => ".
               "\"Header Title\") param not set \& \'useColHeaders\' flag ".
               "is set. Defining col header as \"$number\"");
         }
      }
   }
   
   $self;
}

# Insert a page separation line
# order => int # unless autoindex is set
# pad => {top => int, bottom => int}
# width => int # override the default width (page width)
sub insert
{
   my $self = shift;
   my $line_type = shift;
   my %this = @_;
   
   my $blockname;
   
   # ----------------------------------- #
   # --- Determine block print order --- #
   # ----------------------------------- #
   if($self->{_page}{_profile}{report}{autoindex})
   {
      $blockname = "__separator_$self->{_page}{_index}";
      
      # ----------------------------------------- #
      # --- Add auto print sequence to _order --- #
      # ----------------------------------------- #
      $self->{_order}{_block}{$self->{_page}{_index}++} = $blockname;
   }
   else
   {
      unless($this{order} =~ /^\d+$/)
      {
         $self->_debug(3, 
            "insert(order) Need print order sequence number to process ".
            "separator. Call insert() using insert(\'line_type\', order => int)");
         
         return(undef);
      }
      
      $blockname = "__separator_$this{order}";
      
      $self->{_order}{_block}{$this{order}} = $blockname;
   }
   
   # --- Create a new block --- #
   $self->_default_block($blockname);
   
   # --- No headers will be used --- #
   $self->{_block}{_profile}{$blockname}{useColHeaders} = 0;
   
   # --- Set width - either by callers specs or use page def --- #
   $self->{_block}{_profile}{$blockname}{width} = $this{width} || $self->{_page}{_profile}{report}{width};
   
   # --- Reset, if necessary, the col width --- #
   $self->setcol($blockname, 1, width => $self->{_block}{_profile}{$blockname}{width});
   
   # ------------------------------------ #
   # --- Set padding if any requested --- #
   # ---                              --- #
   # --- We don't use the default pad --- #
   # --- here. The caller must        --- #
   # --- specifically request padding --- #
   # ------------------------------------ #
   my @insert;
   
   if(defined $this{pad})
   {
      eval{
      for(1 .. $this{pad}{top})
         {push(@insert, [$self->_draw_line('blank_line', $self->{_page}{_profile}{report}{width})]);}
      
      push(@insert, [$self->_draw_line($line_type, $self->{_page}{_profile}{report}{width})]);
      
      for(1 .. $this{pad}{bottom})
         {push(@insert, [$self->_draw_line('blank_line', $self->{_page}{_profile}{report}{width})]);}};
   }
   else
   {
      push(@insert, [$self->_draw_line($line_type, $self->{_page}{_profile}{report}{width})]);
   }
   
   $self->fill_block($blockname, @insert);
   $self;
}
###########################
# $obj->fill_block('named_block', @AoA)
#                                      
# Fill formatted, named block w/data
# passed to us in table form where 
# @_ = [array1],[array2],[array3]...
sub fill_block
{
   my $self = shift;
   my $blockname = shift;
   my @table = @_; # AoA
   
   unless(defined $self->{_block}{_profile}{$blockname})
   {
      $self->_debug(3, "fill_block() Attempt to fill a non-defined block. ".
                        "Create block first using defblock()");
      return undef;
   }
   
   my @fCol; my @csv;
   
   my %align = (left => '<', center => '|', right => '>', );
   
   my @col_head;
   
   foreach my $col(sort _numeric(keys %{$self->{_block}{_profile}{$blockname}{column}}))
   {
      # ---------------------- #
      # --- Column attribs --- #
      # ---------------------- #
      my $align = $align{ $self->{_block}{_profile}{$blockname}{column}{$col}{align} };
      my $width = $self->{_block}{_profile}{$blockname}{column}{$col}{width};
      
      # ---------------------- #
      # --- Column header  --- #
      # ---------------------- #
      if(defined $self->{_block}{_profile}{$blockname}{column}{$col}{head})
      {
         push(@col_head, $self->{_block}{_profile}{$blockname}{column}{$col}{head});
      }
      
      push(@fCol, '@'.$align x $width);
   }
   
   my $columns = join(" ", @fCol);
   
   
   my $format = 'formline <<"END", @data;'."\n".'$columns'."\n"."END";
   
   # ------------------------------------------------------------ #
   # --- Build title & column headers first time through only --- #
   # ------------------------------------------------------------ #
   unless($self->{_block}{_profile}{$blockname}{_append})
   {
      $self->{_block}{_profile}{$blockname}{_append} = 1;
      # ------------------- #
      # --- Place Title --- #
      # ------------------- #
      if($self->{_block}{_profile}{$blockname}{title})
      {
         unless($self->{_page}{_profile}{report}{asis})
         {
            # --- Store title & header data in {hdata} --- #
            # --- to retain for template building      --- #
            push(@{$self->{_block}{_profile}{$blockname}{hdata}}, uc($self->{_block}{_profile}{$blockname}{title}));
            
            # --- Title Underline --- #
            my @chars = split('', $self->{_block}{_profile}{$blockname}{title}); # Get char count
            push(@{$self->{_block}{_profile}{$blockname}{hdata}}, ($self->_draw_line('single_line', scalar(@chars))));
            
            push(@csv, uc($self->{_block}{_profile}{$blockname}{title}));
         }
         else
         {
            push(@{$self->{_block}{_profile}{$blockname}{hdata}}, $self->{_block}{_profile}{$blockname}{title});
            push(@csv, $self->{_block}{_profile}{$blockname}{title});
         }
         
         # --------------------------- #
         # --- Pad the block title --- #
         # ---     CONSTANT        --- #
         # --------------------------- #
         unless($self->{_page}{_profile}{report}{asis})
         {
            push(@{$self->{_block}{_profile}{$blockname}{hdata}}, ($self->_draw_line('blank_line', 1)));
         }
      }
      
      if($self->{_block}{_profile}{$blockname}{useColHeaders})
      {
         # ---------------------------- #
         # --- Build Column Headers --- #
         # ---------------------------- #
         my @data = @col_head; 
         
         eval $format;
         
         if($@){$self->_debug(3, "Internal/system Error - $@");} # Who the hell knows?
         
         chomp($^A);
         push(@{$self->{_block}{_profile}{$blockname}{hdata}}, $^A);
         $^A = '';
         
         # -------------------------------- #
         # --- Column Header Underlines --- #
         # -------------------------------- #
         my @col_underline;
         
         my $i = 0;
         for(@col_head)
         {
            my $chars = $self->{_block}{_profile}{$blockname}{column}{++$i}{width}; # Width of col
            push(@col_underline, ($self->_draw_line('under_line', $chars)));
         }
         
         @data = (); # reset data
         
         @data = @col_underline;
         
         eval $format;
         
         if($@){$self->_debug(3, "Internal/system Error - $@");}
         
         chomp($^A);
         push(@{$self->{_block}{_profile}{$blockname}{hdata}}, $^A);
         $^A = '';
      }
      
      if(@col_head > 1){push(@csv, join(',', @col_head));}
      if(@col_head == 1){push(@csv, $col_head[0]);}
   }
   
   my @sorted = $self->_sort($blockname, @table);
   
   # ---------------------------- #
   # --- Add the data portion --- #
   # ---------------------------- #
   my $debug = 0;
   
   foreach my $block(@sorted)
   {
      my @data = @{$block};
      
      push(@csv, join(',', @{$block}));
      
      eval $format;
      
      # ------------------------------------------ #
      # --- This should never happen, but then --- #
      # --- what do i know                     --- #
      # ------------------------------------------ #
      if($@)
      {
         $self->_debug(4, 'Internal/system Error - Data format failure. Please '.
            'contact your system administrator. I\'m sure he\'ll know what to do.'.
            "ABEND - $@");
         
         die $@;
      }
      
      chomp($^A); push(@{$self->{_block}{_profile}{$blockname}{data}}, $^A);
      $^A = '';
   }
   # ---------------------- #
   # --- Store csv data --- #
   # ---------------------- #
   for(@csv){push(@{$self->{_block}{_profile}{$blockname}{_csv}}, $_);}
   
   $self;
}

# $obj->report('get'); # Return report lines w/in array
# $obj->report('print'); # STDOUT
# $obj->report('csv'); # Retrieve csv data
sub report
{
   my $self = shift;
   
   my %this; my @page = ();
   
   $this{lc(shift)} = 1;
   
   
   if(defined $self->{_order}{_block})
   {
      # ---------------------------------------- #
      # --- If a named block has no 'order', --- #
      # --- it will be silently ignored      --- #
      # ---------------------------------------- #
      BLOCK: foreach my $key(sort _numeric(keys %{$self->{_order}{_block}}))
      {
         my $blockname = $self->{_order}{_block}{$key};
         
         if($this{'csv'})
         {
            push(@page, $self->{_block}{_profile}{$blockname}{_csv});
            next BLOCK;
         }
         
         # ----------------------- #
         # --- Top pad, if any --- #
         # ----------------------- #
         if(defined $self->{_block}{_profile}{$blockname}{pad}{top} && $self->{_block}{_profile}{$blockname}{pad}{top} > 0)
         {
            if($this{'print'}){print "\n" x $self->{_block}{_profile}{$blockname}{pad}{top};}
            else
            {
               for(1 .. $self->{_block}{_profile}{$blockname}{pad}{top})
               {
                  push(@page, " ");
               }
            }
         }
         
         # --- Top-of-block data --- #
         if(exists $self->{_block}{_profile}{$blockname}{hdata})
         {
            for(@{$self->{_block}{_profile}{$blockname}{hdata}})
            {
               if($this{'print'}){print "$_\n";}
               else{push(@page, $_);}
            }
         }
         # --- Collected data --- #
         for(@{$self->{_block}{_profile}{$blockname}{data}})
         {
            if($this{'print'}){print "$_\n";}
            else{push(@page, $_);}
         }
         
         # -------------------------- #
         # --- Bottom pad, if any --- #
         # -------------------------- #
         if(defined $self->{_block}{_profile}{$blockname}{pad}{bottom} && $self->{_block}{_profile}{$blockname}{pad}{bottom} > 0)
         {
            if($this{'print'}){print "\n" x $self->{_block}{_profile}{$blockname}{pad}{bottom};}
            else
            {
               for(1 .. $self->{_block}{_profile}{$blockname}{pad}{bottom})
               {
                  push(@page, " ");
               }
            }
         }
      }
   }
   # --- No order, no laundry --- #
   else
   {
      $self->_debug(3, 'Block print order has not been set. Either create Report object using '.
         'Text::Report->new(autoindex => 1) or use $obj->defblock(order => int).'.
         "Cannot print report");
      $self->{_err} = 1;
      push(@{$self->{_errors}}, ["Block print order has not been set. Cannot print report"]);
      
      return undef;
   }
   
   return @page ? @page : undef;
}
# Use this meth to retrieve csv data for block(s)
#  use $obj->report('csv') to retrieve csv data
#  for entire report
# $obj->get_csv(blockname1, blockname2, ...);
sub get_csv
{
   my $self = shift;
   
   my @list;
   
   for(@_ ? @_ : return(undef))
   {
      push(@list, $self->{_block}{_profile}{$_}{_csv});
   }
   
   return(@list);
}

# --------------------------------------------------- #
# --- Reset Named Block to orig default settings. --- #
# --- Overrides any changes made to '_block'      --- #
# --------------------------------------------------- #

# $obj->rst_block($block_name)
# Resets named block to defaults
# If $block_name does not exist, creates new block $block_name and applies defaults.
sub rst_block
{
   my $self = shift;
   
   $self->_default_block((shift));
   
   $self;
}

# $obj->del_block($block_name)
# Deletes Named Block
sub del_block
{
   my $self = shift;
   my $blockname = shift;
   
   delete $self->{_block}{_profile}{$blockname};
   
   $self;
}

# $obj->clr_block_data($block_name)
# Clears data & csv data from Named Block
sub clr_block_data
{
   my $self = shift;
   my $blockname = shift;
   
   delete $self->{_block}{_profile}{$blockname}{data};
   delete $self->{_block}{_profile}{$blockname}{_csv};
   # delete $self->{_block}{_profile}{(shift)}{hdata};
   
   $self;
}

# $obj->clr_block_headers($block_name)
# Clears hdata (header data) from Named Block
sub clr_block_headers
{
   my $self = shift;
   my $blockname = shift;
   
   delete $self->{_block}{_profile}{$blockname}{hdata};
   
   # --- Reset "header set" flag --- #
   $self->{_block}{_profile}{$blockname}{_append} = undef;
   
   $self;
}

# $obj->named_blocks
# Returns an array of all named_block's defined
sub named_blocks
{
   return(keys %{shift->{_block}{_profile}});
}

# $obj->linetypes
# Returns an array of avail line types
sub linetypes
{
   return keys %{shift->{_page}{_line}};
}

# Maybe someday:
# sub order
# {
#    my $self = shift;
#    my %order = @_;
#    
#    # --- Cannot change order if autoindex is set --- #
#    if($self->{_page}{_profile}{report}{autoindex})
#    {
#       # ERROR
#       return(undef);
#    }
#    
#    $self->{_order}{_block} = \%order;
# }

# ----------------------------------- #
# --- Private methods & functions --- #
# ----------------------------------- #
sub _sort
{
   my $self = shift;
   my $blockname   = shift;
   my @table = @_;
   
   return @table unless $self->{_block}{_profile}{$blockname}{sortby}; # 0="Don't sort"
   
   my %idx; my $rec = 0;
   
   # ------------------------------------------ #
   # --- Caller refers to 1st col as col 1, --- #
   # --- we refer to it as element zero     --- #
   # ------------------------------------------ #
   my $sort_col = ($self->{_block}{_profile}{$blockname}{sortby} - 1);
   
   for my $row(@table){$idx{$rec++} = $row->[$sort_col];}
   
   my @sorted;
   
   # ------------------------- #
   # --- Sort numerically  --- #
   # ------------------------- #
   if($self->{_block}{_profile}{$blockname}{sorttype} =~ /numeric/)
   {
      # ------------------------------- #
      # --- Sort in decending order --- #
      # ------------------------------- #
      if($self->{_block}{_profile}{$blockname}{orderby} =~ /descending/)
      {
         foreach my $key(sort { $idx{$b} <=> $idx{$a} } keys %idx)
         {
            push(@sorted, $table[$key]);
         }
      }
      # ------------------------------- #
      # --- Sort in ascending order --- #
      # ------------------------------- #
      else
      {
         foreach my $key(sort { $idx{$a} <=> $idx{$b} } keys %idx)
         {
            push(@sorted, $table[$key]);
         }
      }
   }
   # ---------------------------- #
   # --- Sort alphabetically  --- #
   # ---------------------------- #
   else
   {
      # ------------------------------- #
      # --- Sort in decending order --- #
      # ------------------------------- #
      if($self->{_block}{_profile}{$blockname}{orderby} =~ /descending/)
      {
         foreach my $key(sort { $idx{$b} cmp $idx{$a} } keys %idx)
         {
            push(@sorted, $table[$key]);
         }
      }
      # ------------------------------- #
      # --- Sort in ascending order --- #
      # ------------------------------- #
      else
      {
         foreach my $key(sort { $idx{$a} cmp $idx{$b} } keys %idx)
         {
            push(@sorted, $table[$key]);
         }
      }
   }
   
   return(@sorted);
}

sub _draw_line
{
   my $self = shift;
   my $type = shift;
   my $length = shift;
   
   unless($length =~ /\d+/ && $length > 0)
   {
      $self->_debug(3, "Cannot _draw_line() $type - Line length = $length");
      return(undef);
   }
   
   unless($self->{_page}{_line}{$type})
   {
      $self->_debug(3, "Cannot _draw_line() $type - ".
            "Do not know how to make type ($type)\; For ".
            "a list of valid line types call linetypes()");
      
      return(undef);
   }
   
   else
   {
      return($self->{_page}{_line}{$type} x $length);
   }
}

sub _debug
{
   my $self = shift;
   my ($level, $msg) = @_;
   
   my %err_lev = 
      (4 => 'Critical:', 3 => 'Error:', 2 => 'Warn:', 1 => 'Notice:');

   return unless $self->{_debug}{_lev};
   
   my $fh = $self->{_log}{_file};
   
   if($level >= $self->{_debug}{_lev})
   {
      if($self->{_debug}{_verbose})
      {
         print($fh Carp::longmess("$err_lev{$level} $msg\n"), "\n");
      }
      else{print($fh Carp::shortmess("$err_lev{$level} $msg\n"), "\n");}
   }
}

sub _numeric{$a <=> $b;}

sub _default_block
{
   my $self = shift;
   
   $self->{_block}{_profile}{(shift)} = 
      {
         column => {1 => {width => 80, align => 'center'},},
         sortby => 0, # No sort
         sorttype => 'alpha',
         orderby => 'ascending',
         title => undef,
         useColHeaders => 0,
         width => 12, # Global col width setting
         align => 'center', # Global alignment setting
         # Number of blank lines to add to start|end-of-block
         pad => {top => 0, bottom => 1},
      };
}
# ----------------------------------------- #
# --- Assuming that the caller may not  --- #
# --- have access to 'Storable' declone --- #
# ----------------------------------------- #
sub _assign_def_block
{
   my $self = shift;
   my $blockname = shift;
   
   $self->{_block}{_profile}{$blockname}{width} = 
      $self->{_block}{_profile}{'_block'}{width};
   $self->{_block}{_profile}{$blockname}{align} = 
      $self->{_block}{_profile}{'_block'}{align};
   $self->{_block}{_profile}{$blockname}{sortby} = 
      $self->{_block}{_profile}{'_block'}{sortby};
   $self->{_block}{_profile}{$blockname}{sorttype} = 
      $self->{_block}{_profile}{'_block'}{sorttype};
   $self->{_block}{_profile}{$blockname}{orderby} = 
      $self->{_block}{_profile}{'_block'}{orderby};
   $self->{_block}{_profile}{$blockname}{useColHeaders} = 
      $self->{_block}{_profile}{'_block'}{useColHeaders};
   $self->{_block}{_profile}{$blockname}{title} = 
      $self->{_block}{_profile}{'_block'}{title};
   
   for(keys%{$self->{_block}{_profile}{'_block'}{pad}})
   {
      $self->{_block}{_profile}{$blockname}{pad}{$_} = 
         $self->{_block}{_profile}{'_block'}{pad}{$_};
   }

   for my $col(keys%{$self->{_block}{_profile}{'_block'}{column}})
   {
      for my $t(keys%{$self->{_block}{_profile}{'_block'}{column}{$col}})
      {
         $self->{_block}{_profile}{$blockname}{column}{$col}{$t} = 
            $self->{_block}{_profile}{'_block'}{column}{$col}{$t};
      }
   }
   
   $self;
}

sub _default_report
{
   my $self = shift;
   
   $self->{_page}{_profile}{(shift)} = 
      {
         width     => 80, # Width of report in characters
         asis      => 0,  # Report.pm sets all block titles to caps & adds underline
         autoindex => 1,  # Let us do the indexing for you
      };
}

sub AUTOLOAD
{
   my $self = shift;
   my %profile;
   
   my $type = shift;
   
   if($type){$profile{$type} = 1;}
   
   my %this = @_;
   
   return if $AUTOLOAD =~ /::DESTROY$/;
   
   my $meth = $AUTOLOAD; $meth =~ s/.*://; # Just the method, not the pkg
   
   unless($meth =~ /^profile/){$self->_debug(3, "Bad method - $meth"); return(undef);}
   
   unless($Text::Report::stor_loaded)
   {
      $self->_debug(3, 'Cannot load module Storable; In order to use '.
            '"NamedPages", Storable.pm must be installed & in @INC');
      return(undef);
   }
   
   unless(defined $this{path}){$this{path} = '/tmp';}
   
   # --- Clean path --- #
   $this{path} =~ s|^(.*)/$|$1|;
   
   
   # --- Test path --- #
   unless(-e $this{path})
   {
      $self->_debug(3, "Cannot access profile storage area\; Path ".
            "($this{path}) does not exist");
      return(undef);
   }
   
   # my $sid = int(time);
   
   my $tmp = "$this{path}/stor.test.".int(time);
   
   # --- Test creat Rights --- #
   unless(open F, "+>$tmp")
   {
      $self->_debug(3, "Insufficient file creation rights in profile ".
            "storage area - Path ($this{path})");
      return(undef);
   }
   
   $self->_debug(1, "Created tmp file $tmp");
   
   close F;
   
   # --- Clean up --- #
   my @ret = grep{unlink} $tmp;
   
   $self->_debug(1, "Removed tmp file(s)".join(', ', @ret));
   
   
   # --- Test name --- #
   if($this{name})
   {
      # --- No spaces allowed --- #
      while($this{name} =~ s/\s+//g){};
      
      # --- No special chars --- #
      unless($this{name} =~ /^\w+$/ && $this{name} !~ /^$/)
      {
         $self->_debug(3, "No empty strings or special chars allowed in profile ".
               "name($this{name})\; Create a name that conforms to UNIX file ".
               "naming standards");
         return(undef);
      }
   }
   else
   {
      $self->_debug(2, "No profile name passed as \$obj->profile(\'load\', name => ".
            "\'myname\')\; Assigning default profile name \'default\'");
      
      $this{name} = 'default';
   }
   
   # $obj->profile('load', name => 'str');
   # $obj->profile('save', name => 'str');
   if($profile{load})
   {
      my $msg = "Cannot load stored profile ($this{name})";
      
      # --- Don't overwrite ourselves --- #
      # --- in case of failure        --- #
      my $temp;
      
      eval{$temp->{_block} = retrieve("$this{path}/stor.rpt\.$this{name}\.\_block");};
      
      $self->_debug(4, "$msg\; $@"), return undef if $@;
      
      eval{$temp->{_page} = retrieve("$this{path}/stor.rpt\.$this{name}\.\_page");};
      
      $self->_debug(4, "$msg\; $@"), return undef if $@;
      
      eval{$temp->{_order} = retrieve("$this{path}/stor.rpt\.$this{name}\.\_order");};
      
      $self->_debug(4, "$msg\; $@"), return undef if $@;
      
      $self->{_block} = $temp->{_block};
      $self->{_page} =  $temp->{_page};
      $self->{_order} =  $temp->{_order};
      
      return(1);
   }
   if($profile{save})
   {
      # stor.rpt.<name>._block
      my $temp;
      
      $temp->{_block} = dclone($self->{_block});
      
      # --- Save just the skeleton --- #
      for(keys %{$temp->{_block}{_profile}})
      {
         delete $temp->{_block}{_profile}{$_}{data} unless /^\_/; # Save the separators
         delete $temp->{_block}{_profile}{$_}{_csv};
      }
      
      store($temp->{_block}, "$this{path}/stor.rpt\.$this{name}\.\_block");
      store($self->{_page}, "$this{path}/stor.rpt\.$this{name}\.\_page");
      store($self->{_order}, "$this{path}/stor.rpt\.$this{name}\.\_order");
      
      return(1);
   }
   
   return(undef);
}



__END__

=pod

=head1 NAME

Text::Report - Perl extension for generating mixed columnar formatted reports and report templates


=head1 VERSION

Version 1.003


=head1 SYNOPSIS


    use Text::Report;
    
    # Let's build a simple report complete with title lines, footer
    # and two disparate data sets in tabular form
    
    # Create a new report object:
    $rpt = Text::Report->new(debug => 'error', debugv => 1);
    
    
    # Create a title block:
    $rpt->defblock(name => 'title_lines');
    
    # Create a separator:
    $rpt->insert('dbl_line');
    
    # Create a data block:
    $rpt->defblock(name => 'data1',
          title => 'Statistical Analysis Of Gopher Phlegm Over Time',
          useColHeaders => 1,
          sortby => 1,
          sorttype => 'alpha',
          orderby => 'ascending',
          columnWidth => 14,
          columnAlign => 'left',
          pad => {top => 2, bottom => 2},);
    
    # Create another data block:
    $rpt->defblock(name => 'data2',
          title => 'Resultant Amalgamum Firnunciation Per Anum',
          useColHeaders => 1,
          sortby => 1,
          sorttype => 'numeric',
          orderby => 'ascending',
          columnWidth => 10,
          columnAlign => 'right',
          pad => {top => 2, bottom => 2},);
    
    # Create a separator:
    $rpt->insert('dotted_line');
    
    # Create a footer block:
    $rpt->defblock(name => 'footer');
    
    # Add column headers:
    @header = qw(gopher_a gopher_b gopher_c bobs_pudding);
    @header2 = qw(avg mean meaner meanest outraged paralyzed);
    
    $i = 0;
    for(@header){$rpt->setcol('data1', ++$i, head => $_);}
    
    $i = 0;
    for(@header2){$rpt->setcol('data2', ++$i, head => $_);}
    
    # Change column settings for 'bobs_pudding' data:
    $rpt->setcol('data1', 4, align => 'right', width => 16);
    
    @data = (
       ['a1', 'a2', 'a3', 'b4'], 
       ['b1', 'b2', 'b3', 'c4'], 
       ['c1', 'c2', 'c3', 'c4'],);
    
    @data2 = (
       ['562.93', '121.87', '53.95', '46.05', '39.00', '129.00'], 
       ['123.62', '191.25', '14.62', '52.58', '63.14', '256.32'],);
    
    # Fill our blocks with some useful data:
    $rpt->fill_block('title_lines', ['Simple Report'], ['Baltimore Zoological Research Lab']);
    $rpt->fill_block('data1', @data);
    $rpt->fill_block('data2', @data2);
    $rpt->fill_block('footer', ['Acme Cardboard - All Rights Reserved'], ['Apache Junction, Arizona']);
    
    # Get our formatted report:
    @report = $rpt->report('get');
    
    # Print report:
    for(@report){print $_, "\n";}
   
   
   
                                     Simple Report
                           Baltimore Zoological Research Lab
    
   ================================================================================
    
    
    
   STATISTICAL ANALYSIS OF GOPHER PHLEGM OVER TIME
   -----------------------------------------------
    
   gopher_a        gopher_b        gopher_c             bobs_pudding
   ______________  ______________  ______________   ________________
   a1              a2              a3                             b4
   b1              b2              b3                             c4
   c1              c2              c3                             c4
    
    
    
    
   RESULTANT AMALGAMUM FIRNUNCIATION PER ANUM
   ------------------------------------------
    
           avg        mean      meaner     meanest    outraged   paralyzed
    __________  __________  __________  __________  __________  __________
        123.62      191.25       14.62       52.58       63.14      256.32
        562.93      121.87       53.95       46.05       39.00      129.00
    
    
   ................................................................................
    
                         Acme Cardboard - All Rights Reserved
                               Apache Junction, Arizona

   
   
   
   Beautiful isn't it. And the coolest thing...
      You can save the report template and use it over and over and over...


=head1 DESCRIPTION

Being a Practical Reporting language, it only seems fitting that one should be able to generate
nicely formatted reports with Perl without ever having to do this stuff (and worse)

   format =
   @<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<  @||||||||||| @>>>>> $@###.##
   $bla, $foo, $blek, $bar, $gnu
   .

over and over again. 

And clearing accumulators and writing vast amounts of polemic, convoluted code and cursing. And slamming doors and kicking things that bark and meow. And eventually, while sobbing uncontrollably, copying and pasting the stuff into a spreadsheet at 3:30 A.M.. I have seen this. Ugly stuff. Gives me the creeps.

Well guess what? This type of aberrant behavior will soon be a thing of the past. You may even tear page 168 out of your (2nd edition) Camel Book now. Sure, go ahead. What, it's not your book? Ahh, do it anyway. Whoever does own it will thank you. Unless it's a library book. Then you've got problems.

With Text::Report you can create beautiful text based reports on the fly and even collect csv data for retrieval just in case you still have some primal urge to do the spreadsheet thing. You will never have to touch another perl "format" function ever again.

Just initialize a new report object, tweak the global settings to your liking, create page title and footer blocks, some separators, and data blocks (tabular data) to your heart's content. When you're done building you can save the report template to be used later for the same type of report or you can begin stuffing table data into your data blocks. And that's it. You can now print the report or write it to a file. 

Text::Report will very likely get you so excited that you will mistakenly phone up family members and try to explain it to them.






=head1 METHODS

=over 4

=item new()

=over 6

The C<new> method creates a new report object instance and defines
the attributes of the object.
Attributes are passed as key => value pairs:

=back

=over 6

=item logfh => \*HANDLE

If supplied, 'logfh' directs logging (debug) output to the file handle, 
otherwise output is to *STDOUT.

=item debug => ['off' | 'notice' | 'warning' | 'error' | 'critical']

If supplied, 'debug' sets the level (and amount) of messaging. Setting 
debug to 'off' will give you a nice quiet run, however when running complex
reports, this feature becomes darned handy. The default is set to 'critical'
(minimum verbosity).


=item debugv => [0 | 1]

If supplied, 'debugv' sets the level of Carp'ing. If false, we use Carp::shortmess
and if true we use Carp::longmess.


=item autoindex => [0 | 1]

If false, 'autoindex' will be turned off and you will need to supply a unique
index value for each report component used. 

Not pretty. 

It is strongly recommended that you let Text::Report do the indexing for you. 
The only requirement on your part for autoindexing is to create the report blocks 
(using the $obj->defblock() method) in the  order that you want them to appear in 
the report. 

The default is set to true. I personally don't mess with it that often, although
there have been times when it became essential. Hence its availability.

=back

The following options let you diddle with the global report defaults. Keep
in mind that you may also specify these locally as well which, I find, is 
easier for most reports. These options are also available using the method
$obj->configure().

=over 6

=item width => n

Change the width of the formatted (final) report to the number 'n'
characters specified. The default is set to 80 characters.

=item asis => [0 | 1]

Normally Text::Report sets all block titles to uppercase and adds underlines
to the column headers. 

You may have it your way, however, and specify that you want the report headers 
left just the way that you pass them to Text::Report by setting asis => 1. 

I think that the report is easier to read with capitalised
headers. 

The default is off. (which means that Text::Report will do it his way)

=item column => {'n' => {width => 'x', align => ['left' | 'right' | 'center'], head => 'string'}}

You may change the default column properties by passing the above hash ref
where n = the column number and x = column width and 'string' is whatever you
want for that column header.

=item useColHeaders => [0 | 1]

By turning useColHeaders on you will either be expected to supply column headers
for each data block or the system will provide you with it's own. In the form of
'1', '2', '3' ...

The initial setting is off.

In title, footer, and separator data blocks you want to turn headers off. When
creating data tables you would, perhaps want this turned on.

=item sortby => n

The column number 'n' to sort by. The default is 0 (zero) which means "no sorting
please"

   Here are the default settings:
   
       $rpt = Text::Report->new ( 
           {                  #  DEFAULTS
               debug          => 'critical',
               debugv         => 0, 
               width          => 80, 
               autoindex      => 1, 
               asis           => 0, 
               logfh          => \*STDOUT, 
               blockPad       => {top => 0, bottom => 1}, 
               useColHeaders  => 0,
               sortby         => 0,
           }
       );
    
=back

=item configure()

=over 6

The C<configure> method is used to tweak global report settings.

(You may also use the following options with new())

=back

=over 6

=item width => n

Change the width of the formatted (final) report to the number 'n'
characters specified. The default is set to 80 characters.

=item asis => [0 | 1]

Normally Text::Report sets all block titles to uppercase and adds underlines
to the column headers. 

You may have it your way, however, and specify that you want the report headers 
left just the way that you pass them to Text::Report by setting asis => 1. 

The default is off. (which means that Text::Report will do it his way)

=item column => {'n' => {width => 'x', align => ['left' | 'right' | 'center'], head => 'string'}}

You may change the default column properties by passing the above hash ref
where n = the column number and x = column width and 'string' is whatever you
want for that column header.

=item useColHeaders => [0 | 1]

By turning useColHeaders on you will either be expected to supply column headers
for each data block or the system will provide you with it's own. In the form of
'A', 'B', 'C' ...

The initial setting is off.

In title, footer, and separator data blocks you want to turn headers off. When
creating data tables you would, perhaps want this turned on.

=item sortby => n

The column number 'n' to sort by. The default is 0 (zero).


=back

=item defblock()

=over 6

The C<defblock> method names and sets parameters for a particular
report block such as number of columns, sort column, default column
alignment (which can also be set using setcol() method), et al.

This is where you create a data block. It will usually be a table structure 
that you will use to display all of that data you have been collecting from 
some petri dish in some dark lab somewhere.

=back

=over 6

=item name => 'string'

The name of the block you are about to define. 

=item title => 'string'

The title to display for the block you are about to define. You would not use this
if you were creating a report title or some other data that you did not want a
label for.

=item order => 'n'

Where n is a unique integer. 

This is the order in which the data block you are creating will appear 
in your report. Use this option *only* if you have set new(autoindex => 0) 
and only if you enjoy that feeling you get when you repeatedly shut 
the car door on your fingers. 

=item sortby => 'n'

Where n is an integer. 

This designates the column in this data block that will be used
for sorting.

=item sorttype => ['alpha' | 'numeric']

This tells Text::Report how you want to sort the column for this
data block.

=item orderby => ['ascending' | 'descending']

This tells Text::Report in what order you want to sort the column 
for this data block.

=item useColHeaders => [0 | 1]

Set to true to display headers & header underlines at the head 
of each column.

=item column => {'n' => {width => 'xx', align => ['left' | 'right' | 'center'],  head => 'string'}}

Configure column where 'n' is column number, 'xx' is the width of the column and 
'string' is the header string for this column and is optional.

=item cols => positive integer

Automatically generates columns using preset default width and alignment. 

I love automation.

This feature is handy for homogenous column data (ie; x number of columns each the
same width), but it will truncate data if you get carried away with trying to stuff
more chars per line than the report width is set for.

If you have debug set correctly, it will tell you how to make adjustments to make
everything fit. 

B<Use the debug feature!> I built it for a reason. Building complex reports
will be so much easier if you B<use the debug feature>.

=item pad => {top => 'n', bottom => 'n'}

Block padding - where 'n' is the number of blank lines to pad the top & bottom of 
the block.

=item columnWidth => 'n'

Set the default column width for this block to 'n' characters wide.

=item columnAlign => ['left' | 'right' | 'center']

Set the default alignment for every column in the block. 

Handy. 

This sets the alignment for every column defined or about to be defined. If you 
have six columns and five need left alignment and one needs center, then set 
columnAlign => 'left' and only explicitly set the sixth column, using 
setcol($blockname, $col_num, align => 'center').


=back

=item setblock()

=over 6

The C<setblock> method gives you the opportunity to alter an existing data block's properties with the exception of the block name.

=back

=over 6

=item title => 'string'

The title to display for the block you are about to define. You would not use this
if you were creating a report title or some other data that you did not want a
label for.

=item order => 'n'

Where n is a unique integer. 

This is the order in which the data block you are creating will appear 
in your report. Use this option *only* if you have set new(autoindex => 0).

=item sortby => 'n'

Where n is an integer. 

This designates the column in this data block that will be used
for sorting. A zero would mean no sorting.

=item sorttype => ['alpha' | 'numeric']

This tells Text::Report how you want to sort the column for this
data block.

=item orderby => ['ascending' | 'descending']

This tells Text::Report in what order you want to sort the column 
for this data block.

=item pad => {top => 'n', bottom => 'n'}

Block padding - where 'n' is the number of blank lines to pad the top & bottom of 
the block.

=item useColHeaders => [0 | 1]

Set to true to display headers & header underlines at the head 
of each column.


=back

=item setcol($blockname, $colnumber, ...)

=over 6

The C<setcol> method allows you to set and change certain column properties.

=back

=over 6

=item $blockname

Block name must be supplied as arg zero.

=item $colnumber

Column number must be supplied as arg 1.

=item align => ['left' | 'right' | 'center']

Specifies the justification of a column field.

=item width => n

Change the width of the designated column to the number 'n'
characters specified.

=item head => 'str'

Column header as a string.


=back

=item insert($linetype, ...)

=over 6

The C<insert> method allows you to insert a block to be used as a separator where $linetype is either 'dotted_line' | 'dbl_line' | 'single_line' | 'under_line' | 'blank_line'.

=back

=over 6

=item order => 'n'

Where n is a unique integer. 

This is the order in which the separator you are creating will appear 
in your report. Use this option *only* if you have set new(autoindex => 0).

=item pad => {top => 'n', bottom => 'n'}

Padding - where 'n' is the number of blank lines to pad the top & bottom of 
the separator.

=item width => n

Make the width of the separator the number 'n' characters specified.


=back

=item fill_block($blockname, @AoA)

=over 6

The C<fill_block> method is where the pudding meets the highway. The data sent, as a 3-dimensional array or table, is parsed according to the properties that were set when the block was defined in defblock() or the default properties that were set at the global or report level.

=back

=over 6

=item $blockname

Block name must be supplied as arg zero. 

=item @AoA

Each primary element in the data array contains the table row while the elements contained in the row elements contains each field value in the row as:

   @AoA = (
   ['data', 'data', 'data', 'data'],
   ['data', 'data', 'data', 'data'],);
   


=back

=item report(['get' | 'print' | 'csv'])

=over 6

The C<report> method is how you retrieve the final, formatted report or csv data. The report is returned as an array where each element is a row or line of the report. The csv data is returned as an AoA.

=back

=over 6

=item 'get'

Using the 'get' argument, the report is returned as an array with each element containing a line in the report.
   
   @report = $rpt->report('get');
   for(@report){print $_, "\n";}

=item 'csv'

Using the 'csv' argument, the csv data is returned as an array of arrays.
   
   @csv = $rpt->report('csv');
   for(@csv){for(@{$_}){print $_, "\n";}}

=item 'print'

Using the 'print' argument, the report is printed to STDOUT.


=back

=back


=head1 MISCELLANEOUS METHODS

=over 4


=item get_csv(@listofblocknames)

=over 6

The C<get_csv> method returns csv data in an array of arrays.

=back

=over 6

=item @listofblocknames

One or more block names to retrieve csv data

   @csv = $rpt->get_csv('block1', 'block2');
   for(@csv){for(@{$_}){print $_, "\n";}}


=back

=item rst_block($block_name)

=over 6

The C<rst_block> method resets named block to defaults. If $block_name does not exist, creates new block $block_name and applies defaults.

=back

=over 6

=item $block_name

Must supply a valid block name as an argument.


=back

=item del_block($block_name)

=over 6

The C<del_block> method deletes named block.

=back

=over 6

=item $block_name

Must supply a valid block name as an argument.


=back

=item clr_block_data($block_name)

=over 6

The C<clr_block_data> method clears report data & csv data from block $block_name.

=back

=over 6

=item $block_name

Must supply a valid block name as an argument.


=back

=item clr_block_headers($block_name)

=over 6

The C<clr_block_headers> method clears header data from block $block_name.

=back

=over 6

=item $block_name

Must supply a valid block name as an argument.


=back

=item named_blocks()

=over 6

The C<named_blocks> method returns an array list of all defined named blocks.

No arguments


=back

=item linetypes()

=over 6

The C<linetypes> method returns an array list of all predefined line types.

No arguments

=back

=back


=head1 EXAMPLES

=over 4


Example 1

Generate a report of gas price comparisons on a per zip code basis 
using Ashish Kasturia's Gas::Prices L<http://search.cpan.org/~ashoooo/Gas-Prices-0.0.4/lib/Gas/Prices.pm>

   use Gas::Prices;
   use Text::Report;
   
   
   # --- US zip code list
   my @code = qw(85202 85001 85201);
   
   
   # --- Create our report object
   my $rpt = Text::Report->new(debug => 'off', width => 95);
   
   # --- Define a block for the title area accepting the current 
   # --- default width of 95 chars and centered justification
   $rpt->defblock(name => 'pageHead');
   
   # --- Add two lines to block 'pageHead'
   $rpt->fill_block('pageHead', ["Gasoline Pricing At Stations By Zip Code"],[scalar(localtime(int(time)))]);
   
   # --- Insert a text decoration
   # --- We are using the autoindex feature and allowing Text::Report 
   # --- to keep track of the order in which our blocks appear. We determine 
   # --- that order by the order in which we call defblock() or insert()
   $rpt->insert('dbl_line');
   
   
   # --- We have data returning for 3 different zip codes and want to present 
   # --- that data as pricing per zip code in one report. Create 3 blocks, 
   # --- using each zip code as part of the block name. The structure will be 
   # --- the same for each block in this case.
   foreach my $zip(@code)
   {
      $rpt->defblock(name => 'station_data'.$zip, 
         column =>
         {
            1 => {width => 20, align => 'left', head => 'Station'},
            2 => {width => 35, align => 'left', head => 'Address'},
            3 => {width =>  7, align => 'right', head => 'Regular'},
            4 => {width =>  7, align => 'right', head => 'Plus'},
            5 => {width =>  7, align => 'right', head => 'Premium'},
            6 => {width =>  7, align => 'right', head => 'Diesel'},
         },
         # Block title
         title => "Station Comparison For Zip Code $zip",
         # Yes, use column headers
         useColHeaders => 1,
         # Yes "sort" using column 1
         sortby => 1,
         # Sort alphabetically
         sorttype => 'alpha',
         # Sort low to high
         orderby => 'ascending',
         # pad these blocks with 2 blank lines on top and bottom
         pad => {top => 2, bottom => 2},);
   }
   
   # --- Now that we've constructed the report template, all that's left is to 
   # --- fetch and add the data
   
   foreach my $zip(@code)
   {
      my $gasprice = Gas::Prices->new($zip);
      
      my $stations = $gasprice->get_stations;
      
      sleep 3;
      
      my @data;
      
      foreach my $gas(@{$stations})
      {
         # Remove state & zip (personal preference)
         $gas->{station_address} =~ s/(.*?)\,\s+\w{2}\s+\d{5}/$1/;
         
         push(@data, [
               $gas->{station_name},
               $gas->{station_address},
               $gas->{unleaded_price},
               $gas->{plus_price},
               $gas->{premium_price},
               $gas->{diesel_price}]);
      }
      
      $rpt->fill_block('station_data'.$zip, @data);
   }
   
   # --- Get the formatted report & print to screen
   my @report = $rpt->report('get');
   for(@report){print $_, "\n";}
   
   exit(1);

Here is the resultant output from example 1:

                               Gasoline Pricing At Stations By Zip Code
                                       Mon Jul  9 10:13:33 2007
    
   ===============================================================================================
    
    
    
   STATION COMPARISON FOR ZIP CODE 85202
   -------------------------------------
    
   Station               Address                               Regular     Plus  Premium   Diesel
   ____________________  ___________________________________   _______  _______  _______  _______
   7-ELEVEN              815 S DOBSON RD, MESA                   2.799      N/A      N/A      N/A
   7-ELEVEN              2050 W GUADALUPE RD, MESA               2.799      N/A      N/A      N/A
   7-ELEVEN              1210 W GUADALUPE RD, MESA               2.879      N/A      N/A      N/A
   7-ELEVEN              815 S ALMA SCHOOL RD, MESA              2.819      N/A    3.059      N/A
   CHEVRON               1205 W BASELINE RD, MESA                2.859      N/A    3.099    2.939
   CHEVRON               1808 E BROADWAY RD, TEMPE               2.839    2.969    3.139      N/A
   CHEVRON               414 W GUADALUPE RD, MESA                2.779    2.919    3.019      N/A
   CIRCLE K              751 N ARIZONA AVE, GILBERT              2.779    2.979    3.089    2.899
   CIRCLE K              2196 E APACHE BLVD, TEMPE               2.799    2.929      N/A      N/A
   CIRCLE K              2012 W SOUTHERN AVE, MESA               2.759    2.889      N/A    2.949
   CIRCLE K              2808 S DOBSON RD, MESA                  2.779    2.929    3.099    2.899
   Circle K              417 S Dobson Rd, Mesa                   2.799    2.929    3.099      N/A
   Circle K              1145 W Main St, Mesa                    2.799    2.929    3.099      N/A
   Circle K              1955 W UNIVERSITY DR, Mesa              2.799      N/A      N/A      N/A
   Circle K              735 W Broadway Rd, Mesa                 2.819    2.949    3.119      N/A
   MOBIL                 1817 W BASELINE RD, MESA                2.899      N/A      N/A      N/A
   Quik Trip             1331 S COUNTRY CLUB DR, Mesa            2.799    2.899    2.999      N/A
   Quik Trip             2311 W BROADWAY RD, Mesa                2.799    2.899    2.999      N/A
   SHELL                 2180 E BROADWAY RD, TEMPE               2.899    2.999    3.129    2.999
   SHELL                 2165 E BASELINE RD, TEMPE               2.909    3.009      N/A      N/A
   Shell                 1810 S COUNTRY CLUB DR, Mesa            2.799    2.799    2.929    2.849
   Shell                 1158 W UNIVERSITY DR, Mesa              2.999    3.009    2.879      N/A
   Shell                 2005 W BROADWAY RD, Mesa                2.819    2.799    3.129    2.949
   Shell                 6349 S MCCLINTOCK DR, Tempe             2.799    2.799    3.119    2.829
   Texaco                2816 S COUNTRY CLUB DR, Mesa            2.789      N/A      N/A    2.899
   UNBRANDED             2997 N ALMA SCHOOL RD, CHANDLER         2.779      N/A      N/A      N/A
   Unbranded             1510 S COUNTRY CLUB DR, Mesa            2.809      N/A    2.809    3.049
   Unbranded             756 W SOUTHERN AVE, Mesa                2.699      N/A      N/A    2.899
   Unbranded             1821 S COUNTRY CLUB DR, Mesa            2.829    2.959    2.899      N/A
   Unbranded             5201 S MCCLINTOCK DR, Tempe             2.789    2.899    2.999      N/A
    
    
    
    
   STATION COMPARISON FOR ZIP CODE 85001
   -------------------------------------
    
   Station               Address                               Regular     Plus  Premium   Diesel
   ____________________  ___________________________________   _______  _______  _______  _______
   CHEVRON               2402 E WASHINGTON ST, PHOENIX           2.899      N/A    3.139    2.999
   CIRCLE K              699 E BUCKEYE RD, PHOENIX               2.839    2.969      N/A      N/A
   CIRCLE K              602 N 1ST AVE, PHOENIX                  2.779    2.909    3.079      N/A
   Circle K              1501 W Mcdowell Rd, Phoenix             2.759    2.909    3.099    2.949
   Circle K              309 E Osborn Rd, Phoenix                2.759    2.909      N/A    2.949
   Circle K              614 W ROOSEVELT ST, Phoenix             2.759      N/A    3.059      N/A
   Circle K              702 W Mcdowell Rd, Phoenix              2.779      N/A    3.099      N/A
   Circle K              10 E BUCKEYE RD, Phoenix                2.819      N/A      N/A      N/A
   Circle K              2400 E Mcdowell Rd, Phoenix             2.779    2.949    3.119      N/A
   Circle K              1602 E Washington St, Phoenix           2.879    3.029    3.199      N/A
   Circle K              1732 W VAN BUREN ST, Phoenix            2.839    2.969    3.139      N/A
   Circle K              1342 W THOMAS RD, Phoenix               2.779      N/A      N/A      N/A
   Circle K              1945 E Van Buren St, Phoenix            2.879    3.029    3.199      N/A
   Circle K              1834 W Grant St, Phoenix                2.839    2.969      N/A      N/A
   Circle K              1523 E MCDOWELL RD, Phoenix             2.789    2.759      N/A      N/A
   Circle K              1001 N 16Th St, Phoenix                 2.879    3.029      N/A      N/A
   Circle K              2041 W Van Buren St, Phoenix            2.839    2.969      N/A      N/A
   Circle K              1007 N 7Th St, Phoenix                  2.879      N/A      N/A      N/A
   Circle K              702 E Mcdowell Rd, Phoenix              2.819    2.969    3.119      N/A
   Circle K              2535 N CENTRAL AVE, Phoenix             2.899      N/A      N/A      N/A
   Circle K              966 E Van Buren St, Phoenix             2.859    3.009      N/A      N/A
   Circle K              2850 N 7Th St, Phoenix                  2.859    3.029      N/A      N/A
   Phillips 66           1045 N 24TH ST, Phoenix                 2.799      N/A      N/A    2.899
   SHELL                 305 E THOMAS RD, PHOENIX                2.899      N/A      N/A      N/A
   Shell                 922 N 7TH ST, Phoenix                   2.879    2.989      N/A      N/A
   Shell                 2401 E VAN BUREN ST, Phoenix            2.849      N/A      N/A    3.079
   UNBRANDED             2817 N 7TH ST, PHOENIX                  2.839      N/A      N/A      N/A
   UNBRANDED             125 E MCDOWELL RD, PHOENIX              2.819      N/A      N/A      N/A
   Unbranded             2045 S 7TH AVE, Phoenix                 2.959    2.949    2.989    2.959
   Unbranded             1919 S 7TH ST, Phoenix                  2.899      N/A      N/A    3.299
    
    
    
    
   STATION COMPARISON FOR ZIP CODE 85201
   -------------------------------------
    
   Station               Address                               Regular     Plus  Premium   Diesel
   ____________________  ___________________________________   _______  _______  _______  _______
   7-ELEVEN              815 S ALMA SCHOOL RD, MESA              2.819      N/A    3.059      N/A
   7-ELEVEN              815 S DOBSON RD, MESA                   2.799      N/A      N/A      N/A
   7-ELEVEN              758 E BROWN RD, MESA                    2.859    2.959      N/A      N/A
   ARCO                  25 W MCKELLIPS RD, MESA                 2.799      N/A      N/A      N/A
   CHEVRON               808 E MCKELLIPS RD, MESA                2.869    2.999    3.099    2.939
   CIRCLE K              2196 E APACHE BLVD, TEMPE               2.799    2.929      N/A      N/A
   Chevron               357 N Stapley Dr, Mesa                  2.839      N/A    3.099      N/A
   Circle K              735 W Broadway Rd, Mesa                 2.819    2.949    3.119      N/A
   Circle K              11 E Mckellips Rd, Mesa                 2.779      N/A      N/A      N/A
   Circle K              1550 N Country Club Dr, Mesa            2.779      N/A      N/A      N/A
   Circle K              410 N Center St, Mesa                   2.779      N/A    3.099    2.849
   Circle K              1205 E BROADWAY RD, Mesa                2.799      N/A      N/A      N/A
   Circle K              417 S Dobson Rd, Mesa                   2.799    2.929    3.099      N/A
   Circle K              1145 W Main St, Mesa                    2.799    2.929    3.099      N/A
   Circle K              1154 W 8Th St, Mesa                     2.799    2.929    3.099      N/A
   Circle K              1955 W UNIVERSITY DR, Mesa              2.799      N/A      N/A      N/A
   Circle K              330 E BROADWAY RD, Mesa                 2.799    2.929      N/A      N/A
   Circle K              1160 E UNIVERSITY DR, Mesa              2.879      N/A      N/A      N/A
   Circle K              310 N Mesa Dr, Mesa                     2.819      N/A      N/A      N/A
   Quik Trip             517 W MCKELLIPS RD, Mesa                2.799    2.899    2.999      N/A
   Quik Trip             1331 S COUNTRY CLUB DR, Mesa            2.799    2.899    2.999      N/A
   Quik Trip             2311 W BROADWAY RD, Mesa                2.799    2.899    2.999      N/A
   Quik Trip             816 W UNIVERSITY DR, Mesa               2.799    2.899    2.999      N/A
   SHELL                 1957 N COUNTRY CLUB DR, MESA            2.999      N/A      N/A    2.969
   SHELL                 16 W MCKELLIPS RD, MESA                 2.889    2.989      N/A    2.939
   Shell                 2174 E University Dr, Tempe             2.819    2.779    2.929    2.949
   Shell                 2005 W BROADWAY RD, Mesa                2.819    2.799    3.129    2.949
   Shell                 1158 W UNIVERSITY DR, Mesa              2.999    3.009    2.879      N/A
   Texaco                1601 N BEELINE HWY, Scottsdale          2.899    2.999    3.089      N/A
   Unbranded             756 W SOUTHERN AVE, Mesa                2.699      N/A      N/A    2.899


More examples will be added over time and will be made available at L<http://www.full-duplex.com/svcs04.html> somewhere on the page.

=back


=head1 TODO

Page breaks and pagination. I originally developed Text::Report for electronic media and really had no need to introduce the added overhead and complexity of page numbering, order and vertical sizing. I have used Text::Report in a line-printer environment and everything looks great, however paginating for precut paper presents issues. The need to laser print, at least for me and those who I know are using this package, has not yet presented itself.

I tell you this only so that you know that I know that Text::Report is lacking a bit in the hardcopy print arena.

=head1 BUGS

None that I'm aware of at the moment, but as sure as The Sun Also Rises, someone, perhaps soon, will discover what I will call "some new features". Some features may require adjustments. Some features may require removal. I am preparing myself for the inevitable.

You may report any bugs or feature requests to
C<bug-text-report at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Report>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Report

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Report>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Report>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Report>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Report>

=back

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

CPAN - http://search.cpan.org/

=head1 AUTHOR

David Huggins, (davidius AT cpan DOT org), L<http://www.full-duplex.com>, L<http://www.in-brandon.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Full-Duplex Communications, Inc.  All rights reserved. 

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

If you need a copy of the GNU General Public License write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
