# -*-Perl-*-
use strict;

$Tk::GraphViz::VERSION = '1.01';

package Tk::GraphViz;

use Tk 800.020;
use Tk::Font;

# Parse::Yapp-generated Parser for parsing record node labels
use Tk::GraphViz::parseRecordLabel;


use base qw(Tk::Derived Tk::Canvas);

#use warnings;
use IO qw(Handle File Pipe);
use Carp;
use Reaper qw( reapPid pidStatus );

use IPC::Open3;
use POSIX qw( :sys_wait_h :errno_h );
use Fcntl;


# Initialize as a derived Tk widget
Construct Tk::Widget 'GraphViz';


######################################################################
# Class initializer
#
######################################################################
sub ClassInit
{
  my ($class, $mw) = @_;


  $class->SUPER::ClassInit($mw);
}


######################################################################
# Instance initializer
#
######################################################################
sub Populate
{
  my ($self, $args) = @_;

  $self->SUPER::Populate($args);


  # Default resolution, for scaling
  $self->{dpi} = 72;
  $self->{margin} = .15 * $self->{dpi};

  # Keep track of fonts used, so they can be scaled
  # when the canvas is scaled
  $self->{fonts} = {};
}


######################################################################
# Show a GraphViz graph
#
# Major steps:
# - generate layout of the graph, which includes
#   locations / color info
# - clear canvas
# - parse layout to add nodes, edges, subgraphs, etc
# - resize to fit the graph
######################################################################
sub show
{
  my ($self, $graph, %opt) = @_;

  die __PACKAGE__.": Nothing to show" unless defined $graph;

  # Layout is actually done in the background, so the graph
  # will get updated when the new layout is ready
  $self->_startGraphLayout ( $graph, fit => 1, %opt );
}


######################################################################
# Begin the process of creating the graph layout.
# Layout is done with a separate process, and it can be time
# consuming.  So allow the background task to run to completion
# without blocking this process.  When the layout task is complete,
# the graph display is actually updated.
######################################################################
sub _startGraphLayout
{
  my ($self, $graph, %opt) = @_;

  my ($filename,$delete_file) = $self->_createDotFile ( $graph, %opt );

  # If a previous layout process is running, it needs to be killed
  $self->_stopGraphLayout( %opt );

  $self->{layout} = [];

  if ( ($self->{layout_process} =
	$self->_startDot ( $filename, delete_file => $delete_file,
			   %opt )) ) {
    $self->{layout_process}{filename} = $filename;
    $self->{layout_process}{delete_file} = $delete_file;
    $self->{layout_process}{opt} = \%opt;
    $self->_checkGraphLayout ();
  } else {
    $self->_showGraphLayout( %opt );
  }
}


######################################################################
# Stop a layout task running in the background.
# It is important to do a waitpid() on all the background processes
# to prevent them from becoming orphans/zombies
######################################################################{
sub _stopGraphLayout
{
  my ($self, %opt) = @_;

  my $proc = $self->{layout_process};
  return 0 unless defined $proc;

  if ( defined $proc->{pid} ) {
    my @sig = qw( TERM TERM TERM TERM KILL );
    for ( my $i = 0; $i < 5; ++$i ) {
      last unless defined $proc->{pid};
      kill $sig[$i], $proc->{pid};
      if ( $self->_checkGraphLayout( noafter => 1 ) ) {
	sleep $i+1;
      }
    }
  }

  unlink $proc->{filename} if ( $proc->{delete_file} );
  delete $self->{layout_process};
}


######################################################################
# Check whether the background layout task has finished
# Also reads any available output the command has generated to
# this point.
# If the command is not finished, schedules for this method to be
# called again in the future, after some period.
######################################################################
sub _checkGraphLayout
{
  my ($self, %opt) = @_;

  my $proc = $self->{layout_process};
  if ( !defined $proc ) { return 0; }

  if ( !defined $proc->{pid} ) { return 0; }

  my $finished = 0;
  if ( defined(my $stat = pidStatus($proc->{pid})) ) {
    # Process has exited
    if ( $stat == 0xff00 ) {
      $proc->{error} = "exec failed";
    }
    elsif ( $stat > 0x80 ) {
      $stat >>= 8;
    }
    else {
      if ( $stat & 0x80 ) {
	$stat &= ~0x80;
	$proc->{error} = "Killed by signal $stat (coredump)";
      } else {
	$proc->{error} = "Kill by signal $stat";
      }
    }
    $proc->{status} = $stat;
    $finished = 1;
  }

  else {
    my $kill = kill ( 0 => $proc->{pid} );
    if ( !$kill ) {
      $proc->{status} = 127;
      $proc->{error} = "pid $proc->{pid} gone, but no status!";
      $finished = 1;
    }
  }

  # Read available output...
  while ( $self->_readGraphLayout () ) { last if !$finished; }

  # When finished, show the new contents
  if ( $finished ) {
    $proc->{pid} = undef;
    $self->_stopGraphLayout();

    $self->_showGraphLayout ( %{$proc->{opt}} );
    return 0;
  }

  else {
    # Not yet finished, so schedule to check again soon
    if ( !defined($opt{noafter}) || !$opt{noafter} ) {
      my $checkDelay = 500;
      if ( defined($proc->{goodread}) ) { $checkDelay = 0; }
      $self->after ( $checkDelay, sub { $self->_checkGraphLayout(%opt); } );
    }

    return 1;
  }
}


######################################################################
# Display the new graph layout.
# This is called once the layout of the graph has been completed.
# The layout data itself is stored as a list layout elements,
# typically read directly from the background layout task
######################################################################
sub _showGraphLayout
{
  my ($self, %opt) = @_;

  # Erase old contents
  unless ( defined $opt{keep} && $opt{keep} ) {
    $self->delete ( 'all' );
    delete $self->{fonts}{_default} if exists $self->{fonts}{_default};
  }

  # Display new contents
  $self->_parseLayout ( $self->{layout}, %opt );

  # Update scroll-region to new bounds
  $self->_updateScrollRegion( %opt );

  if ( defined $opt{fit} && $opt{fit} ) {
    $self->fit();
  }

  1;
}



######################################################################
# Create a (temporary) file on disk containing the graph
# in canonical GraphViz/dot format.
#
# '$graph' can be
# - a GraphViz instance
# - a scalar containing graph in dot format:
#   must match /^\s*(?:di)?graph /
# - a IO::Handle from which to read a graph in dot format
#   (contents will be read and converted to a scalar)
# - a filename giving a file that contains a graph in dot format
#
# Returns a filename that contains the DOT description for the graph,
# and an additional flag to indicate if the file is temprary
######################################################################
sub _createDotFile
{
  my ($self, $graph, %opt) = @_;

  my $filename = undef;
  my $delete_file = undef;

  my $ref = ref($graph);
  if ( $ref ne '' ) {
    # A blessed reference
    if ( $ref->isa('GraphViz') ||
	 UNIVERSAL::can( $graph, 'as_canon') ) {
      ($filename, my $fh) = $self->_mktemp();
      eval { $graph->as_canon ( $fh ); };
      if ( $@ ) {
	die __PACKAGE__.": Error calling GraphViz::as_canon on $graph: $@";
      }
      $fh->close;
      $delete_file = 1;
    }

    elsif ( $ref->isa('IO::Handle') ) {
      ($filename, my $fh) = $self->_mktemp();
      while ( <$graph> ) { $fh->print; }
      $fh->close;
      $delete_file = 1;
    }
  }

  else {
    # Not a blessed reference

    # Try it as a filename
    # Skip the filename test if it has newlines
    if ( $graph !~ /\n/m &&
	 -r $graph ) {
      $filename = $graph;
      $delete_file = 0;
    }

    # Try it as a scalar
    elsif ( $graph =~ /^\s*(?:di)?graph / ) {
      ($filename, my $fh) = $self->_mktemp();
      $fh->print ( $graph );
      $fh->close;
      $delete_file = 1;
    }

    else {
      die __PACKAGE__.": Bad graph";
    }
  }

  confess unless defined($filename) && defined($delete_file);
  ($filename, $delete_file);
}


######################################################################
# Create a temp file for writing, open a handle to it
#
######################################################################
{
my $_mktemp_count = 0;
sub _mktemp
{
  my $tempDir = $ENV{TEMP} || $ENV{TMP} || '/tmp';
  my $filename = sprintf ( "%s/Tk-GraphViz.dot.$$.%d.dot",
			   $tempDir, $_mktemp_count++ );
  my $fh = new IO::File ( $filename, 'w' ) ||
    confess "Can't write temp file: $filename: $!";
  binmode($fh);
  ($filename, $fh);
}
}


######################################################################
# Starting running 'dot' (or some other layout command) in the
# background, to convert a dot file to layout output format.
#
######################################################################
sub _startDot
{
  my ($self, $filename, %opt) = @_;

  confess "Can't read file: $filename" 
    unless -r $filename;

  my @layout_cmd = $self->_makeLayoutCommand ( $filename, %opt );

  # Simple, non-asynchronous mode: execute the
  # process synchnronously and wait for all its output
  if ( !defined($opt{async}) || !$opt{async} ) {
    my $pipe = new IO::Pipe;
    $pipe->reader ( @layout_cmd );
    while ( <$pipe> ) { push @{$self->{layout}}, $_; }
    if ( $opt{delete_file} ) {
      unlink $filename;
    }
    return undef;
  }

  # Now execute it
  my $in = new IO::Handle;
  my $out = new IO::Handle;
  $in->autoflush;

  local $@ = undef;
  my $proc = {};
  my $ppid = $$;
  eval {
    $proc->{pid} = open3 ( $in, $out, '>&STDERR', @layout_cmd );
    reapPid ( $proc->{pid} );

    # Fork failure?
    exit(127) if ( $$ != $ppid );
  };
  if ( defined($@) && $@ ne '' ) {
    $self->{error} = $@;
  }

  # Close stdin so child process sees eof on its input
  $in->close;

  $proc->{output} = $out;
  $proc->{buf} = '';
  $proc->{buflen} = 0;
  $proc->{eof} = 0;

  # Enable non-blocking reads on the output
  $self->_disableBlocking ( $out );

  return $proc;
}


