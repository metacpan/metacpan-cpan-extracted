#======================================================================
#
# Text::ProcessMap
#
# Perl module which displays Activity Diagrams in plain text format.
#
# Copyright 2005, Brad J. Adkins. All rights reserved.
#
# This library is free software; you can redistribute it and/or modify 
# it under the same terms as Perl itself.
#
# Address bug reports and comments to: <bradjadkins@badkins.net>.
#
#======================================================================

package Text::ProcessMap;

use strict;
use Carp;
use File::Spec;

our $VERSION = '0.01';

{
  my %_attrs = (
    _title       => 'header',
    _description => 'header',
    _topnote     => 'header',
    _diagramnote => 'header',
    _name        => 'header',
    _number      => 'header',
    _loader_file => 'header',
    _output_file => 'header',
    _minwidth    => 'header',
    _test        => 'header',
    _layout      => 'body',
    _coltitles   => 'body',
    _colwidths   => 'body',
    _boxchars    => 'body',
    _colsp       => 'body'
  );

  sub _accessible {
    my ($self, $property, $method) = @_;

    $property = '_' . $property;
    if ( exists $_attrs{$property} && $_attrs{$property} eq $method ) {
      return 1;
    } else {
      croak("invalid property");
    }
  }

  sub _set {
    my ($self, $property, $value) = @_;

    $property = '_' . $property;
    $self->{$property} = $value;
  }

  sub _get {
    my ($self, $property) = @_;

    $property = '_' . $property;
    $self->{$property};
  }
}

sub new {
  my ($class, %params) = @_;

  my $self = bless {
    _title       => $params{title}       || '',
    _description => $params{description} || '',
    _topnote     => $params{topnote}     || '',
    _diagramnote => $params{diagramnote} || '',
    _name        => $params{name}        || '',
    _number      => $params{number}      || '',
    _minwidth    => $params{minwidth}    || 0, 
    _layout      => $params{layout}      || 'stack',
    _loader_file => $params{loader_file} || '',
    _output_file => $params{output_file} || '',
    _coltitles   => $params{coltitles}   || [],
    _colwidths   => $params{colwidths}   || [],
    _boxchars    => $params{boxchars}    || ["+", ".", "'", "`", "-", "|"],
    _colsp       => $params{colsp}       || '  ',
    _sp          => $params{sp}          || ' ',
    _nl          => $params{nl}          || "\n",
    _mlayout     => [],
    _mheight     => [],
    _fnotes      => [],
    _test        => 0
  }, $class;

  Text::ProcessMap::Object::_init();
  
  return $self;
}

sub header {
  my ($self, %params) = @_;

  foreach my $key ( keys %params ) {
    if ( $self->_accessible($key, 'header') ) { $self->_set($key, $params{$key}); }
  }
}

sub body {
  my ($self, %params) = @_;

  foreach my $key ( keys %params ) {
    if ( $self->_accessible($key, 'body') ) { $self->_set($key, $params{$key}); }
  }
}

sub node {
  my ($self, @args) = @_;
  my %params = @args;
  
  # validate column argument
  my $col = $params{col};  # column number range is 1..n
  if ( !defined $col || $col < 1 ) { croak("invalid column number"); }
  
  my $obj = Text::ProcessMap::Object->new(@args, 'parent', $self);
  my $row = $obj->_get_row;
  @{ $self->{_mlayout}[$col] }[$row] = $obj;
}
    
sub draw {
  my ($self, $fd) = @_;

  $fd = '' unless $fd;
  $self->_read_loader;
  $fd = $self->{_output_file} if $self->{_output_file};

  local *OUTPUT;

  # choose between existing filehandle, filename, or stdout
  SWITCH: {
    if ( $fd =~ /::/ ) { *OUTPUT = $fd; last SWITCH; }
    if ( $fd )         { open(OUTPUT, ">$fd") or croak("file open error"); last SWITCH; }
    *OUTPUT = *STDOUT;
  }

  # output the diagram
  print OUTPUT @{$self->_build_header};
  print OUTPUT @{$self->_build_body};
  print OUTPUT @{$self->_build_footer};
}

