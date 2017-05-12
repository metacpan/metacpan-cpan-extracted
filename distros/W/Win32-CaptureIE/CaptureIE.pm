package Win32::CaptureIE;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'default' => [ qw(
  StartIE
  QuitIE
  Navigate
  PopUp
  RunJS
  Wait
  Refresh
  GetElement
  GetAll
  GetDoc

  CaptureElement
  CaptureElements
  CapturePage
  CaptureBrowser
  CaptureRows
  CaptureThumbshot
  CaptureArea

  $IE
  $Doc
  $Body
  $HWND_IE
  $HWND_Browser
  $CaptureBorder
  $PopUp_IE
  $PopUp_HWND_IE
  $PopUp_HWND_Browser
) ] );

$EXPORT_TAGS{all} = [ map {@$_} values %EXPORT_TAGS ];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = @{ $EXPORT_TAGS{'default'} };

our $VERSION = '1.30';
our $IE;
our $HWND_IE;
our $HWND_Browser;
our $Doc;
our $Body;
our $PopUp_IE;
our $PopUp_HWND_IE;
our $PopUp_HWND_Browser;
our $ProcessPopUps = 0;
our $CaptureBorder = 1;
our ($MOUSE_x, $MOUSE_y);

use Win32::OLE qw(in valof EVENTS);
use Win32::Screenshot qw(:all);
use POSIX qw(ceil floor);
use strict;

##########################################################################

# HACK: DocumentComplete event is not fired when refreshing page but
# only DownloadComplete event, so if refreshing page we need to wait for
# DownloadComplete but not if we are navigating to a page
our $refreshing_page = 0;

sub StartIE {
  my %arg = @_;

  # Open a new browser window and save its' window handle
  $IE = Win32::OLE->new("InternetExplorer.Application");
  Win32::OLE->WithEvents($IE,\&EventHandler,"DWebBrowserEvents2");
  Win32::OLE->Option(Warn => 4);
  $HWND_IE = $IE->{HWND};

  # Let's size the window
  $IE->{height} = $arg{height} || 600;
  $IE->{width} = $arg{width} || 808;
  $IE->{visible} = 1;

  # Show blank page (let the browser create rendering area)
  Navigate('about:blank');

  # We need the window on top because we want to get the screen shots
  Minimize($HWND_IE); Restore($HWND_IE); # this seem to work
  BringWindowToTop( $HWND_IE );

  # Find the largest child window, suppose that this is the area where the page is rendered
  my ($sz, $i) = (0, 0);
  for ( ListChilds($HWND_IE) ) {
    next unless $_->{visible};
    if ( $sz < (($_->{rect}[2]-$_->{rect}[0])*($_->{rect}[3]-$_->{rect}[1])) ) {
      $sz = (($_->{rect}[2]-$_->{rect}[0])*($_->{rect}[3]-$_->{rect}[1]));
      $i = $_->{hwnd};
    }
  }
  $HWND_Browser = $i;

  ($MOUSE_x, $MOUSE_y) = GetCursorPos();
  SetCursorPos(0, 0);
}

sub QuitIE () {
  $IE->Quit();
  $IE = undef;

  SetCursorPos($MOUSE_x, $MOUSE_y);
}

sub Navigate ($) {
  (defined $PopUp_IE ? $PopUp_IE : $IE)->Navigate($_[0]);
  Win32::OLE->MessageLoop();
  GetDoc();
}

sub PopUp (&) {
  $ProcessPopUps = 1;
  &{$_[0]}();
  Win32::OLE->MessageLoop();
  GetDoc();

  # Find the largest child window, suppose that this is the area where the page is rendered
  $PopUp_HWND_IE = $PopUp_IE->{HWND};
  my ($sz, $i) = (0, 0);
  for ( ListChilds($PopUp_HWND_IE) ) {
    next unless $_->{visible};
    if ( $sz < (($_->{rect}[2]-$_->{rect}[0])*($_->{rect}[3]-$_->{rect}[1])) ) {
      $sz = (($_->{rect}[2]-$_->{rect}[0])*($_->{rect}[3]-$_->{rect}[1]));
      $i = $_->{hwnd};
    }
  }
  $PopUp_HWND_Browser = $i;

  $ProcessPopUps = 0;
}