######################################################################
# $self->_disableBlocking ( $fh )
#
# Turn off blocking-mode for the given handle
######################################################################
sub _disableBlocking
{
  my ($self, $fh) = @_;

  my $flags = 0;
  fcntl ( $fh, &F_GETFL, $flags ) or
    confess "Can't get flags for handle";
  $flags = ($flags+0) | O_NONBLOCK;
  fcntl ( $fh, &F_SETFL, $flags ) or
    confess "Can't set flags for handle";

  1;
}


######################################################################
# Assemble the command for executing dot/neato/etc as a child process
# to generate the layout.  The layout of the graph will be read from
# the command's stdout
######################################################################
sub _makeLayoutCommand
{
  my ($self, $filename, %opt) = @_;

  my $layout_cmd = $opt{layout} || 'dot';
  my @opts = ();

  if ( defined $opt{graphattrs} ) {
    # Add -Gname=value settings to command line
    my $list = $opt{graphattrs};
    my $ref = ref($list);
    die __PACKAGE__.": Expected array reference for graphattrs"
      unless defined $ref && $ref eq 'ARRAY';
    while ( my ($key, $val) = splice @$list, 0, 2 ) {
      push @opts, "-G$key=\"$val\"";
    }
  }

  if ( defined $opt{nodeattrs} ) {
    # Add -Gname=value settings to command line
    my $list = $opt{nodeattrs};
    my $ref = ref($list);
    die __PACKAGE__.": Expected array reference for nodeattrs"
      unless defined $ref && $ref eq 'ARRAY';
    while ( my ($key, $val) = splice @$list, 0, 2 ) {
      push @opts, "-N$key=\"$val\"";
    }
  }

  if ( defined $opt{edgeattrs} ) {
    # Add -Gname=value settings to command line
    my $list = $opt{edgeattrs};
    my $ref = ref($list);
    die __PACKAGE__.": Expected array reference for edgeattrs"
      unless defined $ref && $ref eq 'ARRAY';
    while ( my ($key, $val) = splice @$list, 0, 2 ) {
      push @opts, "-E$key=\"$val\"";
    }
  }

  return ($layout_cmd, @opts, '-Tdot', $filename);
}


######################################################################
# Read data from the background layout process, in a non-blocking
# mode.  Reads all the data currently available, up to some reasonable
# buffer size.
######################################################################
sub _readGraphLayout
{
  my ($self) = @_;

  my $proc = $self->{layout_process};
  if ( !defined $proc ) { return; }

  delete $proc->{goodread};
  my $rv = sysread ( $proc->{output}, $proc->{buf}, 10240,
		     $proc->{buflen} );
  if ( !defined($rv) && $! == EAGAIN ) {
    # Would block, don't do anything right now
    return 0;
  }

  elsif ( $rv == 0 ) {
    # 0 bytes read -- EOF
    $proc->{eof} = 1;
    return 0;
  }

  else {
    $proc->{buflen} += $rv;
    $proc->{goodread} = 1;

    # Go ahead and split the output that's available now,
    # so that this part at least is potentially spread out in time
    # while the background process keeps running.
    $self->_splitGraphLayout ();

    return $rv;
  }
}


######################################################################
# Split the buffered data read from the background layout task
# into individual lines
######################################################################
sub _splitGraphLayout
{
  my ($self) = @_;

  my $proc = $self->{layout_process};
  if ( !defined $proc ) { return; }

  my @lines = split ( /\n/, $proc->{buf} );
  
  # If not at eof, keep the last line in the buffer
  if ( !$proc->{eof} ) {
    $proc->{buf} = pop @lines;
    $proc->{buflen} = length($proc->{buf});
  }

  push @{$self->{layout}}, @lines;
}


