package dtRdr::HTMLShim::WxMozilla;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;

BEGIN { # TODO fix this
  package Wx::MozillaBrowser;
  our @ISA = qw(Wx::ScrolledWindow);
}

use Wx qw(
  wxTheClipboard
);
use Wx::DND; # clipboard+drag-n-drop support
use Wx::Event qw(
  EVT_MOUSE_EVENTS
  EVT_KEY_UP
  );
use Wx::Html;
use Wx::Mozilla;
use Wx::Mozilla::Event qw(:all);

  sub base { 'Wx::MozillaBrowser' };
use base 'dtRdr::HTMLWidget';

# TEMPORARY {{{
use dtRdr::Traits::Class qw(
  WARN_NOT_IMPLEMENTED
  );

use dtRdr::HTMLWidget::Shared qw(
  get_scroll_pos
  set_scroll_pos
  scroll_page_down
  scroll_page_up
  jump_to_anchor
); # these are just temporary imports
# TEMPORARY }}}

# Mozilla cannot display file:// images, so we base64 encode them.
use dtRdr::HTMLWidget::Shared;
*img_src_rewrite_sub =
  \&dtRdr::HTMLWidget::Shared::base64_images_rewriter;
########################################################################


use dtRdr::Logger;

our @ISA;

my @events = (qw(
  EVT_MOZILLA_URL_CHANGED
  EVT_MOZILLA_BEFORE_LOAD
  ),
  'EVT_MOZILLA_STATE_CHANGED',
  #EVT_MOZILLA_SECURITY_CHANGED
  qw(
  EVT_MOZILLA_STATUS_CHANGED
  EVT_MOZILLA_TITLE_CHANGED
  EVT_MOZILLA_LOAD_COMPLETE
  EVT_MOZILLA_PROGRESS
  EVT_MOZILLA_RIGHT_CLICK
));


=head1 NAME

dtRdr::HTMLShim::WxMozilla - a linux-only widget shim

=head1 SYNOPSIS

This uses Wx::Mozilla, which still needs work, but the underlying C++
library is basically abandoned.  Please look into webcore.

=cut

=head2 new

  my $widget = dtRdr::HTMLShim::WxMozilla->new(...);

=cut

sub new {
  my $class = shift;

  ######################################################################
  # this is an ugly hack to stop the Mozilla LoadPlugin noise
  # funny that it is supposed to catch it but doesn't
  ######################################################################
  my $error_catch = sub {
    local $SIG{__WARN__};
    my ($sub) = @_;
    my $TO_ERR;
    open($TO_ERR, '<&STDERR');
    close(STDERR);
    my $catch;
    open(STDERR, '>', \$catch);
    my @ans = $sub->();
    open(STDERR, ">&", $TO_ERR);
    close($TO_ERR);
    return($catch, @ans);
  }; # end sub $error_catch
  ######################################################################

  L('construct')->debug("call parent constructor");
  my @args = @_;
  # this is only needed if your plugins setup is broken:
  #my ($bah, $self) = $error_catch->(sub {$class->SUPER::new(@args)});
  my ($bah, $self) = (0, $class->SUPER::new(@args));
  $bah and L('construct')->debug("parent whined about $bah");
  L('construct')->debug("ok, parent constructor");

  $self->setup;

  return $self;
} # end subroutine new definition
########################################################################

=head2 init

  $widget->init($parent);

=cut

sub init {
  my $self = shift;

  $self->SUPER::init(@_);
} # end subroutine init definition
########################################################################


=head2 setup

Setup keybindings, etc.

  $hw->setup;

=cut

sub setup {
  my $self = shift;
  $self->_events_HACK;
} # end subroutine setup definition
########################################################################

=head2 _events_HACK

hack to mess with events

  $hw->_events_HACK;

=cut