sub RunJS ($) {
  (defined $PopUp_IE ? $PopUp_IE : $IE)->Navigate("javascript:$_[0]");
  Wait(1);
  GetDoc();
}

sub Wait (;$) {
  my $time = shift || 1;
  while ( $time > 0 ) {
    Win32::OLE->SpinMessageLoop;
    select undef, undef, undef, 0.1;
    $time -= 0.1;
  }
}

sub Refresh () {
  $refreshing_page = 1;
  $IE->Refresh2(3);
  Win32::OLE->MessageLoop();
  GetDoc();
}

sub GetDoc () {
  $Doc = defined $PopUp_IE ? $PopUp_IE->{Document} : $IE->{Document};
  $Body = (! $Doc->compatMode || $Doc->compatMode eq 'BackCompat') ? $Doc->{Body} : $Doc->{Body}->{parentNode};
}

sub GetElement ($) {
  return $Doc->getElementById($_[0]);
}

sub GetAll ($;$$) {
  my $tag = uc shift;
  my $sub = ref $_[0] eq 'CODE' ? shift : undef;
  my $idx = shift;
  my @elements;

  local $_;
  for ( my $i = 0 ; $i < $Doc->All->length ; $i++ ) {
    $_ = $Doc->All($i);
    push @elements, $_ if $_->tagName eq $tag && (!defined $sub || &$sub( $_ ));
    last if defined $idx && @elements > $idx;
  }

  return defined $idx ? $elements[$idx] : @elements;
}

#####################################################################

sub CaptureRows {
  my $tab = ref $_[0] ? shift : GetElement(shift);
  my %rows = map {$_ => 1} ref $_[0] ? @{$_[0]} : @_;
  return undef if $tab->tagName ne 'TABLE' || !%rows;

  # temporary disable post processing
  my $img;
  {
    local @Win32::Screenshot::POST_PROCESS = ();
    $img = CaptureElement($tab);
  }

  # skip over CaptureBorder and table border (start on top of 1st row)
  my $pos = $CaptureBorder + $tab->rows(0)->{offsetTop};

  for ( my $row = 0 ; $row < $tab->rows->{length} ; $row++ ) {
    if ( $rows{$row} ) { # we want this row,  skip over it
      $pos += $tab->rows($row)->{offsetHeight};
    } else { # don't want this one, chop it out of the picture
      $img->Chop('x'=>0, 'y'=>$pos, 'width'=>0, 'height'=>$tab->rows($row)->{offsetHeight});
    }
  }

  return PostProcessImage( $img );
}

sub CaptureThumbshot {

  # that's not a good idea to capture thumbshots of popup windows
  return if defined $PopUp_IE;

  GetDoc();

  # resize the window to set the client area to 800x600
  $IE->{width} = $IE->{width} + 800-$Body->clientWidth;
  $IE->{height} = $IE->{height} + 600-$Body->clientHeight;

  # scrollTo(0, 0)
  $Body->{scrollTop} = 0;
  $Body->{scrollLeft} = 0;
  Win32::OLE->SpinMessageLoop();

  return CaptureWindowRect($HWND_Browser, $Body->clientLeft, $Body->clientTop, $Body->clientWidth, $Body->clientHeight );
}

sub CaptureElement {
  my $e = ref $_[0] ? shift : GetElement(shift);
  my $args = ProcessArgs(ref $_[0] eq 'HASH' ? shift : {});
  return CapturePage() if $e->tagName eq 'BODY';

  GetDoc();

  my ($px, $py, $sx, $sy, $w, $h);

  # This is the size of the object including its border
  $w = $e->offsetWidth;
  $h = $e->offsetHeight;

  # Let's calculate the absolute position of the object on the page
  my $p = $e;
  while ( $p ) {
    $px += $p->offsetLeft;
    $py += $p->offsetTop;
    $p = $p->offsetParent;
  }

  # Expand the area by capture border
  $px -= ($args->{border_left}||0);
  $py -= ($args->{border_top}||0);
  $w  += ($args->{border_left}||0) + ($args->{border_right}||0);
  $h  += ($args->{border_top}||0) + ($args->{border_bottom}||0);

  return CaptureArea($px, $py, $w, $h);
}