sub _build_header {
  my $self = shift;
  my @header;

  my $nl = $self->{_nl};
  my $sp = $self->{_sp};
  my $ml_imax = $#{$self->{_mlayout}} - 1;
  
  # must have at least one column
  if ( $ml_imax < 0 ) { 
    croak "no columns defined"; 
  }
  # number of column titles must be same as number of columns
  if ( $#{$self->{_coltitles}} != $ml_imax ) { 
    croak "columns/column-titles mismatch"; 
  }
  # number of column widths must be same as number of columns
  if ( $#{$self->{_colwidths}} != $ml_imax ) { 
    croak "columns/column-widths mismatch"; 
  }
  
  return \@header unless $self->_is_header_fancy;  # empty

  push @header, $self->_separator_line('-');

  my $dwidth = $self->_display_width;
  # title diaplay line
  if ( $self->{_title} ) {
    push @header, map { $_ .= $nl }
      $self->_center_wrap($self->{_title}, $dwidth, $sp);
  }
  # description display line
  if ( $self->{_description} ) {
    push @header, map { $_ .= $nl }
      $self->_center_wrap($self->{_description}, $dwidth, $sp);
  }
  # diagram number display line
  if ( $self->{_number} ) {
    push @header, map { $_ .= $nl }
      $self->_center_wrap('Diagram Number ' . $self->{_number}, $dwidth, $sp);
  }
  # topnote display line
  if ( $self->{_topnote} ) {
    push @header, $self->_separator_line('-');
    push @header, map { $_ .= $nl }
      $self->_center_wrap($self->{_topnote}, $dwidth, $sp);
  }
  my $headline = '';
  my $jstr;
  for my $i ( 0 .. $ml_imax ) 
  {
    if ( $i < $ml_imax ) 
    { 
      $jstr = '||' 
    } 
    else 
    { 
      $jstr = $self->{_nl}; 
    }
    $headline .= $self->_center(@{$self->{_coltitles}}[$i], @{$self->{_colwidths}}[$i]);
    $headline .= $jstr;
  }
  push @header, $self->_separator_line('-');
  push @header, $headline;
  push @header, $self->_separator_line('-') . $self->{_nl};

  return \@header;
}

# ---------------------------------------------------------------------
# _build_body
#
# Build the body section of the diagram. This is done using either a
# stack layout or a matrix layout. When stacking, the column objects 
# are aligned one atop the other with no vertical spacing. When using 
# a matrix layout, the column objects are vertically aligned at their 
# top and spaced one object per row, a row can be empty for any given
# column. The default layout is stack.
# ---------------------------------------------------------------------
sub _build_body {
  my $self = shift;
 
  my $sp = $self->{_sp};
  my $nl = $self->{_nl};
  my $colsp = $self->{_colsp};
  my @clines;  # aoa of lines representing node objects

  # check layout requested
  unless ( $self->{_layout} =~ /^stack$|^matrix$/ ) 
  { 
    croak("invalid layout specificied"); 
  }
  
  my $numcols = $#{$self->{_mlayout}};
  
  # using stack layout
  if ( $self->{_layout} eq 'stack' ) 
  {
    for my $col ( 0 .. $numcols ) 
    {
      my $numrows = $#{ @{ $self->{_mlayout}[$col] } };
      for my $row ( 1 .. $numrows ) 
      {
        if ( defined @{ $self->{_mlayout}[$col] }[$row] )
        {
          my $obj = @{ $self->{_mlayout}[$col] }[$row];
          push @{ $clines[$col - 1] }, @{ $obj->{_boxlines} };
        }
      }
    }
  }
  
  # using matrix layout
  if ( $self->{_layout} eq 'matrix' )
  {
    # determine row heights and save to mheight array
    for my $col ( 0 .. $numcols )                          
    {
      my $numrows = $#{ @{ $self->{_mlayout}[$col] } };
      for my $row ( 1 .. $numrows )                        
      {
        if ( !defined @{ $self->{_mheight} }[$row] )
        {
          @{ $self->{_mheight} }[$row] = 0;
        }
        if ( defined @{ $self->{_mlayout}[$col] }[$row] )  
        {
          my $obj = @{ $self->{_mlayout}[$col] }[$row];    
          my $rheight = $obj->_get_height;                 
          if ( !defined @{ $self->{_mheight} }[$row] )
          {
            @{ $self->{_mheight} }[$row] = 0;
          }
          if ( $rheight > @{ $self->{_mheight} }[$row] )
          {
            @{ $self->{_mheight} }[$row] = $rheight;
          }
        }
      }
    }
    # create blank column objects
    for my $col ( 0 .. $numcols )                          
    {
      my $numrows = $#{ @{ $self->{_mlayout}[$col] } };
      for my $row ( 1 .. $numrows )                        
      {
        if ( !defined @{ $self->{_mlayout}[$col] }[$row] )  
        {
          # create a blank object using prev object attributes
          my $connect = ' ';
          my $boxheight = 0;
          if ( $row > 1 )
          {
            # prev object connect attribute
            my $pobj = @{ $self->{_mlayout}[$col] }[$row-1];    
            $connect = $pobj->_get_connect;
            # current row height
            $boxheight = @{ $self->{_mheight} }[$row];
          }
          # create blank object
          my $obj = Text::ProcessMap::Object->new( 
                    parent    => $self,
                    col       => $col,
                    row       => $row,
                    type      => 'blank',
                    boxheight => $boxheight,
                    connect   => $connect,
                    border    => 'off' );
          # store blank object in layout
          @{ $self->{_mlayout}[$col] }[$row] = $obj;
        }
      }
    }
    # output column objects
    for my $col ( 0 .. $numcols ) 
    {
      my $numrows = $#{ @{ $self->{_mlayout}[$col] } };
      for my $row ( 1 .. $numrows ) 
      {
        if ( defined @{ $self->{_mlayout}[$col] }[$row] )
        {
          my $obj = @{ $self->{_mlayout}[$col] }[$row];
          
          my $height = @{ $self->{_mheight} }[$row];
          $obj->_pad($col-1, $height);
          
          push @{ $clines[$col - 1] }, @{ $obj->{_boxlines} };
        }
      }
    }
  }
  
  # get max column lines
  my @aomax;
  for my $i ( 0 .. $numcols ) {
    push @aomax, $#{ $clines[$i] } - 1;
  }
  @aomax = sort _numerically(@aomax);
  my $linmax = $aomax[0];  # max column lines
 
  # pad all columns to same length
  for my $i ( 0 .. $numcols - 1) {
    my $numrows = $#{ $clines[$i] };  # number of rows in this column
    my $colwid = @{$self->{_colwidths}}[$i];  # width of this column
    push @{ $clines[$i] }, map { $sp x $colwid } $numrows .. $linmax;
  }

  # nest three columns into one array
  my @body;
  for my $i ( 0 .. $linmax ) {
    my $line = '';
    for my $j ( 0 .. $numcols - 1) {
      my $glue = $j < $numcols - 1 ? $colsp : $nl;
      $line .= $clines[$j][$i] . $glue;
    }
    push @body, $line;
  }

  push @body, $nl;
  # add diagramnote after the diagram
  if ( $self->{_diagramnote} ) {
    my $dwidth = $self->_display_width;
    push @body, map { $_ .= $nl }
      $self->_center_wrap($self->{_diagramnote}, $dwidth, $sp);
    push @body, $nl;
  }

  return \@body;  # ref to array of body lines
}

