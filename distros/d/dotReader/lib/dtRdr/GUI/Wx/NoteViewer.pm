package dtRdr::GUI::Wx::NoteViewer;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use dtRdr::Note;
use dtRdr::Logger;
use dtRdr::HTMLWidget;

use Wx;
use base 'Wx::Panel';
use Wx::Event qw(
  EVT_BUTTON
  EVT_SPLITTER_SASH_POS_CHANGED
  EVT_SPLITTER_SASH_POS_CHANGING
  EVT_SPLITTER_DOUBLECLICKED
);

use WxPerl::ShortCuts;

use Class::Accessor::Classy;
ro qw(
  frame
  bv_manager
  htmlwidget
  window
  state
  title_bar
  bt_goto
  bt_edit
  bt_delete
  bt_close
);
rw qw(
  notebar_changing
);
rs thread => \ (my $set_thread);
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::GUI::Wx::NoteViewer - a special Wx::Panel

=head1 SYNOPSIS

=cut

=head2 new

  my $nv = dtRdr::GUI::Wx::NoteViewer->new($parent, @args);

=cut

sub new {
  my $class = shift;
  my ($parent, @args) = @_;

  my $self = $class->SUPER::new($parent, @args);

  return($self);
} # end subroutine new definition
########################################################################

=head2 init

  $nv->init($frame);

=cut

sub init {
  my $self = shift;
  my ($frame) = @_;

  { # copy-in some frame stuff
    $self->{frame}      = $frame;
    $self->{bv_manager} = $frame->bv_manager;
    $self->{window}     = $frame->right_window;
    $self->{state}      = $frame->state;
  }

  $self->__create_children;
  $self->__do_properties;
  $self->__do_layout;

  # TODO make url_handler be something besides $self
  $self->htmlwidget->init($self, url_handler => $self);

  $self->SetMinSize(Wx::Size->new(-1, 0));

  { # connect the buttons
    my @button_map = (
      ['goto'   => 'goto_note'],
      #['edit'   => 'edit_note'],
      #['delete' => 'delete_note'],
      ['close'  =>
        sub { $self->notebar_toggle if($self->state->notebar_open); }
      ],
    );
    foreach my $row (@button_map) {
      my ($action, $sub) = @$row;
      $sub = eval("sub {\$self->$sub}") unless(ref($sub) eq 'CODE');
      my $bt_name = 'bt_' . $action;
      EVT_BUTTON($self, $self->$bt_name, sub {
        WARN("$action button");
        $sub->();
      });
    }
  } # end buttons

  EVT_SPLITTER_SASH_POS_CHANGING($self->window, $self->window,
    sub { $self->set_notebar_changing(1); $_[1]->Skip }
  );
  EVT_SPLITTER_SASH_POS_CHANGED($self->window, $self->window,
    sub { $self->notebar_changed($_[1]) }
  );
  EVT_SPLITTER_DOUBLECLICKED($self->window, $self->window,
    sub { $self->notebar_toggle() }
  );

} # end subroutine init definition
########################################################################

=head2 load_url

Acts as a url_handler for the viewer's htmlwidget.

  $self->load_url($url, $killit);

=cut

sub load_url {
  my $self = shift;
  my ($url, $kill) = @_;
  #if($^O eq 'MSWin32') { # now, this is just getting silly
    $kill and $kill->(); # because we're loading it in another pane
  #}

  use URI;
  my $uri = URI->new($url);
  RL('#links')->debug("nv pondering $url");
  if(($uri->scheme || '') eq 'dr') {
    RL('#links')->debug("nv dr link: '$url'");
    my $auth = $uri->authority;
    if($auth eq 'NOTEVIEW') {
      $kill and $kill->();

      my @parts = split(/\/+/, $uri->path);
      shift(@parts); # drop leading null
      # maybe no biggie if there's too many
      (@parts == 2) or warn
        "scary path (@parts) '$url', probably broken...";
      my ($action, $id) = @parts;
      WARN "do $action to $id";
      my $method = $action . '_note';
      $self->can($method) or die "no way to handle action '$action'";
      $self->$method($id);

      return;
    }
  }

  $self->bv_manager->book_view->load_url(@_);
} # end subroutine load_url definition
########################################################################


