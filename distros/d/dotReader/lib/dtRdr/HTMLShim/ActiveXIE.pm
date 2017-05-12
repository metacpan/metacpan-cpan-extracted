package dtRdr::HTMLShim::ActiveXIE;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;

use Carp;
use HTML::Entities;

use constant {
  DEBUG  => 1,  # general
};

use Wx ();
use Wx::Event qw(
  EVT_SET_FOCUS
);
use Wx::ActiveX::Event qw(:all);

use Wx::ActiveX::IE;

# This setting is needed to properly pass unicode.
use Win32::OLE qw(CP_UTF8);
Win32::OLE->Option(CP => CP_UTF8);
use Win32;

use constant base => 'Wx::ActiveX::IE';
use base 'dtRdr::HTMLWidget';

use dtRdr;
use dtRdr::Accessor;
dtRdr::Accessor->rw(qw(
  after_load
));

use Method::Alias (
  scroll_pos => 'get_scroll_pos',
);

use dtRdr::Logger;

=head1 NAME

dtRdr::HTMLShim::ActiveXIE - a windows-only widget shim

=head1 SYNOPSIS

This module needs cleanup.

=cut

=head1 Constructor

=head2 new

Usually not called directly.

  dtRdr::HTMLShim::ActiveXIE->new(...);

=cut

sub new {
  my $package = shift;
  my (@others) = @_;
  my $self = $package->SUPER::new(@others);
  return($self);
} # end subroutine new definition
########################################################################

=head2 init

  $hw->init($parent);

=cut

sub init {
  my $self = shift;
  my ($parent) = @_;

  $self->SUPER::init(@_);

  ref($self) or die "this is an instance method";

  0 and $self->_event_noises($parent);
  0 and WARN(join("\n  ", 'EVENTS:', $self->ListEvents));
  0 and WARN(join("\n  ", 'METHODS:', $self->ListMethods));

  # focus!
  EVT_SET_FOCUS($self, sub {$self->GetOLE->document->focus;});

  # it doesn't generate one of these :-(
  #Wx::Event::EVT_COMMAND_RIGHT_CLICK($self, -1, sub {WARN("right click")});
  #Wx::Event::EVT_RIGHT_DOWN($self, sub {WARN("right down")});
  #Wx::Event::EVT_RIGHT_DOWN($parent, sub {WARN("right down")});

  # This $parent thing looks stupid, but $self is not a valid event
  # handler.  Ok, it is stupid, but them's the breaks in qdos land.
  EVT_ACTIVEX(
    $parent, $self, "BeforeNavigate2",
    sub { $self->before_navigate2($parent,$_[1]) }
  );

  EVT_ACTIVEX( $parent, $self, 'NavigateComplete2',
    sub {
      $self->set_load_in_progress(0);
      RL('#bw')->debug("finally - NavigateComplete2");
      #WARN('NavigateComplete2');
      if(my $subref = $self->after_load) {
        $subref->();
        $self->set_after_load(undef);
      }
    }
  );

  # ick, we have to muck with our zoom here because the widget forgot
  # what we had asked it to do
  EVT_ACTIVEX($parent, $self, 'DownloadComplete', sub {
    #WARN("hack");
    $self->set_zoom($self->get_zoom);
  });


  #notes:
  #IE will not try to navigate to a page without a proto
  #IE needs hack to fix png images

  ######################################################################
  #NOTE if we want to use their methods, we need to fix this:
  unless(__PACKAGE__->isa('Wx::IEHtmlWin')) {
    L->warn("isa push!");
    our @ISA;
    push(@ISA, 'Wx::IEHtmlWin');
  }
  ######################################################################

} # end subroutine init definition
########################################################################

=head2 _event_noises

  $self->_event_noises($parent);

=cut

sub _event_noises {
  my $self = shift;
  my ($parent) = @_;

  # IE Events
  # NavigateError
  # wb1_NewWindow2
  # OnStatusBar
  # StatusTextChange
  # CommandStateChange
  # PropertyChange
  # ProgressChange

  my @events = (
    #'StatusTextChange',
    'DownloadComplete',
    'CommandStateChange',
    'DownloadBegin',
    'ProgressChange',
    'PropertyChange',
    'TitleChange',
    'PrintTemplateInstantiation',
    'PrintTemplateTeardown',
    'UpdatePageStatus',
    'NewWindow2',
    'OnQuit',
    'OnVisible',
    'OnToolBar',
    'OnMenuBar',
    'OnStatusBar',
    'OnFullScreen',
    'DocumentComplete',
    'OnTheaterMode',
    'WindowSetResizable',
    'WindowClosing',
    'WindowSetLeft',
    'WindowSetTop',
    'WindowSetWidth',
    'WindowSetHeight',
    'ClientToHostWindow',
    'SetSecureLockIcon',
    'FileDownload',
    'NavigateError',
    'PrivacyImpactedStateChange',
  );
  foreach my $event (@events) {
    EVT_ACTIVEX( $parent, $self, $event,
      sub {WARN("EVENT ($self) - $event\n\n")},
    );
  }
} # end subroutine _event_noises definition
########################################################################

