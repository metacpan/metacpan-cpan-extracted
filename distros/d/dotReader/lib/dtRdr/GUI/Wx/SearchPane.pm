package dtRdr::GUI::Wx::SearchPane;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use Wx qw(
  wxVERTICAL
  wxHORIZONTAL
  wxEXPAND
  wxRIGHT
  wxADJUST_MINSIZE
  wxTE_PROCESS_ENTER
  wxSUNKEN_BORDER
);
use base 'Wx::Panel';

use MultiTask::Minion;

use Wx::Event;

use dtRdr::Logger;
use dtRdr::Search::Book;
use dtRdr::GUI::Wx::SearchTree;
use dtRdr::GUI::Wx::Utils qw(_accel);
use dtRdr::Annotation::Range;

sub WxPerl::make_style (@) {
  my (@styles) = @_;
  my $style = 0;
  foreach my $item (@styles) {
    my $method = 'wx' . $item;
    Wx->can($method) or croak("no style $method");
    $style |= Wx->$method;
  }
  return($style);
}

use Class::Accessor::Classy;
ro qw(
  main_frame
  bv_manager
  minion
  text_ctrl
  go_button
  stop_button
  message
  tree_ctrl
  sizer
  hsizer_main
  opt_sizer
  opt_sub_sizer
  type_chooser
  search_chooser
  check_case
  lib_button
  sticky_button
  stucky_button
  hide_opts_button
  show_opts_button
);
rw 'timer';
rw 'options_sticky';
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::GUI::Wx::SearchPane - the search pane

=head1 SYNOPSIS

=cut

=head1 Constructor

=head2 new

  my $search = dtRdr::GUI::Wx::SearchPane->new($parent, blah blah);

=cut

sub new {
  my $class = shift;
  my ($parent, @args) = @_;

  my $self = $class->SUPER::new($parent, @args);

  $self->__create_children;
  $self->__do_properties;
  $self->__do_layout;

  return($self);
} # end subroutine new definition
########################################################################

=head1 Setup

=head2 __create_children

  $self->__create_children;

=cut

sub __create_children {
  my $self = shift;
  $self->{sizer} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{hsizer_main} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{opt_sizer} = Wx::FlexGridSizer->new(2,2,0,0);
  $self->{opt_sub_sizer} = Wx::BoxSizer->new(wxHORIZONTAL);

  my @PS = (Wx::wxDefaultPosition(), Wx::wxDefaultSize());
	$self->{text_ctrl} = Wx::TextCtrl->new($self, -1, "", @PS,
    wxTE_PROCESS_ENTER
  );

  # some bitmaps
  my %bmp = qw(
    go    std_button_search
    stop  std_button_stop
    stick std_button_sticky
    stuck std_button_stuck
    hide  ctrl_arrow_5_up
    show  ctrl_arrow_5_down
  );
  $_ = dtRdr::GUI::Wx::Utils->Bitmap($_) for(values(%bmp));

  {
    my @choices = (
      ['titles', 'T.O.C.'   ],
      ['text',   'Full Text'],
    );
    $self->{_type_choices} = [map({$_->[0]} @choices)];
    my $chooser =
      $self->{type_chooser} =
        Wx::Choice->new($self, -1, @PS, [map({$_->[1]} @choices)]);
    $chooser->SetSelection(0); # OSX nit
    # XXX tooltips on choicers might be too cluttered
    1 and $chooser->SetToolTipString(
      "* Titles and Table of Contents\n" .
      "* Entire text of book"
    );
  }
  {
    my @choices = (
      ['phrase', 'Phrase'],
      ['word', 'Word(s)'],
      ['regexp', 'RegExp']
    );
    $self->{_search_choices} = [map({$_->[0]} @choices)];
    my $chooser =
      $self->{search_chooser} =
        Wx::Choice->new($self, -1, @PS, [map({$_->[1]} @choices)]);
    $chooser->SetSelection(0); # OSX nit
    1 and $chooser->SetToolTipString(
      "* Free-form search\n" .
      "* Whole words only\n" .
      "* Regular expression"
    );
  }
  ($self->{go_button} = Wx::BitmapButton->new($self, -1, $bmp{go})
    )->SetToolTipString('Go');
  ($self->{stop_button} = Wx::BitmapButton->new($self, -1, $bmp{stop})
    )->SetToolTipString('Stop');
  ($self->{lib_button} = Wx::Button->new($self, -1, 'Library')
    )->SetToolTipString('Select extra books to search');
  ($self->{sticky_button} = Wx::BitmapButton->new($self, -1, $bmp{stick})
    )->SetToolTipString('Keep options open');
  $self->{stucky_button} = Wx::BitmapButton->new($self, -1, $bmp{stuck});
  $self->{check_case} = Wx::CheckBox->new($self, -1, "Case");
  ($self->{hide_opts_button} = Wx::BitmapButton->new($self, -1, $bmp{hide})
    )->SetToolTipString('Hide search options');
  ($self->{show_opts_button} = Wx::BitmapButton->new($self, -1, $bmp{show})
    )->SetToolTipString('Options');
	$self->{message} = Wx::StaticText->new($self, -1, 'no message here', @PS);
	$self->{tree_ctrl} = dtRdr::GUI::Wx::SearchTree->new($self, -1, @PS,
    WxPerl::make_style qw(
      TR_HAS_BUTTONS
      TR_NO_LINES
      TR_LINES_AT_ROOT
      TR_DEFAULT_STYLE
      SUNKEN_BORDER
      ),
      # 'TR_HIDE_ROOT'
  );
} # end subroutine __create_children definition
########################################################################

