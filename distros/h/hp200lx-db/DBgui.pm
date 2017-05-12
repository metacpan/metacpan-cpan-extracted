#!/usr/local/bin/perl
# FILE %gg/perl/HP200LX/DBgui.pm
#
# Graphical Userinterface for HP 200 LX DBs implemented in Tk
#
# T2D:
# + save complete DB file
# + note view and (configurable) external editor for that biest
# + alternate views:
#   + form and listing based
#   + definition and extrnal storage
#
# T2D strategy:
# + DB object should be independent of HP200 specifics
#
# written:       1998-03-01
# latest update: 2001-03-11  2:22:20
# $Id: $
#

package HP200LX::DBgui;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;

$VERSION = '0.09';
@ISA= qw(Exporter);
@EXPORT_OK= qw(browse_db);

use Tk;
use HP200LX::DBgui::card;
use HP200LX::DBgui::list;
use HP200LX::DBgui::vpt;

# ----------------------------------------------------------------------------
sub new
{
  my $class= shift;
  my $db=    shift;
  my $title= shift;
  my %pars=  @_;

  my $obj=
  {
    db => $db,
    # top => $top,      # no top level widget
    title => $title,
    cards => [],
    lists => [],        # indexed by view point number
    # vpt_list => {},   # filled in later!
  };
  bless $obj, $class;

  print ">> GUI: opts=", join (':', @_), "\n";
  my ($opt, $val);
  foreach $opt (sort keys %pars)
  {
    $val= $pars{$opt};
    print "arg: $opt=$val\n";

    if ($opt eq '-first')
    {
         if ($val eq 'card') { $obj->open_card (); }
      elsif ($val eq 'list') { $obj->open_list ($pars{'-view'}); }
      elsif ($val eq 'vpt')  { $obj->open_vpt_list (); }
    }
  }

  # $obj->open_list (0, %first) if (defined ($first{top}));

  $obj;
}

# ----------------------------------------------------------------------------
# open a list view with a given number
# NOTE: should it be possible to open more than one wigets with
# the same view point?
sub open_list
{
  my $DBgui= shift;
  my $view= shift;              # name or index

  my ($list, $vptd);
  my $db= $DBgui->{db};
  $view= (defined ($vptd= $db->find_viewptdef ($view)))
         ? $vptd->{index} : 0;

  # print ">>> open_list view=$view\n";
  if (defined ($list= $DBgui->{lists}->[$view]))
  {
    $list->{top}->raise ();
    $list->{top}->deiconify ();
    return;
  }

  my $title= $DBgui->{title} . ' '. $view;
  # print ">>> title= $title\n";
  $list= new HP200LX::DBgui::list ($DBgui, $view, $title, @_);

  $DBgui->{lists}->[$view]= $list;
}

# ----------------------------------------------------------------------------
sub hide_list
{
  my $DBgui= shift;
  my $view= shift;

  my $list;
  # print ">>> open_list view=$view\n";
  if (defined ($list= $DBgui->{lists}->[$view]))
  {
    $list->{top}->withdraw ();
  }
  1;
}

# ----------------------------------------------------------------------------
sub open_card
{
  my $DBgui= shift;

  my $title= $DBgui->{title} . ' card';
  my $card= new HP200LX::DBgui::card ($DBgui, $title, @_);
  push (@{$DBgui->{cards}}, $card);

  $DBgui->{active_card}= $card;
}

# ----------------------------------------------------------------------------
sub show_card
{
  my $DBgui= shift;
  my $db_idx= shift;

  my $active_card= $DBgui->{active_card};

  if ($active_card)
  {
    $active_card-> show_record ($db_idx, 0);
  }
  else
  {
    $active_card= $DBgui->open_card ('index' => $db_idx);
    $DBgui->set_active ($active_card);
    # T2D ?: show active card
  }
}

# ----------------------------------------------------------------------------
sub set_active          # wurde das vergessen? (GG 1998-08-09 11:53:17)
{
  my $DBgui= shift;
  $DBgui->{active_card}= shift;
}

# ----------------------------------------------------------------------------
# open a list view with a given number
# NOTE: should it be possible to open more than one wigets with
# the same view point?
sub open_vpt_list
{
  my $DBgui= shift;
  my $list;

  if (defined ($list= $DBgui->{vpt_list}))
  {
    my $top= $list->{top};

    $top->raise ();
    $top->deiconify ();
    return;
  }

  my $title= $DBgui->{title} . ' View Points';
  # print ">>> title= $title\n";
  $list= new HP200LX::DBgui::vpt ($DBgui, $title, @_);

  $DBgui->{vpt_list}= $list;
}

# ----------------------------------------------------------------------------
sub browse_db
{
  MainLoop ();
}

# ----------------------------------------------------------------------------
sub do_save
{
  my $DBgui= shift;

  my $db= $DBgui->{db};

  $db->saveDB ('test.out');
}

# ----------------------------------------------------------------------------
sub create_record_bar
{
  my ($top, $DBgui, $DBparent)= @_;

  my $key_pad= $top->Frame (-relief => 'groove');
  $key_pad->pack (-side => 'bottom', -fill => 'x');

  $key_pad->Label (-text => 'Record')->pack (-side => 'left');
  $key_pad->Button (-text => '<<', -command => sub { $DBgui->show_record (-1, 1); } )->pack (-side => 'left');
  my $ed= $key_pad->Entry (-textvariable => \$DBgui->{disp}, -width => 4)->pack (-side => 'left');
  $ed->bind ('<Return>', sub { $DBgui->show_record (0, 1); });
  $key_pad->Button (-text => '>>', -command => sub { $DBgui->show_record (1, 1); } )->pack (-side => 'left');
  $key_pad->Label (-text => 'of')->pack (-side => 'left');
  $key_pad->Entry (-textvariable => \$DBgui->{num}, -width => 4, -relief => 'flat')->pack (-side => 'left');
  $key_pad->Button (-text => 'ADD', -command => sub { $DBgui->add_record (); } )->pack (-side => 'left');

  if ($DBparent)
  {
    $key_pad->Button (-text => 'Views', -command => sub { $DBparent->open_vpt_list (); } )->pack (-side => 'left');
  }

  $key_pad->Button (-text => 'Done', -command => sub { $DBgui->hide (); } )->pack (-side => 'left');

  $key_pad;
}

# ----------------------------------------------------------------------------
# inherited to card, list, etc?
sub hide
{
  my $widget= shift;
  $widget->{top}->withdraw ();

  $widget->{visibility}= 'withdrawn';
}

# ----------------------------------------------------------------------------
1;

__END__
former top level window containing just a floating menu bar...
  my $top= MainWindow->new ();
  $top->title ($title);

  my $mb= $top->Frame (-relief => 'raised', -width => 40);
  $mb->pack (-side => 'top', -fill => 'x');

  my $mb_f= $mb->Menubutton (-text => 'File', -relief => 'raised')
               ->pack (-side => 'left', -padx => 2, -fill => 'x');
  $mb_f->command (-label => 'Save', -command => sub {$db->saveDB ('test.out');});
  $mb_f->command (-label => 'Exit', -command => sub {exit});

  my $mb_v= $mb->Menubutton (-text => 'Views', -relief => 'raised')
               ->pack (-side => 'left', -padx => 2, -fill => 'x');
