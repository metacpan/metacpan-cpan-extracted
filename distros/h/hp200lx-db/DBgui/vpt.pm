#!/usr/local/bin/perl
# FILE HP200LX/DBgui/vpt.pm
#
# written:       1998-08-09
# latest update: 1999-05-24 12:52:53
#

package HP200LX::DBgui::vpt;

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
  my $title= shift;
  my %pars= @_;

  print ">>> vpt pars=", join (':', %pars), "\n";

  my $top= MainWindow->new ();
  $top->title ($title);

  my $obj=
  {
    'top' => $top,
  };
  bless $obj, $class;

  my $lbf= $top->Frame ();
  my $sb= $lbf->Scrollbar (-orient => 'vertical', -width => 10)
          ->pack (-side => 'right', -fill => 'y', -expand => 1);

  my $lb= $lbf->Listbox (-width => 64, -height => 10,
                 -yscrollcommand => ['set', $sb])
              ->pack (-side => 'left', -fill => 'both', -expand => 1);

  $lbf->pack (-side => 'top', -fill => 'y');

  my $db= $DBgui->{db};
  my ($vpt, $i);
  foreach $vpt (@{$db->{viewptdef}})
  {
    $lb->insert ('end', $vpt->{name});
    $i++;
  }

  $lb->bind ('<Double-1>' => sub { &select_vpt ($DBgui, $lb, 'show'); } );

  my $bbf= $top->Frame ();
  my @buttons=
  (
    [ 'select',         sub { &select_vpt ($DBgui, $lb, 'show'); } ],
    [ 'dump def',       sub { &select_vpt ($DBgui, $lb, 'dump'); } ],
    [ 'hide',           sub { &select_vpt ($DBgui, $lb, 'hide'); } ],
    [ 'done',           sub { $obj->hide (); } ],
  );

  my $b;
  foreach $b (@buttons)
  {
    $bbf->Button ('-text' => $b->[0], '-command' => $b->[1])
        ->pack (-side => 'left', '-fill' => 'x', -expand => 1);
  }

  $bbf->pack (-side => 'bottom', '-fill' => 'x', -expand => '1');

  $obj;
}

# ----------------------------------------------------------------------------
sub select_vpt
{
  my $DBgui= shift;
  my $lb= shift;
  my $action= shift;

  my $lb_idx= $lb->index ('active');
  if ($action eq 'dump')
  {
    my $db= $DBgui->{db};
    my $vptd= $db->find_viewptdef ($lb_idx);
    &HP200LX::DB::vpt::show_viewptdef ($vptd, *STDOUT);
  }
  elsif ($action eq 'hide')
  {
    $DBgui->hide_list ($lb_idx);
  }
  else
  {
    $DBgui->open_list ($lb_idx);
  }
}