sub _build_footer {
  my $self = shift;
  my @footnotes;
  my $fcnt = 0;
  my $fln = '';

  return \@footnotes unless $self->_is_footer_fancy;  # empty
  
  push @footnotes, $self->_separator_line('-');
  my $sp = $self->{_sp};

  # check for footnotes and output as required
  if ( $#{$self->{_fnotes}} > 0 ) {  
    push @footnotes, 'Footnotes:' . $self->{_nl};
    foreach my $note ( @{ $self->{_fnotes} } ) {
      my $pad = length($note->{_id}) + 1;
      push @footnotes, $note->{_id} . ':' . $note->{_short_name} . $self->{_nl} . $self->{_sp} x $pad . $note->{_long_name} . $self->{_nl};
      $fcnt++;
    }
  }
  if ( $fcnt ) {
    push @footnotes, $self->_separator_line('-');
  }
    
  # add page footer
  if ( $self->{_name} ) {
    $fln = $self->{_name};
    $fln = $self->_append_right($fln, $self->_printed, $self->_display_width);
    push @footnotes, $fln;
    push @footnotes, $self->_separator_line('-');
  }

  return \@footnotes;
}

sub _read_loader {
  my $self = shift;
  my %kvps;
  my ($key, $val);
  my (@elem, @boxc, @colt, @colw);
  my $section;
  my $column;

  unless ( $self->{_loader_file} ) { return; }

  open(LOAD, $self->{_loader_file}) || die "unable to open definition file";
  while ( <LOAD> ) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    next unless $_;
    next if /^#/;  # comments

    if ( /^\[/ ) {  # start new section
      if ( /(header|body|column\s+(\d{1,}))/i ) {  # start of section
        $section = $1;
        $column = $2;
        $section =~ s/\s+\d{1,}//;
        %kvps = ();
        @elem = ();
        @boxc = ();
        @colt = ();
        @colw = ();
        next;
      }
    }
    if ( $section =~ /header/i ) {  # header contains only kvps
      unless ( /^put/ ) {
        $key = $self->_get_key($_);
        $val = $self->_get_val($_);
        $kvps{$key} = $val;
      }
    }
    if ( $section =~ /body/i ) {  # body section can contain kvps and array defs
      if ( /^boxchars|^coltitles|^colwidths/i ) {
        unless ( /^put/i ) {
          if ( /^boxchars/i ) {
            @boxc = $self->_get_arr($_);
          }
          if ( /^coltitles/i ) {
            @colt = $self->_get_arr($_);
          }
          if ( /^colwidths/i ) {
            @colw = $self->_get_arr($_);
          }
        }
      } else {
        unless ( /^put/i ) {
          $key = $self->_get_key($_);
          $val = $self->_get_val($_);
          $kvps{$key} = $val;
        }
      }
    }
    if ( $section =~ /column/i ) {
      if ( /^element/i ) {
        push @elem, $self->_get_val($_);
      } else {
        unless ( /^put/i ) {
          $key = $self->_get_key($_);
          $val = $self->_get_val($_);
          $kvps{$key} = $val;
        }
      }
    }
    if ( /^put/i ) { # /
      if ( $section =~ /body/i ) {
        if ( @boxc ) { $kvps{boxchars}  = [ @boxc ]; }
        if ( @colt ) { $kvps{coltitles} = [ @colt ]; }
        if ( @colw ) { $kvps{colwidths} = [ @colw ]; }
        $self->body(%kvps);
      }
      if ( $section =~ /header/i ) {
        $self->header(%kvps);
      }
      if ( $section =~ /column/i ) {
        $kvps{elements} = [ @elem ];
        $kvps{col} = $column;
        $self->node(%kvps);
      }
      %kvps = ();
      @elem = ();
      next;
    }
  }
  close(LOAD);
}