=head2 __create_children

  $self->__create_children;

=cut

sub __create_children {
  my $self = shift;

  $self->{title_bar} =
    Wx::StaticText->new($self, -1, "Title goes here", DefPS);
  $self->{"bt_$_"} = $self->aBitmapButton(
    dtRdr::GUI::Wx::Utils->Bitmap("nv_button_$_")
  ) for(qw(goto close));
  $self->{htmlwidget} = dtRdr::HTMLWidget->new([$self, -1, DefPS]);

} # end subroutine __create_children definition
########################################################################
  sub aBitmapButton { # TODO WxPerl::Spawn or something
    my $self = shift; Wx::BitmapButton->new($self, -1, @_);
  }

=head2 __do_layout

  $self->__do_layout;

=cut

sub __do_layout {
  my $self = shift;

  my $s = $self->{sizer} = Wx::BoxSizer->new(wV);
  my $gs = $self->{gridsizer} = Wx::FlexGridSizer->new(1, 3, 0, 0);
  $gs->Add($self->title_bar, 0, Exp|Ams, 0);
  $gs->Add($self->bt_goto, 0, Ams, 0);
  #$gs->Add($self->bt_edit, 0, Ams, 0);
  #$gs->Add($self->bt_delete, 0, Ams, 0);
  $gs->Add($self->bt_close, 0, Ams, 0);
  $gs->AddGrowableCol(0);
  $s->Add($gs, 0, WX"RIGHT|EXPAND|ALIGN_RIGHT|ADJUST_MINSIZE", 0);
  $s->Add($self->htmlwidget, 1, Exp, 0);
  $self->SetAutoLayout(1);
  $self->SetSizer($s);
  $s->Fit($self);
  $s->SetSizeHints($self);

} # end subroutine __do_layout definition
########################################################################

=head2 __do_properties

  $self->__do_properties;

=cut

sub __do_properties {
  my $self = shift;

  $self->title_bar->SetFont(Wx::Font->new(12, Def, WX"NORMAL", WX"BOLD", 0, ""));
  $self->bt_goto->SetToolTipString("goto");
  #$self->bt_edit->SetToolTipString("edit");
  #$self->bt_delete->SetToolTipString("delete");
  $self->bt_close->SetToolTipString("close");

} # end subroutine __do_properties definition
########################################################################

=head2 setup

  $nv->setup;

=cut

sub setup {
  my $self = shift;

  $self->no_note;

  if(0) {
    my $greeting =
      qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">) .
      "<html><body>no note</body></html>" .
      '';
    $self->htmlwidget->SetPage($greeting);
  }

  { # set the size
    my $win = $self->window;
    my ($x, $y) = $win->GetSizeWH;
    0 and WARN("window size $x, $y");

    # might Hide if the button slivers are annoying, but then we'll have
    # to manually show it
    #$self->Show(0);

    $win->SetSashPosition($y);
    # NOTE a bug on the widget?
  }

} # end subroutine setup definition
########################################################################

=head2 _enable_buttons

  $self->_enable_buttons;

=cut

sub _enable_buttons {
  my $self = shift;
  my ($bool) = @_;
  $bool = 1 unless(@_);
  defined($bool) or croak("invalid");

  foreach my $name (qw(
    goto
  )) {
    my $attribute = 'bt_' . $name;
    $self->$attribute->Enable($bool);
  }
} # end subroutine _enable_buttons definition
########################################################################

=head2 _disable_buttons

  $self->_disable_buttons;

=cut

sub _disable_buttons {
  my $self = shift;
  $self->_enable_buttons(0);
} # end subroutine _disable_buttons definition
########################################################################

=head2 notebar_changed

  $self->notebar_changed($event);

=cut