sub ProcessArgs {
  my $a = shift;
  my %args;

  $args{border_left} =   exists $a->{border_left}   ? $a->{border_left}   : exists $a->{border} ? $a->{border} : $CaptureBorder;
  $args{border_right} =  exists $a->{border_right}  ? $a->{border_right}  : exists $a->{border} ? $a->{border} : $CaptureBorder;
  $args{border_top} =    exists $a->{border_top}    ? $a->{border_top}    : exists $a->{border} ? $a->{border} : $CaptureBorder;
  $args{border_bottom} = exists $a->{border_bottom} ? $a->{border_bottom} : exists $a->{border} ? $a->{border} : $CaptureBorder;
  return \%args;
}

sub CaptureElements {
  my @elements = map { ! ref $_ ? GetElement($_) : $_ } grep { ! ref $_ || ref $_ eq 'Win32::OLE' } @_;
  my $args = ProcessArgs(ref $_[-1] eq 'HASH' ? $_[-1] : {});

  my ($tlx, $tly, $brx, $bry);
  my ($px, $py, $sx, $sy, $w, $h);

  GetDoc();

  # calculate absolute position on the page for all elements
  # and get bounding rect
  for my $e ( @elements ) {
    my $p = $e;

    my ($x, $y) = (0, 0);
    while ( $p ) {
      $x += $p->offsetLeft;
      $y += $p->offsetTop;
      $p = $p->offsetParent;
    }

    $tlx = $x if !defined $tlx || $tlx > $x;
    $tly = $y if !defined $tly || $tly > $y;
    $brx = $x+$e->offsetWidth if !defined $brx || $brx < $x+$e->offsetWidth;
    $bry = $y+$e->offsetHeight if !defined $bry || $bry < $y+$e->offsetHeight;
  }

  $w = $brx - $tlx + 1;
  $h = $bry - $tly + 1;
  $px = $tlx;
  $py = $tly;

  $px -= ($args->{border_left}||0);
  $py -= ($args->{border_top}||0);
  $w  += ($args->{border_left}||0) + ($args->{border_right}||0);
  $h  += ($args->{border_top}||0) + ($args->{border_bottom}||0);

  return CaptureArea($px, $py, $w, $h);
}

sub CapturePage {
  my ($px, $py, $sx, $sy, $w, $h);

  GetDoc();

  return CaptureArea(0, 0, $Body->scrollWidth, $Body->scrollHeight);
}

sub CaptureArea ($$$$) {
  my ($px, $py, $w, $h) = @_;
  my ($sx, $sy);

  $px = 0 if $px < 0;
  $py = 0 if $py < 0;
  $w = $Body->{scrollWidth}-$px if $px+$w > $Body->{scrollWidth};
  $h = $Body->{scrollHeight}-$py if $py+$h > $Body->{scrollHeight};

  # Scrolls the page so that top of the object is visible at the top of the window.
  $Body->{scrollTop} = $py - 2;
  $Body->{scrollLeft} = $px - 2;

  # The position on the screen is different due to page scrolling and Body border
  $sx = $px - $Body->scrollLeft + $Body->clientLeft;
  $sy = $py - $Body->scrollTop + $Body->clientTop;

  if ( $sx+$w < $Body->clientWidth && $sy+$h < $Body->clientHeight ) {

    # If the whole object is visible
    return CaptureWindowRect(defined $PopUp_IE ? $PopUp_HWND_Browser : $HWND_Browser, $sx, $sy, $w, $h );

  } else {

    # If only part of it is visible
    return CaptureAndScroll($px, $py, $w, $h);
  }
}