sub _numerically { 
  $b <=> $a;  # reverse numeric sort
}    

sub _append_right {
  my ($self, $basestr, $addstr, $width) = @_;

  my $pad = $width - length($basestr) - length($addstr);
  return $basestr . $self->{_sp} x $pad . $addstr . $self->{_nl};
}

sub _center {
  my ($self, $str, $width) = @_;

  if ( length($str) >= $width) {
    return substr($str, 0, $width);
  }

  my $lead = int(($width - length($str)) / 2);
  my $trail = int($width - (length($str) + $lead));

  return $self->{_sp} x $lead . $str . $self->{_sp} x $trail;
}

sub _center_wrap {
  my ($self, $str, $width, $sp) = @_;
  my $tmp;
  my @w;

  $width = $width;    
  $str =~ s/\s+/ /g;
  my @str = split ' ', $str;

  @str = map { $self->_cwfix($_, $width) } @str;
  
  my $ll = 0;
  while (@str) {
    my $w = shift(@str);
    if ($ll + length($w) > $width) {
      push @w, $tmp;
      $ll = length($w) + 1;
      $tmp = $w . $sp;
    } else {
      $tmp .= $w . $sp;
      $ll += length($w) + 1;
    }
  }  
  push @w, $tmp if $tmp;

  @w = map { $self->_cwctr($_, $width, $sp) } @w;
  return @w;
}

sub _cwfix {  
  my ($self, $str, $width) = @_;
  if ( length($str) > $width ) {
    $str = substr($str, 0, $width - 1) . '~';
  }
  return $str;
}

sub _cwctr {
  my ($self, $str, $width, $sp) = @_;
  $str =~ s/^\s+|\s+$//g;
  my $lead = int(($width - length($str)) / 2);
  my $tail = int($width - (length($str) + $lead));
  return $sp x $lead . $str . $sp x $tail;
}

sub _is_header_fancy {
  my $self = shift;
  if ( $self->{_title} || $self->{_description} || $self->{_number} ) {
    return 1;
  }
  return 0;
}

sub _is_footer_fancy {
  my $self = shift;
  if ( $#{$self->{_fnotes}} > 0 || $self->{_name} ) {
    return 1;
  }
  return 0;
}

sub _body_width {
  my $self = shift;
  
  my $numcols = $#{$self->{_mlayout}} - 1;
  my $bwidth = 0;

    for my $i ( 0 .. $numcols ) {  
    $bwidth += @{$self->{_colwidths}}[$i];
  }
  $bwidth += ($numcols) * 2;  # add space between cols
  return $bwidth;
}

sub _display_width {
  my $self = shift;
  
  my $bwidth = $self->_body_width;
  my $mwidth = $self->{_minwidth};  
  return $mwidth > $bwidth ? $mwidth : $bwidth;
}

sub _printed {
  my ($self) = @_;

  if ( $self->{_test} ) { return ' 00/00/0000'; }

  my ($sec, $min, $hr, $dy, $mo, $yr, $wd, $doy, $dst) = localtime(time);
  return sprintf(" %02d/%02d/%04d", $mo + 1, $dy, $yr += 1900);
}

sub _separator_line {
  my ($self, $char) = @_;

  my $dwidth = $self->_display_width;
  return $char x $dwidth . $self->{_nl};
}

sub _get_key {
  my ($self, $str) = @_;
  my ($k,$v) = split '=', $str;
  $k =~ s/^\s+//;
  $k =~ s/\s+$//;
  return $k;
}

sub _get_val {
  my ($self, $str) = @_;
  my ($k,$v) = split '=', $str;
  $v =~ s/^\s+//;
  $v =~ s/\s+$//;
  return $v;
}

sub _get_arr {
  my ($self, $str) = @_;
  my ($k,$v) = split '=', $str;
  $v =~ s/^\s+//;
  $v =~ s/\s+$//;
  my @items = split ',', $v;  # extract list items
  @items = map {_trim($_)} @items;  # trim list items
  return @items;  
}

sub _trim {
    my $s = shift;
    $s =~ s/^\s+//g;
    $s =~ s/\s+$//g;
    return $s;
}    

1;

# ---------------------------------------------------------------------
# package Text::ProcessMap::Object;
#
# When a new box is instantiated, the box object immediately invokes
# a function to build an array of lines representing the box and store
# those lines inside of the box object. The array of lines is justified 
# and bordered using preferences supplied by the parent object. This 
# allows the height of the box to be calculated and stored at the same 
# time the box is instantiated.
# ---------------------------------------------------------------------
package Text::ProcessMap::Object;

use Carp;

our $ccol = 1;   # current column
our $crow = 0;   # current row

