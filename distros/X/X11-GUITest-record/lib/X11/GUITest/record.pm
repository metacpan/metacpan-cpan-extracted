=head1 NAME

B<X11::GUITest::record> - Perl implementation of the X11 record extension.

=head1 VERSION

0.15

=head1 DESCRIPTION

This Perl package uses the X11 record extension to capture events 
(from X-server) and  requests (from X-client). Futher it is 
possible to capture mostly all client/server
communitation (partially implemented)

For a full description of the extension see the 
Record Extension Protocol Specification of the 
X Consortium Standard (Version 11, Release 6.4)

=head1 FEATURES

 - Recording mouse movements
 - Recording key presses and key releases
 - Getting information about created and closed windows
 - Getting text from windows (if it is a Poly8 request)

=head1 SYNOPSIS

  use X11::GUITest::record qw /:ALL :CONST/;
  
  # Query version of the record extension
  my $VERSION_EXT = QueryVersion;
 
  print "Record extension version: $VERSION_EXT\n";
  
  # Sets the record context to capture key presses and mouse movements
  SetRecordContext(KeyPress, MotionNotify);

  # Begin record
  EnableRecordContext();

  print "Recording..............\n";
  sleep (5);

  # Stop record
  DisableRecordContext();

  while ($data = GetRecordInfo())
    {
     print "Record: ". $data ->{TxtType} ." ";
     print "X:". $data ->{X} . " Y:". $data ->{Y} 
     		if  ($data ->{TxtType} eq "MotionNotify");

     print "Key:". $data ->{Key} 
     		if  ($data ->{TxtType} eq "KeyPress");
     print "\n";

    }

=head1 DEPENDENCIES

To use this module please activate the record extension in the 
config of the X-Server:

  - under selection "Module"
       Load         "record"

Please make sure that the display variable is set.

=cut

package X11::GUITest::record;

