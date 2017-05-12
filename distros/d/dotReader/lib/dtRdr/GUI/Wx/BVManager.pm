package dtRdr::GUI::Wx::BVManager;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;


use dtRdr;
use dtRdr::Book;
use dtRdr::HTMLWidget;
use dtRdr::GUI;
use dtRdr::GUI::Wx::BookView;
use dtRdr::Annotation::IO;

use Wx qw(
  wxHORIZONTAL
  wxVERTICAL
  wxEXPAND
  wxHW_NO_SELECTION
  wxDefaultSize
  wxDefaultPosition
);

use base 'Wx::Panel';

use Class::Accessor::Classy;
ro qw(
  main_frame
  book_view
  sidebar
  htmlwidget
  anno_io
  note_viewer
  bookbag
);
ro 'in_open';
no  Class::Accessor::Classy;

use dtRdr::Logger;
use dtRdr::BookBag;

=head1 NAME

dtRdr::GUI::Wx::BVManager - a container of sorts

=head1 SYNOPSIS

This widget acts as a container for multiple book views and
holding/finding various in-memory data.

=head1 Inheritance

  Wx::Panel

=cut

=head1 Constructor

=head2 new

Creates a frame.

  $bv = dtRdr::GUI::Wx::BVManager->new($parent, @blahblahblah);

=cut