sub CaptureAndScroll ($$$$) {
  my ($px, $py, $w, $h) = @_;
  my ($strip, $final, $pw, $ph, $ch, $cw, $maxw, $maxh, $sx, $sy);

  GetDoc();

  # Captured area
  $final = '';
  $cw = 0;
  $ch = 0;

  # We will do the screen capturing in more steps by areas of maximum dimensions $maxw x $maxh
  $maxw = $Body->clientWidth;
  $maxh = $Body->clientHeight;

  for ( my $cnt_x=0 ; $cw < $w ; $cnt_x++ ) {

    # Scroll to the top and right
    $Body->{scrollTop} = $px - 2;
    $Body->{scrollLeft} = $px - 2 + $cnt_x * int($maxw*0.9);
    Win32::OLE->SpinMessageLoop;

    $strip = '';
    $ch = 0;

    for ( my $cnt_y=0 ; $ch < $h ; $cnt_y++ ) {

      $Body->{scrollTop} = $px - 2 + $cnt_y * int($maxh*0.9);
      Win32::OLE->SpinMessageLoop;

      # Recalculate the position on the screen
      $sx = $px - $Body->scrollLeft + $Body->clientLeft + $cw;
      $sy = $py - $Body->scrollTop + $Body->clientTop + $ch;

      # Calculate the dimensions of the part to be captured
      $pw = ($px+$cw) - $Body->scrollLeft + $maxw > $maxw ? $maxw - ($px+$cw) + $Body->scrollLeft : $maxw;
      $pw = $cw + $pw > $w ? $w - $cw : $pw;

      $ph = ($py+$ch) - $Body->scrollTop + $maxh > $maxh ? $maxh - ($py+$ch) + $Body->scrollTop : $maxh;
      $ph = $ch + $ph > $h ? $h - $ch : $ph;

      # Capture the part and append it to the strip
      $strip .= (CaptureHwndRect(defined $PopUp_IE ? $PopUp_HWND_Browser : $HWND_Browser, $sx, $sy, $pw, $ph))[2];

      $ch += $ph;
    }

    $final = JoinRawData( $cw, $pw, $h, $final, $strip );

    $cw += $pw;
  }

  return CreateImage( $w, $h, $final );
}


sub CaptureBrowser {

  GetDoc();

  # scrollTo(0, 0)
  $Body->doScroll('pageUp') while $Body->scrollTop > 0;
  $Body->doScroll('pageLeft') while $Body->scrollLeft > 0;

  return CaptureWindow( defined $PopUp_IE ? $PopUp_HWND_IE : $HWND_IE );
}

##########################################################################

sub EventHandler {
  my ($obj,$event,@args) = @_;

  # if the document is fully loaded and ready after Navigate()
  if ($event eq 'DocumentComplete' && $IE->ReadyState() == 4)  {
    Win32::OLE->QuitMessageLoop;
  }

  # if the document is fully loaded and ready after Refresh()
  if ($event eq 'DownloadComplete' && $refreshing_page) {
    $refreshing_page = 0;
    Win32::OLE->QuitMessageLoop;
  }

  # if new window is going to be created
  if ($event eq 'NewWindow2') {

    # if we want to process popups and don't have any yet
    if ( $ProcessPopUps && ! $PopUp_IE ) {

      # create a browser for the window
      $PopUp_IE = Win32::OLE->new("InternetExplorer.Application")->{Application};
      Win32::OLE->WithEvents($PopUp_IE, \&PopUpEventHandler, "DWebBrowserEvents2");
      $args[0]->Put($PopUp_IE);

      # wait while the window is busy
      while ($PopUp_IE->{Busy} == 1) { select(undef, undef, undef, 0.2); }

    # if we do not want any popups, cancel that
    } else {
      $args[1]->Put(1);
    }

  }
}


sub PopUpEventHandler {
  my ($obj,$event,@args) = @_;

  # if the document is fully loaded and ready after Navigate()
  if ($event eq 'DocumentComplete' && $IE->ReadyState() == 4)  {
    Win32::OLE->QuitMessageLoop;
  }

  # if the document is fully loaded and ready after Refresh()
  if ($event eq 'DownloadComplete' && $refreshing_page) {
    $refreshing_page = 0;
    Win32::OLE->QuitMessageLoop;
  }

  # if new window is going to be created, cancel that, we can handle only one popup
  if ($event eq 'NewWindow2') {
    $args[1]->Put(1);
  }

  # if the window has been closed destroy the object
  if ($event eq 'OnQuit') {
    $PopUp_IE = undef;
    $PopUp_HWND_IE = undef;
    $PopUp_HWND_Browser = undef;
  }

}

##########################################################################

1;

__END__

=head1 NAME

Win32::CaptureIE - Capture web pages or its elements rendered by Internet Explorer

=head1 SYNOPSIS

  use Win32::CaptureIE;

  StartIE;
  Navigate('http://my.server/page.html');

  my $img = CaptureElement('tab_user_options');
  $img->Write("ie-elem.png");

  QuitIE;