use strict;
use warnings;
use vars qw(%REQUEST);

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: Do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use .. ':ALL';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'ALL' =>
                                [ qw(
                                EnableRecordContext
                                DisableRecordContext
                                QueryVersion
                                GetRecordInfo
                                GetAllRecordInfo
                                SetDeliveredEvents
                                SetDeviceEvents
                                SetErrors
                                SetCoreRequests
                                SetCoreReplies
                                SetExtRequestsMajor
                                SetExtRequestsMinor
                                SetExtRepliesMajor
                                SetExtRepliesMinor
                                SetRecordDEBUG
                                ConvRequest2Text
                                ConvEvent2Text
                                AddRecordRange
                                SetRecordContext)
                                ],
                     'CONST' => [ qw(
                                Event
                                Request
                                KeyPress
                                KeyRelease
                                ButtonPress
                                ButtonRelease
                                MotionNotify
                                EnterNotify
                                LeaveNotify
                                FocusIn
                                FocusOut
                                KeymapNotify
                                Expose
                                GraphicsExpose
                                NoExpose
                                VisibilityNotify
                                CreateNotify
                                DestroyNotify
                                UnmapNotify
                                MapNotify
                                MapRequest
                                ReparentNotify
                                ConfigureNotify
                                ConfigureRequest
                                GravityNotify
                                ResizeRequest
                                CirculateNotify
                                CirculateRequest
                                PropertyNotify
                                SelectionClear
                                SelectionRequest
                                SelectionNotify
                                ColormapNotify
                                ClientMessage
                                MappingNotify
                                X_CreateWindow
                                X_ChangeWindowAttributes
                                X_GetWindowAttributes
                                X_DestroyWindow
                                X_DestroySubwindows
                                X_ChangeSaveSet
                                X_ReparentWindow
                                X_MapWindow
                                X_MapSubwindows
                                X_UnmapWindow
                                X_UnmapSubwindows
                                X_ConfigureWindow
                                X_CirculateWindow
                                X_GetGeometry
                                X_QueryTree
                                X_InternAtom
                                X_GetAtomName
                                X_ChangeProperty
                                X_DeleteProperty
                                X_GetProperty
                                X_ListProperties
                                X_SetSelectionOwner
                                X_GetSelectionOwner
                                X_ConvertSelection
                                X_SendEvent
                                X_GrabPointer
                                X_UngrabPointer
                                X_GrabButton
                                X_UngrabButton
                                X_ChangeActivePointerGrab
                                X_GrabKeyboard
                                X_UngrabKeyboard
                                X_GrabKey
                                X_UngrabKey
                                X_AllowEvents
                                X_GrabServer
                                X_UngrabServer
                                X_QueryPointer
                                X_GetMotionEvents
                                X_TranslateCoords
                                X_WarpPointer
                                X_SetInputFocus
                                X_GetInputFocus
                                X_QueryKeymap
                                X_OpenFont
                                X_CloseFont
                                X_QueryFont
                                X_QueryTextExtents
                                X_ListFonts
                                X_ListFontsWithInfo
                                X_SetFontPath
                                X_GetFontPath
                                X_CreatePixmap
                                X_FreePixmap
                                X_CreateGC
                                X_ChangeGC
                                X_CopyGC
                                X_SetDashes
                                X_SetClipRectangles
                                X_FreeGC
                                X_ClearArea
                                X_CopyArea
                                X_CopyPlane
                                X_PolyPoint
                                X_PolyLine
                                X_PolySegment
                                X_PolyRectangle
                                X_PolyArc
                                X_FillPoly
                                X_PolyFillRectangle
                                X_PolyFillArc
                                X_PutImage
                                X_GetImage
                                X_PolyText8
                                X_PolyText16
                                X_ImageText8
                                X_ImageText16
                                X_CreateColormap
                                X_FreeColormap
                                X_CopyColormapAndFree
                                X_InstallColormap
                                X_UninstallColormap
                                X_ListInstalledColormaps
                                X_AllocColor
                                X_AllocNamedColor
                                X_AllocColorCells
                                X_AllocColorPlanes
                                X_FreeColors
                                X_StoreColors
                                X_StoreNamedColor
                                X_QueryColors
                                X_LookupColor
                                X_CreateCursor
                                X_CreateGlyphCursor
                                X_FreeCursor
                                X_RecolorCursor
                                X_QueryBestSize
                                X_QueryExtension
                                X_ListExtensions
                                X_ChangeKeyboardMapping
                                X_GetKeyboardMapping
                                X_ChangeKeyboardControl
                                X_GetKeyboardControl
                                X_Bell
                                X_ChangePointerControl
                                X_GetPointerControl
                                X_SetScreenSaver
                                X_GetScreenSaver
                                X_ChangeHosts
                                X_ListHosts
                                X_SetAccessControl
                                X_SetCloseDownMode
                                X_KillClient
                                X_RotateProperties
                                X_ForceScreenSaver
                                X_SetPointerMapping
                                X_GetPointerMapping
                                X_SetModifierMapping
                                X_GetModifierMapping
                                X_NoOperation)
                                ],
                    );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'ALL'} }, @{ $EXPORT_TAGS{'CONST'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.15';

bootstrap X11::GUITest::record $VERSION;

our $AUTOLOAD;

# Preloaded methods go here

# Defined request types

# Signal handling
$SIG{INT} = sub {exit 0;};  # Catches term signal


my $DEBUG=0;

my @Records = ();

=head1 FUNCTIONS

Parameters enclosed within [] are optional.

=cut

# Category Constants
sub Event()                     { 0;}
sub Request()                   { 1;}
# Returns (Category, Type)

# Event Constants

sub KeyPress()                  { (0,2);}
sub KeyRelease()                { (0,3);}
sub ButtonPress()               { (0,4);}
sub ButtonRelease()             { (0,5);}
sub MotionNotify()              { (0,6);}
sub EnterNotify()               { (0,7);}
sub LeaveNotify()               { (0,8);}
sub FocusIn()                   { (0,9);}
sub FocusOut()                  { (0,10);}
sub KeymapNotify()              { (0,11);}
sub Expose()                    { (0,12);}
sub GraphicsExpose()            { (0,13);} 
sub NoExpose()                  { (0,14);}
sub VisibilityNotify()          { (0,15);}
sub CreateNotify()              { (0,16);}           
sub DestroyNotify()             { (0,17);}
sub UnmapNotify()               { (0,18);}
sub MapNotify()                 { (0,19);}
sub MapRequest()                { (0,20);}
sub ReparentNotify()            { (0,21);}
sub ConfigureNotify()           { (0,22);}
sub ConfigureRequest()          { (0,23);}
sub GravityNotify()             { (0,24);}
sub ResizeRequest()             { (0,25);}
sub CirculateNotify()           { (0,26);}
sub CirculateRequest()          { (0,27);}
sub PropertyNotify()            { (0,28);}
sub SelectionClear()            { (0,29);}
sub SelectionRequest()          { (0,30);}
sub SelectionNotify()           { (0,31);}
sub ColormapNotify()            { (0,32);}
sub ClientMessage()             { (0,33);}
sub MappingNotify()             { (0,34);}

# Request Constants

sub X_CreateWindow()            { (1,1);}
sub X_ChangeWindowAttributes()  { (1,2);}
sub X_GetWindowAttributes()     { (0,3);}
sub X_DestroyWindow()           { (1,4);}
sub X_DestroySubwindows()       { (1,5);}
sub X_ChangeSaveSet()           { (1,6);}
sub X_ReparentWindow()          { (1,7);}
sub X_MapWindow()               { (1,8);}
sub X_MapSubwindows()           { (1,9);}
sub X_UnmapWindow()             { (1,10);}
sub X_UnmapSubwindows()         { (1,11);}
sub X_ConfigureWindow()         { (1,12);}
sub X_CirculateWindow()         { (1,13);}
sub X_GetGeometry()             { (1,14);}
sub X_QueryTree()               { (1,15);}
sub X_InternAtom()              { (1,16);}
sub X_GetAtomName()             { (1,17);}
sub X_ChangeProperty()          { (1,18);}
sub X_DeleteProperty()          { (1,19);}
sub X_GetProperty()             { (1,20);}
sub X_ListProperties()          { (1,21);}
sub X_SetSelectionOwner()       { (1,22);}
sub X_GetSelectionOwner()       { (1,23);}
sub X_ConvertSelection()        { (1,24);}
sub X_SendEvent()               { (1,25);}
sub X_GrabPointer()             { (1,26);}
sub X_UngrabPointer()           { (1,27);}
sub X_GrabButton()              { (1,28);}
sub X_UngrabButton()            { (1,29);}
sub X_ChangeActivePointerGrab() { (1,30);}
sub X_GrabKeyboard()            { (1,31);}
sub X_UngrabKeyboard()          { (1,32);}
sub X_GrabKey()                 { (1,33);}
sub X_UngrabKey()               { (1,34);}
sub X_AllowEvents()             { (1,35);}
sub X_GrabServer()              { (1,36);}
sub X_UngrabServer()            { (1,37);}
sub X_QueryPointer()  	        { (1,38);}
sub X_GetMotionEvents()         { (1,39);}
sub X_TranslateCoords()         { (1,40);}
sub X_WarpPointer()             { (1,41);}
sub X_SetInputFocus()           { (1,42);}
sub X_GetInputFocus()           { (1,43);}
sub X_QueryKeymap()             { (1,44);}
sub X_OpenFont()  	        { (1,45);}
sub X_CloseFont()  	        { (1,46);}
sub X_QueryFont()               { (1,47);}
sub X_QueryTextExtents()        { (1,48);}
sub X_ListFonts()  	        { (1,49);}
sub X_ListFontsWithInfo()       { (1,50);}
sub X_SetFontPath()  	        { (1,51);}
sub X_GetFontPath()             { (1,52);}
sub X_CreatePixmap() 	        { (1,53);}
sub X_FreePixmap()              { (1,54);}
sub X_CreateGC()                { (1,55);}
sub X_ChangeGC()                { (1,56);}
sub X_CopyGC()                  { (1,57);}
sub X_SetDashes()               { (1,58);}
sub X_SetClipRectangles()       { (1,59);}
sub X_FreeGC()                  { (1,60);}
sub X_ClearArea()               { (1,61);}
sub X_CopyArea()                { (1,62);}
sub X_CopyPlane()               { (1,63);}
sub X_PolyPoint()               { (1,64);}
sub X_PolyLine()                { (1,65);}
sub X_PolySegment()             { (1,66);}
sub X_PolyRectangle()           { (1,67);}
sub X_PolyArc()                 { (1,68);}
sub X_FillPoly()                { (1,69);}
sub X_PolyFillRectangle()       { (1,70);}
sub X_PolyFillArc()             { (1,71);}
sub X_PutImage()                { (1,72);}
sub X_GetImage()                { (1,73);}
sub X_PolyText8()               { (1,74);}
sub X_PolyText16()              { (1,75);}
sub X_ImageText8()              { (1,76);}
sub X_ImageText16()             { (1,77);}
sub X_CreateColormap()          { (1,78);}
sub X_FreeColormap()            { (1,79);}
sub X_CopyColormapAndFree()     { (1,80);}
sub X_InstallColormap()         { (1,81);}
sub X_UninstallColormap()       { (1,82);}
sub X_ListInstalledColormaps()  { (1,83);}
sub X_AllocColor()              { (1,84);}
sub X_AllocNamedColor()         { (1,85);}
sub X_AllocColorCells()         { (1,86);}
sub X_AllocColorPlanes()        { (1,87);}
sub X_FreeColors()              { (1,88);}
sub X_StoreColors()             { (1,89);}
sub X_StoreNamedColor()         { (1,90);}
sub X_QueryColors()             { (1,91);}
sub X_LookupColor()             { (1,92);}
sub X_CreateCursor()            { (1,93);}
sub X_CreateGlyphCursor()       { (1,94);}
sub X_FreeCursor()              { (1,95);}
sub X_RecolorCursor()           { (1,96);}
sub X_QueryBestSize()           { (1,97);}
sub X_QueryExtension()          { (1,98);}
sub X_ListExtensions()          { (1,99);}
sub X_ChangeKeyboardMapping()   { (1,100);}
sub X_GetKeyboardMapping()      { (1,101);}
sub X_ChangeKeyboardControl()   { (1,102);}
sub X_GetKeyboardControl()      { (1,103);}
sub X_Bell()  	                { (1,104);}
sub X_ChangePointerControl()    { (1,105);}
sub X_GetPointerControl()       { (1,106);}
sub X_SetScreenSaver() 	        { (1,107);}
sub X_GetScreenSaver()          { (1,108);}
sub X_ChangeHosts()             { (1,109);}
sub X_ListHosts()               { (1,110);}
sub X_SetAccessControl()        { (1,111);}
sub X_SetCloseDownMode()        { (1,112);}
sub X_KillClient()  	        { (1,113);}
sub X_RotateProperties()        { (1,114);}
sub X_ForceScreenSaver()        { (1,115);}
sub X_SetPointerMapping()       { (1,116);}
sub X_GetPointerMapping()       { (1,117);}
sub X_SetModifierMapping()      { (1,118);}
sub X_GetModifierMapping()      { (1,119);}
sub X_NoOperation()             { (1,127);}
        
sub INIT 
{
	unless ($DEBUG == 0) {SetDEBUG($DEBUG);}
	print "DBG: Init Module ".__PACKAGE__."\n" if $DEBUG;
	InitDisplay();
        InitRecordData();
}

sub END 
{
	print "DBG: DeInit Module ".__PACKAGE__."\n" if $DEBUG;
	DisableRecordContext();
        DeInitRecordData();
	DeInitDisplay();
}

sub ConvType2Text
    {
    my ($cat, $type) = @_;
    if ($cat == Event) 
	{
	return ConvEvent2Text($type)
	}
    elsif ($cat == Request)
	{
	return ConvRequest2Text($type)
	}


    }

sub CompConstant
    {
    my ($cat, $type, $con_cat, $con_type) = @_;
    if ($type == $con_type  && $cat == $con_cat)
        {
        return 1;
        }
    return 0;
    }



sub Callback
    {
    my ($cat, $type, $time, $x, $y, @args ) = @_;
    
    #Text
    
    if (CompConstant ($cat,$type,X_PolyText8)) 
       {
       my $Text = shift @args;
    
     push (@Records,{"Category" => $cat,
                     "Type"     => $type,
		     "Time"	=> $time,
                     "TxtType"  => ConvType2Text($cat, $type),
                     "X"        => $x,
                     "Y"        => $y,
                     "Text"     => $Text
                    });
       }
    elsif (CompConstant($cat, $type, KeyPress) || CompConstant($cat, $type, KeyRelease) ||
           CompConstant($cat, $type, ButtonPress) || CompConstant($cat, $type, ButtonRelease))
        {
        my $Key  = shift @args;
        push (@Records,{"Category" => $cat,
                        "Type"     => $type,
			"Time"     => $time,
                        "TxtType"  => ConvType2Text($cat, $type),
                        "X"        => $x,
                        "Y"	   => $y,
                        "Key"      => $Key
                        });
        
        }
    else
    {
     my $Win  = shift @args;
     my $PWin = shift @args;
     push (@Records,{"Category" => $cat,
                     "Type"     => $type,
		     "Time"	=> $time,
                     "TxtType"  => ConvType2Text($cat, $type),
                     "X"        => $x,
                     "Y"        => $y,
                     "WinID"    => $Win,
                     "PWin"     => $PWin,
                     });
        }
    
    }


sub SetRecordDEBUG
    {
    my $level = shift;
    $level = 1 unless (defined ($level));
    $DEBUG = $level;
    CSetDEBUG($level);
    }

=over 8

=item SetRecordContext category, type, [category, type..]

Specifies what the context has to record.
It is possible to use the constant functions as:

SetRecordContext(KeyPress, KeyRelease, MotionNotify);

It is only possible to use DeliverdEvents and CoreRequests. To use other
please choose one of the low level functions like SetDeviceEvents.

Some implemented events/requests are:

    - KeyPress 
    - KeyRelease
    - ButtonPress
    - ButtonRelease
    - MotionNotify
    - X_CreateWindow
    - X_DestroyWindow
    - X_PolyText8

=back

=cut

sub SetRecordContext
    {
    my @info = @_;
    my $cat  = undef;
    my $type = undef;
    foreach (@info)
        {
        unless (defined ($cat))
            {
            $cat = $_;
            }
        else
            {
            $type = $_;
            
            SetDeliveredEvents ($type,$type ) if ($cat == Event);
            SetCoreRequests    ($type,$type ) if ($cat == Request);
            AddRecordRange();
            
            
            $cat = undef;
            }
        }
    }


=over 8

=item GetRecordInfo 

To get one single record information from record queue.

This function will return 0 if the end of the queue is reached.
Otherwise it will return a hash with the following values:

    - {"Category"}:     Category of the record (0 for event
                                                1 for request)
                                             
    - {"Type"}          Type of the record in digits
    - {"TxtType"  }     Type of the record in text
    - {"Time"}          Server timestamp
   [- {"X"}             X coordinte]
   [- {"Y"}             Y coordinte]
   [- {"Text"}          Text if it is a X_Polytext8]
   [- {"Key"}           Key if it is a key press or key release event]
   [- {"WinID"}         WindowID]
   [- {"PWinID"}        Parent WindowID]
   
   

=back

=cut

sub GetRecordInfo
    {
    my $ret=0;
    # Ok there are some current data in array
    $ret = @Records;
    unless ($ret == 0  ) { return shift @Records;}

    $ret = CGetRecordInfo();
    unless ($ret == 0){return shift @Records; }
    return 0;

    }
    



=over 8

=item GetAllRecordInfo

Similar to GetRecordInfo but returns an array of hashes with all record information.

=back

=cut

sub GetAllRecordInfo
	{
	my @data;
	

	while (my $ret = CGetRecordInfo())
		{
		unless ($ret == 0){push (@data, shift @Records); }
		}

	while (@Records)
                {
                push (@data, shift @Records);
                }



	return \@data;
	}

=over 8

=item DisableRecordContext

Disables the record context. 

=back

=cut

sub DisableRecordContext
	{

	@Records =();	
	CDisableRecordContext();
	}


1;
