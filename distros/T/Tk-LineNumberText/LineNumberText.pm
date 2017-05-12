package Tk::LineNumberText;

our ( $AUTOLOAD, $VERSION );
$VERSION = '0.5';

use Tk;
use Tk::widgets qw(Canvas DialogBox);
use base qw(Tk::Frame);
use Carp;
use strict;

Construct Tk::Widget '_LineNumberText';

sub Tk::Widget::LineNumberText
{
  my ( $pw, $widget, %args ) = @_;

  # Widget might be in a non-standard location
  unless ( eval "require $widget" )
  {

    # or now try forcing the Tk::
    carp "Tk::${widget} not found" unless ( eval "require Tk::${widget}" );
  }

  $pw->_LineNumberText( -widget => $widget, %args );
}

# Constants for QueueLayout flags (even though they are not used - good
# for debugging

sub _Default ()   { 1 }
sub _Map ()       { 2 }
sub _Event ()     { 4 }
sub _Auto()       { 8 }
sub _Scrolling () { 16 }
sub _User ()      { 32 }

sub Populate
{

  my ( $self, $args ) = @_;

  $self->SUPER::Populate($args);

  $self->{'minwidth'}       = 40;
  $self->{'linenumshowing'} = 1;
  $self->{'dialog'}         = 1;
  $self->{'dontshow'}       = 0;

  my $widget = delete $args->{-widget};

  my $canvas = $self->Canvas(
    -takefocus          => 0,
    -cursor             => 'left_ptr',
    -bd                 => 0,
    -highlightthickness => 0,
    -relief             => 'flat',
    -width              => $self->{'minwidth'},
  );

  $self->{'canvas'} = $canvas;

  my $ftext =
    $self->Scrolled($widget)
    ->grid( -row => 0, -column => 1, -sticky => 'nsew' );
  $self->{'rtext'} = my $rtext = $ftext->Subwidget('scrolled');

  $self->gridColumnconfigure( 1, -weight => 1 );
  $self->gridRowconfigure( 0, -weight => 1 );

  $self->Advertise( 'yscrollbar', $ftext->Subwidget('yscrollbar') );
  $self->Advertise( 'xscrollbar', $ftext->Subwidget('xscrollbar') );
  $self->Advertise( 'corner',     $ftext->Subwidget('corner') );
  $self->Advertise( 'frame',      $ftext );
  $self->Advertise( 'scrolled',   $rtext );
  $self->Advertise( 'text',       $rtext );
  $self->Advertise( 'linenum',    $canvas );

  # Set scrolling command to run the lineupdate..
  my $yscroll       = $self->Subwidget('yscrollbar');
  my $scrollcommand = $yscroll->cget( -command );

  $yscroll->configure(
    -command => sub {
      $scrollcommand->Call(@_);
      $self->QueueLayout(_Scrolling);
    }
  );

  #Default the Canvas font to the same as the text widget
  my $font = $rtext->cget( -font );

  $self->ConfigSpecs(
    -linenumalign    => [ 'METHOD', undef,       undef,       'left' ],
    -linenumside     => [ 'METHOD', undef,       undef,       'left' ],
    -linenumbg       => [ 'METHOD', 'linenumbg', 'lineNumbg', '#aaaaaa' ],
    -linenumfg       => [ 'METHOD', 'linenumfg', 'lineNumfg', '#000000' ],
    -linenumactivefg => [ 'METHOD', undef,       undef,       '#666666' ],
    -linenumfont     => [ 'METHOD', undef,       undef,       'Helvetica 11' ],
    # -allowlineselect  => [ 'METHOD',  undef,       undef,       1 ],
    -curlinehighlight => [ 'METHOD', undef, undef, 'none' ],
    -curlinebg        => [ 'METHOD', undef, undef, '#ffffee' ],
    -curlinefg        => [ 'METHOD', undef, undef, '#000000' ],
    -curlinestipple   => [ 'METHOD', undef, undef, undef ],
    -allowbookmarks   => [ 'METHOD', undef, undef, 1 ],
    -bookmarkfill     => [ 'METHOD', undef, undef, '#00FF00' ],
    -bookmarkoutline  => [ 'METHOD', undef, undef, '#000000' ],
    -bookmarkshape    => [ 'METHOD', undef, undef, 'triangle' ],
    -bookmarkstipple  => [ 'METHOD', undef, undef, undef ],
    -background       => [ $ftext,   undef, undef, undef ],
    -foreground       => [ $ftext,   undef, undef, undef ],
    -scrollbars       => [ $ftext,   undef, undef, 'ose' ],
    -font             => [ $rtext,   undef, undef, undef ],
    -bg               => -background,
    -fg               => -foreground,
    'DEFAULT'         => [$rtext],
  );

  $self->Delegates( 'DEFAULT' => 'scrolled' );

  #Bindings
  $canvas->Tk::bind( '<Map>',           sub { $self->QueueLayout(_Map) } );
  $canvas->Tk::bind( '<ButtonPress-1>', sub { $self->_buttonPress } );

# We are allowing derived Text widgets to be
# used as well - such as CodeText. These derived classes may have already
# overwritten some class bindings (such as doAutoIndent for the Return key in CodeText).
# Therefore - we save any bind callbacks to be executed first before we overwrite the binding.

  foreach my $event (
    qw/Expose Visibility Configure
    KeyPress ButtonPress ButtonRelease-1 Return
    ButtonRelease-2 B2-Motion B1-Motion MouseWheel/
    )
  {
    my $bindsub = $rtext->bind("<$event>");
    if ($bindsub)
    {
      $rtext->bind(
        "<$event>",
        sub {
          $bindsub->Call;
          $self->QueueLayout(_Event);
        }
      );
    }
    else
    {
      $rtext->bind( "<$event>", sub { $self->QueueLayout(_Event); } );
    }
  }

}    # end Populate