sub notebar_changed {
  my $self = shift;
  my ($event) = @_;

  RL('#notebar')->debug("'notebar_changed' fired");

  # this fires on a resize -- really bad, so we'll just track and skip
  $self->notebar_changing or return;
  $self->set_notebar_changing(0);

  # TODO there's one more case here where the window gets shrunk such
  # that our size is forced to be reduced.  When it is shrunk or
  # expanded (ala F7) this event fires once when it is done (~because
  # we're on the bottom here and gravity says so.)  At the moment, we're
  # not remembering the position that results from shrinkage (which is
  # good) but if the user re-enlarges the window and then fires the
  # toggle, it will change from the forced size to the remembered size,
  # which could be unsettling.  We should probably see if we have enough
  # room to reasonably expand back to our remembered size and then do
  # it.

  my $state = $self->state;
  # ok, this only fires on manual drags and not SetSashPosition() ?
  my $new_pos = $event->GetSashPosition;
  my $height = ($self->window->GetSizeWH)[1];
  my $nb_size = $height - $new_pos;
  RL('#notebar')->debug("pos changed to $new_pos ($nb_size)");

  if($nb_size < 60) {
    # meh, call it a draggy-toggle and DWIM
    if($state->notebar_open) { # you meant close, right?
      $state->set_notebar_open(0);
      $self->window->SetSashPosition($height);
    }
    else { # magic open
      # (un?)fortunately, this means the doubleclick is not needed from
      # the closed position.  Is that inconsistent?
      $state->set_notebar_open(1);
      $self->window->SetSashPosition($height - $state->notebar_position);
    }
  }
  else {
    # remember the new position (from the bottom)
    $state->set_notebar_position($nb_size);
    $state->set_notebar_open(1); # just in case
  }
} # end subroutine notebar_changed definition
########################################################################

=head2 notebar_toggle

  $self->notebar_toggle($event);

=cut

sub notebar_toggle {
  my $self = shift;
  my ($event) = @_;
  my $state = $self->state;
  my $pos = $self->window->GetSashPosition();
  my $height = ($self->window->GetSizeWH)[1];

  # TODO focus whichever tab is on top
  RL('#notebar')->debug("window toggle: $pos");
  # NOTE mac gets silly about this if SashPosition is less than 3
  my $open = $state->notebar_open;
  $self->window->SetSashPosition(
    $height - ($open ? 0 : $state->notebar_position)
  );
  $state->set_notebar_open(! $open);
} # end subroutine notebar_toggle definition
########################################################################


=head2 be_open

  $nv->be_open;

=cut

sub be_open {
  my $self = shift;
  $self->notebar_toggle unless($self->state->notebar_open);
} # end subroutine be_open definition
########################################################################

=head2 be_closed

  $nv->be_closed;

=cut

sub be_closed {
  my $self = shift;
  $self->notebar_toggle if($self->state->notebar_open);
} # end subroutine be_closed definition
########################################################################

=head1 Note Manipulation

The viewer has a concept of a "current" note, which is updated by the
BVManager and the C<show_note()> method.


=head2 thread_id

Return the ID of the current thread.  Returns undef if there is not one.

  my $id = $nv->thread_id;

=cut

sub thread_id {
  my $self = shift;
  my $thread = $self->thread;
  defined($thread) or return();
  return($thread->id);
} # end subroutine thread_id definition
########################################################################

=head2 no_note

Quit showing whatever note you were showing for whatever reason?

  $nv->no_note;

=cut

# TODO rename as clear() ?

sub no_note {
  my $self = shift;
  # disable the control buttons
  $self->_disable_buttons;
  $self->title_bar->SetLabel('- no note -');
  $self->htmlwidget->SetPage('');
  if(my $note = delete($self->{note})) {
    $note->DESTROY;
  }
  $self->$set_thread(undef);
  # TODO anything else?
  $self->be_closed;
} # end subroutine no_note definition
########################################################################

=head2 goto_note

  $self->goto_note;

=cut

sub goto_note {
  my $self = shift;
  $self->bv_manager->book_view->jump_to($self->thread->note);
} # end subroutine goto_note definition
########################################################################

