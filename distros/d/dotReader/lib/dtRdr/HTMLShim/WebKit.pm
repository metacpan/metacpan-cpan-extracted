package dtRdr::HTMLShim::WebKit;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

#BEGIN { # TODO fix this
#  package Wx::WebKit;
#  our @ISA = qw(Wx::ScrolledWindow);
#}

use Wx::WebKit;

  sub base { 'Wx::WebKitCtrl' };
use base qw(dtRdr::HTMLWidget);

use Wx::WebKit::Event qw(:all);
#use Wx::Panel;

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

# webkit can do either absolute links or base64 encoded
use dtRdr::HTMLWidget::Shared;
*img_src_rewrite_sub =
  \&dtRdr::HTMLWidget::Shared::base64_images_rewriter;

use dtRdr::Logger;

=head1 NAME

dtRdr::HTMLShim::WebKit - the webkit html widget

=cut

=head2 new

Constructor.  Passes through to shim base.

  dtRdr::HTMLShim::WebKit->new([@args], [@args]);

=cut

sub new {
  my $self = shift;
  my (@others) = @_;
  {
    # XXX THE WEBKIT API IS WRONG:
    # the constructor should not need a URL
    # but I guess that's in the C++ api now
    splice(@{$others[0]}, 2, 0, "");
  }
  $self = $self->SUPER::new(@others);
  $self->SetBackgroundColour(Wx::Colour->new(244,25,0));
  return $self;
} # end subroutine new definition
########################################################################

=head2 init

Registers event handlers.

  $hw->init($parent);

=cut

sub init {
  my $self = shift;
  my ($parent) = @_;

  $self->SUPER::init(@_);

  # setup events
  EVT_WEBKIT_BEFORE_LOAD($self, -1,
    sub {$_[0]->before_load($parent, $_[1])});

  # meddle
  0 and Wx::Event::EVT_KEY_UP($self, sub {my ($s, $evt) = @_;
    WARN "got event $evt";
    #$evt->Skip;
  });
  0 and EVT_WEBKIT_STATE_CHANGED($self, $self, sub {my ($s, $evt) = @_;
    WARN "STATE_CHANGED $evt";
  });

} # end subroutine init definition
########################################################################

=head2 before_load

Handles the BeforeLoadEvent

  $self->before_load($parent, $evt);

=cut

sub before_load {
  my $self = shift;
  my ($parent, $evt) = @_;

  my $url = $evt->GetURL;
  # get rid of the weirdos
  return if($url =~ m#^applewebdata://#);
  return if($url =~ m#^about:blank#);

  RL('#links')->debug("IN...($self)", $url);

  if($self->load_in_progress) {
    WARN "bye";
    $self->set_load_in_progress(0);
    return;
  }

  # it appears that we don't have to deal with this circularity issue
  # TODO though I'm sort of guessing here -- need an acceptance test
  #$self->set_load_in_progress(1);

  RL('#links')->debug("FOLLOW");
  my $killit = sub {
    $evt->Cancel;
    $self->set_load_in_progress(0);
  };
  if($self->url_handler->load_url($url, $killit)) {
    $evt->Cancel;
  }
} # end subroutine before_load definition
########################################################################

=head2 get_selection_context

  my ($pre, $str, $post) = $hw->get_selection_context($context_length);

=cut

{
my $ABSURD_STRING = '>>><<<';
my $SELECT_O_SCRIPT = <<"  ---";
  var selection = window.getSelection();

  function getSurroundingText(selText, direction, numChars){
    var surText = "";

    var otherDirection = "backward";
    var strStart = selText.length;

    if (direction == "backward"){
        otherDirection = "forward";
        strStart = 0;
        // the cursor position is at the end of the selection
        // so we have to move "backwards" over the selection
        // itself, too.
        numChars += selText.length;
    }

    var strEnd = strStart + numChars;

    for (i = 0; i < numChars; i++) {
        selection.modify("extend", direction, "character");
    }

    surText = selection + '';
    surText = surText.substring(strStart, strEnd)

    // restore the selection to its original state
    for (i = 0; i < numChars; i++) {
        selection.modify("extend", otherDirection, "character");
    }

    return surText;

  }

  function getSelectionContext(numChars) {

    var preText = "";
    var postText = "";
    var selText = selection + '';
    var strLen = selText.length;

    postText = getSurroundingText(selText, "forward", numChars);
    preText = getSurroundingText(selText, "backward", numChars);

    return preText + '$ABSURD_STRING' + selText + '$ABSURD_STRING' + postText;
  }
  ---

sub get_selection_context {
  my $self = shift;
  my ($blength) = @_;
  defined $blength or $blength = 10;
  my $script = $SELECT_O_SCRIPT . "\ngetSelectionContext($blength);";
  ##WARN "select with\n$script\n\n  ";
  my $found = $self->RunScript($script);
  my ($l, $m, $t, @e) = split(/$ABSURD_STRING/, $found);
  @e and die "error in get_selection_context split -- @e";
  return($l, $m, $t);
} # end subroutine get_selection_context definition
########################################################################
}

# XXX this should be in the XS code
sub SetPage { my $self = shift; $self->SetPageSource(@_); }


=head2 load_url

  $hw->load_url($url);

=cut

sub load_url {
  my $self = shift;
  WARN "hey ($self)"; # XXX trouble where the dispatch switches widgets?
  $self->set_load_in_progress(1);
  $self->LoadURL(@_);
} # end subroutine load_url definition
########################################################################

=head1 AUTHOR

Dan Sugalski <dan@sidhe.org>

Eric Wilhelm <ewilhelm at cpan dot org>

=head1 COPYRIGHT

Copyright (C) 2006-2007 by Dan Sugalski, Eric L. Wilhelm, and OSoft, All
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

# vim:ts=2:sw=2:et:sta
1;