=head2 __do_layout

  $self->__do_layout;

=cut

sub __do_layout {
  my $self = shift;

  $self->SetAutoLayout(1);
  my $sizer = $self->sizer;
  my $hsizer_main = $self->hsizer_main;
  my $opt_sizer = $self->opt_sizer;
  $self->SetSizer($sizer);
	#$sizer->Fit($self); # Is glade just wrong?
	$sizer->SetSizeHints($self);

 	$hsizer_main->Add($self->text_ctrl, 1, wxEXPAND, 0);
 	$hsizer_main->Add($self->go_button, 0, 0, 0);
 	$hsizer_main->Add($self->stop_button, 0, 0, 0);
  $hsizer_main->Show($self->stop_button, 0);
 	$sizer->Add($hsizer_main, 0, wxEXPAND|wxADJUST_MINSIZE, 0);

  $sizer->Add($self->show_opts_button, 0, wxEXPAND, 0);
  $sizer->Show($self->show_opts_button, 0);

  $opt_sizer->AddGrowableCol(0);
  $opt_sizer->Add($self->type_chooser, 0, wxEXPAND, 0);
  # TODO library select dialog
  $opt_sizer->Add($self->lib_button, 1, 0, 0);
  $opt_sizer->Add($self->search_chooser, 0, wxEXPAND, 0);
  {
    my $sub_sizer = $self->opt_sub_sizer;
    $sub_sizer->Add($self->check_case, 1, wxEXPAND, 0);
    $sub_sizer->Add($self->sticky_button, 0, wxEXPAND, 0);
    $sub_sizer->Add($self->stucky_button, 0, wxEXPAND, 0);
    $sub_sizer->Show($self->stucky_button, 0);

    $opt_sizer->Add($sub_sizer, 0, wxEXPAND, 0);
  }
  1 or $opt_sizer->Show($self->lib_button, 0);
  $sizer->Add($opt_sizer, 0, wxEXPAND, 0);
  1 or $sizer->Show($opt_sizer, 0);

  $sizer->Add($self->hide_opts_button, 0, wxEXPAND, 0);

  $sizer->Add($self->message, 0, 0, 0);
  $sizer->Show($self->message, 0);
  1 or $sizer->Show(1, 0); # hides it

 	$sizer->Add($self->tree_ctrl, 1, wxEXPAND, 0);

  $self->set_options_sticky(0);
  $self->_show_options(1);

} # end subroutine __do_layout definition
########################################################################

=head2 __do_properties

  $self->__do_properties;

=cut

sub __do_properties {
  my $self = shift;
  $self->tree_ctrl->SetBackgroundColour(Wx::Colour->new(244, 245, 255));
} # end subroutine __do_properties definition
########################################################################

=head1 Methods

=head2 init

  $pane->init($frame);

=cut

