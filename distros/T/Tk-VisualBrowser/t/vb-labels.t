# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/Tk-VisualBrowser.t'

#########################

use Test::More tests => 54;
BEGIN { use_ok('Tk::VisualBrowser') };
use Data::Dumper;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Tk;

my $vb;
my $top;
my $use_l = 0;
my $use_b = 0;

my $VERSION = 1.00;
my (@IMG, @IMG2, @LABELS, @LABELS2, @BALLOONS, @BALLOONS2);

my @CFG = (
  { use_labels => 1, use_balloons => 1},
  { use_labels => 0, use_balloons => 1},
  { use_labels => 1, use_balloons => 0},
);

foreach my $ref (@CFG) { # test loop {{{
  $use_l = $ref->{use_labels};
  $use_b = $ref->{use_balloons};

  $top = MainWindow->new;
  # Menubar
  $top->configure(-menu => my $menubar = $top->Menu
    ,  -title => "Tk::VisualBrowser ".$Tk::VisualBrowser::VERSION
  );
  $menubar->cascade(-label => "~File",
    -menuitems =>
    [
      [command => 'List of Pictures', '-command', sub{ show_list( $vb) }],
      [command => 'List of selected', '-command', sub{ show_selected( $vb) }],
      [command => 'Swap', '-command', sub{ $vb->swap_selected }],
      [command => 'Select all', '-command', sub{ $vb->select_all }],
      [command => 'Deselect all', '-command', sub{ $vb->deselect_all }],
  
      [qw/command Exit -command/, sub{ exit }],
    ],
  );
  $menubar->cascade(-label => "~Help",
    -menuitems =>
    [
      [qw/command About -command/, sub{ print "test.pl: version $VERSION\n"}],
      [qw/command Contents -command/, sub{ print "TODO: implement Help ...\n" }],
    ],
  );
  
  
  
  $vb = $top->VisualBrowser(-rows => 3, -cols => 4, -use_labels => $use_l, -use_balloons => $use_b)->pack;
  
  @IMG = qw(
  ScanImage16.gif
  ScanImage17.gif
  ScanImage18.gif
  ScanImage19.gif
  ScanImage20.gif
  ScanImage21.gif
  ScanImage22.gif
  ScanImage23.gif
  ScanImage39.gif
  ScanImage40.gif
  ScanImage41.gif
  );
  @IMG2 = @IMG; # copy
  @LABELS = qw(
  Label-16
  Label-17
  Label-18
  Label-19
  Label-20
  Label-21
  Label-22
  Label-23
  Label-39
  Label-40
  Label-41
  );
  @LABELS2 = @LABELS; # copy
  @BALLOONS = qw(
  Balloon-16
  Balloon-17
  Balloon-18
  Balloon-19
  Balloon-20
  Balloon-21
  Balloon-22
  Balloon-23
  Balloon-39
  Balloon-40
  Balloon-41
  );
  @BALLOONS2 = @BALLOONS; # copy
  
  # try to use 0 as number of rows:
  eval {
    $vb->configure(-rows => 0, -cols => 4,
    );
  };
  #print ">>$@<<\n";
  ok($@, "error in number of rows");
  
  # try to use 0 as number of cols:
  eval {
    $vb->configure(-rows => 3, -cols => 0);
  };
  #print ">>$@<<\n";
  ok($@, "error in number of cols");
  
  
  $vb->configure(-pictures => \@IMG,
    -rows => 3, -cols => 3,
    -thumbnail => \&get_thb,
    -highlight => "yellow",
      -balloon_texts => \@BALLOONS, -label_texts => \@LABELS
  );
  
  
  my $b_exit = $top->Button(
    -text      => "Exit",
    -width     => 6,
    -command   => sub{
      exit;
                  },
  )->pack();
  
  $vb->scroll(0);
  
  
  # select all
  $vb->select_all;
  my @sel = $vb->get_selected;
  ok( eq_array(\@sel, \@IMG), "select all");
  
  # select none
  $vb->deselect_all;
  @sel = $vb->get_selected;
  is( scalar @sel, 0, "deselect all");
  
  $vb->select(3);
  $vb->select(4);
  @sel = $vb->get_selected_idx;
  ok( eq_array(\@sel, [3, 4]), "select 3, 4");
  $vb->deselect_all;
  
  # swap two pictures
  ($IMG2[3], $IMG2[5]) = ($IMG2[5], $IMG2[3]);
  $vb->{SEL}[5] = 1;  # whitebox test ...
  $vb->{SEL}[3] = 1;
  $vb->swap_selected;
  $vb->select_all;
  @sel = $vb->get_selected;
  $vb->deselect_all;
  ok( eq_array(\@sel, \@IMG2), "swap");
  ok( eq_array(\@IMG, \@IMG2), "swap img"); # original array has been modified ...
  ($BALLOONS2[3], $BALLOONS2[5]) = ($BALLOONS2[5], $BALLOONS2[3]);
  ($LABELS2[3], $LABELS2[5])     = ($LABELS2[5], $LABELS2[3]);
  ok( eq_array(\@BALLOONS, \@BALLOONS2), "swap balloons") if $use_b;
  ok( eq_array(\@LABELS, \@LABELS2), "swap labels") if $use_l;
# print "IMG", Dumper @IMG;
# print "IMG2", Dumper @IMG2;
# print "BALLOONS", Dumper @BALLOONS;
# print "BALLOONS2", Dumper @BALLOONS2;
  
  # select more than two and try to swap
  $vb->{SEL}[5] = 1;  # whitebox test ...
  $vb->{SEL}[3] = 1;
  $vb->{SEL}[2] = 1;
  my $ok = $vb->swap_selected;
  
  is($ok, 0, "error in swap");
  $vb->deselect_all;
  
  
  # try to get color info about some subwidgets:
  my $bg = $vb->{Thmb}[0][1]->cget(-background);
  is($bg, "#CCCCCC", "bg Thmb");
  $vb->configure(-bg_color => "#c3c3c3");
  $vb->configure(-pictures => \@IMG ); # in order to get the new colors via rebuild ...
  $bg = $vb->{Thmb}[0][1]->cget(-background);
  is($bg, "#c3c3c3", "bg Thmb");
  
  #======================
  if (! $ENV{INTERACTIVE_MODE}){
  $top->after(1500, sub{ remove_test($vb);} );
  $top->after(2000, sub{ reconfig_test($vb);} );
  $top->after(3000, sub{ ok(1, "exit automatically"); $top->destroy} );
  }
  MainLoop;
} # test loop }}}