sub AUTOLOAD
{
  my ($self)   = shift;
  my ($method) = do { ($AUTOLOAD) =~ /(\w+$)/ };

  # Don't propagate DESTROY methods
  return if $AUTOLOAD =~ /::DESTROY$/;
  $self->Subwidget('scrolled')->$method(@_);
  $self->QueueLayout(_Auto);
}

# Configure methods
# ------------------------------------------
sub linenumalign
{
  my ( $w, $align ) = @_;
  return $w->{'linenumalign'} unless defined $align;
  $align = lc($align);

  # Force to "north" based Canvas text item anchors.
  # Also allow justify or anchor type arguments
  # i.e left and west / right and east are the same
  #
  if ( $align =~ /^l/ or $align eq 'w' )
  {
    $w->{'anchor'} = 'nw';
    $w->{'xval'}   = 1;
    $w->{'canvas'}->itemconfigure( 'TEXT', -anchor => 'nw' );
  }
  elsif ( $align =~ /^c/ )
  {
    $w->{'anchor'} = 'n';
    $w->{'xval'}   = $w->{'minwidth'} / 2;
    $w->{'canvas'}->itemconfigure( 'TEXT', -anchor => 'n' );
  }
  elsif ( $align =~ /^r/ or $align eq 'e' )
  {
    $w->{'anchor'} = 'ne';
    $w->{'xval'}   = $w->{'minwidth'} - 1;
    $w->{'canvas'}->itemconfigure( 'TEXT', -anchor => 'ne' );
  }
  else
  {
    return $w->{'linenumalign'};    #for cget requests
  }

  $w->QueueLayout(_Default);
  $w->{'linenumalign'} = $align;
  return $w->{'linenumalign'};
}

# ------------------------------------------
sub linenumside
{
  my ( $w, $side ) = @_;
  return $w->{'linenumside'} unless defined $side;
  $side = lc($side);
  return unless ( $side eq 'left' or $side eq 'right' );
  $w->{'linenumside'} = $side;
  if ( $w->{'linenumshowing'} )
  {
    $w->hidelinenum;
    $w->showlinenum;
  }
  return $w->{'linenumside'};
}

# ------------------------------------------
sub linenumbg
{
  my ( $w, $bg ) = @_;
  return $w->{'linenumbg'} unless defined $bg;
  $w->{'linenumbg'} = $bg;
  $w->{'canvas'}->configure( -bg => $bg );
  $w->QueueLayout(_Default);
  return $w->{'linenumbg'};
}

# ------------------------------------------
sub linenumfg
{
  my ( $w, $fg ) = @_;

  # This sets the text color
  return $w->{'linenumfg'} unless defined $fg;
  $w->{'linenumfg'} = $fg;
  $w->{'canvas'}->itemconfigure( 'TEXT', -fill => $fg );
  $w->QueueLayout(_Default);
  return $w->{'linenumfg'};
}

# ------------------------------------------
sub linenumactivefg
{
  my ( $w, $fg ) = @_;

  # This sets the activefill of the text
  return $w->{'linenumactivefg'} unless defined $fg;
  $w->{'linenumactivefg'} = $fg;
  $w->{'canvas'}->itemconfigure( 'TEXT', -activefill => $fg );
  $w->QueueLayout(_Default);
  return $w->{'linenumactivefg'};
}

# ------------------------------------------
sub bookmarkoutline
{
  my ( $w, $color ) = @_;
  return $w->{'bookmarkoutline'} unless defined $color;
  $w->{'canvas'}->itemconfigure( 'BOOKMARK', -outline => $color );
  $w->{'bookmarkoutline'} = $color;
  $w->QueueLayout(_Default);
  return $w->{'bookmarkoutline'};
}

# ------------------------------------------
sub bookmarkfill
{
  my ( $w, $color ) = @_;
  return $w->{'bookmarkfill'} unless defined $color;
  $w->{'canvas'}->itemconfigure( 'BOOKMARK', -fill => $color );
  $w->{'bookmarkfill'} = $color;
  $w->QueueLayout(_Default);
  return $w->{'bookmarkfill'};
}

# ------------------------------------------
sub bookmarkstipple
{
  my ( $w, $stipple ) = @_;
  return $w->{'bookmarkstipple'} unless defined $stipple;
  $w->{'canvas'}->itemconfigure( 'BOOKMARK', -stipple => $stipple );
  $w->{'bookmarkstipple'} = $stipple;
  $w->QueueLayout(_Default);
  return $w->{'bookmarkstipple'};
}