sub init {
  my $self = shift;
  my ($frame) = @_;

  $self->{main_frame} = $frame;
  my @attributes = qw(
    bv_manager
  );
  foreach my $attrib (@attributes) {
    my $l_attrib = $attrib;
    $self->{$l_attrib} = $frame->$attrib;
  }

  my $starter = sub {$_[1]->Skip; $self->search};
  my $stopper = sub {$_[1]->Skip; $self->stop_search};
  # keys
  Wx::Event::EVT_TEXT_ENTER($self, $self->text_ctrl, $starter);
  $self->SetAcceleratorTable( Wx::AcceleratorTable->new(
    $self->_accel('ESCAPE', $stopper))
  );

  # buttons
  Wx::Event::EVT_BUTTON($self->go_button, -1, $starter);
  Wx::Event::EVT_BUTTON($self->stop_button, -1, $stopper);

  { # expando
    my $show = sub {$_[1]->Skip; $self->_show_options(1)};
    my $hide = sub {$_[1]->Skip; $self->_show_options(0)};
    Wx::Event::EVT_BUTTON($self->show_opts_button, -1, $show);
    Wx::Event::EVT_BUTTON($self->hide_opts_button, -1, $hide);
  }
  { # sticky
    my $stick = sub {$_[1]->Skip; $self->set_options_sticky(1)};
    my $stuck = sub {$_[1]->Skip; $self->set_options_sticky(0)};
    Wx::Event::EVT_BUTTON($self->sticky_button, -1, $stick);
    Wx::Event::EVT_BUTTON($self->stucky_button, -1, $stuck);
  }

  # pretend we're the main_frame
  $self->tree_ctrl->init($self);

  # disable this for now
  $self->lib_button->Enable(0);
} # end subroutine init definition
########################################################################

=head2 search

  $self->search;

=cut

sub search {
  my $self = shift;
  WARN("search");

  if($self->minion) {
    delete($self->{minion})->quit;
    die "search in bad state";
  }

  my $bvm = $self->bv_manager;

  my $bv = $bvm->book_view or return;

  my $book = $bv->book;
  $book or die "no book?";
  $book->drop_selections;


  my $find = $self->text_ctrl->GetValue;
  length($find) or return;
  L->debug("search for $find");

  my $type = $self->get_type_choice;

  { # setup the regexp
    my $search = $self->get_search_choice;
    my $mod = $self->check_case->IsChecked ? '#' : 'i';
    if($search eq 'regexp') {
      $find = qr/(?$mod)$find/
    }
    elsif($search eq 'word') {
      $find = qr/(?$mod)\b\Q$find\E\b/;
    }
    elsif($search eq 'phrase') {
      $find = qr/(?$mod)\Q$find\E/;
    }
  }
  L->debug("regexp compiled to $find");

  $self->hide_message;
  $self->hide_options;
  $self->enable_search(0);

  my $tree = $self->tree_ctrl;
  $tree->DeleteAllItems;
  $self->{_hits} = {};

  if($type eq 'text') { # TODO other types
    $self->search_book($find, $book);
  }
  elsif($type eq 'titles') {
    $self->search_toc($find, $book);
  }
  else {
    die "'$type' type searches are not supported";
  }


} # end subroutine search definition
########################################################################

=head2 search_toc

  $self->search_toc($regexp, $book);

=cut

sub search_toc {
  my $self = shift;
  my ($find, $book) = @_;

  # XXX bah -- lots of this is a copy of search_book, but I don't see a
  # good refactor right now.

  my $tree = $self->tree_ctrl;
  $tree->book_root($book);

  my @nodes = $book->visible_nodes; # that's about it for this

  # focus the tree on the first hit
  my $first_hit; $first_hit = sub {
    undef($first_hit);
    $tree->SetFocus;
    $tree->SelectItem($_[0]);
  };

  require Time::HiRes;
  my $start_time = Time::HiRes::time();
  my $hits = 0;
  my $minion = MultiTask::Minion->make(sub {
    my $m = shift;
    return(
    work => sub {
      my $node = shift(@nodes);
      unless($node) { # done
        $m->finish;
        L->debug('search done');
        return;
      }
      my $title = $node->title;
      #WARN("search ", $title);
      $title =~ m/$find/ or return;
      #WARN("hit");
      $hits++;
      my $item = $tree->want_item($node);
      $tree->SetItemBold($item);
      $first_hit and $first_hit->($item);
    },
    finish => sub {
      L->debug("running search finish");
      $m->quit;

      # TODO regen the current page if it is for this book and has hits?

      unless($hits) { # XXX per $book
        # XXX $self->nothing_found($book) ?
        $self->flash_message("Nothing found");

        $tree->DeleteAllItems;
        # XXX $tree->delete_book_items($book);

        $self->text_ctrl->SetFocus; # XXX iff the focus is on searchbox?
      }
      else {
        my $time = sprintf('%0.1f', Time::HiRes::time() - $start_time);
        $self->flash_message('Done (' . $hits . ' hits/' . $time . 's)');
      }
    },
    quit => sub {
      $m->SUPER_quit;
      delete($self->{minion});
      $self->enable_search(1);
    },
    );
  }); # end make minion
  $self->{minion} = $minion;
  $self->main_frame->taskmaster->add($minion);
  $self->flash_message('Searching...');
} # end subroutine search_toc definition
########################################################################