=head2 before_navigate2

Callback for link clicks

  $hw->before_navigate2($parent, $evt);

=cut

sub before_navigate2 {
  my $self = shift;
  my ($parent, $evt) = @_;

  RL('#links')->debug("IN...$evt->{URL}");
  if($self->load_in_progress) {
    #$self->set_load_in_progress(0);
    return;
  }

  ######################################################################
  ### this is pointless
  ### TODO: using book_view for this causes problems if we've got a pane
  ### with no book (e.g. just started, etc.)
  ##unless($parent->book_view) {
  ##  use URI;
  ##  my $uri = URI->new($evt->{URL});
  ##  # hmm.
  ##  if(defined(my $anchor = $uri->fragment)) {
  ##    $evt->{Cancel} = 1;
  ##    RL('#links')->debug("jump to $anchor");
  ##    $self->jump_to_anchor($anchor);
  ##    return;
  ##  }
  ##  L->error("I can't do other stuff here yet");
  ##  return;
  ##}
  ######################################################################

  $self->set_load_in_progress(1);
  RL('#links')->debug("FOLLOW");
  my $killit = sub {
    $evt->{Cancel}=1;
    $self->set_load_in_progress(0);
  };
  if($self->url_handler->load_url($evt->{URL}, $killit)) {
    $self->set_load_in_progress(0);
    $evt->{Cancel} = 1;
  }
} # end subroutine before_navigate2 definition
########################################################################

=head2 jump_to_anchor

  $hw->jump_to_anchor($name);

=cut

sub jump_to_anchor {
  my $self = shift;
  my ($name) = @_;

  my $doc = $self->GetOLE->document;
  $doc or die;

  my $anchor_idx = $self->_find_element('a', 'name', $name);
  defined($anchor_idx) or L->error("anchor '$name' not found");

  my $el = $doc->all($anchor_idx);
  $el->scrollIntoView;
} # end subroutine jump_to_anchor definition
########################################################################

=head2 _find_element

We'll see how long this interface lasts.

  my $idx = $self->_find_element($type, $foo, $equals);

=cut

sub _find_element {
  my $self = shift;
  my ($type, $key, $equals) = @_;

  $type = uc($type);

  my $doc = $self->GetOLE->document;
  $doc or die;

  if(defined(my $len = $doc->all->length)) {
    foreach my $i (0..$len) {
      my $el = $doc->all($i);
      $el or next;
      ($el->tagName eq $type) or next;
      my $val = $el->getAttribute($key);
      defined($val) or next;
      if($val eq $equals) {
        return($i);
      }
      if(0) {
        print STDERR join("\n  ", map({"$_:  " .$el->$_} qw(
          tagName
          offsetTop
          )),
        map({my $at = $el->getAttribute($_);
        defined($at) ? "att $_:  $at":()} qw(
          name
          )),
        ),
        "\n";
      }
    }
  }
  else {
    die "no elements to find";
  }
  return();
} # end subroutine _find_element definition
########################################################################

=head2 load_url

  $hw->load_url($url);

=cut

sub load_url {
  my $self = shift;
  my ($url) = @_;
  $self->set_load_in_progress(1);
  # NOTE makes no difference, it is still a mouse-click (brilliant!)
  #$self->GetOLE->Navigate($url);
  $self->LoadUrl($url);
} # end subroutine load_url definition
########################################################################

=head2 SetPage

  $self->SetPage($html);

=cut

sub SetPage {
  my $self = shift;
  my ($html) = @_;

  my $ole = $self->GetOLE;
  my $doc = $ole->document();
  $doc->new();
  $doc || warn "no doc";
  if(1) {
    $doc->write($html); # makes anchored links not fire
    $ole->Refresh; # unless we do this
    WARN("hit SetPage");
  }
  else {
    # but doing this means we have to deal with CSS
    # and seems to cause some other problems too
    $doc->CreateElement('body');
    $doc->{body}{innerHTML} = $html;
  }
  0 and WARN("{{{$html}}}");
  $doc->{defaultCharset} = 'UTF-8';

  # I guess ALPHA means "doesn't work"
  if(0) {
    WARN "setup event";
    Win32::OLE->import('EVENTS');
    Win32::OLE->WithEvents($self->GetOLE, sub {WARN @_});
  }

  $doc->close();
  #my $css = $doc->createStyleSheet();
} # end subroutine SetPage definition
########################################################################