# ------------------------------------------
sub bookmarkshape
{
  my ( $w, $shape ) = @_;
  $shape = lc($shape);
  if ( $shape =~ /^r/ )
  {
    $w->{'shape'} = 'rectangle';
    $w->QueueLayout(_Default);
  }
  elsif ( $shape =~ /^c/ or $shape =~ /^o/ )
  {    #circle or oval
    $w->{'shape'} = 'circle';
    $w->QueueLayout(_Default);
  }
  elsif ( $shape =~ /^t/ )
  {    #triangle
    $w->{'shape'} = 'triangle';
    $w->QueueLayout(_Default);
  }
  else
  {
    return $w->{'shape'};
  }
  return $w->{'shape'};
}

# ------------------------------------------
sub curlinebg
{
  my ( $w, $bg ) = @_;
  return $w->{'curlinebg'} unless defined $bg;
  $w->{'curlinebg'} = $bg;
  $w->{'rtext'}->tagConfigure( 'CURLINE', -background => $bg );
  return $w->{'curlinebg'};
}

# ------------------------------------------
sub curlinefg
{
  my ( $w, $fg ) = @_;
  return $w->{'curlinefg'} unless defined $fg;
  $w->{'curlinefg'} = $fg;
  $w->{'rtext'}->tagConfigure( 'CURLINE', -foreground => $fg );
  return $w->{'curlinefg'};
}

# ------------------------------------------
sub curlinehighlight
{
  my ( $w, $where ) = @_;
  return $w->{'curlinehighlight'} unless defined $where;

  my $canvas = $w->{'canvas'};
  my $rtext  = $w->{'rtext'};
  if ( $where eq 'none' )
  {
    $canvas->delete('RECT');
    $rtext->tagRemove( 'CURLINE', '1.0', 'end' );
  }
  elsif ( $where eq 'text' )
  {
    $canvas->delete('RECT');
  }
  elsif ( $where eq 'linenum' )
  {
    $rtext->tagRemove( 'CURLINE', '1.0', 'end' );
  }
  elsif ( $where eq 'both' )
  {
    $w->{'curlinehighlight'} = $where;
    $w->QueueLayout(_Default);
    return;
  }
  else
  {
    return;
  }
  $w->{'curlinehighlight'} = $where;
  $w->QueueLayout(_Default);
}

# ------------------------------------------
sub curlinestipple
{
  my ( $w, $stipple ) = @_;
  return $w->{'curlinestipple'} unless defined $stipple;
  $w->{'curlinestipple'} = $stipple;
  $w->{'rtext'}->tagConfigure( 'CURLINE', -bgstipple => $stipple );
  return $w->{'curlinestipple'};
}

# ------------------------------------------
sub linenumfont
{
  my ( $w, $font ) = @_;
  return $w->{'linenumfont'} unless defined $font;
  $w->{'linenumfont'} = $font;
  $w->{'canvas'}->itemconfigure( 'TEXT', -font => $font );
  return $w->{'linenumfont'};
}

# ------------------------------------------
sub allowbookmarks
{
  my ( $w, $val ) = @_;
  return $w->{'allowbookmarks'} unless defined $val;
  my $c     = $w->{'canvas'};
  my $rtext = $w->{'rtext'};
  if ($val)
  {

    unless ( Tk::Exists $w->{'menu'} )
    {
      $w->_makeMenu;
    }

    unless ( Tk::Exists $w->{'dialog'} )
    {
      $w->{'dialog'} = $w->DialogBox( -title => 'Sorry', -buttons => ["OK"] );
      $w->{'dialog'}
        ->add( 'Label', -text => "Bookmarking a blank line is *not* supported" )
        ->pack;
      $w->{'dialog'}->add(
        'Checkbutton',
        -text     => "Don't show again",
        -variable => \$w->{'dontshow'}
      )->pack;
    }

    $c->Tk::bind( '<ButtonPress-2>', sub { $w->_toggleBookmark; } );
    $c->Tk::bind( '<ButtonPress-3>', sub { $w->_postmenu } );
    $rtext->bind( '<F5>', sub { $w->_prev } );
    $rtext->bind( '<F6>', sub { $w->_next } );
    $w->{'allowbookmarks'} = 1;
  }
  else
  {
    $c->Tk::bind( '<ButtonPress-2>', '' );
    $c->Tk::bind( '<ButtonPress-3>', '' );
    $rtext->bind( '<F5>', '' );
    $rtext->bind( '<F6>', '' );
    $c->delete('BOOKMARK');
    $w->{'rtext'}->tagDelete('BOOKMARK');
    $w->{'allowbookmarks'} = 0;
  }
  return $w->{'allowbookmarks'};
}

# For possible future use..
sub allowlineselect
{
  my ( $w, $val ) = @_;
  return $w->{'allowlineselect'} unless defined $val;
  if ($val)
  {
    $w->{'canvas'}
      ->Tk::bind( '<Double-ButtonPress-1>', sub { $w->selectCurLine } );
  }
  else
  {
    $w->{'canvas'}->Tk::bind( '<Double-ButtonPress-1>', '' );
  }
}

############################################
# Public Methods
############################################

# ------------------------------------------
sub showlinenum
{
  my ($w) = @_;
  return if ( $w->{'linenumshowing'} );
  my $col;
  ( $w->{'linenumside'} eq 'right' ) ? ( $col = 2 ) : ( $col = 0 );
  $w->{'canvas'}->grid( -row => 0, -column => $col, -sticky => 'ns' );
  $w->{'linenumshowing'} = 1;
}