=head2 search_book

  $self->search_book($regexp, $book);

=cut

sub search_book {
  my $self = shift;
  my ($find, $book) = @_;

  my $tree = $self->tree_ctrl;
  $tree->book_root($book);

  my $searcher = dtRdr::Search::Book->new(
    find => $find,
    book => $book
  );

  # focus the tree on the first hit
  my $first_hit; $first_hit = sub {
    undef($first_hit);
    $tree->SetFocus;
    $tree->SelectItem($_[0]);
  };

  require Time::HiRes;
  my $start_time = Time::HiRes::time();
  my $hits = 0;
  my $minion = MultiTask::Minion->make(sub {
    my $m = shift;
    return(
    work => sub {
      my $result = $searcher->next;
      unless($result) { # searcher done
        $m->finish;
        L->debug('search done');
        return;
      }
      #WARN("search");
      $result->null and return;
      $hits++;
      #WARN("hit");
      my $node = $result->start_node;
      my $item = $tree->want_item($node);
      my $aselect = dtRdr::AnnoSelection->claim($result->selection);
      my $hitcount;
      {
        $self->{_hits}{$node} ||= [];
        $hitcount = push(@{$self->{_hits}{$node}}, $aselect);
        # TODO abstract that
        # plus display "+$childhits" ? (bit trickier)
      }
      $tree->SetItemText($item, "($hitcount) " . $node->title);
      $tree->SetItemBold($item);
      $first_hit and $first_hit->($item);
      $book->add_selection($aselect);
    },
    finish => sub {
      L->debug("running search finish");
      $m->quit;

      # TODO regen the current page if it is for this book and has hits?

      unless(%{$self->{_hits}}) { # XXX per $book
        $self->flash_message("Nothing found");

        $tree->DeleteAllItems;
        # XXX $tree->delete_book_items($book);

        $self->text_ctrl->SetFocus; # XXX iff the focus is on searchbox?
      }
      else {
        my $time = sprintf('%0.1f', Time::HiRes::time() - $start_time);
        $self->flash_message('Done (' . $hits . ' hits/' . $time . 's)');
      }
    },
    quit => sub {
      $m->SUPER_quit;
      delete($self->{minion});
      $self->enable_search(1);
    },
    );
  }); # end make minion
  $self->{minion} = $minion;
  $self->main_frame->taskmaster->add($minion);
  $self->flash_message('Searching...');
} # end subroutine search_book definition
########################################################################

=head2 hide_message

  $self->hide_message;

=cut

sub hide_message {
  my $self = shift;
  $self->sizer->Show($self->message, 0);
  $self->sizer->Layout;
} # end subroutine hide_message definition
########################################################################

=head2 flash_message

  $self->flash_message("Nothing Found", 3);

=cut

sub flash_message {
  my $self = shift;
  my ($message, $timeout) = @_;

  if(my $timer = $self->timer) {
    $timer->Stop;
  }

  $self->message->SetLabel('');
  $self->sizer->Show($self->message, 1);
  $self->sizer->Layout;
  $self->message->SetLabel($message);
  $self->set_timer( my $timer = Wx::Timer->new($self) );
  if(defined($timeout)) {
    Wx::Event::EVT_TIMER($self, -1, sub {
      $timer->Stop;
      $self->Disconnect($timer, -1, Wx::wxEVT_TIMER());
      $self->hide_message;
      $self->set_timer(undef);
    });
    $timer->Start($timeout * 1000);
  }
} # end subroutine flash_message definition
########################################################################

=head2 enable_search

  $self->enable_search($bool);

=cut

sub enable_search {
  my $self = shift;
  my ($bool) = @_;
  $self->text_ctrl->Enable($bool);
  # enable/disable/hide the buttons
  my $go = $self->go_button;
  my $stop = $self->stop_button;
  $go->Enable($bool);
  $stop->Enable(! $bool);
  my $hsizer_main = $self->hsizer_main;
  $hsizer_main->Show(($bool ? $stop : $go), 0);
  $hsizer_main->Show(($bool ? $go : $stop), 1);
  $hsizer_main->Layout;
} # end subroutine enable_search definition
########################################################################

=head2 stop_search

  $self->stop_search;

=cut

sub stop_search {
  my $self = shift;
  WARN "stop";
  if(my $minion = $self->minion) {
    $minion->quit;
  }
  $self->flash_message("Search cancelled", 1);
  $self->_show_options(1);
  $self->text_ctrl->SetFocus;
} # end subroutine stop_search definition
########################################################################

