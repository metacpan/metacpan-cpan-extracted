package Win32::GUI::HyperLink;

use warnings;
use strict;

use Win32::GUI 1.02 qw();
  # 1.02 required for LoadCursor, ShellExecute and GetCapture
use base qw(Win32::GUI::Label);

=head1 NAME

Win32::GUI::HyperLink - A Win32::GUI Hyperlink control

=cut

our $VERSION = 0.14;

=head1 SYNOPSIS

Win32::GUI::HyperLink is a Win32::GUI::Label that
acts as a clickable hyperlink.  By default
it has a 'hand' Cursor, is drawn in blue text rather than black and the
text is dynamically underlined when the mouse moves over the text.
The Label can be clicked to launch a hyperlink, and supports onMouseIn
and onMouseOut events to allow (for example) the link url to be
displayed while the mouse is over the link.

    use Win32::GUI::HyperLink;

    my $hyperlink = Win32::GUI::HyperLink->new($parent_window, %options);

    my $hyperlink = $parent_window->AddHyperLink(%options);

    $url = $hyperlink->Url();

    $hyperlink->Url($url);

    $hyperlink->Launch();

Win32::GUI::HyperLink is a sub-class of Win32::GUI::Label, and so
supports all the options and methods of Win32::GUI::Label.  See
the L<Win32::GUI::Label> documentation for further information.
Anywhere that behaviour differs is highlighted below.

See the F<HyperLinkDemo.pl> script for examples of using the
functionality. This demo script can be found in the F<.../Win32/GUI/demos/HyperLink>
directory beneath the installation directory.

=cut

######################################################################
# Some useful constants
######################################################################
# Don't "use constant", as it fails with earlier versions of perl
sub IDC_HAND        () {32649};
sub WM_SETFONT      () {48};
sub SW_SHOWNORMAL   () {1};
sub WM_MOUSEMOVE    () {512};
sub WM_LBUTTONDOWN  () {513};

sub UNDERLINE_NONE  () {0};
sub UNDERLINE_HOVER () {1};
sub UNDERLINE_ALWAYS() {2};

######################################################################
# package global storage
######################################################################
# If we create a cursor object, then store it here so that
# we only create one cursor object regardless of how many HyperLink
# objects we have.  See function _get_hand_cursor().
our $_hand_cursor = undef;

######################################################################
# Private callback functions
######################################################################

######################################################################
# Private _mouse_move()
# MouseMove event hook handler for label
######################################################################
sub _mouse_move
{
  my ($self, $wparam, $lparam, $type, $msgcode) = @_;

  return unless $type == 0;
  return unless $msgcode == WM_MOUSEMOVE;

  my $cxM = $lparam & 0xFFFF;         # in client co-ordinates
  my $cyM = ($lparam >> 16) & 0xFFFF; # in client co-ordinates
  # If we have captured the mouse, they can be negative, so
  # convert to signed values
  if($cxM > 32767) { $cxM -= 65536; }
  if($cyM > 32767) { $cyM -= 65536; }

  my $hWnd = $self->{-handle};

  # Strategy:
  # While we're getting mouse events, the cursor is either in our window
  # or we have captured the mouse.
  # If we get mouse events, and we haven't got the capture, then the
  # mouse has moved into our window, so we change the font to underline
  # and set capture.
  # If we get mouse events and we have capture, then we check to see if
  # the mouse is over our control. If it is we do nothing;  If not,
  # then we relase capture and set the text back to normal

  # Based on ideas and code from:
  # http://www.codeguru.com/Cpp/controls/staticctrl/article.php/c5803/ 
  
  my $getcapture = Win32::GUI::GetCapture();

  if($getcapture != $hWnd)
  {
    ### MouseIn
    # Set Mouse Capture to our window
    $self->SetCapture();

    # if we have an underlined font set it and force a redraw
    $self->SendMessage(WM_SETFONT, $self->{_hUfont}, 1) if($self->{_hUfont});

    # Call the MouseIn callback
    # NEM
    if( ref($self->{-onMouseIn}) eq 'CODE' ) {
      &{$self->{-onMouseIn}}($self, $cxM, $cyM);
    }
    # OEM
    if( $self->{-name} ) {
      my $callback = "main::" . $self->{-name} . "_MouseIn";
      if(defined(&$callback)) {
        my $ref = \&$callback;
        &{$ref}($self, $cxM, $cyM);
      }
    }
  } else {
    my ($clW, $ctW, $crW, $cbW) = $self->GetClientRect();

    # If pointer is not in window
    if ( ($cxM < $clW) || ($cxM > $crW) ||
         ($cyM < $ctW) || ($cyM > $cbW) )
    {
      ### onMouseOut
      # if we have a normal font, set it and force a redraw
      $self->SendMessage(WM_SETFONT, $self->{_hNfont}, 1) if($self->{_hNfont});

      # Call the onMouseOut callback
      # NEM
      if( ref($self->{-onMouseOut}) eq 'CODE' ) {
        &{$self->{-onMouseOut}}($self, $cxM, $cyM);
      }
      # OEM
      if( $self->{-name} ) {
        my $callback = "main::" . $self->{-name} . "_MouseOut";
        if(defined(&$callback)) {
          my $ref = \&$callback;
          &{$ref}($self, $cxM, $cyM);
        }
      }

      # Release capture
      $self->ReleaseCapture();
    }
  }

  return; # no return value, so not to affect normal operation
};