# ------------------------------------------
sub hidelinenum
{
  my ($w) = @_;
  return unless ( $w->{'linenumshowing'} );
  $w->{'canvas'}->gridForget;
  $w->{'linenumshowing'} = 0;
}

# ------------------------------------------
sub togglelinenum
{
  my ($w) = @_;
  ( $w->{'linenumshowing'} ) ? ( $w->hidelinenum ) : ( $w->showlinenum );
}

# ------------------------------------------
sub lineupdate

{
  $_[0]->QueueLayout(_User);
}

# ------------------------------------------
sub lineshowing

{
  return $_[0]->{'linenumshowing'};
}

sub addbookmark
{

  # Programmatically add bookmarks
  # Just return gracefully if an attempt is made
  # to bookmark a blank line (which is not currently supported)
  my $w = shift;
  return unless $_[0];
  return unless $w->cget('-allowbookmarks');

  foreach my $ln (@_)
  {
    my $ls = "$ln.0";
    my $le = "$ln.end";
    my ($first) = $w->{'rtext'}->tagNextrange( 'BOOKMARK', $ls, $le );
    next if defined $first;    #line already bookmarked
    $w->_addOneBookmark( $ln, 0 );    # 0 flag for programmatic add
  }
}

sub deletebookmark
{

  # Programmatically delete bookmarks
  # Just return gracefully if an attempt is made
  # to delete a bookmark which doesn't exist
  my $w = shift;
  return unless $_[0];
  return unless $w->cget('-allowbookmarks');

  foreach my $ln (@_)
  {
    my $ls = "$ln.0";
    my $le = "$ln.end";
    my ($first) = $w->{'rtext'}->tagNextrange( 'BOOKMARK', $ls, $le );
    next unless defined $first;    # line not bookmarked
    $w->{'canvas'}->delete("BM$ln");
    $w->{'rtext'}->tagRemove( 'BOOKMARK', $ls, $le );
  }

}

############################################
# Private Methods
############################################

sub _makeMenu
{
  my ($w) = shift;
  $w->{'menu'} = my $m = $w->{'canvas'}->Menu(
    -tearoff     => 0,
    -postcommand => [ '_enumBookmarks', $w ]
  );
  $m->command(
    -label       => 'Prev Bookmark',
    -command     => [ '_prev', $w ],
    -accelerator => "F5"
  );
  $m->command(
    -label       => 'Next Bookmark',
    -command     => [ '_next', $w ],
    -accelerator => "F6"
  );
  $m->checkbutton(
    -label    => 'List bookmarks ..',
    -variable => \$w->{'menulines'},
    -command  => [ '_repostmenu', $w ]
  );
  $w->{'menulines'} = 1;
}

sub _repostmenu
{
  my $w = shift;
  $w->_postmenu( $w->{X}, $w->{Y} );
}

sub _postmenu
{
  my ( $w, @xy ) = @_;
  @xy = $w->pointerxy unless ( defined $xy[1] );
  $w->{'menu'}->Post(@xy);
  ( $w->{X}, $w->{Y} ) = @xy;
}

sub _getLineNumberNextToMouse
{
  my ($w)    = shift;
  my $rtext  = $w->{'rtext'};
  my $canvas = $w->{'canvas'};
  my $e      = $canvas->XEvent;
  my $texty = $e->y - $rtext->cget( -bd ) - $rtext->cget( -highlightthickness );
  my $string  = '@0' . ',' . $texty;
  my $textidx = $w->{'rtext'}->index($string);
  $textidx =~ /^(\d+)\./;
  return $1;
}

sub _buttonPress
{
  my ($w) = shift;
  my $ln = $w->_getLineNumberNextToMouse;
  $w->_gotoLineNum($ln);
}

# for possible future use
sub selectCurLine
{
  my $w  = shift;
  my $ln = $w->_getLineNumberNextToMouse;
  $w->{'rtext'}->unselectAll;
  $w->{'rtext'}->tagAdd( 'sel', $ln . '.0', $ln . '.end' );
}

sub _toggleBookmark
{
  my ($w) = shift;
  my $c   = $w->{'canvas'};
  my $ln  = $w->_getLineNumberNextToMouse;
  if ( $c->gettags("BM$ln") )
  {
    $w->_deleteOneBookmark( "BM$ln", $ln );
  }
  elsif ( $c->gettags("REAL$ln") )
  {
    $w->_addOneBookmark( $ln, 1 );
  }

}

sub _addOneBookmark
{

  my ( $w, $ln, $user ) = @_;
  return unless defined $ln;

  my $contents = $w->{'rtext'}->get( $ln . '.0', $ln . '.end' );
  if ( $contents eq '' and $user )
  {
    my $popanchor;
    ( $w->{'linenumside'} eq 'left' )
      ? ( $popanchor = 'w' )
      : ( $popanchor = 'e' );
    $w->{'dialog'}->Show( -popover => 'cursor', -popanchor => $popanchor )
      unless ( $w->{'dontshow'} );
    return;
  }
  elsif ( $contents eq '' and not $user )
  {
    return;
  }

  $w->_createOneBookmark($ln);
  $w->_bookmarkText($ln);
  $w->QueueLayout(_Default);
}