=pod

=begin notes

  $doc->{'styleSheets'}->addRule("BODY", "background-color:red");
  $css->addRule("*", "font-size:24px");
  $css->addRule("BODY", "background-color:red");
  $css->addRule("*", "behavior: url('E:/osoft.com_svn/src/client/data/gui_global/iepngfix.htc')");

=end notes

=cut

# que?
sub _fix_png {
  my $self = shift;
  my ($content) = @_;
#  #           1 start             2 quote     3 image
#  $content=~s/(<img.*?src\s*=\s*)(["'])([^\2]+?\.png)\s*\2/$1$2E:\\osoft.com_svn\\src\\client\\data\\gui_global\\blank.gif$2 style="filter: progid:DXImageTransform.Microsoft.AlphaImageLoader(src='$3', sizingMethod='scale');"/ig;
  return $content;
}

=head2 print_page

  $hw->print_page;

=cut

sub print_page {
  my $self = shift;

  my $doc = $self->GetOLE->document();
  $doc->execCommand('Print');
} # end subroutine print_page definition
########################################################################

=head2 get_scroll_pos

  my $y = $self->get_scroll_pos;

=cut

sub get_scroll_pos {
  my $self = shift;

  my $doc = $self->GetOLE->document();
  return($doc->{body}->{scrollTop});
} # end subroutine get_scroll_pos definition
########################################################################

=begin Workaround-Notes

We have to set a trap for the events, since the widget doesn't block on
a load_url.  It currently looks like only the website scroll position
will end up in this situation.  No, I'm not happy with it.

=end Workaround-Notes

=cut

=head2 set_scroll_pos

  $hw->set_scroll_pos($y);

=cut

sub set_scroll_pos {
  my $self = shift;
  my ($y) = @_;

  if($self->load_in_progress) { # defer till later
    $self->after_load and carp("that's going to hurt");
    $self->set_after_load(sub { $self->set_scroll_pos($y); });
    # WARN('defer set_scroll_pos');
    return; # XXX should lie and say it worked here?
  }

  my $doc = $self->GetOLE->document();
  RL('#noise')->debug("setting to $y");
  # weird possibly better to set the onloadevent and refresh?
  $doc->{body}->{scrollTop} = $y;
  $doc->{body}->{scrollTop} = $y;
  return($doc->{body}->{scrollTop});
} # end subroutine set_scroll_pos definition
########################################################################


=head2 scroll_page_down

  $hw->scroll_page_down;

Returns true if successful, false otherwise.

=cut

sub scroll_page_down {
  my $self = shift;

  my $doc = $self->GetOLE->document();
  $doc or return;

  my $y = $self->get_scroll_pos;
  $doc->{Body}->doScroll('pageDown');
  return($y != $self->get_scroll_pos);
} # end subroutine page_down definition
########################################################################


=head2 scroll_page_up

  $hw->scroll_page_up;

Returns true if successful, false otherwise.

=cut

sub scroll_page_up {
  my $self = shift;

  my $doc = $self->GetOLE->document();
  $doc or return;

  my $y = $self->get_scroll_pos;
  $doc->{Body}->doScroll('pageUp');
  return($y != $self->get_scroll_pos);
} # end subroutine page_down definition
########################################################################

=head2 scroll_page_bottom

  hw->scroll_page_bottom

=cut

sub scroll_page_bottom {
  my $self = shift;

  my $doc = $self->GetOLE->document();
  $doc->{parentWindow}->scrollTo(0, $doc->{body}->{scrollHeight});
} # end subroutine scroll_page_bottom definition
########################################################################

=head2 get_selection

  my $string = $hw->get_selection;

=cut

sub get_selection {
  my $self = shift;

  my $doc = $self->GetOLE->document();
  my $tr = $doc->{selection}->createRange();
  return($tr->{Text});
} # end subroutine get_selection definition
########################################################################

=head2 get_selection_as_html

  my $html = $hw->get_selection_as_html;

=cut

sub get_selection_as_html {
  my $self = shift;

  my $doc = $self->GetOLE->document();
  my $tr = $doc->{selection}->createRange();
  return $tr->{'htmlText'};
} # end subroutine get_selection_as_html definition
########################################################################

=head2 get_selection_context

  my ($pre, $str, $post) = $hw->get_selection_context($context_length);

=cut

