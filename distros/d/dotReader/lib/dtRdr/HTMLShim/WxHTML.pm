package dtRdr::HTMLShim::WxHTML;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;

use Wx ();
use Wx::Event qw(
  EVT_MENU
  EVT_KEY_UP
  EVT_LEFT_DCLICK
  EVT_MOUSE_EVENTS
  );
use Wx::Html;
# XXX could do this, but t/00-load.t doesn't like it
# unless(exists($INC{'dtRdr/HTMLWidget.pm'})) {
#   warn "this isn't meant to be used directly";
# }

use constant base => 'Wx::HtmlWindow';
use base 'dtRdr::HTMLWidget';

use dtRdr::Logger;

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

use dtRdr::HTMLWidget::Shared ();
*filter_HTML = \&dtRdr::HTMLWidget::Shared::absolute_images_filter;

=head1 NAME

dtRdr::HTMLShim::WxHTML - a cross-platform widget without css

=head1 SYNOPSIS

This module is scheduled to get some nice concrete boots and a trip to
the lake.

=cut

=head2 new

  dtRdr::HTMLShim::WxHTML->new(...)

=cut

sub new {
  my $package = shift;
  my ($b_args, $w_args) = @_;
  my ($parent, @b_args) = @$b_args;
  my @defaults = (
    -1,
    &Wx::wxDefaultPosition,
    &Wx::wxDefaultSize,
    #&Wx::wxHW_NO_SELECTION
  );
  defined($b_args[$_]) or $b_args[$_] = $defaults[$_] for(0..$#defaults);

  my $self = $package->SUPER::new([$parent, @b_args], $w_args);
  $self->load_in_progress(0);

  # XXX ??? --Eric
  # $self->{print_object} = wxHtmlEasyPrinting->new();

  return($self);
} # end subroutine new definition
########################################################################


=head2 meddle

  $hw->meddle;

=cut

sub meddle {
  my $self = shift;

  #  "<img src='file:///tmp/img/mailman.jpg'>".
  #  "<img src='file:///tmp/img/PythonPowered.png'>".
  #  "<img src='file:///tmp/img/powerlogo.gif'>".
  my @pages = (
    [0, "/tmp/img/mailman.html"],
    [0, "/tmp/img/PythonPowered.html"],
    [0, "/tmp/img/powerlogo.html"],
    [0, "http://localhost/osoft-hacks/mailman.html"],
    [0, "http://localhost/osoft-hacks/PythonPowered.html"],
    [0, "http://localhost/osoft-hacks/powerlogo.html"],
    [0, "http://localhost/osoft-hacks/"],
    [0, "http://osoft.com/"],
    [0, "http://osoft.com/store/"],
    [0, "http://dotreader.com/"],
    [0, "http://scratchcomputing.com/"],
    [0, "http://vectorsection.org/"],
    [0, "http://tinaconnolly.com/"],
  );
  my $page = (grep({$_->[0]} @pages))[0];
  $page and $self->LoadPage($page->[1]);
} # end subroutine meddle definition
########################################################################

=head2 init

  $hw->init($parent);

=cut

sub init {
  my $self = shift;
  my ($parent) = @_;

  $self->SUPER::init(@_);

  $self->{parent} = $parent;

  # TODO
  # self->SetRelatedStatusBar(...)

  # This gets us web browsing, but requires file:// on local stuff
  # XXX and crashes on windows (bad build?)
  use Wx::FS;
  eval{Wx::FileSystem::AddHandler(Wx::InternetFSHandler->new)};
  $@ and WARN("error initializing FSHandler, maybe no browsing");
  {
    # this does nothing unless we make a menu/hotkey for it
    # and might as well keep it in Frame.pm or something
    EVT_MENU($parent, &Wx::wxID_COPY, sub { my ($h, $e) = @_;
      warn "copy event";
    });
  }

  EVT_LEFT_DCLICK($self, sub {warn "yay";});
  EVT_KEY_UP($self, \&OnKeyUp);
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
} # end subroutine init definition
########################################################################

=head2 start_print

Hmm, what's this do?  I think it is more like a do_print().

=cut

sub start_print {
  my $self = shift;
  my $page = $self->GetOpenedPage();
  my $status;
  if ($page ne '') {
    $status = $self->{print_object}->PrintFile($page);
  } else {
    $page = $self->{html_source};
    $status = $self->{print_object}->PrintText($page, '');
  }
  return $status;
} # end subroutine start_print definition
########################################################################

# Not implemented
 sub get_cursor_pos {
  return;
}

# Not implemented
 sub get_selection_boundary {
  return;
}

# XXX what are these? {{{
 sub register_get_file {
  my ($self, $code) = @_;
  my $old_code = $self->{WxHTMLShim}{get_file};
  $self->{WxHTMLShim}{get_file} = $code;
  return $old_code;
}

 sub register_url_changed {
  my ($self, $code) = @_;
  my $old_code = $self->{WxHTMLShim}{url_changed};
  $self->{WxHTMLShim}{url_changed} = $code;
  return $old_code;
}

 sub register_form_post {
  my ($self, $code) = @_;
  my $old_code = $self->{WxHTMLShim}{form_post};
  $self->{WxHTMLShim}{form_post} = $code;
  return $old_code;
}

 sub register_form_get {
  my ($self, $code) = @_;
  my $old_code = $self->{WxHTMLShim}{form_get};
  $self->{WxHTMLShim}{form_get} = $code;
  return $old_code;
}
# XXX }}}

########################################################################

=head1 Backend Overrides

=head2 OnLinkClicked

This is what's called when someone clicks a link

  $widget->OnLinkClicked($link_obj);

=cut

sub OnLinkClicked {
  my $self = shift;
  my ($link) = @_;

  my $url = $link->GetHref;
  warn "link:  '", $url, "'";

  # XXX complete hack XXX
  return($self->url_handler->load_url($url));

  return $self->SUPER::OnLinkClicked($link);
  #if (exists $self->{WxHTMLShim}{url_changed}) {
  #  $self->{WxHTMLShim}{url_changed}($self, $url);
  #  return;
  #} else {
    return $self->LoadPage('file:///tmp/index.html');
    return $self->LoadPage($url);
  #}
} # end subroutine OnLinkClicked definition
########################################################################
use Method::Alias load_url => 'LoadPage';
use Method::Alias LoadURL => 'LoadPage';

=head2 OnOpeningURL

  $widget->OnOpeningURL($type, $url, $redirect);

=cut

sub OnOpeningURL {
  my $self = shift;
  my ($type, $url, $redirect) = @_;

  warn "called OnOpeningURL $type|$url|$redirect";
  if (exists $self->{WxHTMLShim}{get_file}) {
  }
  else {
  }

} # end subroutine OnOpeningURL definition
########################################################################

=head2 OnCellClicked

not working -- IS NOT CONNECTED BY WxPerl

  $hw->OnCellClicked($cell, $x, $y, $event);

=cut

sub OnCellClicked {
  my $self = shift;
  my ($cell, $x, $y, $event) = @_;

  warn "you clicked on $cell at ($x,$y)";
} # end subroutine OnCellClicked definition
########################################################################


=head2 OnKeyUp

  $hw->OnKeyUp($event);

=cut

sub OnKeyUp {
  my $self = shift;
  my ($event) = @_;
  # there's no binding to this:
  # $self->SUPER::OnKeyUp($event);
  # wxTheClipboard->clear;

  warn "OnKeyUp($event)";
} # end subroutine OnKeyUp definition
########################################################################

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