sub new {
  my ($class, %params) = @_;

  my $self = bless {
    _parent    => $params{parent},
    _col       => $params{col},
    _row       => $params{row}       || 0,               # new 2/21
    _id        => $params{id}        || '',
    _title     => $params{title}     || '',
    _elements  => $params{elements}  || [],
    _in        => $params{in}        || '-',
    _out       => $params{out}       || '-',
    _connect   => $params{connect}   || '',
    _vertex    => $params{vertex}    || '',              # new 2/27
    _header    => $params{header}    || '',              # new 2/21
    _footer    => $params{footer}    || '',              # new 2/21
    _type      => $params{type}      || 'box',           # new 2/21
    _border    => $params{border}    || 'on',            # new 2/21
    _boxheight => $params{boxheight} || 0,               # new 2/27
    _subtype   => 0,                                     # new 2/21
    _footnotes => [],
    _boxlines  => [],
  }, $class;

  unless ( $self->{_connect} ) { 
      $self->{_connect} = $self->{_parent}->{_sp};
  }

  if ( $self->{_type} =~ /^arrow/ )  # get arrow extended attributes
  {  
    $self->{_type} =~ /^arrow:(\d)/;
    $self->{_subtype} = $1 || 0;
    $self->{_type} = 'arrow';
    $self->{_border} = 'off'; 
    $self->{_sp} = $self->{_parent}->{_sp};

    if ( $self->{_subtype} > 3 ) { 
      croak("invalid arrow type");
    }
  }

  unless ( $self->{_type} =~ /^box$|^arrow$|^blank$/ ) { 
    croak("invalid type");
  }

  unless ( $self->{_border} =~ /^on$|^off$/ ) { 
    croak("invalid border type");
  }
  
  # store row info, row is automatically generated if not given
  if ( $self->{_type} =~ /^arrow$|^box$/ )
  {
    $crow++;
    if ( $self->{_col} > $ccol ) { $ccol = $self->{_col}; $crow = 1;}
    if ( $self->{_row} > 0 && $self->{_row} < $crow ) { croak("invalid row sequence"); }
    if ( $self->{_row} > $crow ) { $crow = $self->{_row}; }
    $self->{_row} = $crow;
  } 
   
  $self->_build_box;
            
  return $self;
}

sub _init {
  $ccol = 1;   # reset current column
  $crow = 0;   # reset current row
}

sub _get_row {
  my $self = shift;
  return $self->{_row};
}

sub _get_height {
  my $self = shift;
  return $self->{_boxheight};
}

sub _get_connect {
  my $self = shift;
  return $self->{_connect};
}