sub _deleteOneBookmark
{
  my ( $w, $tag, $ln ) = @_;
  $w->{'canvas'}->delete($tag);
  $w->{'rtext'}->tagRemove( 'BOOKMARK', $ln . '.0', $ln . '.end' );
  $w->QueueLayout(_Default);
}

sub _getRealLine
{
  my ( $w, $tag ) = @_;
  return unless defined $tag;
  my $c = $w->{'canvas'};
  my ($item) = $c->find( 'withtag', $tag );
  my ($realtag) = grep( /REAL/, $c->gettags($item) );
  $realtag =~ /REAL(\d+)/;
  my $line = $1;
  return $line;
}

sub _bookmarkText
{
  my ( $w, @lines ) = @_;
  my @indices;
  my $t = $w->{'rtext'};
  foreach my $line (@lines)
  {
    push @indices, $line . '.0', $line . '.end';
    $t->tagRemove( 'BOOKMARK', $line . '.0', $line . '.end' );

  }
  $t->tagAdd( 'BOOKMARK', @indices );
}

sub _next
{
  my ($w) = @_;
  my $rtext = $w->{'rtext'};

  # This should find the next bookmark with respect to the insert cursor
  my $idx1 = $rtext->index('insert');
  return unless $idx1;
  my $idx2 = 'end';
  my ($next) = $rtext->tagNextrange( 'BOOKMARK', $idx1 . '+ 1 chars', $idx2 );
  return unless $next;
  $w->_gotoLineNum($next);
  $w->QueueLayout(_Default);
}

sub _prev
{
  my ($w) = @_;
  my $rtext = $w->{'rtext'};

  # This should find the previous bookmark with respect to the insert cursor
  my $idx1 = $rtext->index('insert');
  return unless $idx1;
  my $idx2 = '1.0';
  my ($prev) = $rtext->tagPrevrange( 'BOOKMARK', $idx1 . '- 1chars', $idx2 );
  return unless $prev;
  $w->_gotoLineNum($prev);
  $w->QueueLayout(_Default);
}

sub _enumBookmarks
{
  my ($w) = @_;
  my $menu = $w->{'menu'};

  my @bm = $w->_dumpBookmarks;
  unless ( $bm[0] )
  {
    return 0;
  }
  my $end = $menu->index('end');
  $menu->delete( 3, 'end' ) unless ( $end == 2 );
  return unless ( $w->{'menulines'} );
  my $count = 3;
  my $cb;
  foreach my $l (@bm)
  {

    if ( $count == 10 )
    {
      $cb    = 1;
      $count = 0;
    }
    else
    {
      $cb = 0;
    }
    $menu->add(
      'command',
      -columnbreak => $cb,
      -label       => "Line $l",
      -command     => [ '_gotoLineNum', $w, $l ]
    );
    $count++;
  }
}

sub _gotoLineNum
{
  my ( $w, $line ) = @_;
  my $rtext = $w->{'rtext'};
  $line .= '.0' unless ( $line =~ /\./ );
  $rtext->markSet( 'insert', $line );
  $rtext->see($line);
  $w->{'menu'}->Unpost;    #Windows bug doesn't return focus
  $w->QueueLayout(_Default);
}

sub _dumpBookmarks
{

  # Return all line numbers of current bookmarks
  my ($w) = @_;
  my @linarr;
  my %linehash = $w->{'rtext'}->tagRanges('BOOKMARK');

  if ( my @lines = keys %linehash )
  {
    foreach my $l (@lines)
    {
      $l =~ /^(\d+)\./o;
      push( @linarr, $1 );
    }
    my @sorted = sort { $a <=> $b } @linarr;
    return @sorted;
  }
  return undef;
}