sub get_thb {
  shift;
}

sub show_list { #{{{
  my $vb = shift;
  show_files(@{$vb->cget('-pictures')});
} # show_list }}}

sub show_selected { #{{{
  my $vb = shift;
  show_files($vb->get_selected);
} # show_selected #}}}

sub show_files { #{{{
  my @files = @_;
  my $tl = $top->Toplevel( -title => "Pictures in ./");

  my $list = $tl -> ScrlListbox(
  -label => 'Pictures',
  -height => 15,
  -width  => 55,
  -selectmode => 'single',
  -exportselection => 0,
  ) -> pack;

  my $b_ok = $tl->Button(
    -text      => "Ok",
    -width     => 4,
    -command   => sub{
                     $tl->destroy;
                  },
  )->pack;
  
  foreach my $jpg ( @files ){
    $list->insert("end", " $jpg");
  }
} # show_files }}}

sub reconfig_test { # {{{
  my $vb = shift;
  $vb->configure(-pictures => \@IMG,
  -rows => 2, -cols => 4,
  -thumbnail => \&get_thb,
  -highlight => "green",
    -balloon_texts => \@BALLOONS, -label_texts => \@LABELS
);

  my $r = $vb->cget(-rows);
  my $c = $vb->cget(-cols);
  is($r, 2, "rows");
  is($c, 4, "cols");
} # reconfig_test }}}

sub remove_test { # {{{
  my $vb = shift;
  $vb->deselect_all();
  $vb->select(3);
  $vb->select(5);
  $vb->remove_selected();
  $vb->select_all();
  my @sel = $vb->get_selected;
  print "@sel\n";
  print "@IMG\n";
  splice(@IMG2, 5, 1);
  splice(@IMG2, 3, 1);
  splice(@LABELS2, 5, 1);
  splice(@LABELS2, 3, 1);
  splice(@BALLOONS2, 5, 1);
  splice(@BALLOONS2, 3, 1);
  ok( eq_array(\@sel, \@IMG), "select after remove");
  ok( eq_array(\@sel, \@IMG2), "select after remove");
  ok( eq_array(\@BALLOONS, \@BALLOONS2), "BALLOONS after remove") if $use_b;
  ok( eq_array(\@LABELS, \@LABELS2), "LABELS after remove") if $use_l;
} # remove_test }}}

__END__

 vim:ft=perl:foldmethod=marker:foldcolumn=4