sub new {
  my $class = shift;
  my ($parent, @args) = @_;

  my $self = $class->SUPER::new($parent, @args);
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head1 Setup

=head2 init

  $bvm->init($frame);

=cut

sub init {
  my $self = shift;
  my ($frame) = @_;

  $self->{main_frame} = $frame;
  $self->{sidebar} = $frame->sidebar;
  $self->{note_viewer} = $frame->note_viewer;
  $self->{bookbag} = dtRdr::BookBag->new;

  my $widget = dtRdr::HTMLWidget->new([$self, -1]);
  $self->{htmlwidget}   = $widget;
  $widget->init($self, url_handler => $self);
  $self->show_welcome;
  if($widget->can('meddle')) {$widget->meddle();}

  if(0) {
    warn "\n\n";
    warn "mainframe is ", $self->GetParent->GetParent, "\n";
    warn "event handler: ", $widget->GetEventHandler, "\n";
    warn "event handler: ", $self->GetEventHandler, "\n\n --";
  }

  # we're a pane, so we make a sizer and set it on ourself
  my $sizer = $self->{sizer} = Wx::BoxSizer->new(
    wxHORIZONTAL
    #wxVERTICAL
    );
  $sizer->Add($widget, 1, wxEXPAND, 0);
  $self->SetAutoLayout(1);
  $self->SetSizer($sizer);
  $sizer->SetSizeHints($self);

  # might need to enable this if you want to be able to flip to a
  # full-screen noteviewer
  #$self->SetMinSize(Wx::Size->new(-1, 0));

  # setup the core_link callback
  dtRdr::Book->callback->set_core_link_sub(sub {
    use URI;
    my ($file) = @_;
    return(
      URI->new('file://' . dtRdr::GUI->find_icon($file))->as_string
    );
  });

  # setup the img_src_rewrite callback
  if($widget->can('img_src_rewrite_sub')) {
    dtRdr::Book->callback->set_img_src_rewrite_sub(
      $widget->img_src_rewrite_sub
    );
  }

  # setup the sync callbacks
  # annotation_created, changed, deleted => _annotation_created ...
  foreach my $event (qw(created changed deleted)) {
    my $setter = 'set_annotation_' . $event . '_sub';
    my $action = '_annotation_' . $event;
    dtRdr::Book->callback->$setter(sub {$self->$action(@_)});
  }

  # get ourselves an annotation IO object
  my $anno_io = $self->{anno_io} =
    dtRdr::Annotation::IO->new(uri => dtRdr->user_dir . 'annotations/');
} # end subroutine init definition
########################################################################

=head2 show_welcome

  $bvm->show_welcome;

=cut

sub show_welcome {
  my $self = shift;

  my $greeting = "this is " . ref($self->htmlwidget) . "<br>";
  L->info("setting greeting");

  if(0) { # playing with anchors
    $greeting .= qq(<p><a name="top">hi</a>) .
      qq( <a href="http://osoft.com/">osoft.com</a><br>) .
      qq( <a href="http://osoft.com/foo#bar">osoft.com/foo#bar</a><br>) .
      qq( <a href="http://osoft.com/foo.html#bar">osoft.com/foo.html#bar</a><br>) .
      qq( <a href="http://osoft.com/foo.html#bar">osoft.com/index.php#bar</a><br>) .
      qq( <a href="#foo">go to foo</a>) .
      qq( <a href="#bar">or bar</a>) .
      '<br>'x80 . "\n" .
      qq(<a name="foo">welcome to foo</a>) .
      qq( would you like to <a href="#bar">visit bar</a>) .
      qq( or go back to <a href="#top">the top</a>) .
      qq(</p>) . "\n".
      '<p>'.'<br>'x80 . "\n" .
      qq(<a name="bar">welcome to bar</a></p>) .
      qq( ... off to <a href="#foo">foo</a>) .
      qq( or go back to <a href="#top">the top</a>) .
      '<br>'x80 .
      '';
  }
  elsif(0) { # more hackery
    if(defined($ENV{THOUT_HOME})) {
      $self->htmlwidget->LoadURL($ENV{THOUT_HOME});
    }
    else {
      use dtRdr::Hack;
      $greeting .= dtRdr::Hack->get_widget_img();
      $greeting =
        qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">).
        "<html><body>$greeting</body></html>";
      $self->htmlwidget->SetPage($greeting);
    }
  }
  else { # TODO something nicer here
    $greeting =
      qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">).
      "<html><body>Welcome to DotReader!</body></html>";
    $self->htmlwidget->SetPage($greeting);
  }

} # end subroutine show_welcome definition
########################################################################

=head1 GUI Control

=head2 enable

  $bvm->enable('_profile');

=head2 disable

  $bvm->disable('_profile');

=cut

sub enable  {$_[0]->{main_frame}->enable($_[1]);}
sub disable {$_[0]->{main_frame}->disable($_[1]);}

=head1 Hacks

The multi-view needs to be finished, at which point more of this will
make more sense.

=head2 load_url

This API is probably stable, but the behavior will definitely change.
Currently, this just loads directly in the widget unless there is a book
open.

  $self->load_url($url);

=cut

sub load_url {
  my $self = shift;
  my ($url) = @_;
  if(my $bv = $self->book_view) {
    $bv->load_url($url);
  }
  else {
    $self->htmlwidget->load_url($url);
  }
} # end subroutine load_url definition
########################################################################
#sub load_url { my $self = shift; $self->book_view->load_url(@_); }

=head1 Book

=head2 open_book

Opens the book object as the primary view.

  $bvm->open_book($book);

=cut

sub open_book {
  my $self = shift;
  my ($book) = @_;

  # clear and reset a lot of stuff
  $self->main_frame->set_title($book->title);
  $self->note_viewer->no_note;
  # TODO clear search results?

  # TODO if we have a book_view, freeze it, etc
  $self->{book_view} and L->info("\n\nnot done\n\n");

  # create and init the bookview
  my $bv = $self->{book_view} = dtRdr::GUI::Wx::BookView->new($book);
  $bv->init($self);
  my $sidebar = $self->sidebar;
  $bv->set_widgets(
    book_tree      => $sidebar->contents,
    note_tree      => $sidebar->notes,
    bookmark_tree  => $sidebar->bookmarks,
    highlight_tree => $sidebar->highlights,
    htmlwidget     => $self->htmlwidget
  );

  # BOOKBAG {{{
  my $bag = $self->bookbag;
  # TODO we need DESTROY on tab-close somewhere
  # for now, open one means close another
  $bag->delete($_) for($bag->list);

  # only apply if we don't have this book in the bookbag
  unless($bag->find($book->id)) {
    # disable the callbacks during the anno_io setup (or else the
    # callbacks would run before the populate() calls)
    local $self->{in_open} = 1;
    $self->anno_io->apply_to($book);
  }
  $bag->add($book);
  # BOOKBAG }}}
  
  { # populate the sidebar trees
    my @trees = qw(
      book
      note
      bookmark
      highlight
    );
    foreach my $tree (@trees) {
      my $attrib = $tree . '_tree';
      $bv->$attrib->populate($book);
    }
  }

  $bv->render_node_by_id($book->toc->id);
  $self->enable('_book');

    $self->enable('_no_drm'); # XXX needs a conditional

  $self->disable('navigation_page_up');
  $self->disable('file_add_book'); # default to disabled
  # sorry, we can't handle going back to a destroyed view object yet
  $self->disable('_history');
  $self->sidebar->select_item('contents');
} # end subroutine open_book definition
########################################################################

=head1 Notifications

=head2 _annotation_created

  $self->_annotation_created($anno);

=cut

sub _annotation_created {
  my $self = shift;
  my ($anno) = @_;

  $self->in_open and return;

  foreach my $bv ($self->find_book_views($anno->book)) {
    $bv->annotation_created($anno);
  }
  if($anno->ANNOTATION_TYPE eq 'note') {
    foreach my $nv ($self->find_note_views($anno)) {
      # rebuild thread
      $nv->show_note($anno);
    }
  }
} # end subroutine _annotation_created definition
########################################################################

=head2 _annotation_changed

  $self->_annotation_changed($anno);

=cut

sub _annotation_changed {
  my $self = shift;
  my ($anno) = @_;

  $self->in_open and return;

  # SBs for title
  foreach my $bv ($self->find_book_views($anno->book)) {
    $bv->annotation_changed($anno);
  }

  if($anno->ANNOTATION_TYPE eq 'note') {
    # check NVs if $anno->references;
    foreach my $nv ($self->find_note_views($anno)) {
      $nv->render;
    }
  }
} # end subroutine _annotation_changed definition
########################################################################

=head2 _annotation_deleted

  $self->_annotation_deleted($anno);

=cut

sub _annotation_deleted {
  my $self = shift;
  my ($anno) = @_;

  $self->in_open and return;

  foreach my $bv ($self->find_book_views($anno->book)) {
    $bv->annotation_deleted($anno);
  }

  if($anno->ANNOTATION_TYPE eq 'note') {
    # check NVs if $anno->references;
    foreach my $nv ($self->find_note_views($anno)) {
      # rebuild thread or maybe just go away
      $nv->note_deleted($anno);
    }
  }
} # end subroutine _annotation_deleted definition
########################################################################

=head1 Annotations

=head2 create_note

Open the note editor for a newly created note.  Requires an existing
note object which is not yet in the book.

  $bvm->create_note($note, %args);

=cut

sub create_note {
  my $self = shift;
  my ($note, %args) = @_;

  use dtRdr::GUI::Wx::NoteEditor;
  my $editor = dtRdr::GUI::Wx::NoteEditor->new();
  if($args{public}) {
    # TODO make that be an object?
    $editor->checkbox_public->SetValue(1);
  }

  # add the note and let the callbacks deal with the rest
  # -- user can then background this
  $note->book->add_note($note);

  my $saver = sub {
    $note->set_title($editor->text_ctrl_title->GetValue);
    $note->set_content($editor->text_ctrl_body->GetValue);
    # XXX icky
    if($editor->checkbox_public->IsChecked) {
      # TODO drop-down to pick server
      my ($server, @plus) = dtRdr->user->config->servers;
      @plus and die "ok, time to fix this bit";
      $note->make_public(
        owner => undef,
        server => $server->id,
      );
    }

    $note->book->change_note($note);
  };
  $editor->set_saver($saver);

  # TODO
  #   Q: what if they decide to come back and edit it again while that
  #     editor is still open?
  #   A: have a list of editor objects and just do $editor->Raise
  my $reverter = sub {
    $note->book->delete_note($note);
  };
  $editor->set_reverter($reverter);
  $editor->set_fields(
    title => $note->title,
    body  => $note->content,
  );

  # TODO set_autosaver

  # defer the show until here because it messes with focus otherwise
  $editor->Show(1);
} # end subroutine create_note definition
########################################################################

=head2 edit_note

Edit an existing note.

  $bv->edit_note($note);

=cut

sub edit_note {
  my $self = shift;
  my ($note) = @_;

  if(my $pub = $note->public) {
    defined($pub->owner) and die "you do not own that note";
  }

  use dtRdr::GUI::Wx::NoteEditor;
  if(0) {
  # TODO check for existing editor and raise if so
    WARN("edit_note() not done yet");
    return;
  }

  # make a new one with a proper revert
  my $editor = dtRdr::GUI::Wx::NoteEditor->new();
  $editor->set_fields(
    title => $note->title,
    body  => $note->content,
  );

  # XXX icky
  $editor->checkbox_public->SetValue(defined($note->public));
  $editor->checkbox_public->Enable(0);

  my $book = $note->book;
  my $saver = sub {
    $note->set_title($editor->text_ctrl_title->GetValue);
    $note->set_content($editor->text_ctrl_body->GetValue);
    # TODO $note->inc_rev ? or do unchange_note below ?
    $note->book->change_note($note);
  };
  $editor->set_saver($saver);
  # need to have a serialized note
  # (though this only matters if we have autosave enabled)
  my $snapshot = $note->clone;
  my $reverter = sub {
    WARN("revert not working yet");
    # we have to write into the existing object
    %$note = %$snapshot;
    # XXX only need this when autosave is enabled
    # $note->book->change_note($note);
  };
  $editor->set_reverter($reverter);
  # TODO autosaver
  # defer the show until here because it messes with focus otherwise
  $editor->Show(1);
} # end subroutine edit_note definition
########################################################################

=head2 show_note

  $bvm->show_note($note);

=cut

sub show_note {
  my $self = shift;
  my ($note) = @_;
  $self->note_viewer->show_note($note);
} # end subroutine show_note definition
########################################################################

=head1 Finding Views

This part is in flux.

=head2 find_book_views

  my @views = $bvm->find_book_views($book);

=cut

sub find_book_views {
  my $self = shift;
  my ($book) = @_;

  # TODO a bookbag, viewbag or something
  my @views = ($self->book_view);

  return(grep({$_->book == $book} @views));
} # end subroutine find_book_views definition
########################################################################

=head2 find_note_views

  my @views = $bvm->find_note_views($note);

=cut

sub find_note_views {
  my $self = shift;
  my ($note) = @_;

  my @views = ($self->note_viewer);

  my $note_id = $note->id;
  my $root_id;
  if(my @refs = $note->references) {
    $root_id = $refs[-1];
  }
  return(
    grep({
      my $id = $_->thread_id;
      defined($id) and (
        ($id eq $note_id) or (defined($root_id) and ($id eq $root_id))
      )
    } @views
    )
  );
} # end subroutine find_note_views definition
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