sub _createOneBookmark
{

# This will create one bookmark at the location of the linenumber item represented by
# an argument to this method. And it will tag the associated text as a bookmark.
# Canvas line numbers are tagged with the "real" line number.
# This can be via a user interaction (i.e. double-click or a menu choice) or anytime
# a line update is called.

  my ( $w, $ln ) = @_;
  my $tag  = 'REAL' . $ln;
  my $c    = $w->{'canvas'};
  my $side = $w->{'linenumside'};
  my ( $x0, $y0, $x1, $y1 ) = $c->bbox($tag);
  my $shape = $w->{'shape'};

  if ( defined $x0 )
  {
    my $h     = ( $y1 - $y0 ) / 2;    # half height
    my $width = $c->cget( -width );
    if ( $side eq 'left' )
    {
      if ( $shape eq 'triangle' )
      {
        $c->create(
          'polygon',
          $width - $h * 2, $y0 + 1, $width - 1, $y0 + $h, $width - $h * 2,
          $y1 - 1,
          -fill    => $w->{'bookmarkfill'},
          -stipple => $w->{'bookmarkstipple'},
          -outline => $w->{'bookmarkoutline'},
          -tags    => [ 'BOOKMARK', "BM$ln" ]
        );
      }
      elsif ( $shape eq 'circle' )
      {
        $c->create(
          'oval',
          $width - $h * 2 - 1, $y0, $width - 1, $y1,
          -fill    => $w->{'bookmarkfill'},
          -stipple => $w->{'bookmarkstipple'},
          -outline => $w->{'bookmarkoutline'},
          -tags    => [ 'BOOKMARK', "BM$ln" ]
        );
      }
      elsif ( $shape eq 'rectangle' )
      {
        $c->create(
          'rectangle',
          $width - $h * 2 + 1, $y0 + 1, $width - 1, $y1 - 1,
          -fill    => $w->{'bookmarkfill'},
          -stipple => $w->{'bookmarkstipple'},
          -outline => $w->{'bookmarkoutline'},
          -tags    => [ 'BOOKMARK', "BM$ln" ]
        );
      }
    }
    else
    {
      if ( $shape eq 'triangle' )
      {
        $c->create(
          'polygon',
          $h * 2, $y0 + 1, 1, $y0 + $h, $h * 2, $y1 - 1,
          -fill    => $w->{'bookmarkfill'},
          -stipple => $w->{'bookmarkstipple'},
          -outline => $w->{'bookmarkoutline'},
          -tags    => [ 'BOOKMARK', "BM$ln" ]
        );
      }
      elsif ( $shape eq 'circle' )
      {
        $c->create(
          'oval',
          0, $y0, $h * 2, $y1,
          -fill    => $w->{'bookmarkfill'},
          -stipple => $w->{'bookmarkstipple'},
          -outline => $w->{'bookmarkoutline'},
          -tags    => [ 'BOOKMARK', "BM$ln" ]
        );
      }
      elsif ( $shape eq 'rectangle' )
      {
        $c->create(
          'rectangle',
          0, $y0, $h * 2 - 1, $y1 - 1,
          -fill    => $w->{'bookmarkfill'},
          -stipple => $w->{'bookmarkstipple'},
          -outline => $w->{'bookmarkoutline'},
          -tags    => [ 'BOOKMARK', "BM$ln" ]
        );
      }
    }
  }
}