=head2 edit_note

  $self->edit_note($id);

=cut

sub edit_note {
  my $self = shift;
  my ($id) = @_;

  # need to get the note from ...
  my $got = $self->have($id) or die "I don't have that note ($id)";
  if($got->is_fake) {
    die "can't edit the dummy notes";
  }
  $self->bv_manager->edit_note($got);
} # end subroutine edit_note definition
########################################################################
# XXX grr, this is inefficient, but I don't want to deal with staleness
# with the current architectural state of things
  sub have { my $self = shift; my ($id) = @_;
    my $thread = $self->thread or die "no thread here?";
    my %have = $thread->rmap(sub {$_->id => $_});
    my $got = $have{$id} or return();
    return($got->note);
  }

=head2 delete_note

  $self->delete_note($id);

=cut

sub delete_note {
  my $self = shift;
  my ($id) = @_;
  defined($id) or die "wrong api";
  # should just bv_manager->**_note() ?
  WARN "lookup";
  my $note = $self->have($id) or die "I don't have that note";
  WARN "do it";
  if($note->is_fake) {
    die "can't delete the dummy notes";
  }

  # TODO "are you sure" dialog

  $note->book->delete_note($note);
} # end subroutine delete_note definition
########################################################################

=head2 reply_note

  $self->reply_note($id);

=cut

sub reply_note {
  my $self = shift;
  my ($id) = @_;

  my $got = $self->have($id) or die "I don't have that note ($id)";
  my $title = $got->title;
  $title = "Re:  $title" unless($title =~ m/^re: */i);
  my $note = dtRdr::Note->create(
    node => $got->node,
    range => $got,
    title => $title,
    references => [$got->id, $got->references],
  );
  $self->bv_manager->create_note($note,
    ($got->public ? (public => 1) : ())
  );
} # end subroutine reply_note definition
########################################################################

=head2 show_note

  $nv->show_note($note_object);

=cut

sub show_note {
  my $self = shift;
  my ($note) = @_;

  $self->_enable_buttons;
  $self->be_open;

  # make a thread
  my $thread = $note->book->note_thread($note);
  my $tc = 'dtRdr::NoteThread';
  ($thread) = $tc->create($thread) unless($thread->isa($tc));
  #WARN "got ", join(",", $thread->rmap(sub {$_->id}));

  $self->$set_thread($thread);

  $self->render;
} # end subroutine show_note definition
########################################################################

=head2 note_deleted

Notify the view that the annotation was deleted.

  $nv->note_deleted($anno);

=cut

sub note_deleted {
  my $self = shift;
  my ($note) = @_;

  my $did = $note->id;
  my @list = grep({(not $_->is_fake) and ($_->id ne $did)}
    $self->thread->rmap(sub {$_->note}));
  if(@list) {
    # there's something left;
    $self->show_note($list[0]);
  }
  else {
    $self->no_note;
  }

} # end subroutine note_deleted definition
########################################################################

=head2 render

Render the current thread.

  $nv->render;

=cut

sub render {
  my $self = shift;

  my $thread = $self->thread or croak("no thread");

  my $title = $thread->note->title;
  $title = '--' unless defined($title);
  $self->title_bar->SetLabel($title);

  # TODO something about this css and html wrapping sillyness
  my $css = <<'CSS';
h1.title {
  color: #FF0000;
  font-size: 15px;
}
body {
  color: #000000;
  font-size: 12px;
  font-family: Geneva, Arial, Helvetica;
  background-color: white;
  margin-top: 0px;
  margin-left: 0px;
}
CSS

  my $page =
    '<html><head>' .
    '<style>' . $css . '</style>' .
    '</head><body>' .
    #'<h1 class="title">' . $title . '</h1>' .
    #'<p>' .
    #(defined($content) ? $content : '-- no content --') .
    #'</p>' .
    qq(<span style="float:right;background-color:yellow"
      ><i>NOTE: this view is a work in progress.</i></span>) .
    join("\n", $self->render_thread($thread)) .
    '</body></html>';

  DBG_DUMP('NOTEVIEW', 'notes.html', sub {$page});
  $self->htmlwidget->SetPage($page);
} # end subroutine render definition
########################################################################

  my $w = sub { # TODO something something
    my ($tag, $args, $text) = @_;
    unless($text) {
      $text = $args;
      $args = {};
    }
    my $atts = '';
    foreach my $k (keys(%$args)) {
      $atts .= qq( $k="$args->{$k}");
    }
    return(join("\n",
      "<$tag$atts>",
      $text, "</$tag>"
    ));
  };

