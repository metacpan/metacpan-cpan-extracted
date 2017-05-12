package dtRdr::HTMLWidget;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;

use Carp;


use dtRdr::Traits::Class qw(
  NOT_IMPLEMENTED
  WARN_NOT_IMPLEMENTED
  );

my $delegate_class;

use Wx qw(
  wxHW_NO_SELECTION
  );

use dtRdr::Logger;

use Class::Accessor::Classy;
rw qw(
  load_in_progress
  zoom
);
ro qw(
  parent
  url_handler
);
rs html_source => \ (my $set_html_source);
no  Class::Accessor::Classy;


=head1 NAME

dtRdr::HTMLWidget - Generic HTML widget interface

=head1 SYNOPSIS

  use dtRdr::HTMLWidget;

=head1 DESCRIPTION

Provides a browser-independent widget.  Uses a platform-specific
adapter (shim), or the basic WxHTML widget if that fails.

=cut

our @ISA;
BEGIN {
  $delegate_class = 0;
  my %dispatch = (
    darwin   => 'dtRdr::HTMLShim::WebKit',
    MSWin32  => 'dtRdr::HTMLShim::ActiveXIE',
    linux    => 'dtRdr::HTMLShim::WxMozilla',
    # linux    => 'dtRdr::HTMLShim::WxHTML',
    fallback => 'dtRdr::HTMLShim::WxHTML',
    );

  # override
  my $force = $ENV{THOUT_WIDGET} ?
    'dtRdr::HTMLShim::' . $ENV{THOUT_WIDGET} :
    undef;
  # pick one
  if(my $backend = $force || $dispatch{$^O}) {
    eval "use $backend";
    if($@) {
      die "$force not working ($@)" if($force);
      warn "could not use $backend -- try fallback ($@)";
    }
    else {
      $delegate_class = $backend;
    }
  }
  else {
    warn "'$^O' backend not specified";
  }

  # If something went wrong, go to the fallback
  unless($delegate_class) {
    eval "use $dispatch{fallback}";
    $@ and die "even the fallback failed! $@";
    $delegate_class = $dispatch{fallback};
  }

  # If we can't use the fallback, then punt
  our @ISA;
  # we're basically inserting ourselves between the platform-specific
  # widget and the class that it wants to inherit from
  # e.g. we inherit from the widget's chosen base class on its behalf
  push(@ISA, $delegate_class->base);
} # end BEGIN

=head1 CONSTRUCTOR

=head2 new

Constructor / Factory method.

Create and return a new HTML rendering widget.

Base classes may inherit this.

Calling classes should call this (do not call the base class constructor
directly.)

  my @wx_args = (
    # from http://www.wxwindows.org/manuals/2.6.3/wx_wxhtmlwindow.html
    $parent, # wxWindow *parent,
    $id,     # wxWindowID id = -1,
    $pos,    # const wxPoint& pos = wxDefaultPosition,
    $size,   # const wxSize& size = wxDefaultSize,
    $style,  # long style = wxHW_DEFAULT_STYLE,
    $name,   # const wxString& name = "htmlWindow"
    );
  $widget = dtRdr::HTMLWidget->new(\@wx_args, \%opts);

ASIDE: this is the old interface:

  $widget = dtRdr::HTMLWidget->new($parent, $id, $position, $size, $style)

=cut

sub new {
  my $package = shift;
  my $caller = caller;
  my ($b_args, $w_args) = @_;
  # allow duality of API
  if((ref($b_args) || '') ne 'ARRAY') {
    eval {$b_args->isa('Wx::Window')} or croak("bad arguments @_");
    $b_args = [@_];
  }
  $w_args ||= {};

  if(defined($caller) and $caller->isa(__PACKAGE__)) {
    # being inherited => be a base class
    0 and warn "base class for $caller";
    my $class = ref($package) || $package;
    0 and warn "b_args: ", join("|", @$b_args);
    my $self = $class->base->new(@$b_args);
    bless($self, $class);
    return($self);
  }
  else {
    # being called => be a factory
    0 and warn "factory" . ($caller ? " (for $caller)" : '');
    return($delegate_class->new($b_args, $w_args));
  }
} # end subroutine new definition
########################################################################

=head1 Class Methods

=head2 base

Returns the base class of the widget.  Subclass must override this.

  $widget->base;

=cut