=head2 hide_options

Hides the options pane unless the sticky is set.

  $self->hide_options;

=cut

sub hide_options {
  my $self = shift;
  $self->options_sticky and return;
  $self->_show_options(0);
} # end subroutine hide_options definition
########################################################################

=head2 _show_options

  $self->_show_options(1|0);

=cut

sub _show_options {
  my $self = shift;
  my ($bool) = @_;

  my $show = $self->show_opts_button;
  my $hide = $self->hide_opts_button;
  my $sizer = $self->sizer;

  $sizer->Show(($bool ? $show : $hide), 0);
  $sizer->Show(($bool ? $hide : $show), 1);
  $sizer->Show($self->opt_sizer, $bool);
  # XXX sadly, that pokes our subsizer for some reason
  $self->set_options_sticky($self->options_sticky);
  $sizer->Layout;
  $self->opt_sizer->Layout;
  if($bool) {
    $self->type_chooser->SetFocus;
  }
  else {
    $self->text_ctrl->SetFocus;
  }
} # end subroutine _show_options definition
########################################################################

=head2 set_options_sticky

  $self->set_options_sticky(1|0);

=cut

sub set_options_sticky {
  my $self = shift;
  my ($bool) = @_;

  my $stick = $self->sticky_button;
  my $stuck = $self->stucky_button;
  my $sizer = $self->opt_sub_sizer;
  $sizer->Show(($bool ? $stick : $stuck), 0);
  $sizer->Show(($bool ? $stuck : $stick), 1);
  $sizer->Layout;

  $self->SUPER::set_options_sticky($bool);
} # end subroutine set_options_sticky definition
########################################################################

=head2 get_type_choice

Returns the key string corresponding to the type_chooser selection.

  $self->get_type_choice;

=cut

sub get_type_choice {
  my $self = shift;

  my $i = $self->type_chooser->GetSelection;
  return($self->{_type_choices}[$i]);
} # end subroutine get_type_choice definition
########################################################################

=head2 get_search_choice

  $self->get_search_choice;

=cut

sub get_search_choice {
  my $self = shift;

  my $i = $self->search_chooser->GetSelection;
  return($self->{_search_choices}[$i]);
} # end subroutine get_search_choice definition
########################################################################

=head2 _make_found_context

  $self->_make_found_context($book, $selection);

=cut

sub _make_found_context {
  my $self = shift;
  my ($book, $selection) = @_;
  # XXX this is too big when the selection is big
  my $snode = $selection->node;
  my $nc = $book->get_NC($snode);
  my ($s, $e) = ($selection->a, $selection->b);
  WARN("got context $s, $e");
  my $len = 10;
  $s -= $len;
  $e += $len;
  $s = 0 if($s < 0);
  my $span = $snode->word_end - $snode->word_start;
  $e = $span if($e > $span);
  WARN("got context $s, $e");
  my $context = substr($nc, $s, $e - $s);
  WARN("got context $context");
  return($context);
} # end subroutine _make_found_context definition
########################################################################

=head2 show_context_menu

  $pane->show_context_menu($node, $wxPoint);

=cut

sub show_context_menu {
  my $self = shift;
  my ($node, $point) = (@_);

  my @selections;
  my $book = $node->book;

  # TODO skip-out if this was a TOC search?

  foreach my $hnode ($node, $book->descendant_nodes($node)) {
    my $hits = $self->{_hits}{$hnode};
    next unless($hits and ref($hits));
    push(@selections, @$hits);
  }

  # node with no hits in visible children
  @selections or return;

  my $menu = Wx::Menu->new;
  foreach my $hit (@selections) {
    my $string = $self->_make_found_context($book, $hit);
    $string =~ s/\t/ /g; # just in case
    $string =~ s/&/&&/g;
    my $item = $menu->Append(Wx::NewId(), $string);
    Wx::Event::EVT_MENU($menu, $item, sub {
      $_[1]->Skip;
      $self->goto_item($node, $hit);
    });
  }

  $self->PopupMenu($menu, $point);
} # end subroutine show_context_menu definition
########################################################################

=head2 goto_item

  $pane->goto_item($node, $selection);

=cut

sub goto_item {
  my $self = shift;
  my ($node, $selection) = @_;

  # TODO insert selections in book
  # TODO set the current hit somewhere in self for prev/next buttons

  my $bv = $self->bv_manager->book_view;
  $bv->render_node_by_id($node->id);

  # scroll
  if($selection) {
    $bv->jump_to($selection);
  }
} # end subroutine goto_item definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

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

# vi:ts=2:sw=2:et:sta
1;