=head2 render_thread

  my $html_chunk = $nv->render_thread($thread);

=cut

sub render_thread {
  my $self = shift;
  my ($thread) = @_;

  my $subref = sub {
    my ($n) = @_;
    if($n->is_dummy) { # TODO this fixup should happen elsewhere?
      my $p = $n->parent;
      #$p or WARN "no p for me!";
      my $title = ($p ? $p->note->title : '---') . ' <i>(missing)</i>';
      my $note = $n->note;
      $note->set_title($title);
      $note->set_content(
        '-- note \'' . $note->id . '\' not available --'
      );
    }
    # prepend indentation
    my $indent = ('&#160;'x5)x ($n->depth + 1) || '';
    #WARN "indent $indent";
    return(
      $w->('tr',
        $w->('td',
          $w->('table',
            $w->('tr',
              $w->('td', $indent) .
              $w->('td', $self->render_note($n->note))
            )
          )
        ) .
        $w->('td', $self->render_meta($n->note))
      )
    );
  };
  return($w->('table',
    {width => '100%'},
    join("\n", $thread->rmap($subref))));
} # end subroutine render_thread definition
########################################################################

=head2 render_note

  my $html_chunk = $nv->render_note($note);

=cut

sub render_note {
  my $self = shift;
  my ($note) = @_;

  my $title = $note->title;
  my $content = $note->content;
  $content = '' unless(defined($content));

  my $chunk = $w->('h3', $title) .  $content;
  return($chunk);
} # end subroutine render_note definition
########################################################################

=head2 render_meta

  my $table = $nv->render_meta($note);

=cut

sub render_meta {
  my $self = shift;
  my ($note) = @_;

  my $id = $note->id;

  my $p = $note->public;
  my $user = ($p ?
    ('<b>' . (defined($p->owner) ? $p->owner : 'you') .
      '</b> on ' . $p->server # TODO get servername?
    ) :
    '<u>private</u>'
  );

  my $ts = $note->mod_time || $note->create_time;
  my ($date, $time);
  if($ts) {
    ($date, $time) = $self->date_format($ts);
  }
  else {
    $time = '~sometime~';
    $date ='';
  }

  my @links;
  my $href_base = 'dr://NOTEVIEW/';
  push(@links, map(
    {$w->('a', {href => $href_base . "$_/$id"}, $_)}
    'reply',
    ($note->is_fake ? () :
      (($p and defined($p->owner)) ? () : ('edit', 'delete'))
    )
  ));
  my $chunk = $w->('table',
    $w->('tr',
      $w->('td',
        join('<br/>', map({$w->('i', $_)} $user, $time, $date))
      )
    ) .
    $w->('tr',
      $w->('td', join('<br/>', @links))
    )
  );
  return($chunk);
} # end subroutine render_meta definition
########################################################################

=head1 MoveMe!

=head2 date_format

  my ($date, $time) = $package->date_format($epoch_time);

=cut

sub date_format {
  my $self = shift;
  my ($ts) = @_;

  # TODO DateTime?
  # TODO user-configurable formatting (24hr vs am/pm etc)
  # TODO fancy formatting (Today, Yesterday, etc.)
  use Date::Format ();
  my $date = Date::Format::time2str('%m/%d', $ts);
  my $time = Date::Format::time2str('%I:%M %P', $ts);
  return($date, $time);
} # end subroutine date_format definition
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