# ---------------------------------------------------------------------
# _build_box
# 
# Build the array containing box lines for this box. The lines produced
# comprise a complete image of this particular box instance. The lines
# are stored inside the box object for later reference. 
# ---------------------------------------------------------------------
sub _build_box {
  my $self = shift;
  
  my $parent = $self->{_parent};
  my ($tlch, $trch, $brch, $blch, $hch, $vch) = @{ $parent->{_boxchars} };
  my $width = @{$parent->{_colwidths}}[$self->{_col}-1];  # this column width
  my $sp = $parent->{_sp};  # space char
  my $center = 1;  # default centered, TODO all user defined, stored in parent
  my $border = 0;
  if ( $self->{_border} eq 'on' ) { 
    $border = 1; 
  } else {
    ($tlch, $trch, $brch, $blch, $hch, $vch) = ($sp, $sp, $sp, $sp, $sp, $sp);
  }

  if ( $self->{_type} eq 'box' )
  {
    if ( $border )
    {
      push @{ $self->{_boxlines} },                                   
              $self->_box_line($hch, $tlch, $trch, $self->{_in}, $width);
    }
    if ( $self->{_header} )
    {
      push @{ $self->{_boxlines} },
              $self->_wrap($self->{_header}, $width, $vch, $sp, 1);
      push @{ $self->{_boxlines} },
              $self->_box_line($hch, $vch, $vch, '', $width);
    }
    if ( $self->{_id} )
    {
      push @{ $self->{_boxlines} }, 
              $self->_wrap('['.$self->{_id}.']', $width, $vch, $sp, 1);
    }
    if ( $self->{_title} )
    {
      push @{ $self->{_boxlines} }, 
              $self->_wrap($self->{_title}, $width, $vch, $sp, 1);
    }
    if ( $#{ $self->{_elements} } > -1 )                          
    {
      foreach my $line ( @{ $self->{_elements} } ) 
      {
        push @{ $self->{_boxlines} }, 
                $self->_wrap($line, $width, $vch, $sp, 1);
      }
    }
    if ( $self->{_footer} )                                     
    {
      push @{ $self->{_boxlines} },
              $self->_box_line($hch, $vch, $vch, '', $width);
      push @{ $self->{_boxlines} },
              $self->_wrap($self->{_footer}, $width, $vch, $sp, 1);
    }
    if ( $border ) 
    {
      push @{ $self->{_boxlines} }, 
              $self->_box_line($hch, $blch, $brch, $self->{_out}, $width);
    }
  }

  if ( $self->{_type} eq 'arrow' ) 
  {
    push @{ $self->{_boxlines} },
            $self->_box_line($sp, $sp, $sp, $self->{_connect}, $width);
    if ( $self->{_title} )
    {
      push @{ $self->{_boxlines} }, 
              $self->_wrap($self->{_title}, $width, $sp, $sp, 1);
    }
    push @{ $self->{_boxlines} }, 
            $self->_arr_line($width);
  }

  if ( $self->{_type} eq 'blank' ) 
  {
    if ( $self->{_boxheight} > 0 )
    {
      for ( 1 .. $self->{_boxheight} - 1 )
      {
        push @{ $self->{_boxlines} },                                   
                $self->_box_line($sp, $sp, $sp, $self->{_connect}, $width);
      }
    }
  }

  # all objects get connect space
  if ( $self->{_connect} )
  { 
    push @{ $self->{_boxlines} },
            $self->_box_line($sp, $sp, $sp, $self->{_connect}, $width);
  }

  # store the height  
  $self->{_boxheight} = $#{ $self->{_boxlines} } + 1;  # overall height
}

# ---------------------------------------------------------------------
# _pad
#
# Pad object height to specified number of rows. If a connect char has
# been specified for this object, use that char when padding.
# ---------------------------------------------------------------------
sub _pad {
  my ($self, $col, $height) = @_;

  if ( $height > $self->{_boxheight} )
  {
    my $parent = $self->{_parent};
    my $width = @{ $parent->{_colwidths} }[$col];  # this column width
    my $sp = $parent->{_sp}; 
    for ( $self->{_boxheight} .. $height - 1 ) 
    {
      push @{ $self->{_boxlines} },
              $self->_box_line($sp, $sp, $sp, $self->{_connect}, $width);
    }
  }
}

# ---------------------------------------------------------------------
# _wrap
#
# Accept a string and wrap it to multiple lines of the specified width. 
# Either left justify or center justify the lines depending on 
# argument. Any single word which is longer than the specified width
# is automatically footnoted and the footnote object created is stored 
# in the box's parent object. The string is returned as an array of 
# lines, each line bordered by the specified border char.
# 
# used by:
#   Text::ProcessMap::Object::new
#
# uses:
#   _wftn, _wctr, _wlft
# ---------------------------------------------------------------------
sub _wrap {
  my ($self, $str, $width, $echar, $sp, $center) = @_;
  my $tmp;
  my @w;

  $width = $width - 2;    
  $str =~ s/\s+/ /g;
  my @str = split ' ', $str;

  @str = map { $self->_wftn($_, $width) } @str;
  
  my $ll = 0;
  while (@str) {
    my $w = shift(@str);
    if ($ll + length($w) > $width) {
      push @w, $tmp;
      $ll = length($w) + 1;
      $tmp = $w . $sp;
    } else {
      $tmp .= $w . $sp;
      $ll += length($w) + 1;
    }
  }  
  push @w, $tmp if $tmp;

  if ( $center ) {
    @w = map { $echar . $self->_wctr($_, $width, $sp) . $echar } @w;
  } else {
    @w = map { $echar . $self->_wlft($_, $width, $sp) . $echar } @w;
  }
  
  return @w;
}

# ---------------------------------------------------------------------
# _wftn
#
# Create footnote for word longer than the specified width.
#
# used by: _wrap
# ---------------------------------------------------------------------
sub _wftn {  
  my ($self, $str, $width) = @_;
  # handle single words longer than width
  if ( length($str) > $width ) {
    my $longstr = $str;
    $str = substr($str, 0, $width - 1) . '~';
    
    # create a new footnote object to hold long text
    my $note = Text::ProcessMap::Footnote->new(   # create footnote object
      parent     => $self,
      id         => $self->{_id},
      long_name  => $longstr,
      short_name => $str,
    );
    # store footnote object in parent object
    push @{$self->{_parent}->{_fnotes}}, $note || croak("box stack error");
    
  }
  return $str;
}

# ---------------------------------------------------------------------
# _wlft
#
# Left justify string using specified width.
#
# used by: _wrap
# ---------------------------------------------------------------------
sub _wlft {  
  my ($self, $str, $width, $sp) = @_;
  $str =~ s/^\s+|\s+$//g;
  my $tail = int($width - (length($str)));
  return $str . $sp x $tail;
}

# ---------------------------------------------------------------------
# _wctr
#
# Center string using specified width.
#
# used by: _wrap
# ---------------------------------------------------------------------
sub _wctr {
  my ($self, $str, $width, $sp) = @_;
  $str =~ s/^\s+|\s+$//g;
  my $lead = int(($width - length($str)) / 2);
  my $tail = int($width - (length($str) + $lead));
  return $sp x $lead . $str . $sp x $tail;
}

# ---------------------------------------------------------------------
# _arr_line
#
# Build an arrow object. 
# ---------------------------------------------------------------------
sub _arr_line {
  my ($self, $width) = @_;

  my $subtype = $self->{_subtype};
  my $sp = $self->{_sp};

  my $al = '-' x ($width - 2);  # arrow line
  if ( $subtype == 0 ) { $al = '-'.$al.'-'; }
  if ( $subtype == 1 ) { $al = '<'.$al.'.'; }
  if ( $subtype == 2 ) { $al = '<'.$al.'>'; }
  if ( $subtype == 3 ) { $al = '-'.$al.'>'; }
  return $al;
}

sub _box_line {
  my ($self, @args) = @_;
  my ($hc, $lc, $rc, $cc, $width) = @args;

  $cc = '' unless $cc;  
  
  my $tempc = '~';  # use a temp char to build the string initially
  my $ww = $width - 2;
  my $str = $tempc x $ww;
  my $clen = length($cc);
  my $cloc = int($ww / 2) - int($clen / 2) - 1;

  $str = substr($str,0,$cloc) . $cc . substr($str,$cloc+$clen,$ww);
  $str =~ s/$tempc/$hc/g;  # replace the temp chars with real chars
  return $lc . $str . $rc;
}

1;

package Text::ProcessMap::Footnote;

sub new {
  my ($class, %params) = @_;

  my $self = bless {
    _parent     => $params{parent},
    _col        => $params{col}        || '',
    _id         => $params{id}         || '',
    _long_name  => $params{long_name}  || '',
    _short_name => $params{short_name} || ''
  }, $class;

  return $self;
}

1;

__END__

=pod 

=head1 NAME

Text::ProcessMap - Create process diagrams in plain text format.

=head1 DESCRIPTION

This module provides a text based tool for the generation process diagrams, sometimes called process maps. The process maps produced by this module are similar to UML Interaction Diagrams, only much simpler.

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Text::ProcessMap;

    my $pmap = Text::ProcessMap->new;

    $pmap->header(
        title => 'Hello World',
        name  => 'test'
    );

    $pmap->body(
        coltitles => ['Column 1', 'Column 2', 'Column 3'],
        colwidths => [20, 20, 20],
    );

    $pmap->node(
        col      => 1,
        id       => '11',
        title    => 'My Input',
        elements => [ 'Input Element 1', 'Input Element 2' ]
    );

    $pmap->node(
        col      => 2,
        id       => '21',
        title    => 'My Process',
        elements => [ 'Process Element 1', 'Process Element 2' ]
    );

    $pmap->node(
        col      => 3,
        id       => '31',
        title    => 'My Output',
        elements => [ 'Output Element 1', 'Output Element 2' ]
    );

    $pmap->draw;

=head1 SUMMARY

A process map provides a simple method to document the high-level details of a system process or computer activity.

Information to display can be defined directly in a Perl script using methods provided by the module, or using text based definition files. The definition files are structured like ini files, making them easy to build and maintain.

Output can be directed to either a file or to STDOUT, making it possible to use the module interactively, in batch mode, or as a component in a CGI script.

=head1 SAMPLE DIAGRAM

Below is an example diagram demonstrating the 'matrix' layout option:

 ----------------------------------------------------------------
                              Lorem
                           Lorem Ipsum
                        Diagram Number 1
 ----------------------------------------------------------------
    Lorem Ipsum dolor sit amet, consectetuer adipiscing elit.
 ----------------------------------------------------------------
       Column 1      ||      Column 2      ||      Column 3
 ----------------------------------------------------------------

 +------------------.                        +------------------.
 |      HEADER      |    This is an arrow    |      [I04]       |
 |------------------|    with description    |      Title       |
 |      [I01]       |         text.          |   Lorem Ipsum    |
 |      Title       |  ------------------->  | dolor sit amet,  |
 |   Lorem Ipsum    |                        |   consectetuer   |
 | dolor sit amet,  |                        | adipiscing elit. |
 |   consectetuer   |                        `------------------'
 | adipiscing elit. |                                 |
 |The final element.|                                 |
 `------------------'                                 |
                                                      |
 +------------------.                                 |
 |      [I02]       |                                 |
 |      Title       |                                 |
 |   Lorem Ipsum    |                                 |
 | dolor sit amet,  |                                 |
 |   consectetuer   |                                 |
 | adipiscing elit. |                                 |
 |------------------|                                 |
 |      FOOTER      |                                 |
 `------------------'                                 |
                                                      |
                       +------------------.           |
                       | This is a header |           |
                       |showing word wrap.|           |
                       |------------------|           |
                       |      [I03]       |           |
                       |      Title       |           |
                       |   Lorem Ipsum    |           |
                       | dolor sit amet,  |           |
                       |   consectetuer   |           |
                       | adipiscing elit. |           |
                       |------------------|           |
                       | This is a footer |           |
                       |showing word wrap.|           |
                       `------------------'           |
                                                      |
                                             +------------------.
                                             |      [I05]       |
                                             |      Title       |
                                             |   Lorem Ipsum    |
                                             | dolor sit amet,  |
                                             |   consectetuer   |
                                             | adipiscing elit. |
                                             `------------------'

 Lorem Ipsum dolor sit amet, consectetuer adipiscing elit.

 ----------------------------------------------------------------
 lorem_ipsum                                           02/28/2005
 ----------------------------------------------------------------

=head1 METHODS

=head2 new()

No required parameters. You may optionally provide any of the parameters accepted by the header() and body() methods described below. Arguments are passed using an anonymous hash.

    my $pmap = Text::ProcessMap->new;

=head2 header()

Use this method to set the header characteristics and other general attributes of the process map. Arguments are passed using an anonymous hash.

    $pmap->header(
        title       => 'Hello World',
        description => 'The Hello World Process',
        topnote     => 'This note will be displayed in the header',
        diagramnote => 'This note will be displayed in the footer',
        number      => '1',                       # displayed in header
        name        => 'A name for the diagram',  # displayed in footer
        loader_file => 'sample1',
        output_file => 'output1',
    );

=head2 body()

Use this method to set the body characteristics of the Activity Diagram. Arguments are passed using an anonymous hash. 

    $pmap->body(
        layout      => 'stack',  # can be either 'stack' or 'matrix'
        coltitles   => ['Column 1', 'Column 2', 'Column 3'],
        colwidths   => [20, 20, 20],
        boxchars    => ["+", ".", "'", "`", "-", "|"],  # default
    );