######################################################################
# Private _click()
# Left button down event hook handler for label
# processes Clicks on the label 
######################################################################
sub _click
{
  my ($self, $wparam, $lparam, $type, $msgcode) = @_;

  return unless $type == 0;
  return unless $msgcode == WM_LBUTTONDOWN;

  $self->Launch();
  return; # no return value, so not to affect normal operation
};

=head1 METHODS

=cut

######################################################################
# Public new()
# constructor
######################################################################

=head2 new

  $hyperlink = Win32::GUI::HyperLink->new($parent, %options);

  $hyperlink = $window->AddHyperLink(%options);

Takes any options that L<Win32::GUI::Label> does with the following changes:

=over

=item B<-url>

The Link to launch. e.g. C<< -url => "http://www.perl.com/", >>
If not supplied will default to B<-text>.

=item B<-onMouseIn>

A code reference to call when the mouse moves over the link text.

=item B<-onMouseOut>

A code reference to call when the mouse moves off the link text.

=item B<-underline>

Controls how the text behaves as the mouse moves over and off the link text.
Possible values are: B<0> Text is not underlined. B<1> Text is underlined when
the mouse is over the link text.  This is the default.  B<2> Text is always
underlined.

=back

=head3 Differences to Win32::GUI::Label

If B<-text> is not supplied, then B<-text> defaults to B<-url>.
(If neither B<-url> nor B<-text> are supplied, then you have an empty label!)

B<-notify> is always set  to B<1>.

If a B<-onClick> handler is supplied, then the default action of launching
the link when the link is clicked is disabled.  See L</Launch> method
for how to get this functionality from you own Click handler.

=head3 Original/Old Event Model (OEM)

Win32::GUI::HyperLink will call the subroutines
C<< main::NAME_MouseIn >> and C<< main::NAME_MouseOut >>
, if they exist, when the mouse moves over the link,
and when the mouse moves out oif the link respectively, where NAME is
the name of the label, set with the B<-name> option.

=cut

sub new
{
  my $this = shift;
  my $class = ref($this) || $this;

  my $parentWin = shift;

  my %options = @_; # convert options to hash for easy manipulation;

  # somewhere to temporarily put options that we'll want
  # to store in the object once we have created it.
  my %storage;

  # Parse the options, and remove the non-standard Win32::GUI::Label
  # options (although I suspect that it wouldn't complain). Add defaults
  # for others if not provided
  
  #text and url
  $options{-url} = $options{-text} if not exists $options{-url};
  $options{-text} = $options{-url} if not exists $options{-text};
  if(exists $options{-url} ) {
    $storage{-url} = $options{-url};
    delete $options{-url};
  }
  $storage{-url} = "" if not defined $storage{-url};
  $options{-text} = "" if not defined $options{-text};

  # colour
  $options{-foreground} = [0,0,255] if not exists $options{-foreground};  # default is blue

  # cursor
  if(not exists $options{-cursor} ) {
    # Try to load the window standard hand cursor
    $options{-cursor} = Win32::GUI::LoadCursor(IDC_HAND);
    delete $options{-cursor} if not defined $options{-cursor};
  }

  # underline style
  my $underline = UNDERLINE_HOVER;   # default is to underline when hovered over the link
  if(exists $options{-underline} ) {
    $underline = $options{-underline};
    delete $options{-underline};
  }

  # we need -notify, so set it
  $options{-notify} = 1;
  
  # onMouseIn/Out: remember onMouesIn and onMouseOut refernces
  # for us to call in our onMouseMove callback.
  if(exists $options{-onMouseIn} ) {
    $storage{-onMouseIn} = $options{-onMouseIn};
    delete $options{-onMouseIn};
  }
  if(exists $options{-onMouseOut} ) {
    $storage{-onMouseOut} = $options{-onMouseOut};
    delete $options{-onMouseOut};
  }

  ################################################
  # Call the parent constructor.
  # The return value is already a reference to 
  # a hash bless(ed) into the right class, so no
  # additional bless() is required.
  my $self = $class->SUPER::new($parentWin, %options);

  # Store additional data in the label object's hash so that we
  # have access to it in all callbacks
  foreach my $key (keys(%storage)) {
    $self->{$key} = $storage{$key};
  }

  # Set up our callbacks using Hook().  This done in preference to
  # using -onMouseMove and -onClick to allow it to work with both
  # OEM and NEM
  # Use WM_LBUTTONDOWN rather than NM_CLICK, as hooking WM_NOTIFY messages
  # is broken in Win32::GUI V1.0 and earlier
  $self->Hook(WM_LBUTTONDOWN, \&_click) if not exists $options{-onClick};
  $self->Hook(WM_MOUSEMOVE,   \&_mouse_move);

  # If underline == UNDERLINE_NONE(0) do nothing;
  # otherwise make a copy of the label font with underline
  # If underline == UNDERLINE_ALWAYS(2) set the label font to underlined
  # If underline == UNDERLINE_HOVER(1) put handles to both fonts into the
  # object hash, for use in the MouseMove hook
  if($underline != UNDERLINE_NONE) {
    my $hfont = $self->GetFont(); # handle to normal font
    my %fontOpts = Win32::GUI::Font::Info($hfont);
    $fontOpts{-underline} = 1;
    my $ufont = new Win32::GUI::Font (%fontOpts);
    if($underline == UNDERLINE_HOVER) {
      # Store the handles in the label hash for use in the callbacks
      $self->{_hNfont} = $hfont;
      $self->{_hUfont} = $ufont->{-handle};
    } elsif($underline == UNDERLINE_ALWAYS) {
      $self->SetFont($ufont);
    }
    # Store a reference to the new (underlined) font in the
    # label hash, to prevent it being destroyed before the
    # label.  Typically at the end of this
    # block, when $ufont goes out of scope, the perl GC would
    # call the Win32::GUI::Font DESTROY for the object, but
    # so long as the reference exists it will not get destroyed.
    # It will get destroyed when the last reference to this
    # HyperLink object is destroyed.
    $self->{_u_font_ref} = \$ufont;
  }

  return $self;
}