=head1 DESCRIPTION

The package enables you to automatically create screenshots of your
web server pages for the user guide or whatever you need it for. The
best part is that you don't bother yourself with scrolling and object
localization. Just tell the ID of the element and receive an Image::Magick
object. The package will do all the scrolling work, it will take the
screenshots and glue the parts together.

=head1 EXPORT

=over 8

=item :default

C<CaptureArea>
C<CaptureBrowser>
C<CaptureElement>
C<CaptureElements>
C<CapturePage>
C<CaptureRows>
C<CaptureThumbshot>
C<GetDoc>
C<GetAll>
C<GetElement>
C<Navigate>
C<RunJS>
C<PopUp>
C<Wait>
C<QuitIE>
C<Refresh>
C<StartIE>
C<$Body>
C<$CaptureBorder>
C<$Doc>
C<$HWND_Browser>
C<$HWND_IE>
C<$IE>
C<$PopUp_HWND_Browser>
C<$PopUp_HWND_IE>
C<$PopUp_IE>

=back

=head2 Internet Explorer controlling functions

=over 8

=item StartIE ( %params )

This function creates a new Internet Explorer process via Win32::OLE.
You can specify width and height of the window as parameters.

  StartIE( width => 808, height => 600 );

The function will bring the window to the top and try to locate the
child window where the page is rendered. The mouse cursor will be moved
to the top left corner of the screen to not interfere with the browser.

=item QuitIE ( )

Terminates the Internet Explorer process and destroys the Win32::OLE
object. Restores the original cursor position.

=item Navigate ( $url )

Loads the specified page and waits until the page is completely loaded. Then it will
call C<GetDoc> function.

=item RunJS ( $script )

Runs the specified JavaScript code in the browser and waits for 1 second.

=item PopUp ( \$code )

Opens popup window by calling the code and redirects all other functions
to that popup.

See chapter L<PopUp Handling|PopUp Handling> for more info.

=item Wait ( [$seconds] )

Waits for specified time (default 1 second) while calling C<< Win32::OLE->SpinMessageLoop >>
to let IE to process the requests.

=item Refresh ( )

Refreshes the currently loaded page and calls C<GetDoc> function.

=item GetDoc ( )

Loads C<$Doc> and C<$Body> global variables.

=item GetAll ( $tagName [, \$code [, $index ]] )

Returns the list of objects of specified tag name or N-th object from the
list if $index is specified. The first element in the list has indx 0. The
list is composed from C<< document->all >> collection.

If you specify a code ref it will be used to limit the list in the same way
grep does it.

  # get 3rd span element with class=label
  my $label = GetAll('SPAN', sub {$_->{className} eq 'label'}, 2 );


=item GetElement ( $id )

Returns the object of specified ID by calling C<< document->getElementById() >>.

=back

=head2 Capturing functions

These function works like other C<Capture*(...)> functions from L<Win32::Screenshot|Win32::Screenshot> package.

=over 8

=item CaptureArea ( $px, $py, $w, $h )

Capture selected area on page. The coordinates are relative to the tole
left corner of the page. If the area is larger than the window the function
will capture the whole area step by step by scrolling the window content
(in all directions) and will return a complete image of the page.

=item CaptureBrowser ( )

Captures whole Internet Explorer window including the window title and border.

=item CaptureElement ( $id | $element [, \%args ] )

Captures the element specified by its ID or passed as reference to the
element object. The function will scroll the page content to show the top
of the element and scroll down and right step by step to get whole area
occupied by the object.

It can capture a small surrounding area around the element specified
by %args hash or C<$CaptureBorder> global variable. It recognizes paramters
C<border>, C<border-left>, C<border-top>, C<border-right> and C<border-bottom>.
The priority is C<border-*> -> C<border> -> C<$CaptureBorder>.

=item CaptureElements ( $id1 | $element1, $id2 | $element2, ... [, \%args ] )

Captures all selected elements. The function captures the outter bounding
box of all elements in the same way as CaptureElement captures only one.

=item CapturePage ( )