=head2 node()

Use this method to define diagram objects. Arguments are passed using an anonymous hash. The example below demonstrates the use of all the arguments accepted by the node method. Each method call generates a single diagram object.

    $pmap->node(
        col      => 2,
        row      => 3,
        id       => 'I03',
        header   => 'This is a header showing word wrap.',
        title    => 'Title',
        elements => ['Lorem Ipsum','dolor sit amet,','consectetuer','adipiscing elit.'],
        footer   => 'This is a footer showing word wrap.'
    );

=head2 draw()

Draws the diagram. If no argument is provided, the diagram will be sent to STDOUT. Other arguments accepted are an existing file handle or a file name to be created.

    $pmap->draw;             # output to STDOUT

    $pmap->draw(*DIAG);      # use file handle

    $pmap->draw($filename);  # create file $filename

=head1 DEFINITION FILES

A definition file is a diagram definition that can be read at run-time. This allows the you to build and maintain a library of process maps. A sample definition file is shown below. The definition files are similar to ini files, each section of the file provides input to a method, the word B<put> is used to indicate when a method should be invoked. This definition file was used to create the sample diagram shown above.

 [Header]

 title       = Lorem
 description = Lorem Ipsum
 topnote     = Lorem Ipsum dolor sit amet, consectetuer adipiscing elit.
 diagramnote = Lorem Ipsum dolor sit amet, consectetuer adipiscing elit.
 name        = lorem_ipsum
 number      = 19          
 put

 [Body]

 colwidths = 20,20,20
 coltitles = Column 1,Column 2,Column 3
 layout    = matrix
 put

 [Column 1]

 row     = 1
 id      = I01
 title   = Title
 header  = HEADER
 element = Lorem Ipsum
 element = dolor sit amet,
 element = consectetuer
 element = adipiscing elit.
 element = The final element.
 put

 row     = 2
 id      = I02
 footer  = FOOTER
 title   = Title
 element = Lorem Ipsum
 element = dolor sit amet,
 element = consectetuer
 element = adipiscing elit.
 put

 [Column 2]

 row   = 1
 type  = arrow:3
 title = This is an arrow with description text.
 put

 row     = 3
 id      = I03
 header  = This is a header showing word wrap.
 title   = Title
 element = Lorem Ipsum
 element = dolor sit amet,
 element = consectetuer
 element = adipiscing elit.
 footer  = This is a footer showing word wrap.
 put

 [Column 3]

 row     = 1
 id      = I04
 title   = Title
 element = Lorem Ipsum
 element = dolor sit amet,
 element = consectetuer
 element = adipiscing elit.
 connect = |
 put

 row     = 4
 id      = I05
 title   = Title
 element = Lorem Ipsum
 element = dolor sit amet,
 element = consectetuer
 element = adipiscing elit.
 put

=head1 TEXT FORMATTING

Text entries are automatically word-wrapped to multiple lines. There is one exception to this rule, if a word is longer then the width of a diagram object, it will be truncated and a footnote generated for that word. The footnote will show the original word alongside its truncted version.

=head1 REFERENCES

Scott Ambler, Agile Modeling: http://www.agilemodeling.com/

UML Distilled, Third Edition. Scott Ambler.

=head1 AUTHOR

Copyright 2005, Brad J. Adkins. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Address bug reports and comments to: bradjadkins@badkins.net.

If you find this module useful, please feel free to send the Author an email and describe how you are using it. Thanks.

=head1 CREDITS

Thanks are in order to the following individuals for their suggestions.

Joel and Doug.

=head1 BUGS

Address bug reports and comments to: bradjadkins@badkins.net.

=head1 TODO

Some additional arrow types would be nice, but consideration will need to go into the approach used to define arrows in order to accomplish this.

=head1 SEE ALSO

Text::Flowchart