######################################################################
# Parse the layout data in dot 'text' format, as returned
# by _dot2layout.  Nodes / edges / etc defined in the layout
# are added as object in the canvas
######################################################################
sub _parseLayout
{
  my ($self, $layoutLines, %opt) = @_;

  my $directed = 1;
  my %allNodeAttrs = ();
  my %allEdgeAttrs = ();
  my %graphAttrs = ();
  my ($minX, $minY, $maxX, $maxY) = ( undef, undef, undef, undef );
  my @saveStack = ();

  my $accum = undef;

  foreach ( @$layoutLines ) {
    s/\r//g;  # get rid of any returns ( dos text files)

    chomp;

    # Handle line-continuation that gets put in for longer lines,
    # as well as lines that are continued with commas at the end
    if ( defined $accum ) {
      $_ = $accum . $_;
      $accum = undef;
    }
    if ( s/\\\s*$// ||
         /\,\s*$/ ) {
      $accum = $_;
      next;
    }

    #STDERR->print ( "gv _parse: $_\n" );

    if ( /^\s+node \[(.+)\];/ ) {
      $self->_parseAttrs ( "$1", \%allNodeAttrs );
      next;
    }

    if ( /^\s+edge \[(.+)\];/ ) {
      $self->_parseAttrs ( "$1", \%allEdgeAttrs );
      next;
    }

    if ( /^\s+graph \[(.+)\];/ ) {
      $self->_parseAttrs ( "$1", \%graphAttrs );
      next;
    }

    if ( /^\s+subgraph \S+ \{/ ||
         /^\s+\{/ ) {
      push @saveStack, [ {%graphAttrs},
			 {%allNodeAttrs},
			 {%allEdgeAttrs} ];
      delete $graphAttrs{label};
      delete $graphAttrs{bb};
      next;
    }

    if ( /^\s*\}/ ) {
      # End of a graph section
      if ( @saveStack ) {
	# Subgraph
	if ( defined($graphAttrs{bb}) && $graphAttrs{bb} ne '' ) {
	  my ($x1,$y1,$x2,$y2) = split ( /\s*,\s*/, $graphAttrs{bb} );
	  $minX = min($minX,$x1);
	  $minY = min($minY,$y1);
	  $maxX = max($maxX,$x2);
	  $maxY = max($maxY,$y2);
	  $self->_createSubgraph ( $x1, $y1, $x2, $y2, %graphAttrs );
	}

	my ($g,$n,$e) = @{pop @saveStack};
	%graphAttrs = %$g;
	%allNodeAttrs = %$n;
	%allEdgeAttrs = %$e;
	next;
      } else {
	# End of the graph
	# Create any whole-graph label
	if ( defined($graphAttrs{bb}) ) {
	  my ($x1,$y1,$x2,$y2) = split ( /\s*,\s*/, $graphAttrs{bb} );
	  $minX = min($minX,$x1);
	  $minY = min($minY,$y1);
	  $maxX = max($maxX,$x2);
	  $maxY = max($maxY,$y2);

	  # delete bb attribute so rectangle is not drawn around whole graph
	  delete  $graphAttrs{bb};

	  $self->_createSubgraph ( $x1, $y1, $x2, $y2, %graphAttrs );
	}
	last;
      }
    }

    if ( /\s+(.+) \-[\>\-] (.+) \[(.+)\];/ ) {
      # Edge
      my ($n1,$n2,$attrs) = ($1,$2,$3);
      my %edgeAttrs = %allEdgeAttrs;
      $self->_parseAttrs ( $attrs, \%edgeAttrs );

      my ($x1,$y1,$x2,$y2) = $self->_createEdge ( $n1, $n2, %edgeAttrs );
      $minX = min($minX,$x1);
      $minY = min($minY,$y1);
      $maxX = max($maxX,$x2);
      $maxY = max($maxY,$y2);
      next;
    }

    if ( /\s+(.+) \[(.+)\];/ ) {
      # Node
      my ($name,$attrs) = ($1,$2);

      # Get rid of any leading/tailing quotes
      $name =~ s/^\"//;
      $name =~ s/\"$//;

      my %nodeAttrs = %allNodeAttrs;
      $self->_parseAttrs ( $attrs, \%nodeAttrs );

      my ($x1,$y1,$x2,$y2) = $self->_createNode ( $name, %nodeAttrs );
      $minX = min($minX,$x1);
      $minY = min($minY,$y1);
      $maxX = max($maxX,$x2);
      $maxY = max($maxY,$y2);
      next;
    }

  }

}


######################################################################
# Parse attributes of a node / edge / graph / etc,
# store the values in a hash
######################################################################
sub _parseAttrs
{
  my ($self, $attrs, $attrHash) = @_;

  while ( $attrs =~ s/^,?\s*([^=]+)=// ) {
    my ($key) = ($1);

    # Scan forward until end of value reached -- the first
    # comma not in a quoted string.
    # Probably a more efficient method for doing this, but...
    my @chars = split(//, $attrs);
    my $quoted = 0;
    my $val = '';
    my $last = '';
    my ($i,$n);
    for ( ($i,$n) = (0, scalar(@chars)); $i < $n; ++$i ) {
       my $ch = $chars[$i];
       last if $ch eq ',' && !$quoted;
       if ( $ch eq '"' ) { $quoted = !$quoted unless $last eq '\\'; }
       $val .= $ch;
       $last = $ch;
    }
    $attrs = join('', splice ( @chars, $i ) );

    # Strip leading and trailing ws in key and value
    $key =~ s/^\s+|\s+$//g;
    $val =~ s/^\s+|\s+$//g;

    if ( $val =~ /^\"(.*)\"$/ ) { $val = $1; }
    $val =~ s/\\\"/\"/g; # Un-escape quotes
    $attrHash->{$key} = $val;
  }

}


######################################################################
# Create a subgraph / cluster
#
######################################################################
sub _createSubgraph
{
  my ($self, $x1, $y1, $x2, $y2, %attrs) = @_;

  my $label = $attrs{label};
  my $color = $attrs{color} || 'black';

  # Want box to be filled with background color by default, so that
  # it is 'clickable'
  my $fill = $self->cget('-background');

  my $tags = [ subgraph => $label, %attrs ];

  # Get/Check a valid color
  $color = $self->_tryColor($color);

  my @styleArgs;
  if( $attrs{style} ){
    my $style = $attrs{style};
    if ( $style =~ /dashed/i ) {
      @styleArgs = (-dash => '-');
    }
    elsif ( $style =~ /dotted/ ) {
      @styleArgs = (-dash => '.');
    }
    elsif ( $style =~ /filled/ ) {
      $fill = ( $self->_tryColor($attrs{fillcolor}) || $color );
    }
    elsif( $style =~ /bold/ ) {
      # Bold outline, gets wider line
      push @styleArgs, (-width => 2);
    }
  }

  # Create the box if coords are defined
  if( $attrs{bb} ) {
    my $id = $self->createRectangle ( $x1, -1 * $y2, $x2, -1 * $y1,
				      -outline => $color,
				      -fill => $fill, @styleArgs,
				      -tags => $tags );
    $self->lower($id); # make sure it doesn't obscure anything
  }

  # Create the label, if defined
  if ( defined($attrs{label}) ) {
    my $lp = $attrs{lp} || '';
    my ($x,$y) = split(/\s*,\s*/,$lp);
    if ( $lp eq '' ) { ($x,$y) = ($x1, $y2); }

    $label =~ s/\\n/\n/g;
    $tags->[0] = 'subgraphlabel'; # Replace 'subgraph' w/ 'subgraphlabel'
    my @args = ( $x, -1 * $y,
		 -text => $label,
		 -tags => $tags );
    push @args, ( -state => 'disabled' );
    if ( $lp eq '' ) { push @args, ( -anchor => 'nw' ); }

    $self->createText ( @args );
  }
}


######################################################################
# Create a node
#
######################################################################
sub _createNode
{
  my ($self, $name, %attrs) = @_;

  my ($x,$y) = split(/,/, $attrs{pos});
  my $dpi = $self->{dpi};
  my $w = $attrs{width} * $dpi; #inches
  my $h = $attrs{height} * $dpi; #inches
  my $x1 = $x - $w/2.0;
  my $y1 = $y - $h/2.0;
  my $x2 = $x + $w/2.0;
  my $y2 = $y + $h/2.0;

  my $label = $attrs{label};
  $label = $attrs{label} = $name unless defined $label;
  if ( $label eq '\N' ) { $label = $attrs{label} = $name; }

  #STDERR->printf ( "createNode: $name \"$label\" ($x1,$y1) ($x2,$y2)\n" );


  # Node shape
  my $tags = [ node => $name, %attrs ];

  my @args = ();

  my $outline = $self->_tryColor($attrs{color}) || 'black';
  my $fill = $self->_tryColor($attrs{fillcolor}) || $self->cget('-background');
  my $fontcolor = $self->_tryColor($attrs{fontcolor}) || 'black';
  my $shape = $attrs{shape} || '';

  foreach my $style ( split ( /,/, $attrs{style}||'' ) ) {
    if ( $style eq 'filled' ) {
      $fill = ( $self->_tryColor($attrs{fillcolor}) ||
		$self->_tryColor($attrs{color}) ||
		'lightgrey' );
    }
    elsif ( $style eq 'invis' ) {
      $outline = undef;
      $fill = undef;
    }
    elsif ( $style eq 'dashed' ) {
      push @args, -dash => '--';
    }
    elsif ( $style eq 'dotted' ) {
      push @args, -dash => '.';
    }
    elsif ( $style eq 'bold' ) {
      push @args, -width => 2.0;
    }
    elsif ( $style =~ /setlinewidth\((\d+)\)/ ) {
      push @args, -width => "$1";
    }
  }

  push @args, -outline => $outline if ( defined($outline) );
  push @args, -fill => $fill if ( defined($fill) );

  my $orient = $attrs{orientation} || 0.0;

  # Node label
  $label =~ s/\\n/\n/g;

  unless ( $shape eq 'record' ) {
    # Normal non-record node types
    $self->_createShapeNode ( $shape, $x1, -1*$y2, $x2, -1*$y1,
			      $orient, @args, -tags => $tags );

    $label = undef if ( $shape eq 'point' );

    # Node label
    if ( defined $label ) {
      $tags->[0] = 'nodelabel'; # Replace 'node' w/ 'nodelabel'
      @args = ( ($x1 + $x2)/2, -1*($y2 + $y1)/2, -text => $label,
		-anchor => 'center', -justify => 'center',
		-tags => $tags, -fill => $fontcolor );
      push @args, ( -state => 'disabled' );
      $self->createText ( @args );
    }
  }
  else {
    # Record node types
    $self->_createRecordNode ( $label, %attrs, tags => $tags );
  }

  # Return the bounding box of the node
  ($x1,$y1,$x2,$y2);
}


######################################################################
# Create an item of a specific shape, generally used for creating
# node shapes.
######################################################################
my %polyShapes =
  ( box => [ [ 0, 0 ], [ 0, 1 ], [ 1, 1 ], [ 1, 0 ] ],
    rect => [ [ 0, 0 ], [ 0, 1 ], [ 1, 1 ], [ 1, 0 ] ],
    rectangle => [ [ 0, 0 ], [ 0, 1 ], [ 1, 1 ], [ 1, 0 ] ],
    triangle => [ [ 0, .75 ], [ 0.5, 0 ], [ 1, .75 ] ],
    invtriangle => [ [ 0, .25 ], [ 0.5, 1 ], [ 1, .25 ] ],
    diamond => [ [ 0, 0.5 ], [ 0.5, 1.0 ], [ 1.0, 0.5 ], [ 0.5, 0.0 ] ],
    pentagon => [ [ .5, 0 ], [ 1, .4 ], [ .75, 1 ], [ .25, 1 ], [ 0, .4 ] ],
    hexagon => [ [ 0, .5 ], [ .33, 0 ], [ .66, 0 ],
		 [ 1, .5 ], [ .66, 1 ], [ .33, 1 ] ],
    septagon => [ [ .5, 0 ], [ .85, .3 ], [ 1, .7 ], [ .75, 1 ],
		  [ .25, 1 ], [ 0, .7 ], [ .15, .3 ] ],
    octagon => [ [ 0, .3 ], [ 0, .7 ], [ .3, 1 ], [ .7, 1 ],
		 [ 1, .7 ], [ 1, .3 ], [ .7, 0 ], [ .3, 0 ] ],
    trapezium => [ [ 0, 1 ], [ .21, 0 ], [ .79, 0 ], [ 1, 1 ] ],
    invtrapezium => [ [ 0, 0], [ .21, 1 ], [ .79, 1 ], [ 1, 0 ] ],
    parallelogram => [ [ 0, 1 ], [ .20, 0 ], [ 1, 0 ], [ .80, 1 ] ],
    house => [ [ 0, .9 ], [ 0, .5 ], [ .5, 0 ], [ 1, .5 ], [ 1, .9 ] ],
    invhouse => [ [ 0, .1 ], [ 0, .5 ], [ .5, 1 ], [ 1, .5 ], [ 1, .1 ] ],
    folder => [ [ 0, 0.1 ], [ 0, 1 ], [ 1, 1 ], [ 1, 0.1 ],
                [0.9, 0 ], [0.7 , 0 ] , [0.6, 0.1 ] ],
    component => [ [ 0, 0 ], [ 0, 0.1 ], [ 0.03, 0.1 ], [ -0.03, 0.1 ],
                   [ -0.03, 0.3 ], [ 0.03 , 0.3 ], [ 0.03, 0.1 ],
                   [ 0.03 , 0.3 ], [ 0 , 0.3 ], [ 0, 0.7 ], [ 0.03, 0.7 ],
                   [ -0.03, 0.7 ], [ -0.03, 0.9 ], [ 0.03 , 0.9 ],
                   [ 0.03, 0.7 ], [ 0.03 , 0.9 ], [ 0 , 0.9 ],
                   [ 0, 1 ], [ 1, 1 ], [ 1, 0 ] ],
);

sub _createShapeNode
{
  my ($self, $shape, $x1, $y1, $x2, $y2, $orient, %args) = @_;

  #STDERR->printf ( "createShape: $shape ($x1,$y1) ($x2,$y2)\n" );
  my $id = undef;

  my @extraArgs = ();

  # Special handling for recursive calls to create periphery shapes
  # (for double-, triple-, etc)
  my $periphShape = $args{_periph};
  if ( defined $periphShape ) {
    delete $args{_periph};

    # Periphery shapes are drawn non-filled, so they are
    # not clickable
    push @extraArgs, ( -fill => undef, -state => 'disabled' );
  };


  # Simple shapes: defined in the polyShape hash
  if ( exists $polyShapes{$shape} ) {
    $id = $self->_createPolyShape ( $polyShapes{$shape}, 
				    $x1, $y1, $x2, $y2, $orient,
				    %args, @extraArgs );
  }

  # Other special-case shapes:

  elsif ( $shape =~ s/^double// ) {
    my $diam = max(abs($x2-$x1),abs($y2-$y1));
    my $inset = max(2,min(5,$diam*.1));
    return $self->_createShapeNode ( $shape, $x1, $y1, $x2, $y2, $orient,
				     %args, _periph => [ 1, $inset ] );
  }

  elsif ( $shape =~ s/^triple// ) {
    my $diam = max(abs($x2-$x1),abs($y2-$y1));
    my $inset = min(5,$diam*.1);
    return $self->_createShapeNode ( $shape, $x1, $y1, $x2, $y2, $orient,
				     %args, _periph => [ 2, $inset ] );
  }

  elsif (  $shape eq 'plaintext' ) {
    # Don't draw an outline for plaintext
    $id = 0;
  }

  elsif ( $shape eq 'point' ) {
    # Draw point as a small oval
    $shape = 'oval';
  }

  elsif ( $shape eq 'ellipse' || $shape eq 'circle' ) {
    $shape = 'oval';
  }

  elsif ( $shape eq 'oval' ) {

  }

  elsif ( $shape eq '' ) {
    # Default shape = ellipse
    $shape = 'oval';
  }

  else {
    warn __PACKAGE__.": Unsupported shape type: '$shape', using box";
  }

  if ( !defined $id ) {
    if ( $shape eq 'oval' ) {
      $id = $self->createOval ( $x1, $y1, $x2, $y2, %args, @extraArgs );
    } else {
      $id = $self->createRectangle ( $x1, $y1, $x2, $y2, %args, @extraArgs );
    }
  }

  # Need to create additional periphery shapes?
  if ( defined $periphShape ) {
    # This method of stepping in a fixed ammount in x and y is not
    # correct, because the aspect of the overall shape changes...
    my $inset = $periphShape->[1];
    $x1 += $inset;
    $y1 += $inset;
    $x2 -= $inset;
    $y2 -= $inset;
    if ( --$periphShape->[0] > 0 ) { 
      @extraArgs = ( _periph => $periphShape );
    } else {
      @extraArgs = ();
    }
    return $self->_createShapeNode ( $shape, $x1, $y1, $x2, $y2, $orient,
				     %args, @extraArgs );
  }

  $id;
}


######################################################################
# Create an arbitrary polygonal shape, using a set of unit points.
# The points will be scaled to fit the given bounding box.
######################################################################
sub _createPolyShape
{
  my ($self, $upts, $x1, $y1, $x2, $y2, $orient, %args) = @_;

  my ($ox, $oy) = 1.0;
  if ( $orient != 0 ) {
    $orient %= 360.0;

    # Convert to radians, and rotate ccw instead of cw
    $orient *= 0.017453; # pi / 180.0
    my $c = cos($orient);
    my $s = sin($orient);
    my $s_plus_c = $s + $c;
    my @rupts = ();
    foreach my $upt ( @$upts ) {
      my ($ux, $uy) = @$upt;
      $ux -= 0.5;
      $uy -= 0.5;

      #STDERR->printf ( "orient: rotate (%.2f,%.2f) by %g deg\n",
      #		       $ux, $uy, $orient / 0.017453 );
      $ux = $ux * $c - $uy * $s; # x' = x cos(t) - y sin(t)
      $uy = $uy * $s_plus_c;     # y' = y sin(t) + y cos(t)
      #STDERR->printf ( "       --> (%.2f,%.2f)\n", $ux, $uy  );

      $ux += 0.5;
      $uy += 0.5;

      push @rupts, [ $ux, $uy ];
    }
    $upts = \@rupts;
  }

  my $dx = $x2 - $x1;
  my $dy = $y2 - $y1;
  my @pts = ();
  foreach my $upt ( @$upts ) {
    my ($ux, $uy ) = @$upt;

    push @pts, ( $x1 + $ux*$dx, $y1 + $uy*$dy );
  }
  $self->createPolygon ( @pts, %args );
}


######################################################################
# Draw the node record shapes
######################################################################
sub _createRecordNode
{
  my ($self, $label, %attrs) = @_;

  my $tags = $attrs{tags};

  # Get Rectangle Coords
  my $rects = $attrs{rects};
  my @rects = split(' ', $rects);
  my @rectsCoords = map [ split(',',$_) ], @rects;

  # Setup to parse the label (Label parser object created using Parse::Yapp)
  my $parser = new Tk::GraphViz::parseRecordLabel();
  $parser->YYData->{INPUT} = $label;

  # And parse it...
  my $structure = $parser->YYParse
    ( yylex => \&Tk::GraphViz::parseRecordLabel::Lexer,
      yyerror => \&Tk::GraphViz::parseRecordLabel::Error,
      yydebug => 0 );
  die __PACKAGE__.": Error Parsing Record Node Label '$label'\n"
    unless $structure;

  my @labels = @$structure;

  # Draw the rectangles
  my $portIndex = 1;  # Ports numbered from 1. This is used for the port name
                      # in the tags, if no port name is defined in the dot file
  foreach my $rectCoords ( @rectsCoords ) {
    my ($port, $text) = %{shift @labels};

    # use port index for name, if one not defined
    $port = $portIndex unless ( $port =~ /\S/);

    my %portTags = (@$tags); # copy of tags
    $portTags{port} = $port;

    # get rid of leading trailing whitespace
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;

    $portTags{label} = $text;

    my ($x1,$y1,$x2,$y2) = @$rectCoords;
    $self->createRectangle ( $x1, -$y1, $x2, -$y2, -tags => [%portTags] );

    # Find midpoint for label anchor point
    my $midX = ($x1 + $x2)/2;
    my $midY = ($y1 + $y2)/2;
    $portTags{nodelabel} = delete $portTags{node}; # Replace 'node' w/ 'nodelabel'
    $self->createText ( $midX, -$midY, -text => $text, -tags => [%portTags]);

    $portIndex++;
  }
}


######################################################################
# Create a edge
#
######################################################################
sub _createEdge
{
  my ($self, $n1, $n2, %attrs) = @_;

  my $x1 = undef;
  my $y1 = undef;
  my $x2 = undef;
  my $y2 = undef;

  my $tags = [ edge => "$n1 $n2",
	       node1 => $n1, node2 => $n2,
	       %attrs ];

  # Parse the edge position
  my $pos = $attrs{pos} || return;
  my ($startEndCoords,@coords) = $self->_parseEdgePos ( $pos );
  my $arrowhead = $attrs{arrowhead};
  my $arrowtail = $attrs{arrowtail};

  my @args = ();

  # Convert Biezer control points to 4 real points to smooth against
  #  Canvas line smoothing doesn't use beizers, so we supply more points
  #   along the manually-calculated bezier points.

  @coords = map @$_, @coords; #flatten coords array

  my @newCoords;
  my ($startIndex, $stopIndex);
  $startIndex = 0;
  $stopIndex  = 7;
  my $lastFlag = 0;
  my @controlPoints;
  while($stopIndex <= $#coords){
    @controlPoints = @coords[$startIndex..$stopIndex];

    # If this is the last set, set the flag, so we will get
    # the last point
    $lastFlag = 1 if( $stopIndex == $#coords);

    push @newCoords, 
      $self->_bezierInterpolate(\@controlPoints, 0.1, $lastFlag);

    $startIndex += 6;
    $stopIndex += 6;
  }

  # Add start/end coords
  if(defined($startEndCoords->{s})){
    unshift @newCoords, @{ $startEndCoords->{s} }; # put at the begining
  }
  if(defined($startEndCoords->{e})){
    push @newCoords, @{ $startEndCoords->{e}}; # put at the end
  }

  # Convert Sign of y-values of coords, record min/max
  for( my $i = 0; $i < @newCoords; $i+= 2){
    my ($x,$y) = @newCoords[$i, $i+1];
    push @args, $x, -1*$y;
    #printf ( "  $x,$y\n" );
    $x1 = min($x1, $x);
    $y1 = min($y1, $y);
    $x2 = max($x2, $x);
    $y2 = max($y2, $y);
  }

  #STDERR->printf ( "createEdge: $n1->$n2 ($x1,$y1) ($x2,$y2)\n" );
  if ( defined($startEndCoords->{s}) &&
       defined($startEndCoords->{e}) &&
       (not defined $arrowhead) &&
       (not defined $arrowtail) ) { # two-sided arrow
    push @args, -arrow => 'both';
  }
  elsif ( defined($startEndCoords->{e}) &&
	  (not defined $arrowhead) ) { # arrow just at the end
    push @args, -arrow => 'last';	
  }
  elsif ( defined($startEndCoords->{s}) &&
	  (not defined $arrowtail) ) { # arrow just at the start
    push @args, -arrow => 'first';	
  }

  my $color = $attrs{color};

  foreach my $style ( split(/,/, $attrs{style}||'') ) {
    if ( $style eq 'dashed' ) {
      push @args, -dash => '--';
    }
    elsif ( $style eq 'dotted' ) {
      push @args, -dash => ',';
    }
    elsif ( $style =~ /setlinewidth\((\d+)\)/ ) {
      push @args, -width => "$1";
    }
    elsif ( $style =~ /invis/ ) {
      # invisible edge, make same as background
      $color = $self->cget('-background');
    }
  }

  push @args, -fill => ( $self->_tryColor($color) || 'black' );

  # Create the line
  $self->createLine ( @args, -smooth => 1, -tags => $tags );

  # Create the arrowhead (at end of line)
  if ( defined($arrowhead) && $arrowhead =~ /^(.*)dot$/ ) {
    my $modifier = $1;

    # easy implementation for calculating the arrow position
    my ($x1, $y1) = @newCoords[(@newCoords-2), (@newCoords-1)];
    my ($x2, $y2) = @newCoords[(@newCoords-4), (@newCoords-3)];
    my $x = ($x1 + $x2)/2;
    my $y = ($y1 + $y2)/2;
    my @args = ($x-4, -1*($y-4), $x+4, -1*($y+4));

    # check for modifiers
    if ($modifier eq "o") {
      push @args, -fill => $self->cget('-background');
    } else {
      push @args, -fill => ($self->_tryColor($color) || 'black');
    }

    # draw
    $self->createOval ( @args );
  }

  # Create the arrowtail (at start of line)
  if ( defined($arrowtail) && $arrowtail =~ /^(.*)dot$/ ) {
    my $modifier = $1;

    # easy implementation for calculating the arrow position
    my ($x1, $y1) = @newCoords[0, 1];
    my ($x2, $y2) = @newCoords[2, 3];
    my $x = ($x1 + $x2)/2;
    my $y = ($y1 + $y2)/2;
    my @args = ($x-4, -1*($y-4), $x+4, -1*($y+4));

    # check for modifiers
    if ($modifier eq "o") {
      push @args, -fill => $self->cget('-background');
    } else {
      push @args, -fill => ($self->_tryColor($color) || 'black');
    }

    # draw
    $self->createOval ( @args );
  }

  # Create optional label
  my $label = $attrs{label};
  my $lp = $attrs{lp};
  if ( defined($label) && defined($lp) ) {
    $label =~ s/\\n/\n/g;
    $tags->[0] = 'edgelabel'; # Replace 'edge' w/ 'edgelabel'
    my ($x,$y) = split(/,/, $lp);
    my @args = ( $x, -1*$y, -text => $label, -tags => $tags,
                 -justify => 'center' );
    push @args, ( -state => 'disabled' );
    $self->createText ( @args );
  }


  # Return the bounding box of the edge
  ($x1,$y1,$x2,$y2);
}


######################################################################
# Parse the coordinates for an edge from the 'pos' string
#
######################################################################
sub _parseEdgePos
{
  my ($self, $pos) = @_;

  # Note: Arrows can be at the start and end, i.e.
  #    pos =  s,410,104 e,558,59 417,98 ...
  #      (See example graph 'graphs/directed/ldbxtried.dot')

  # hash of start/end coords
  # Example: e => [ 12, 3 ], s = [ 1, 3 ]
  my %startEnd;

  # Process all start/end points (could be none, 1, or 2)
  while ( $pos =~ s/^([se])\s*\,\s*(\d+)\s*\,\s*(\d+)\s+// ) {
    my ($where, $x, $y) = ($1, $2, $3);
    $startEnd{$where} = [ $x, $y ];
  }

  my @loc = split(/ |,/, $pos);
  my @coords = ();
  while ( @loc >= 2 ) {
    my ($x,$y) = splice(@loc,0,2);
    push @coords, [$x,$y];
  }

  (\%startEnd, @coords);
}


######################################################################
# Sub to make points on a curve, based on Bezier control points
#  Inputs:
#   $controlPoints: Array of control points (x/y P0,1,2,3)
#   $tinc:  Increment to use for t (t = 0 to 1 )
#   $lastFlag: Flag = 1 to generate the last point (where t = 1)
#
#  Output;
#   @outputPoints: Array of points along the biezier curve
#
#  Equations used
#Found Bezier Equations at http://pfaedit.sourceforge.net/bezier.html
#
#	A cubic Bezier curve may be viewed as:
#	x = ax*t3 + bx*t2 + cx*t +dx
#	 y = ay*t3 + by*t2 + cy*t +dy
#
#	Where
#
#	dx = P0.x
#	dy = P0.y
#	cx = 3*P1.x-3*P0.x
#	cy = 3*P1.y-3*P0.y
#	bx = 3*P2.x-6*P1.x+3*P0.x
#	by = 3*P2.y-6*P1.y+3*P0.y
#	ax = P3.x-3*P2.x+3*P1.x-P0.x
#	ay = P3.y-3*P2.y+3*P1.y-P0.y
######################################################################
sub _bezierInterpolate
{
  my ($self,$controlPoints, $tinc, $lastFlag) = @_;

  # interpolation constants
  my ($ax,$bx,$cx,$dx);
  my ($ay,$by,$cy,$dy);

  $dx =    $controlPoints->[0];
  $cx =  3*$controlPoints->[2] - 3*$controlPoints->[0];
  $bx =  3*$controlPoints->[4] - 6*$controlPoints->[2] + 3*$controlPoints->[0];
  $ax = (  $controlPoints->[6] - 3*$controlPoints->[4] + 3*$controlPoints->[2]
	   - $controlPoints->[0] );

  $dy =    $controlPoints->[1];
  $cy =  3*$controlPoints->[3] - 3*$controlPoints->[1];
  $by =  3*$controlPoints->[5] - 6*$controlPoints->[3] + 3*$controlPoints->[1];
  $ay = (  $controlPoints->[7] - 3*$controlPoints->[5] + 3*$controlPoints->[3]
	   - $controlPoints->[1] );

  my @outputPoints;
  for( my $t=0; $t <= 1; $t+=$tinc ){
    # don't do the last point unless lastflag set
    next if($t == 1 && !$lastFlag);

    # Compute X point
    push @outputPoints, ($ax*$t**3 + $bx*$t**2 + $cx*$t +$dx);

    # Compute Y point
    push @outputPoints, ($ay*$t**3 + $by*$t**2 + $cy*$t +$dy);
  }

  return @outputPoints;
}


######################################################################
# Update scroll region to new bounds, to encompass
# the entire contents of the canvas
######################################################################
sub _updateScrollRegion
{
  my ($self) = @_;

  # Ignore passed in in bbox, get a new one
  my ($x1,$y1,$x2,$y2) = $self->bbox('all');
  return 0 unless defined $x1;

  # Set canvas size from graph bounding box
  my $m = 0;#$self->{margin};
  $self->configure ( -scrollregion => [ $x1-$m, $y1-$m, $x2+$m, $y2+$m ],
		     -confine => 1 );

  # Reset original scale factor
  $self->{_scaled} = 1.0;

  1;
}


######################################################################
# Update the scale factor
#
# Called by operations that do scaling
######################################################################
sub _scaleAndMoveView
{
  my ($self, $scale, $x, $y) = @_;

  $self->scale ( 'all' => 0, 0, $scale, $scale );
  my $new_scaled = $self->{_scaled} * $scale;
  #STDERR->printf ( "\nscaled: %s -> %s\n",
  #		       $self->{_scaled}, $new_scaled );

  # Scale the fonts:
  my $fonts = $self->{fonts};
  #print "new_scaled = $new_scaled\n";
  foreach my $fontName ( keys %$fonts ) {
    my $font = $fonts->{$fontName}{font};
    my $origSize = $fonts->{$fontName}{origSize};

    # Flag to indicate size is negative (i.e. specified in pixels)
    my $negativeSize = $origSize < 0 ? -1 : 1;
    $origSize = abs($origSize); # Make abs value for finding scale

    # Fonts can't go below size 2, or they suddenly jump up to size 6...
    my $newSize = max(2,int( $origSize*$new_scaled + 0.5));

    $newSize *= $negativeSize;

    $font->configure ( -size => $newSize );
    #print "Font '$fontName' Origsize = $origSize, newsize $newSize, actual size ".$font->actual(-size)."\n";
  }

  $self->{_scaled} = $new_scaled;

  # Reset scroll region
  my @sr = $self->cget( '-scrollregion' );
  my $sr = \@sr;
  if ( @sr == 1 ) { $sr = $sr[0]; }
  $_ *= $scale foreach ( @$sr );
  $self->configure ( -scrollregion => $sr );

  # Change the view to center on correct area
  # $x and $y are expected to be coords in the pre-scaled system
  my ($left, $right) = $self->xview;
  my ($top, $bot) = $self->yview;
  my $xpos = ($x*$scale-$sr->[0])/($sr->[2]-$sr->[0]) - ($right-$left)/2.0;
  my $ypos = ($y*$scale-$sr->[1])/($sr->[3]-$sr->[1]) - ($bot-$top)/2.0;
  $self->xview( moveto => $xpos );
  $self->yview( moveto => $ypos );

  #($left, $right) = $self->xview;
  #($top, $bot) = $self->yview;
  #STDERR->printf( "scaled: midx=%s midy=%s\n",
  #		  ($left+$right)/2.0, ($top+$bot)/2.0 );
  1;
}


######################################################################
# Setup some standard bindings.
#
# This enables some standard useful functionality for scrolling,
# zooming, etc.
#
# The bindings need to interfere as little as possible with typical
# bindings that might be employed in an application using this
# widget (e.g. Button-1).
#
# Also, creating these bindings (by calling this method) is strictly
# optional.
######################################################################
sub createBindings
{
  my ($self, %opt) = @_;

  if ( scalar(keys %opt) == 0 # Empty options list
       || defined $opt{'-default'} && $opt{'-default'} ) {

    # Default zoom bindings
    $opt{'-zoom'} = 1;

    # Default scroll bindings
    $opt{'-scroll'} = 1;

    # Key-pad bindings
    $opt{'-keypad'} = 1;
  }

  if ( defined $opt{'-zoom'} ) {
    $self->_createZoomBindings( %opt );
  }

  if ( defined $opt{'-scroll'} ) {
    $self->_createScrollBindings( %opt );
  }

  if ( defined $opt{'-keypad'} ) {
    $self->_createKeypadBindings( %opt );
  }

}


######################################################################
# Setup bindings for zooming operations
#
# These are bound to a specific mouse button and optional modifiers.
# - To zoom in: drag out a box from top-left/right to bottom-right/left
#   enclosing the new region to display
# - To zoom out: drag out a box from bottom-left/right to top-right/left.
#   size of the box determines zoom out factor.
######################################################################
sub _createZoomBindings
{
  my ($self, %opt) = @_;

  # Interpret zooming options

  # What mouse button + modifiers starts zoom?
  my $zoomSpec = $opt{'-zoom'};
  die __PACKAGE__.": No -zoom option" unless defined $zoomSpec;
  if ( $zoomSpec =~ /^\<.+\>$/ ) {
    # This should be a partial bind event spec, e.g. <1>, or <Shift-3>
    # -- it must end in a button number
    die __PACKAGE__.": Illegal -zoom option"
      unless ( $zoomSpec =~ /^\<.+\-\d\>$/ ||
	       $zoomSpec =~ /^\<\d\>$/ );
  }
  else {
    # Anything else: use the default
    $zoomSpec = '<Shift-2>';
  }

  # Color for zoom rect
  my $zoomColor = $opt{'-zoomcolor'} || 'red';

  # Initial press starts drawing zoom rect
  my $startEvent = $zoomSpec;
  $startEvent =~ s/(\d\>)$/ButtonPress-$1/;
  #STDERR->printf ( "startEvent = $startEvent\n" );
  $self->Tk::bind ( $startEvent => sub { $self->_startZoom ( $zoomSpec,
							     $zoomColor ) });
}


######################################################################
# Called whenever a zoom event is started.  This creates the initial
# zoom rectangle, and installs (temporary) bindings for mouse motion
# and release to drag out the zoom rect and then compute the zoom
# operation.
#
# The motion / button release bindings have to be installed temporarily
# so they don't conflict with other bindings (such as for scrolling
# or panning).  The original bindings for those events have to be
# restored once the zoom operation is completed.
######################################################################
sub _startZoom
{
  my ($self, $zoomSpec, $zoomColor) = @_;

  # Start of the zoom rectangle
  my $x = $self->canvasx ( $Tk::event->x );
  my $y = $self->canvasy ( $Tk::event->y );
  my @zoomCoords = ( $x, $y, $x, $y );
  my $zoomRect = $self->createRectangle 
    ( @zoomCoords, -outline => $zoomColor );

  # Install the Motion binding to drag out the rectangle -- store the
  # origin binding.
  my $dragEvent = '<Motion>';
  #STDERR->printf ( "dragEvent = $dragEvent\n" );
  my $origDragBind = $self->Tk::bind ( $dragEvent );
  $self->Tk::bind ( $dragEvent => sub {
		      $zoomCoords[2] = $self->canvasx ( $Tk::event->x );
		      $zoomCoords[3] = $self->canvasy ( $Tk::event->y );
		      $self->coords ( $zoomRect => @zoomCoords );
		    } );

  # Releasing button finishes zoom rect, and causes zoom to happen.
  my $stopEvent = $zoomSpec;
  $stopEvent =~ s/^\<.*(\d\>)$/<ButtonRelease-$1/;
  #STDERR->printf ( "stopEvent = $stopEvent\n" );
  my $threshold = 10;
  my $origStopBind = $self->Tk::bind ( $stopEvent );
  $self->Tk::bind ( $stopEvent => sub {
		      # Delete the rect
		      $self->delete ( $zoomRect );

		      # Restore original bindings
		      $self->Tk::bind ( $dragEvent => $origDragBind );
		      $self->Tk::bind ( $stopEvent => $origStopBind );

		      # Was the rectangle big enough?
		      my $dx = $zoomCoords[2] - $zoomCoords[0];
		      my $dy = $zoomCoords[3] - $zoomCoords[1];

		      return if ( abs($dx) < $threshold ||
				  abs($dy) < $threshold );

		      # Find the zooming factor
		      my $zx = $self->width() / abs($dx);
		      my $zy = $self->height() / abs($dy);
		      my $scale = min($zx, $zy);

		      # Zoom in our out?
		      # top->bottom drag means out,
		      # bottom->top drag means in.
		      # (0,0) is top left, so $dy > 0 means top->bottom
		      if ( $dy > 0 ) {
			# Zooming in!
			#STDERR->printf ( "Zooming in: $scale\n" );
		      } else {
			# Zooming out!
			$scale = 1 - 1.0 / $scale;
			#STDERR->printf ( "Zooming out: $scale\n" );
		      }

		      # Scale everying up / down
		      $self->_scaleAndMoveView
			( $scale,
			  ($zoomCoords[0]+$zoomCoords[2])/2.0,
			  ($zoomCoords[1]+$zoomCoords[3])/2.0 );
		    });

  1;
}


######################################################################
# Setup bindings for scrolling / panning operations
#
######################################################################
sub _createScrollBindings
{
  my ($self, %opt) = @_;

  # Interpret scrolling options

  # What mouse button + modifiers starts scroll?
  my $scrollSpec = $opt{'-scroll'};
  die __PACKAGE__.": No -scroll option" unless defined $scrollSpec;
  if ( $scrollSpec =~ /^\<.+\>$/ ) {
    # This should be a partial bind event spec, e.g. <1>, or <Shift-3>
    # -- it must end in a button number
    die __PACKAGE__.": Illegal -scroll option"
      unless ( $scrollSpec =~ /^\<.+\-\d\>$/ ||
	       $scrollSpec =~ /^\<\d\>$/ );
  }
  else {
    # Anything else: use the default
    $scrollSpec = '<2>';
  }

  # Initial press starts panning
  my $startEvent = $scrollSpec;
  $startEvent =~ s/(\d\>)$/ButtonPress-$1/;
  #STDERR->printf ( "startEvent = $startEvent\n" );
  $self->Tk::bind ( $startEvent => sub { $self->_startScroll 
					   ( $scrollSpec ) } );
}


######################################################################
# Called whenever a scroll event is started.  This installs (temporary)
# bindings for mouse motion and release to complete the scrolling.
#
# The motion / button release bindings have to be installed temporarily
# so they don't conflict with other bindings (such as for zooming)
# The original bindings for those events have to be restored once the
# zoom operation is completed.
######################################################################
sub _startScroll
{
  my ($self, $scrollSpec) = @_;

  # State data to keep track of scroll operation
  my $startx = $self->canvasx ( $Tk::event->x );
  my $starty = $self->canvasy ( $Tk::event->y );

  # Dragging causes scroll to happen
  my $dragEvent = '<Motion>';
  #STDERR->printf ( "dragEvent = $dragEvent\n" );
  my $origDragBind = $self->Tk::bind ( $dragEvent );
  $self->Tk::bind ( $dragEvent => sub {
		      my $x = $self->canvasx ( $Tk::event->x );
		      my $y = $self->canvasy ( $Tk::event->y );

		      # Compute scroll ammount
		      my $dx = $x - $startx;
		      my $dy = $y - $starty;
		      #STDERR->printf ( "Scrolling: dx=$dx, dy=$dy\n" );

                      # Feels better is scroll speed is reduced.
		      # Also is more natural inverted, feeld like dragging
		      # the canvas
                      $dx *= -.9;
                      $dy *= -.9;

                      my ($xv) = $self->xview();
                      my ($yv) = $self->yview();
		      my @sr = $self->cget( '-scrollregion' );
                      #STDERR->printf ( "  xv=$xv, yv=$yv\n" );
                      my $xpct = $xv + $dx/($sr[2]-$sr[0]);
                      my $ypct = $yv + $dy/($sr[3]-$sr[1]);
                      #STDERR->printf ( "  xpct=$xpct, ypct=$ypct\n" );
                      $self->xview ( moveto => $xpct );
                      $self->yview ( moveto => $ypct );

		      # This is the new reference point for
		      # next motion event
		      $startx = $x;
		      $starty = $y;
                      #STDERR->printf ( "  scrolled\n" );

		    } );

  # Releasing button finishes scrolling
  my $stopEvent = $scrollSpec;
  $stopEvent =~ s/^\<.*(\d\>)$/<ButtonRelease-$1/;
  #STDERR->printf ( "stopEvent = $stopEvent\n" );
  my $origStopBind = $self->Tk::bind ( $stopEvent );
  $self->Tk::bind ( $stopEvent => sub {

		      # Restore original bindings
		      $self->Tk::bind ( $dragEvent => $origDragBind );
		      $self->Tk::bind ( $stopEvent => $origStopBind );

		    } );

  1;
}


######################################################################
# Setup bindings for keypad keys to do zooming and scrolling
#
# This binds +/- on the keypad to zoom in and out, and the arrow/number
# keys to scroll.
######################################################################
sub _createKeypadBindings
{
  my ($self, %opt) = @_;

  $self->Tk::bind ( '<KeyPress-KP_Add>' =>
		  sub { $self->zoom( -in => 1.15 ) } );
  $self->Tk::bind ( '<KeyPress-KP_Subtract>' =>
		  sub { $self->zoom( -out => 1.15 ) } );

  $self->Tk::bind ( '<KeyPress-KP_1>' =>
		  sub { $self->xview( scroll => -1, 'units' );
			$self->yview( scroll => 1, 'units' ) } );
  $self->Tk::bind ( '<KeyPress-KP_2>' =>
		  sub { $self->yview( scroll => 1, 'units' ) } );
  $self->Tk::bind ( '<KeyPress-KP_3>' =>
		  sub { $self->xview( scroll => 1, 'units' );
			$self->yview( scroll => 1, 'units' ) } );
  $self->Tk::bind ( '<KeyPress-KP_4>' =>
		  sub { $self->xview( scroll => -1, 'units' ) } );
  $self->Tk::bind ( '<KeyPress-KP_6>' =>
		  sub { $self->xview( scroll => 1, 'units' ) } );
  $self->Tk::bind ( '<KeyPress-KP_7>' =>
		  sub { $self->xview( scroll => -1, 'units' );
			$self->yview( scroll => -1, 'units' ) } );
  $self->Tk::bind ( '<KeyPress-KP_8>' =>
		  sub { $self->yview( scroll => -1, 'units' ) } );
  $self->Tk::bind ( '<KeyPress-KP_9>' =>
		  sub { $self->xview( scroll => 1, 'units' );
			$self->yview( scroll => -1, 'units' ) } );

  1;
}


#######################################################################
## Setup binding for 'fit' operation
##
## 'fit' scales the entire contents of the graph to fit within the
## visible portion of the canvas.
#######################################################################
#sub _createFitBindings
#{
#  my ($self, %opt) = @_;
#
#  # Interpret options
#
#  # What event to bind to?
#  my $fitEvent = $opt{'-fit'};
#  die __PACKAGE__.": No -fit option" unless defined $fitEvent;
#  if ( $fitEvent =~ /^\<.+\>$/ ) {
#    die __PACKAGE__.": Illegal -fit option"
#      unless ( $fitEvent =~ /^\<.+\>$/ );
#  }
#  else {
#    # Anything else: use the default
#    $fitEvent = '<Key-f>';
#  }
#
#  STDERR->printf ( "fit event = $fitEvent\n" );
#  $self->Tk::bind ( $fitEvent => sub { $self->fit( 'all' ) });
#  1;
#}


######################################################################
# Scale the graph to fit within the canvas
#
######################################################################
sub fit
{
  my ($self, $idOrTag) = @_;
  $idOrTag = 'all' unless defined $idOrTag;

  my $w = $self->width();
  my $h = $self->height();
  my ($x1,$y1,$x2,$y2) = $self->bbox( $idOrTag );
  return 0 unless ( defined $x1 && defined $x2 &&
		    defined $y1 && defined $y2 );

  my $dx = abs($x2 - $x1);
  my $dy = abs($y2 - $y1);

  my $scalex = $w / $dx;
  my $scaley = $h / $dy;
  my $scale = min ( $scalex, $scaley );
  if ( $scalex >= 1.0 && $scaley >= 1.0 ) {
    $scale = max ( $scalex, $scaley );
  }

  $self->_scaleAndMoveView ( $scale, 0, 0 );
  $self->xview( moveto => 0 );
  $self->yview( moveto => 0 );

  1;
}


######################################################################
# Zoom in or out, keep top-level centered.
#
######################################################################
sub zoom
{
  my ($self, $dir, $scale) = @_;

  if ( $dir eq '-in' ) {
    # Make things bigger
  }
  elsif ( $dir eq '-out' ) {
    # Make things smaller
    $scale = 1 / $scale;
  }

  my ($xv1,$xv2) = $self->xview();
  my ($yv1,$yv2) = $self->yview();
  my $xvm = ($xv2 + $xv1)/2.0;
  my $yvm = ($yv2 + $yv1)/2.0;
  my ($l, $t, $r, $b) = $self->cget( -scrollregion );

  $self->_scaleAndMoveView ( $scale,
			     $l + $xvm *($r - $l),
			     $t + $yvm *($b - $t) );

  1;
}


sub zoomTo
{
  my ($self, $tagOrId) = @_;

  $self->fit();

  my @bb = $self->bbox( $tagOrId );
  return unless @bb == 4 && defined($bb[0]);

  my $w = $bb[2] - $bb[0];
  my $h = $bb[3] - $bb[1];
  my $scale = 2;
  my $x1 = $bb[0] - $scale * $w;
  my $y1 = $bb[1] - $scale * $h;
  my $x2 = $bb[2] + $scale * $w;
  my $y2 = $bb[3] + $scale * $h;

  #STDERR->printf("zoomTo:  bb = @bb\n".
  #		 "         w=$w h=$h\n".
  #		 "         x1,$y1, $x2,$y2\n" );

  $self->zoomToRect( $x1, $y1, $x2, $y2 );
}


sub zoomToRect
{
  my ($self, @box) = @_;

  # make sure x1,y1 = lower left, x2,y2 = upper right
  ($box[0],$box[2]) = ($box[2],$box[0]) if $box[2] < $box[0];
  ($box[1],$box[3]) = ($box[3],$box[1]) if $box[3] < $box[1];

  # What is the scale relative to current bounds?
  my ($l,$r) = $self->xview;
  my ($t,$b) = $self->yview;
  my $curr_w = $r - $l;
  my $curr_h = $b - $t;

  my @sr = $self->cget( -scrollregion );
  my $sr_w = $sr[2] - $sr[0];
  my $sr_h = $sr[3] - $sr[1];
  my $new_l = max(0.0,$box[0] / $sr_w);
  my $new_t = max(0.0,$box[1] / $sr_h);
  my $new_r = min(1.0,$box[2] / $sr_w);
  my $new_b = min(1.0,$box[3] / $sr_h);

  my $new_w = $new_r - $new_l;
  my $new_h = $new_b - $new_t;

  my $scale = max( $curr_w/$new_w, $curr_h/$new_h );

  $self->_scaleAndMoveView( $scale,
			    ($box[0] + $box[2])/2.0,
			    ($box[1] + $box[3])/2.0 );

  1;
}


######################################################################
# Over-ridden createText Method
#
# Handles the embedded \l\r\n graphViz control characters
######################################################################
sub createText
{
  my ($self, $x, $y, %attrs) = @_;

  if( defined($attrs{-text}) ) {

    # Set Justification, based on any \n \l \r in the text label
    my $label = $attrs{-text};
    my $justify = 'center';

    # Per the dotguide.pdf, a '\l', '\r', or '\n' is
    #  just a line terminator, not a newline. So in cases
    #   where the label ends in one of these characters, we are
    #   going to remove the newline char later
    my $removeNewline;
    if( $label =~ /\\[nlr]$/){
      $removeNewline = 1;
    }

    if( $label =~ s/\\l/\n/g ){
      $justify = 'left';
    }
    if( $label =~ s/\\r/\n/g ){
      $justify = 'right';
    }

    # Change \n to actual \n
    if( $label =~ s/\\n/\n/g ){
      $justify  = 'center';
    }

    # remove ending newline if flag set
    if( $removeNewline){
      $label =~ s/\n$//;
    }

    # Fix  any escaped chars
    #   like \} to }, and \\{ to \{
    $label =~ s/\\(?!\\)(.)/$1/g;

    $attrs{-text} = $label;
    $attrs{-justify} = $justify;

    # Fix the label tag, if there is one
    my $tags;
    if( defined($tags = $attrs{-tags})){
      my %tags = (@$tags);
      $tags{label} = $label if(defined($tags{label}));
      $attrs{-tags} = [%tags];
    }

    # Get the default font, if not defined already
    my $fonts = $self->{fonts};
    unless(defined($fonts->{_default}) ){

      # Create dummy item, so we can see what font is used
      my $dummyID = $self->SUPER::createText 
	( 100,25, -text => "You should never see this" );
      my $defaultfont = $self->itemcget($dummyID,-font);

      # Make a copy that we will mess with:
      $defaultfont = $defaultfont->Clone;
      $fonts->{_default}{font}     = $defaultfont;
      $fonts->{_default}{origSize} = $defaultfont->actual(-size);

      # Delete the dummy item
      $self->delete($dummyID);
    }

    # Assign the default font
    unless( defined($attrs{-font}) ){
      $attrs{-font} = $fonts->{_default}{font};
    }

  }

  # Call Inherited createText
  $self->SUPER::createText ( $x, $y, %attrs );
}


######################################################################
#  Sub to try a color name, returns the color name if recognized
#   'black' and issues a warning if not
######################################################################
sub _tryColor
{
  my ($self,$color) = @_;

  return undef unless defined($color);

  # Special cases
  if( $color eq 'crimson' ) {
    # crimison not defined in Tk, so use GraphViz's definition
    return sprintf("#%02X%02x%02X", 246,231,220); 
  }
  elsif( $color =~ /^(-?\d+\.?\d*)\s+(-?\d+\.?\d*)\s+(-?\d+\.?\d*)\s*$/ ) {
    # three color numbers
    my($hue,$sat,$bright) = ($1,$2,$3);
    return $self->_hsb2rgb($hue,$sat,$bright);
  }

  # Don't check color if it is a hex rgb value
  unless( $color =~ /^\#\w+/ ) {
    my $tryColor = $color;
    $tryColor =~ s/\_//g; # get rid of any underscores
    my @rgb;
    eval { @rgb = $self->rgb($tryColor); };
    if ($@) {
      warn __PACKAGE__.": Unkown color $color, using black instead\n";
      $color = 'black';
    } else {
      $color = $tryColor;
    }
  }

  $color;
}	


######################################################################
# Sub to convert from Hue-Sat-Brightness to RGB hex number
#
######################################################################
sub _hsb2rgb
{
  my ($self,$h,$s,$v) = @_;

  my ($r,$g,$b);
  if( $s <= 0){
    $v = int($v);
    ($r,$g,$b) = ($v,$v,$v);
  }
  else{
    if( $h >= 1){
      $h = 0;
    }
    $h = 6*$h;
    my $f = $h - int($h);
    my $p = $v * (1 - $s);
    my $q = $v * ( 1 - ($s * $f));
    my $t = $v * ( 1 - ($s * (1-$f)));
    my $i = int($h);
    if( $i == 0){	   ($r,$g,$b)  = ($v, $t, $p);}
    elsif( $i == 1){ ($r,$g,$b)  = ($q, $v, $p);}
    elsif( $i == 2){($r,$g,$b)   = ($p, $v, $t);}
    elsif( $i == 3){($r,$g,$b)   = ($p, $q, $v);}
    elsif( $i == 4){($r,$g,$b)   = ($t, $p, $v);}
    elsif( $i == 5){($r,$g,$b)   = ($v, $p, $q);}

  }

  sprintf("#%02X%02x%02X", 255*$r, 255*$g, 244*$b);
}


######################################################################
# Utility functions
######################################################################

sub min {
  if ( defined($_[0]) ) {
    if ( defined($_[1]) ) { return ($_[0] < $_[1])? $_[0] : $_[1]; }
    else { return $_[0]; }
  } else {
    if ( defined($_[1]) ) { return $_[1]; }
    else { return undef; }
  }
}

sub max {
  if ( defined($_[0]) ) {
    if ( defined($_[1]) ) { return ($_[0] > $_[1])? $_[0] : $_[1]; }
    else { return $_[0]; }
  } else {
    if ( defined($_[1]) ) { return $_[1]; }
    else { return undef; }
  }
}

__END__


=head1 NAME

Tk::GraphViz - Render an interactive GraphViz graph

=head1 SYNOPSIS

    use Tk::GraphViz;
    my $gv = $mw->GraphViz ( qw/-width 300 -height 300/ )
      ->pack ( qw/-expand yes -fill both/ );
    $gv->show ( $dotfile );

=head1 DESCRIPTION

The B<GraphViz> widget is derived from B<Tk::Canvas>.  It adds the ability to render graphs in the canvas.  The graphs can be specified either using the B<DOT> graph-description language, or using via a B<GraphViz> object.

When B<show()> is called, the graph is passed to the B<dot> command to generate the layout info.  That info is then used to create rectangles, lines, etc in the canvas that reflect the generated layout.

Once the items have been created in the graph, they can be used like any normal canvas items: events can be bound, etc.  In this way, interactive graphing applications can be created very easily.

=head1 METHODS

=head2 $gv->show ( graph, ?opt => val, ...? )

Renders the given graph in the canvas.  The graph itself can be specified in a number of formats.  'graph' can be one of the following:

=over 4

=item - An instance of the GraphViz class (or subclass thereof)

=item - A scalar containing a graph in DOT format.  The scalar must match /^\s*(?:di)?graph /.

=item - An instance of the IO::Handle class (or subclass thereof), from which to read a graph in DOT format.

=item - The name / path of a file that contains a graph in DOT format.

=back

show() will recognize some options that control how the graph is rendered, etc.  The recognized options:

=over 4

=item layout => CMD

Specifies an alternate command to invoke to generate the layout of the graph.  If not given, then default is 'dot'.  This can be used, for example, to use 'neato' instead of 'dot'.

=item graphattrs => [ name => value, ... ]

Allows additional default graph attributes to be specified.  Each name => value pair will be passed to dot as '-Gname=value' on the command-line.

=item nodeattrs => [ name => value, ... ]

Allows additional default node attributes to be specified.  Each name => value pair will be passed to dot as '-Nname=value' on the command-line.

=item edgeattrs => [ name => value, ... ]

Allows additional default edge attributes to be specified.  Each name => value pair will be passed to dot as '-Ename=value' on the command-line.

=back

For example, to use neato to generate a layout with non-overlapping nodes and spline edges:

    $gv->show ( $file, layout => 'neato',
                graphattrs => [qw( overlap false spline true )] );


=head2 $gv->createBindings ( ?option => value? )

The Tk::GraphViz canvas can be configured with some bindings for standard operations.  If no options are given, the default bindings for zooming and scrolling will be enabled.  Alternative bindings can be specified via these options:

=over 4

=item -zoom => I<true>

Creates the default bindings for zooming.  Zooming in or out in the canvas will be bound to <Shift-2> (Shift + mouse button 2).  To zoom in, click and drag out a zoom rectangle from top left to bottom right.  To zoom out, click and drag out a zoom rectangle from bottom left to top right.

=item -zoom => I<spec>

This will bind zooming to an alternative event sequence.  Examples:

    -zoom => '<1>'      # Zoom on mouse button 1
    -zoom => '<Ctrl-3>' # Zoom on Ctrl + mouse button 3

=item -scroll => I<true>

Creates the default bindings for scrolling / panning.  Scrolling the canvas will be bound to <2> (Mouse button 2).

=item -scroll => I<spec>

This will bind scrolling to an alternative event sequence.  Examples:

    -scroll => '<1>'      # Scroll on mouse button 1
    -scroll => '<Ctrl-3>' # Scroll on Ctrl + mouse button 3

=item -keypad => I<true>

Binds the keypad arrow / number keys to scroll the canvas, and the keypad +/- keys to zoom in and out.  Note that the canvas must have the keyboard focus for these bindings to be activated.  This is done by default when createBindings() is called without any options.

=back

=head2 $gv->fit()

Scales all of the elements in the canvas to fit the canvas' width and height.

=head2 $gv->zoom( -in => factor )

Zoom in by scaling everything up by the given scale factor.  The factor should be > 1.0 in order to get reasonable behavior.

=head2 $gv->zoom( -out => factor )

Zoom out by scaling everything down by the given scale factor.  This is equivalent to

    $gv->zoom ( -in => 1/factor )

The factor show be > 1.0 in order to get reasonable behavior.

=head1 TAGS

In order to facilitate binding, etc, all of the graph elements (nodes, edges, subgraphs) that a created in the cavas.  Specific tags are given to each class of element.  Additionally, all attributes attached to an element in the graph description (e.g. 'color', 'style') will be included as tags.

=head2 Nodes

Node elements are identified with a 'node' tag.  For example, to bind something to all nodes in a graph:

    $gv->bind ( 'node', '<Any-Enter>', sub { ... } );

The value of the 'node' tag is the name of the node in the graph (which is not equivalent to the node label -- that is the 'label' tag)

=head2 Edges

Edge elements are identified with a 'edge' tag.  For example, to bind something to all edges in a graph:

    $gv->bind ( 'edge', '<Any-Enter>', sub { ... } );

The value of the 'edge' tag is an a string of the form "node1 node2", where node1 and node2 are the names of the respective nodes.  To make it convenient to get the individual node names, the edge also has tags 'node1' and 'node2', which give the node names separately.

=head2 Subgraphs

Subgraph elements are identified with a 'subgraph' tag.  The value of the 'subgraph' is the name of the subgraph / cluster.

=head1 EXAMPLES

The following example creates a GraphViz widgets to display a graph from a file specified on the command line.  Whenever a node is clicked, the node name and label are printed to stdout:

    use GraphViz;
    use Tk;

    my $mw = new MainWindow ();
    my $gv = $mw->Scrolled ( 'GraphViz',
                             -background => 'white',
                             -scrollbars => 'sw' )
      ->pack ( -expand => '1', -fill => 'both' );

    $gv->bind ( 'node', '<Button-1>', sub {
                my @tags = $gv->gettags('current');
                push @tags, undef unless (@tags % 2) == 0;
                my %tags = @tags;
                printf ( "Clicked node: '%s' => %s\n",
                         $tags{node}, $tags{label} );
                } );

    $gv->show ( shift );
    MainLoop;


=head1 BUGS AND LIMITATIONS

Lots of DOT language features not yet implemented

=over 4

=item Various node shapes and attributes: polygon, skew, ...

=item Edge arrow head types

=head1 ACKNOWLEDGEMENTS

See http://www.graphviz.org/ for more info on the graphviz tools.

=head1 AUTHOR

Jeremy Slade E<lt>jeremy@jkslade.netE<gt>

Other contributors:
Mike Castle,
John Cerney,
Phi Kasten,
Jogi Kuenstner
Tobias Lorenz,
Charles Minc,
Reinier Post,
Slaven Rezic

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2008 by Jeremy Slade

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