######################################################################
# Public Win32::GUI::Window::AddHyperLink()
# Alternate constructor in the Win32::GUI $window->AddXX style
######################################################################
sub Win32::GUI::Window::AddHyperLink
{
  return Win32::GUI::HyperLink->new(@_);
}

######################################################################
# Public Url()
######################################################################

=head2 Url

  $url = $hyperlink->Url();

Get the value of the current link.

  $hyperlink->Url($url);

Set the value of the current link.

=cut

sub Url
{
  $_[0]->{-url} = $_[1] if defined $_[1];
  return $_[0]->{-url};
}

######################################################################
# Public Launch()
######################################################################

=head2 Launch

  $hyperlink->Launch();

Launches the link url in the user's default browser. This method is supplied
to make it easy to call the default Click functionality from your
own Click Handler.  If you pass a C<-onClick> option to the constructor
then the default handler is disabled.  This allows you to turn off
the default click behaviour by passing a reference to an empty 
subroutine:

  -onClick => sub {},

If you have your own Click handler, then the default behaviour can be restored
by calling C<< $self->Launch() >> from within your handler.

Returns C<1> on Success, C<0> on failure (and C<carp>s a warning),
and C<undef> if there is no link url to try to launch.

C<< Launch() >> passes the value of the link url to the operating
system, which launches the link in the user's default browser.

The link is passed to the Windows ShellExecute
function, and so
any valid executable program
or document that has a file association should be successsfully
started.

=cut

sub Launch
{
  my $self = shift;
  my $retval = undef;

  # Only try to open the link if it is actually defined
  if($self->Url()) {
    $retval = 1;
    my $exitval = $self->ShellExecute("",$self->Url(),"","",SW_SHOWNORMAL);
    if ($exitval <= 32) {
        require Carp;
        Carp::carp "Failed opening ".$self->Url()." ShellExecute($exitval) $^E";
        $retval = 0;
    }
  }

  return $retval;
}

=head1 AUTHOR

Robert May, C<< <robertmay@cpan.org> >>

=head1 REQUIRES

L<Win32::GUI> v1.02 or later.

=head1 COMPATABILITY

This module should be backwards compatable with all prior
Win32::GUI::HyperLink releases, including the original
(v0.02) release.  If you find that it is not, please
inform the Author.

=head1 EXAMPLES

  use strict;
  use warnings;

  use Win32::GUI 1.02;
  use Win32::GUI::HyperLink;

  # A window
  my $win = Win32::GUI::Window->new(
    -title => "HyperLink",
    -pos => [ 100, 100 ],
    -size => [ 240, 200 ],
  );

  # Simplest usage
  $win->AddHyperLink(
    -text => "http://www.perl.org/",
    -pos => [10,10],
  );

  $win->Show();
  Win32::GUI::Dialog();
  exit(0);

=head1 BUGS

See the F<TODO> file from the disribution.

Please report any bugs or feature requests to the Author.

=head1 ACKNOWLEDGEMENTS

Many thanks to the Win32::GUI developers at
L<http://sourceforge.net/projects/perl-win32-gui/>

There was a previous incarnation of Win32::GUI::HyperLink that was posted
on win32-gui-users@lists.sourceforge.net in 2001.  I am not sure of the
original author but it looks like Aldo Calpini.

Some of the ideas here are taken from
L<http://www.codeguru.com/Cpp/controls/staticctrl/article.php/c5803/>

=head1 COPYRIGHT & LICENSE

Copyright 2005..2009 Robert May, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Win32::GUI::HyperLink