sub base { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head1 Callback Methods

=head2 init

Initialization callback.

  $widget->init($parent, url_handler => $handler);

=cut

sub init {
  my $self = shift;
  my $parent = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my %args = @_;
  $self->{parent} = $parent;
  my @attribs = qw(
    url_handler
  );
  foreach my $arg (@attribs) {
    $self->{$arg} = $args{$arg} if(exists($args{$arg}));
  }
} # end subroutine init definition
########################################################################

=head1 ...Methods

=head2 render_HTML

Render the HTML in the widget.

  $bool = $widget->render_HTML($html, $data_handle);

$data_handle must respond to requests for related URIs.  Note that the
URIs I<may> have a dotReader specific prefix, such as book:.

  $data_handle->get_member_string($relative_uri)

=cut

sub render_HTML {
  my $self = shift;
  my ($html, $dh) = @_;

  $self->{load_in_progress} = 1;
  # XXX shouldn't need this filtering anymore
  # $html = $self->filter_HTML($html, $dh);
  DBG_DUMP('FILTERED', 'filtered.html', sub {$html});
  my $status = $self->SetPage($html);
  $self->$set_html_source($html);
  $self->{load_in_progress} = 0;
  return $status;
} # end subroutine render_HTML definition
########################################################################

=head2 reset_wrap

Grabs the widget's internal state variables, runs $subref, and resets
the state variables.

  $hw->reset_wrap($subref);

=cut

sub reset_wrap {
  my $self = shift;
  my ($subref) = @_;
  my $yscroll = $self->get_scroll_pos();
  #L->debug("scroll pos $yscroll");
  my $zoom = $self->get_zoom;
  #L->debug("zoom $zoom");
  $subref->();
  my $new_pos = $self->set_scroll_pos($yscroll);
  #L->debug("set scroll pos to $new_pos");
  $self->set_zoom($zoom);
} # end subroutine reset_wrap definition
########################################################################

=head2 filter_HTML

  $html = $hw->filter_HTML($html, $datahandle);

=cut

sub filter_HTML {
  my $self = shift;
  my ($html, $dh) = @_;
  return($html);
} # end subroutine filter_HTML definition
########################################################################

=head2 allow_copy

  $widget->allow_copy($bool)

Enable or disable OS copy-to-clipboard functionality

=cut

sub allow_copy {
  my ($self, $allow) = @_;
  my $style = $self->GetWindowStyleFlag();
  if (!$allow) {
    $style = $style | wxHW_NO_SELECTION;
    $self->SetWindowStyleFlag($style);
  } else {
    $style = $style & (~wxHW_NO_SELECTION);
    $self->SetWindowStyleFlag($style);
  }
} # end subroutine allow_copy definition
########################################################################

=head1 Handlers

These are the callbacks that the widget shims must implement. In all
cases, registering a callback for a widget returns the previously
registered callback, on the off-chance that your code's doing a
temporary override of the callback.

=head2 register_get_file

  $old_callback = $widget->register_get_file(&callback)

  This is the function called when the widget needs to fetch a file
  that's embedded within a webpage. (This is for E<lt>imgE<gt> tag
  fetches and suchlike things)

=cut

sub register_get_file { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head2 load_in_progress

  $bool = $widget->load_in_progress;

Returns true if the widget is currently fetching information or working
on rendering the HTML contents, false if it is not.

=cut

# accessor
########################################################################

=head2 get_scroll_pos

  callback implement in html shim
  $position = $widget->get_cursor_pos();
  Returns the current vertical scroll bar position for the HTML widget

=cut

sub get_scroll_pos { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head2 set_scroll_pos

  callback implement in html shim
  $widget->set_scroll_pos(200);

  Sets the current vertical scroll bar position for the HTML widget

=cut

sub set_scroll_pos { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head2 scroll_page_down

  callback implement in html shim
  scroll_page_down();
  scrolls the browser widget down 1 page.
  equivilent to [Page Down]
  Returns 1 if successfull or 0 if it can't scroll

=cut

sub scroll_page_down { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################


=head2 scroll_page_up

  callback implement in html shim
  scroll_page_up();
  scrolls the browser widget down 1 page.
  equivilent to [Page Up]
  Returns 1 if successfull or 0 if it can't scroll

=cut

sub scroll_page_up { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################


=head2 scroll_page_bottom

  callback implement in html shim
  scroll_page_bottom
  scrolls the browser to the bottom of the page

=cut

sub scroll_page_bottom { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################


=head2 increase_font

callback implement in html shim
Decreases the font size
  $widget->increase_font

=cut

sub increase_font {  my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head2 decrease_font

callback implement in html shim
Decreases the font size
  $widget->decrease_font

=cut

sub decrease_font {  my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head2 register_url_changed        XXX   NOT USED   XXX

  $old_callback = $widget->register_url_changed(&callback)

  This is the callback that's called when the browser pane is about to
  change to a new page because someone clicked on a link.

=cut

sub register_url_changed { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head2 register_form_post

  $old_callback = $widget->register_form_post(&callback)

  This is the callback that's called when the browser pane does a form
  POST request.

=cut

sub register_form_post { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head2 register_form_get

  $old_callback = $widget->register_form_get(&callback)

  This is the callback that's called when the browser pane does a form
  GET request.

=cut

sub register_form_get { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head1 history

=head2 history_next

  Navigates to the next state in history

=cut

sub history_next { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head2 history_back

  Navigates to the previous state in history

=cut

sub history_back { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head1 Print

=head2 print_page

  Print the current page

=cut

sub print_page { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################


=head1 Selection

=head2 get_selection

  Returns selected text

  my $string = $hw->get_selection;

=cut

sub get_selection { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head2 get_selection_as_html

  my $html = $hw->get_selection_as_html;

=cut

sub get_selection_as_html { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head2 get_selection_context

  Returns ($pre, $str, $post)
  where pre and post text are $context_length or less if the selected
  text is near the begining or end of the document

  my ($pre, $str, $post) = $hw->get_selection_context($context_length);

=cut

sub get_selection_context { my $self = shift; $self->NOT_IMPLEMENTED; }
########################################################################

=head1 AUTHOR

Dan Sugalski, E<lt>dan@sidhe.orgE<gt>

Eric Wilhelm

Gary Varnell

=head1 COPYRIGHT

Copyright (C) 2006 by Dan Sugalski, Eric Wilhelm, and OSoft, All Rights
Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

1;
# vim:ts=2:sw=2:et:sta