sub _events_HACK {
  my $self = shift;
  EVT_MOZILLA_RIGHT_CLICK($self, -1,
    sub {$_[0]->event_right_click($_[1]) }
  );
  if(0) { # silly trial code
    foreach my $name (@events) {
      my $sub = eval("\\&$name");
      $sub->($self, -1,
        sub {warn "\n\n  $name happened! $_[1]\n"}
        );
    }
    # XXX this does not prevent copying
    0 and EVT_MOUSE_EVENTS($self, sub { my ($h, $e) = @_;
      warn "mouse event";
      wxTheClipboard->Open;
      wxTheClipboard->Clear;
      wxTheClipboard->Close;
      $e->StopPropagation;
      $e->Skip(1);
      # even this does nothing useful here!
      #$h->SetEvtHandlerEnabled(0);
      });
  }
  if(0) {
    # EVT_MOZILLA_SECURITY_CHANGED($self, -1, sub {
    #   my ($w, $ev) = @_;
    #   warn "SECURITY event: ",$ev->GetSecurity;
    # });
    EVT_MOZILLA_STATE_CHANGED($self, -1, sub {
      my ($w, $ev) = @_;
      WARN("STATE event. ",
        join("|", map({$_ . " => " . $ev->$_} qw(GetState GetURL)))
      );
    });
    EVT_MOZILLA_BEFORE_LOAD($self, -1, sub {
      my ($w, $ev) = @_;
      WARN("BEFORE_LOAD event. ",
        join("|", map({$_ . " => " . $ev->$_} qw(GetURL)))
      );
    });
  }
  #EVT_KEY_UP($self, \&OnKeyUp);
} # end subroutine _events_HACK definition
########################################################################

=head2 OnKeyUp

Where we'll probably have to hand-map the accelerator table.

  $hw->OnKeyUp($event);

=cut

sub OnKeyUp {
  my $self = shift;
  my ($event) = @_;
  # there's no binding to this:
  #$self->SUPER::OnKeyUp($event);

  warn "OnKeyUp($event)";
} # end subroutine OnKeyUp definition
########################################################################

=head2 event_right_click

Currently, this is just the only click we can snag.

  $widget->event_right_click($event);

=cut

sub event_right_click {
  my $self = shift;
  my ($event) = @_;

  my $killit = sub {
    #$event->Skip;
  };
  my $url = $event->GetLink;
  $url or return; # only because this is a silly way to handle links
  if($self->url_handler->load_url($url, $killit)) {
    #$event->Skip;
  }

} # end subroutine event_right_click definition
########################################################################

=head2 load_url

  $self->load_url($url);

=cut

sub load_url {
  my $self = shift;
  my ($url) = @_;
  $self->LoadURL($url);
} # end subroutine load_url definition
########################################################################

=head2 SetPage

  $widget->SetPage($content);

=cut

sub SetPage {
  my $self = shift;
  my ($html) = @_;
  $self->SUPER::SetPage($html);
} # end subroutine SetPage definition
########################################################################

=head2 load_in_progress

Just IsBusy().  Possibly incorrect, not heavily used?

=cut

sub load_in_progress {
  my $self = shift;
  # XXX is this Mozilla's internal state?  We may need our own too
  return $self->IsBusy();
}
########################################################################


=head2 get_selection_context

  my ($pre, $str, $post) = $hw->get_selection_context($context_length);

=cut

sub get_selection_context {
  my $self = shift;
  my ($blength) = @_;
  # XXX ignoring that ATM because all I got is this stupid clipboard

  my $string = $self->GetSelection;
  return('',$string, '');
} # end subroutine get_selection_context definition
########################################################################

=head2 decrease_font

  $self->decrease_font;

=cut

sub decrease_font {
  my $self = shift;
  # TODO hook to get_zoom/set_zoom for statefulness
  $self->SetZoom( $self->GetZoom() - 0.2);
} # end subroutine decrease_font definition
########################################################################

=head2 increase_font

  $self->increase_font;

=cut

sub increase_font {
  my $self = shift;
  # TODO hook to get_zoom/set_zoom for statefulness
  $self->SetZoom( $self->GetZoom() + 0.2);
} # end subroutine increase_font definition
########################################################################

# NOT DONE? {{{
# XXX I guess all of these just aren't done yet? --Eric
 sub get_cursor_pos {
  do('./util/BREAK_THIS') or die;
}

 sub register_get_file {
  do('./util/BREAK_THIS') or die;
}

 sub register_url_changed {
  do('./util/BREAK_THIS') or die;
}

 sub register_form_post {
  do('./util/BREAK_THIS') or die;
}

 sub register_form_get {
  do('./util/BREAK_THIS') or die;
}
# NOT DONE? }}}

=head1 AUTHOR

Dan Sugalski <dan@sidhe.org>

Eric Wilhelm <ewilhelm at cpan dot org>

=head1 COPYRIGHT

Copyright (C) 2006 by Dan Sugalski, Eric L. Wilhelm, and OSoft, All
Rights Reserved.

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