# ------------------------------------------
sub _lineupdate
{
  my ($w) = @_;

  my $rtext  = $w->{'rtext'};
  my $canvas = $w->{'canvas'};
  return
    unless ( $canvas->ismapped )
    ;    # Don't bother continuing if line numbers cannot be displayed
  my $idx1 = $rtext->index('@0,0');    # First visible line in text widget
  $rtext->see($idx1);
  my ( $dummy, $ypix ) = $rtext->dlineinfo($idx1);

  my $theight = $rtext->height;
  my $oldy    = my $lastline = -99;    #ensure at least one number gets shown

  my @LineNum;
  my $insertidx = $rtext->index('insert');
  my ($insertLine) = split( /\./, $insertidx );
  my $insertVisible = 0;

  my $canvasline = 0;
  my $lastitem   = -99;

  $canvas->delete('TEXT');
  my $xval   = $w->{'xval'};
  my $anchor = $w->{'anchor'};

  while (1)
  {
    my $idx = $rtext->index( '@0,' . "$ypix" );
    my ($realline) = split( /\./, $idx );
    $insertVisible = 1 if ( $realline == $insertLine );
    my ( $x, $y, $wi, $he ) = $rtext->dlineinfo($idx);
    last unless defined $he;

    last if ( $oldy == $y );    #line is the same as the last one
    $oldy = $y;
    $ypix += $he;
    last if $ypix >= $theight;    #we have reached the end of the display
    last if ( $y == $ypix );

    $canvasline++;

    if ( $realline == $lastline )
    {
      $lastline = $realline;
      next;
    }
    else
    {

      # Note: Benchmark tests for creating and deleting show virtually no
      #  difference in speed over using itemconfigure. Besides - by deleting
      #  and re-creating, there is no need to "keep track".
      push @LineNum, $realline;
      my $k = $canvas->create(
        'text', $xval, $y,
        -text       => $realline,
        -anchor     => $anchor,
        -fill       => $w->{'linenumfg'},
        -activefill => $w->{'linenumactivefg'},
        -font       => $w->{'linenumfont'},
        -tags       => [ 'TEXT', "REAL$realline" ]
      );
      $lastitem = $k;
    }

    $lastline = $realline;
  }

  #Bookmarks on top
  $canvas->lower('TEXT');
  $canvas->delete('BOOKMARK');

  # Re-create bookmarks (if there are any) for only the displayed lines

  for ( my $counter = 0 ; $counter <= $#LineNum ; $counter++ )
  {
    my ( $index1, $index2 ) = $rtext->tagNextrange(
      'BOOKMARK',
      $LineNum[$counter] . '.0',
      $LineNum[$#LineNum] . '.end'
    );

    last unless defined $index1;

    my $ln = int($index1);

    #ensure the indices cover the entire line.
    $rtext->tagRemove( 'BOOKMARK', $index1, $index2 );
    $rtext->tagAdd( 'BOOKMARK', $ln . '.0', $ln . '.end' );
    $w->_createOneBookmark($ln);
  }

  #ensure proper width of canvas
  my @bbox = $canvas->bbox($lastitem);
  return unless ( defined( $bbox[0] ) );
  my $neededwidth = ( $bbox[2] - $bbox[0] );
  my $canvaswidth = $canvas->cget( -width );
  my $minwidth    = $w->{'minwidth'};

  if ( $neededwidth > $canvaswidth )
  {
    $canvas->configure( -width => $neededwidth );
  }
  elsif ( $neededwidth <= $minwidth && $canvaswidth != $minwidth )
  {
    $canvas->configure( -width => $minwidth );
  }

  # Do the current line highlight if so configured
  if ($insertVisible)
  {
    my $highlight = $w->{'curlinehighlight'};
    if ( $highlight eq 'both' )
    {
      $w->_highlightCurlineText;
      $w->_highlightCurlineCanvas;
    }
    elsif ( $highlight eq 'linenum' )
    {
      $w->_highlightCurlineCanvas;
    }
    elsif ( $highlight eq 'text' )
    {
      $w->_highlightCurlineText;
    }
  }
  else
  {
    $rtext->tagRemove( 'CURLINE', '1.0', 'end' );
    $canvas->delete('RECT');
  }
}

sub _highlightCurlineText
{
  my ($w) = shift;
  my $rtext = $w->{'rtext'};
  $rtext->tagRemove( 'CURLINE', '1.0', 'end' );
  my $curline = $rtext->index('insert');
  $curline =~ /^(\d+)\./;
  return unless $curline;
  $rtext->tagAdd( 'CURLINE', "$1\.0", "$1\.end + 1 chars" ) if ($curline);
  $rtext->tagLower('CURLINE');
}

sub _highlightCurlineCanvas
{
  my ($w) = shift;
  my $canvas = $w->{'canvas'};
  $canvas->delete('RECT');
  my $curline = $w->{'rtext'}->index('insert');
  return unless $curline;
  $curline =~ /^(\d+)\./;
  my $line = $1;
  return unless $line;
  my ( $x0, $y0, $x1, $y1 ) = $canvas->bbox("REAL$line");
  $canvas->itemconfigure( "REAL$line", -fill => $w->{'curlinefg'} );
  $canvas->create(
    'rectangle', 0, $y0, $canvas->width - 1, $y1,
    -width => 0,
    -fill  => $w->{'curlinebg'},
    -tags  => ['RECT']
  );
  $canvas->lower('RECT');
}

# Shamelessly stolen code from Tk::Pane
# Constants passed but never used here?
sub QueueLayout
{
  my ( $w, $why ) = @_;
  $w->afterIdle( [ 'Layout', $w ] ) unless ( $w->{'LayoutPending'} );
  $w->{'LayoutPending'} |= $why;
}

sub Layout
{
  my ($w) = @_;
  return unless Tk::Exists($w);
  my $why = $w->{'LayoutPending'};
  $w->{'LayoutPending'} = 0;

  if ($why)
  {
    $w->_lineupdate;
  }

}
1;

__END__

=head1 NAME

B<Tk::LineNumberText> - Line numbers for your favorite Text-derived widget

=head1 SYNOPSIS

I<$linenumtext> = I<$parent>-E<gt>B<LineNumberText>(I<C<Text-Derived Widget>>,?I<options>?);

=head1 EXAMPLE

   use Tk;
   use Tk::LineNumberText;

   my $mw=tkinit;
   $mw->LineNumberText('Text',
     -wrap=>'word',
     -font=>['Courier',12],
     -linenumfont=>['Courier',12],
     -curlinehighlight=>'both',
     -bg=>'white')->pack(-fill=>'both', -expand=>1);

   MainLoop;

=head1 RELEASE NOTES

This version is B<NOT backwards compatible>. Some options have been deleted and others
have changed. This was to be expected anyways - as v0.1 was documented as beta. For
various reasons - I have jumped straight to a v0.5. Whenever the word B<C<"Text">> is used
within this documentation - it is assumed that it refers to the B<C<"Text-derived widget">>
you pass at instantiation.

=head1 DESCRIPTION

B<LineNumberText> is a composite widget which provides line numbers for your
favorite widget derived from B<Tk::Text> or, of course, even for B<Tk::Text> itself.

=head1 SUPER-CLASS

B<LineNumberText> I<ISA> B<Tk::Frame> consisting of a Canvas to plot the line numbers
and a Scrolled Text widget. This code has been tested using B<Tk::Text>, B<Tk::CodeText>
and B<Tk::TextUndo>.

The line numbers I<B<should>> adjust automatically as text is edited or scrolled
(either programmatically or interactively). If you find cases
where this doesn't happen - please contact the author with the particulars.

LineNumberText does not sub-class any of the B<Text> methods. Instead, B<AUTOLOAD> is used
to get at the Text methods and then the line number update is done. The previous version
used to actually override all these methods, which caused problems for some users. This
is no longer the case.

=head1 WIDGET-SPECIFIC OPTIONS

All options should be available as per your Text widget documentation. Additionally
the following options are offered..

=head2 In Alphabetical Order

=over 4

=item B<-allowbookmarks>

Boolean to allow E<lt>1E<gt> or disallow E<lt>0E<gt> user-interactive bookmarks.

=item B<-bookmarkfill>

Fill color for bookmark.

=item B<-bookmarkoutline>

Outline color for bookmark.

=item B<-bookmarkshape>

Shape of bookmark must be one of: B<rectangle>, B<circle> or B<triangle>

=item B<-bookmarkstipple>

Bitmap stipple for bookmarks. eg/ gray50

=item B<-curlinebg>

Background color of the current line. The current line is defined
as the line containing the I<insert> cursor.

=item B<-curlinefg>

Foreground color of the current line. The current line is defined
as the line containing the I<insert> cursor.

=item B<-curlinehighlight>

Must be ONE of the following:

=over 4

=item B<I<none>>

Current line will NOT be highlighted. This is the default.

=item B<I<text>>

Highlight the entire current line in the text widget only.

=item B<I<linenum>>

Highlight the current line number only.

=item B<I<both>>

Highlight the current line in both the text widget and the
line number.

=back

=item B<-curlinestipple>

Bitmap stipple to use on the current line highlight background.
Default is no stipple (i.e. undef).

=item B<-linenumactivefg>

Active color of the line numbers. Done by adjusting the I<-activefill> option
of a canvas text item.

=item B<-linenumalign>

Anchor position for the line numbers with respect to the canvas.
Must be one of B<I<left>>, B<I<center>> or B<I<right>>.

=item B<-linenumbg>

Background color of the line numbers. This is the background color of the
canvas itself.

=item B<-linenumfg>

Foreground color of the line numbers. Done by adjusting the I<-fill> option
of a canvas text item.

=item B<-linenumfont>

Font type of the line numbers. Done by adjusting the I<-font> option
of a canvas text item.

=item B<-linenumside>

Specifies which side of the text widget to place the line numbers. Must be
either B<I<left>> or B<I<right>>. Default is left.

=back

=head1 WIDGET METHODS

As stated above, all methods should find their way to the proper module
by the AUTOLOAD routine. The following widget-specific methods also exist.

=over 4

=item I<$linenumtext>->B<addbookmarks>(E<lt>I<Line number list>E<gt>)

Programmatically add bookmarks to each line number specified in the list passed.
Note: Array references are not yet supported.

=item I<$linenumtext>->B<deletebookmarks>(E<lt>I<Line number list>E<gt>)

Programmatically delete bookmarks at each line number specified in the list passed.
Note: Array references are not yet supported.

=item I<$linenumtext>->B<hidelinenum>

Hide the linenumber widget. (i.e. gridForget)

=item I<$linenumtext>->B<showlinenum>

Show the linenumber widget. (i.e. grid)

=item I<$linenumtext>->B<togglelinenum>

Toggle the visibility of the linenumber widget.

=item I<$linenumtext>->B<lineshowing>

Returns a boolean value to indicate the visibility of the linenumber widget.

=item I<$linenumtext>->B<lineupdate>

Force line numbers to update.

NOTE: This method B<should not> have to be called manually. This widget is designed
to do the updates for you. However - I have provided this to allow the force the
update just in case there are situations when it fails to do so. But I hope you
would e-mail me if you come across any bugs.

=back

=head1 CANVAS BINDINGS

=over 4

=item <ButtonPress-1>

Set I<insert mark> of B<text widget> to the line number clicked.

=item <ButtonPress-2>

Toggle bookmark.

=item <ButtonPress-3>

Navigation menu.

=back

=head1 TEXT-WIDGET BINDINGS

=over 4

=item <F5>

Go to previous bookmark.

=item <F6>

Go to next bookmark.

=back

=head1 ADVERTISED WIDGETS

The following widgets are advertised:

=over 4

=item scrolled

The text or text-derived widget.

=item text

The text or text-derived widget. (Same as B<scrolled> above)

=item frame

The frame containing the scrollbars and text widget (As per the
L<Tk::Scrolled|Tk::Scrolled> method).

=item yscrollbar

The scrollbar widget using for vertical scrolling.

=item xscrollbar

The Scrollbar widget using for horizontal scrolling.

=item corner

The frame in the corner between the vertical and horizontal scrollbars.

=item linenum

The canvas widget used for the line numbers.

=back

=head1 BUGS

There will always be a line number on the first display line -- even if
the text could actually be wrapped from a line which is off screen. I did
this to ensure that at least one line number is shown at all times.

=head1 OTHER STUFF

=over 4

=item *

By design - the text widget will have tags placed within it in order to support
bookmarks next to the line numbers. You will see these tags if you use the dump
method.

=item *

By design - a blank line cannot be bookmarked. I made a valor attempt to use
marks instead of tags - to no avail. Tags are easy and will be deleted through user
interaction; marks always stay.

=back

=head1 WISH LIST

=over 4

=item *

Allow selection of lines by interacting with the line number.

=item *

Allow user defined images for bookmarks.

=item *

Allow bookmarks to remain persistent so they are not lost on a save.

=item *

Allow bookmarking of blank lines.

=item *

How about someone building a full-fledged perl/Tk IDE now that we have
line numbers and bookmarks !

=back

=head1 SEE ALSO

L<Tk::Frame|Tk::Frame>, L<Tk::Text|Tk::Text>, L<Tk::Scrolled|Tk::Scrolled>, L<Tk::Canvas|Tk::Canvas>.

=head1 THANK YOU

Thanks go to the following people for their kind advice, suggestions and
code samples.

Dean Arnold, Eric Hodges, Darin McBride, Brian McCauley, Brian McGonigle,
Ala Qumsieh, Steve Schulze.

=head1 AUTHOR

Jack Dunnigan E<lt>goodcall1@hotmail.comE<gt>

Copyright (C) 2004. All rights reserved. This module is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

Inspired by B<ctext.tcl> written by George Peter Staplin.

See I<http://wiki.tcl.tk/4134>.

=cut

