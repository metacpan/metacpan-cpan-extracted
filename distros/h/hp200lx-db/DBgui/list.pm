#!/usr/local/bin/perl
# FILE DBgui/list.pm
#
# list view component of the HP-200LX/DB GUI
#
# written:       1998-03-08
# latest update: 2001-03-11  2:23:23
# $Id: $
#

package HP200LX::DBgui::list;

use strict;
use vars qw($VERSION @ISA);
use Exporter;

$VERSION= '0.09';
@ISA= qw(Exporter HP200LX::DBgui);

use Tk;

# ----------------------------------------------------------------------------
sub new
{
  my $class= shift;
  my $DBgui= shift;
  my $view= shift;      # NUMBER!!! (not the name) of the view
  my $title= shift;
  my %pars= @_;

  print ">>> list pars=", join (':', %pars), "\n";
  my $height= 15;       # || shift?

  my $db= $DBgui->{db};
  my $vptd= $db->find_viewptdef ($view)
            || $db->find_viewptdef ($view= 0)
            || return;

  my $vpt_name= $vptd->{name};
  $view= $vptd->{index};
  print "view=$view name=$vpt_name\n";
  my $fd= $db->{fielddef};      # description abuot data types
  my ($col, %fields, $top);
  my ($mb_v);

  my @columns= (); # column number to name mapping
  my @lb= ();   # column number to list box mapping
  # &HP200LX::DB::vpt::show_viewptdef ($vptd, *STDOUT);
  my $cols= $vptd->{cols};

  unless (defined ($top= $pars{top}))
  {
    $top= MainWindow->new ();
    $top->title ("$title [$vpt_name]");

    # menu bar
    my $mb= $top->Frame (-relief => 'raised', -width => 40);

    # menu item "view"
    $mb->pack (-side => 'top', -fill => 'x');
    my $mb_f= $mb->Menubutton (-text => 'File', -relief => 'raised')
                 ->pack (-side => 'left', -padx => 2, -fill => 'x');
    $mb_f->command (-label => 'Hide', -command => sub {$top->withdraw ();});
    $mb_f->command (-label => 'Exit', -command => sub {exit});

    $mb_v= $mb->Menubutton (-text => 'View', -relief => 'raised')
               ->pack (-side => 'left', -padx => 2, -fill => 'x');
    $mb_v->command (-label => 'select view', -command => sub {$DBgui->open_vpt_list});
    $mb_v->command (-label => 'dump def',
      -command => sub {&HP200LX::DB::vpt::show_viewptdef ($vptd, *STDOUT);});
  }

  my $List_View=
  {
    DBgui => $DBgui,
    db => $db,

    num => 0,           # number of records
    disp => 0,          # record currently shown

    top => $top,
    view => $view,
    vptd => $vptd,
    vptt => [],         # filled in later on
    columns => \@columns,
    lists => \@lb,
  };
  bless $List_View, $class;

  # record bar
  &HP200LX::DBgui::create_record_bar ($top, $List_View, $DBgui);

  my $sbf= $top->Frame ();
  $sbf->Label()->pack (-side => 'top'); # place holder
  my $sb= $sbf->Scrollbar (-orient => 'vertical', -width => 10)
          ->pack (-side => 'bottom', -fill => 'y', -expand => 1);
  $List_View->{scroll}= $sb;

  # 1. produce the main widget as a horizontal composition of
  #    frames consisting of
  #    + a Label used as heading and
  #    + a Listbox used to show the data
  # 2. map column names and Listbox items where data can be filled in later
  my ($name, $lb);
  foreach $col (@$cols)
  {
    my $num= $col->{num};
    my $vc= $top->Frame ();
    my $fe= $fd->[$num];
    $name= $fe->{name};

    $vc->Label (-text => $name, -width => $col->{width}, -relief => 'ridge')
         ->pack (-side => 'top', -fill => 'x');
    $lb= $vc->Listbox (-width => $col->{width},
                       -height => $height,
                       -yscrollcommand => ['set', $sb])
              ->pack (-side => 'bottom', -fill => 'both', -expand => 1);

    $vc->pack (-side => 'left', -fill => 'both', -expand => 1);

    push (@columns, $name);
    push (@lb, $lb);
  }

  $sbf->pack (-side => 'left', -fill => 'y');
  $sb->configure (-command => ['yview', $List_View]);

  foreach $lb (@lb)
  {
    $lb->bind ('<Double-1>' => sub { $List_View->select_item ($lb); } );
  }

  $mb_v->command (-label => 'refresh',
    -command => sub {$List_View->show_rows (1);});

  $List_View->show_rows (0);
  $List_View;
}

# ----------------------------------------------------------------------------
sub show_rows
{
  my $List_View= shift;
  my $forced_update= shift;

  my $view=     $List_View->{view};
  my $db=       $List_View->{db};
  my $columns=  $List_View->{columns};
  my $lists=    $List_View->{lists};

  my $vptt= $db->find_viewpttable ($view);
  $List_View->{vptt}= $vptt;

  # fill data items into each cell
  if ($forced_update || $vptt == undef || $#$vptt < 0)
  { # hack up a faked view point table; T2D: refresh the real table
    $vptt= $db->refresh_viewpt ($view);
  }

  my $max= $db->get_last_index ();
# print ">>> insert_row: vptt=", $#$vptt+1, " max=$max\n";

  # use view point table to produce the right sorting of the items
  my ($i, $j);
  for ($j= 0; $j <= $#$columns; $j++)
  {
    $lists->[$j]->delete (0, 'end');
  }

  foreach $i (@$vptt)
  {
# print ">>>> insert: i=$i\n";
    my $rec= $db->FETCH ($i) || next;  # or bail out ???
# print ">>>> insert: i=$i found\n";
    for ($j= 0; $j <= $#$columns; $j++)
    {
      my $s= $rec->{$columns->[$j]};
      $s=~ tr/\r\n /   /s;
      $lists->[$j]->insert ('end', $s);
    }
  }

  $List_View->{num}= 1+ $#$vptt;
}

# ----------------------------------------------------------------------------
# vertical scroll method for a composite list view widget:
# calls yview method for each list
sub yview
{
  my $w= shift;
  foreach (@{$w->{lists}}) { $_->yview (@_); }
}

# ----------------------------------------------------------------------------
sub select_item
{
  my $DBlist= shift;
  my $listbox= shift;

  my $lb_idx= $listbox->index ('active');
  my $db_idx= $DBlist->{vptt}->[$lb_idx];
  $DBlist->{disp}= $lb_idx;

  print ">>> show_card lb_idx=$lb_idx db_idx=$db_idx\n";
  $DBlist->{DBgui}->show_card ($db_idx+1);
}

# ----------------------------------------------------------------------------
# Place Holder methods
sub add_record { print "List View Add Record not yet implemented!\n"; }
sub show_record
{
  my ($DBlist, $num, $whence)= @_;

  if ($whence == 2)     { $DBlist->{disp}= $DBlist->{num} - $num; }
  elsif ($whence == 1)  { $DBlist->{disp} += $num; }
  else                  { $DBlist->{disp}= $num; }

  $num= $DBlist->{disp};
  $num= $DBlist->{disp}= 1 if ($num < 1);
  $num= $DBlist->{disp}= $DBlist->{num} if ($num > $DBlist->{num});

  my $db_idx= $DBlist->{vptt}->[$num];

  print ">>> show_card num=$num\n";
  $DBlist->{DBgui}->show_card ($db_idx+1);
}