sub get_selection_context {
  my $self = shift;
  my ($blength) = @_;
  defined $blength or $blength = 10;
  my ($pre,$post,$select);
  my $doc = $self->GetOLE->document();
  my $s_range = $doc->{selection}->createRange();

  # clone it twice, adjusting each clone according to the endpoints of
  # the original
  my $l_range = $s_range->duplicate;
  $l_range->moveStart('character', -$blength);
  $l_range->setEndPoint('EndToStart', $s_range);
  my $r_range = $s_range->duplicate;
  $r_range->moveEnd('character', +$blength);
  $r_range->setEndPoint('StartToEnd', $s_range);

  my ($l, $s, $r) = map({$_->{'Text'}} $l_range, $s_range, $r_range);
  RL('#highlight')->debug("selection got [$l][$s][$r]");
  return($l,$s,$r);
} # end subroutine get_selection_context definition
########################################################################


=head2 increase_font

Increases the font size.

  $hw->increase_font;

Currently more of a zoom since it also increases the size of images.

=cut

# TODO - make this only affect the text
sub increase_font {
  my $self = shift;
  $self->_zoomer(1);
} # end subroutine increase_font definition
########################################################################

=head2 decrease_font

Decreases the font size.

  $hw->decrease_font;

=cut

sub decrease_font {
  my $self = shift;
  $self->_zoomer(-1);
} # end subroutine decrease_font definition
########################################################################

=head2 _zoomer

  $self->_zoomer(-1);

=cut

sub _zoomer {
  my $self = shift;
  my ($dir) = @_;

  my $step = 0.2;
  my $min = 0.2;

  my $zoom = $self->get_zoom;
  $zoom += $dir * $step;
  $zoom = $min if($zoom < $min);

  $self->set_zoom($zoom);
} # end subroutine _zoomer definition
########################################################################

=head2 get_zoom

  my $zoom = $hw->get_zoom;

=cut

sub get_zoom {
  my $self = shift;

  my $st = $self->GetOLE->document->{body}->{Style};

  # get and/or initialize the zoom level
  my $zoom = $self->SUPER::get_zoom;
  $zoom and return($zoom);
  $zoom = $st->getAttribute('zoom');
  $zoom = 1 if($zoom eq '');
  $self->SUPER::set_zoom($zoom);
  return($zoom);
} # end subroutine get_zoom definition
########################################################################

=head2 set_zoom

  $hw->set_zoom($zoom);

=cut

sub set_zoom {
  my $self = shift;
  my ($zoom) = @_;

  my $st = $self->GetOLE->document->{body}->{Style};
  $st->setAttribute('zoom', $zoom);
  WARN("set zoom $zoom");
  $zoom = $st->getAttribute('zoom');
  WARN("zoom set $zoom");
  $self->SUPER::set_zoom($zoom);
  return($zoom);
} # end subroutine set_zoom definition
########################################################################

#sub register_get_file {
#  my ($self, $code) = @_;
#  my $old_Build run_clientcode = $self->{WxHTMLShim}{get_file};
#  $self->{WxHTMLShim}{get_file} = $code;
#  return $old_code;
#}

#sub register_url_changed {
#  my ($self, $code) = @_;
#  my $old_code = $self->{WxHTMLShim}{url_changed};
#  $self->{WxHTMLShim}{url_changed} = $code;
#  return $old_code;
#}
#
#sub register_form_post {
#  my ($self, $code) = @_;
#  my $old_code = $self->{WxHTMLShim}{form_post};
#  $self->{WxHTMLShim}{form_post} = $code;
#  return $old_code;
#}
#
#sub register_form_get {
#  my ($self, $code) = @_;
#  my $old_code = $self->{WxHTMLShim}{form_get};
#  $self->{WxHTMLShim}{form_get} = $code;
#  return $old_code;
#}

## This is what's called when someone clicks a link
#sub OnLinkClicked {
#  my ($self, $link) = @_;
#  warn qq(link: $link\n);
#  my $url = _extract_url($link);
#  # TODO: push url on history stack
#  if($link=~/pkg:\/\/(.*)/i){
# XXX XXX XXX XXX don't do this:
#                               $self->{html_view_1}->get_html_by_id($1);
#                              }
#
#  #if (exists $self->{WxHTMLShim}{url_changed}) {
#  #  $self->{WxHTMLShim}{url_changed}($self, $url);
#  #  return;
#  #} else {
#    $self->{wbOLE} = $self->GetOLE();
#    return $self->{wbOLE}->Navigate($url);
#
#  #}
#}

#sub _extract_url{
#  my ($url)=@_;
#  #return 'E:/osoft.com_svn/src/t/test_packages/bsd_big.png';# XXX image test
#  print $url->GetHref();
#  return $url->GetHref();
#}
#sub OnOpeningURL {
#  my ($self, $type, $url, $redirect) = @_;
#  if (exists $self->{WxHTMLShim}{get_file}) {
#  } else {
#  }
#
#}

=head1 AUTHOR

Gary Varnell

Eric Wilhelm <ewilhelm at cpan dot org>

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

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