Captures whole page currently loaded in the Internet Explorer window. Only the page content will
be captured - no window, no scrollbars. If the page is smaller than the window only the occupied
part of the window will be captured. If the page is longer (scrollbars are active) the function
will capture the whole page step by step by scrolling the window content (in all directions) and
will return a complete image of the page.

=item CaptureRows ( $id | $element , @rows )

Captures the table specified by its ID or passed as reference to the
table object. The function will scroll the page content to show the top
of the table and scroll down and right step by step to get whole area
occupied by the table. Than it will chop unwanted rows from the image and it will
return the image of table containing only selected rows. Rows are numbered from zero.

It can capture a small surrounding area around the element specified
by C<$CaptureBorder> global variable.

=item CaptureThumbshot ( )

Resizes the window to set the client area to 800x600 pixels. Captures the client
area where the page is rendered. No scrolling is done.

=back

=head2 Global variables

=over 8

=item $CaptureBorder

The function C<CaptureElement> is able to capture the element and
a small area around it. How much of surrounding space will be captured
is defined by C<$CaptureBorder>. It is not recommended to capture more
than 3-5 pixels because parts of other elements could be captured
as well. Default border is 1 pixel wide.

=item $IE

The function C<StartIE> will create a new Internet Explorer process
and its Win32::OLE reference will be stored in this variable. See the
MSDN documentation for InternetExplorer object.

=item $Doc

The function C<GetDoc> will assign C<< $IE->{Document} >> into this
variable. See the MSDN documentation for Document object.

=item $Body

The function C<GetDoc> will assign C<< $IE->{Document}->{Body} >> into this
variable. See the MSDN documentation for BODY object.

=item $HWND_IE

The function C<StartIE> will assign the handle of the Internet Explorer window
into this variable from C<< $IE->{HWND} >>.

=item $HWND_Browser

The function C<StartIE> will try to find the largest child window and
suppose that this is the area where is the page rendered. It is used to
convert page coordinates to screen coordinates.

=item $PopUp_IE, $PopUp_HWND_IE, $PopUp_HWND_Browser

These variables has similar meaning as their namesakes but are related
to the popup window. If $PopUp_IE is defined than all functions use it
instead of $IE.

=back

=head1 TIPS

=over 8

=item Calling JavaScript functions

If you need to call a JavaScript function to get to anoter page or submit the form
you can just use Navigate. Note that C<Win32::CaptureIE::Navigate()> waits for page
load complete but C<< $IE->Navigate() >> do not.

  Navigate("javascript:form_submit('approve');");

If you need to wait for a while after the call use C<RunJS()> function.

  RunJS("form_del();");

=item Capturing only a part of element

To capture only a part of the element set the border to negative values. But do not
overdraw it, you still have to have something to capture.

  # capture messages between the toolbar and the 1st fieldset
  $img = CaptureElements('toolbar', GetAll('FIELDSET', 0),
    { border_top => -12, border_bottom => -64 }
  );

=item Process execution suspending

If you need to make the program sleep for a while do not use in-build C<sleep()> function.
Use C<Wait> instead. It will periodically call C<< Win32::OLE->SpinMessageLoop >>
to process any signals comming from OLE interface.

  # wait 2 seconds
  Wait( 2 );

=back

=head2 PopUp Handling

The package can handle capturing of popup window. Only one at a time and you have to spawn the window
by using C<PopUp> function. Any new window creation requests are denied by default! You shouldn't be
bothered by popups you don't want.

  # get an element named 'clickme'
  my $button = GetElement('clickme');

  # create the popup window by clicking on the 'Click Me' button
  PopUp { $button->click(); };

  # let's capture the content of the popup window
  CapturePage()->Write('popup.png');

  # let's capture the element on the popup window
  CaptureElement('inputline')->Write('popup-inline.png');

  # let's do any other business with the popup window
  ...

  # done, shut it
  RunJS("window.close();");

  # capturing is redirected back to the main window
  CapturePage()->Write('main.png');

=head1 SEE ALSO

=over 8

=item MSDN

http://msdn.microsoft.com/library You can find there the description
of InternetExplorer object and DOM.

=item L<Win32::Screenshot|Win32::Screenshot>

This package is used for capturing screenshots. Use its post-processing
features for automatic screenshot modification.

=back

=head1 AUTHOR

P.Smejkal, E<lt>petr.smejkal@seznam.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by P.Smejkal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
